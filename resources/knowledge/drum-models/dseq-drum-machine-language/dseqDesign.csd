<CsoundSynthesizer>
<CsInstruments>
sr     = 44100
kr     = 4410
ksmps  = 10
nchnls = 2




; Instrument List
# define dseq          # 1 #
# define dseqTemplate  # 2 #
# define valueAmp      # 3 #
# define valuePitch    # 4 #
# define paramStandard # 5 #
# define paramGlobal   # 6 #
# define paramTable    # 7 #
# define durFixed      # 8 #
# define durAbsolute   # 9 #
# define durBeatTime   # 10 #
# define durDivision   # 11 #




; Globals for instr paramGlobal
giamp   = 0.5
gipitch = 9.00
gipan   = 0.9




; instr dseq
; --- inlined: ./dseq.csinstr ---

instr $dseq
/*
	dseq drum machine micro-language v0.3
	
	by   Jacob Joaquin
	date March 3, 2008
	web  http://www.thumbuki.com/
*/

	ispb        =      p3          ; Seconds per beat, set to 1 in score
	iinstr      =      p4          ; The instrument to generate events for
	ithru1      =      p5          ; User parameter passed to iinstr
	ithru2      =      p6          ; User parameter passed to iinstr
	ithru3      =      p7          ; User parameter passed to iinstr
	ithru4      =      p8          ; User parameter passed to iinstr
	ithru5      =      p9          ; User parameter passed to iinstr
	Sphrase     strget p10         ; dseq phrase to interpret
	ilength     strlen Sphrase     ; Length of the pattern
	iSindex     =      0           ; Points to the current string index
	itime       =      0           ; Relative postion of phrase, in beat time
	iresolution =      1 / 16 * 4  ; Defaults to a sixteenth note

	; Exit if empty string
	if( ilength == 0 ) igoto exit

	; For error messaging system
	imessages = 1  ; Are messages turned on?  1 = on, 0 = off
	ispace    = 0  ; Counts spaces for error messages

	; Converts all letters to lower case
	Sphrase strlower Sphrase

	; Ascii ranges of hexadecimal characters
	ic_0 strchar "0"
	ic_9 strchar "9"
	ic_a strchar "a"
	ic_f strchar "f"

	; Calculate k-frame
	ikf = 1 / kr / ispb



	main_loop:
		; Read character from string
		Schar strsub Sphrase, iSindex, iSindex + 1
	
		; Space " "
		icompare strcmp Schar, " "
		if( icompare == 0 ) igoto main_space

		; Rest "."
		icompare strcmp Schar, "."
		if( icompare == 0 ) igoto main_rest
	
		; Hexadecimal 0-f
		ic_x strchar Schar
		if( ( ic_x >= ic_0 && ic_x <= ic_9 ) || \
          ( ic_x >= ic_a && ic_x <= ic_f ) ) igoto main_hexadecimal

		; Resolution "r"
		icompare strcmp Schar, "r"
		if( icompare == 0 ) igoto r_loop

		; Error
		igoto err_main_loop



	main_space:
		; Do nothing, process next character
		igoto advanceSindex



	main_rest:
		; Advance internal clock
		itime = itime + iresolution

		; Process next character
		igoto advanceSindex


			
	main_hexadecimal:
		; Convert hexadecimal character to a value between 0 and 15
		Svalue strcat "0x", Schar
		ivalue strtol Svalue

		; Schedule i-event
		schedule iinstr, itime * ispb, ikf, ispb, iresolution, ivalue, \
		         ithru1, ithru2, ithru3, ithru4, ithru5

		; Advance internal clock
		itime = itime + iresolution

		; Process next character
		igoto advanceSindex



	r_loop:
		; Clear resolution value string 
		SrValue strcpy  ""

		; Read in next character from phrase
		iSindex =       iSindex + 1
		Schar   strsub  Sphrase, iSindex, iSindex + 1

		; Get ascii value of Schar
		ic_x strchar Schar

		; Integer 0-9
		if( ( ic_x >= ic_0 ) && ( ic_x <= ic_9 ) ) igoto r_int

		; Error
		igoto err_d_loop



	r_int:
		; Append string integer to SrValue
		SrValue strcat SrValue, Schar

		; Get next character from phrase
		iSindex = iSindex + 1
		Schar strsub Sphrase, iSindex, iSindex + 1

		; Space " "
		icompare strcmp Schar, " "
		if( icompare == 0 ) igoto r_calculate

		; Integer 0-9
		ic_x strchar Schar
		if( ( ic_x >= ic_0 ) && ( ic_x <= ic_9 ) ) igoto r_int
	
		; Triplet "t"
		icompare strcmp Schar, "t"
		if( icompare == 0 ) igoto r_triplet
	
		; Sub-divide "d"		
		icompare strcmp Schar, "d"
		if( icompare == 0 ) igoto d_loop
	
		; Error
		igoto err_r_int
			


	r_calculate:
		irInt strtol SrValue             ; Convert string to integer
		if( irInt == 0 ) igoto err_zero  ; Error, value of zero not allowed
		iresolution =  4 / irInt         ; Change division of note

		; Process next character
		igoto advanceSindex



	r_triplet:
		irInt strtol SrValue             ; Convert string to integer
		if( irInt == 0 ) igoto err_zero  ; Error, value of zero not allowed
		iresolution = 8 / ( 3 * irInt )  ; Change division of note

		; Get next character from phrase 
		iSindex =      iSindex + 1
		Schar   strsub Sphrase, iSindex, iSindex + 1

		; Space " "
		icompare strcmp Schar, " "
		if( icompare == 0 ) igoto advanceSindex

		; Error
		igoto err_r_triplet



	d_loop:
		irInt strtol SrValue             ; Convert string to integer
		if( irInt == 0 ) igoto err_zero  ; Error, value of zero not allowed

		; Clear sub-divide value string 
		SdValue strcpy ""

		; Get next character from phrase
		iSindex =      iSindex + 1
		Schar   strsub Sphrase, iSindex, iSindex + 1
	
		; Integer 0-9
		ic_x strchar Schar
		if( ( ic_x >= ic_0 ) && ( ic_x <= ic_9 ) ) igoto d_int

		; Error
		igoto err_d_loop



	d_int:
		; Append string integer to SdValue
		SdValue strcat SdValue, Schar

		; Get next character from phrase
		iSindex =      iSindex + 1
		Schar   strsub Sphrase, iSindex, iSindex + 1

		; Space " "
		icompare strcmp Schar, " "
		if( icompare == 0 ) igoto d_calculate

		; Integer 0-9
		ic_x strchar Schar
		if( ( ic_x >= ic_0 ) && ( ic_x <= ic_9 ) ) igoto d_int

		; Error
		igoto err_d_int



	d_calculate:
		idInt strtol SdValue                 ; Convert string to integer
		if( idInt == 0 ) igoto err_zero      ; Error, value of zero not allowed
		iresolution = 4 / ( irInt * idInt )  ; Change division of note

		; Process next character
		igoto advanceSindex



	advanceSindex:
		; Get next character from phrase
		iSindex = iSindex + 1

		; If end of phrase has not been reached, go to main_loop
		if( iSindex < ilength ) igoto main_loop

		; Phrase finished, exit interpreter
		igoto exit






	; Error Messages

	err_main_loop:
		if( imessages == 0 ) igoto exit
		printf_i "\ndseq error.  Invalid character detected:\n\t%s\n\t", 1, Sphrase
	err_main_loop_space:
		if( ispace == iSindex ) igoto err_main_loop_continue
		prints " "
		ispace = ispace + 1
		igoto err_main_loop_space
	err_main_loop_continue:
		prints "^^\n\tExpects ' ', 0-f, . or r here.\n"
		igoto err_terminate



	err_d_loop:
		if( imessages == 0 ) igoto exit
		printf_i "\ndseq error.  Invalid character detected:\n\t%s\n\t", 1, Sphrase
	err_d_loop_space:
		if( ispace == iSindex ) igoto err_d_loop_continue
		prints " "
		ispace = ispace + 1
		igoto err_d_loop_space
	err_d_loop_continue:
		prints "^^\n\tExpects 0-9 here.\n"
		igoto err_terminate



	err_r_int:
		if( imessages == 0 ) igoto exit
		printf_i "\ndseq error.  Invalid character detected:\n\t%s\n\t", 1, Sphrase
	err_r_int_space:
		if( ispace == iSindex ) igoto err_r_int_continue
		prints " "
		ispace = ispace + 1
		igoto err_r_int_space
	err_r_int_continue:
		prints "^^\n\tExpects ' ', t or d here.\n"
		igoto err_terminate



	err_d_int:
		if( imessages == 0 ) igoto exit
		printf_i "\ndseq error.  Invalid character detected:\n\t%s\n\t", 1, Sphrase
	err_d_int_space:
		if( ispace == iSindex ) igoto err_d_int_continue
		prints " "
		ispace = ispace + 1
		igoto err_d_int_space
	err_d_int_continue:
		prints "^^\n\tExpects 0-9 or ' ' here.\n"
		igoto err_terminate



	err_r_triplet:
		if( imessages == 0 ) igoto exit
		printf_i "\ndseq error.  Invalid character detected:\n\t%s\n\t", 1, Sphrase
	err_r_triplet_space:
		if( ispace == iSindex ) igoto err_r_triplet_continue
		prints " "
		ispace = ispace + 1
		igoto err_r_triplet_space
	err_r_triplet_continue:
		prints "^^\n\tExpects ' ' here.\n"
		igoto err_terminate



	err_zero:
		if( imessages == 0 ) igoto exit
		printf_i "\ndseq error.  Invalid value detected:\n\t%s\n\t", 1, Sphrase
	err_zero_space:
		if( ispace == ( iSindex - 1 ) ) igoto err_zero_continue
		prints " "
		ispace = ispace + 1
		igoto err_zero_space
	err_zero_continue:
		prints "^^\n\tExpects a value greater than 0 here.\n"
		igoto err_terminate



	err_terminate:
		prints "\tInterpreter terminated.\n\n";





	; Exit Interpreter
	exit:
endin


; --- end ./dseq.csinstr ---





instr $dseqTemplate
	ikf    = p3   ; One k-frame in seconds
	ispb   = p4   ; Seconds per beat
	ires   = p5   ; The resolution of the beat.  One beat = 1
	ivalue = p6   ; Numeric value of the note trigger
	iudp1  = p7   ; User-defined paramter 1
	iudp2  = p8   ; User-defined paramter 2
	iudp3  = p9   ; User-defined paramter 3
	iudp4  = p10  ; User-defined paramter 4
	iudp5  = p11  ; User-defined paramter 5

	idur = 1            ; Set duration to one second
	xtratim idur - ikf  ; Extend time


	; Insert Synthesis Engine Here


endin




instr $valueAmp
	ikf    = p3
	inull  = p4
	inull  = p5
	ivalue = p6
	inull  = p7
	inull  = p8
	inull  = p9
	inull  = p10
	inull  = p11


	; Instrument duration
	idur = 0.5
	xtratim idur - ikf


	; Convert note trigger value to amplitude
	iamp = ( ivalue / 15 ) * 0dbfs


	; Oscillator amplitude controlled by dseq value
	aosc oscils iamp, 440, 0


	; Amplitude envelope
	aenv line 1, idur, 0
	aosc =    aosc * aenv


	; Output
	outs aosc, aosc
endin




instr $valuePitch
	ikf      = p3
	inull    = p4
	inull    = p5
	ivalue   = p6
	iamp     = p7  ; Amplitude
	ibasepch = p8  ; Base Pitch
	inull    = p9
	inull    = p10
	inull    = p11


	; Instrument duration
	idur = 0.5
	xtratim idur - ikf


	; Convert note trigger value to pitch
	ipch = cpspch( ibasepch + ( 0.01 * ivalue ) )


	; Scale amplitude
	iamp = iamp * 0dbfs


	; Oscillator amplitude controlled by dseq value
	aosc oscils iamp, ipch, 0


	; Amplitude envelope
	aenv line 1, idur, 0
	aosc =    aosc * aenv


	; Output
	outs aosc, aosc
endin




instr $paramStandard
	ikf    = p3
	inull  = p4
	inull  = p5
	ivalue = p6
	iamp   = p7  ; Amplitude
	ipitch = p8  ; Pitch
	ipan   = p9  ; Pan
	inull  = p10
	inull  = p11


	; Instrument duration
	idur = 0.5
	xtratim idur - ikf


	; Oscillator
	iamp =      iamp * ( ivalue / 15 ) * 0dbfs
	aosc oscils iamp, cpspch( ipitch ), 0


	; Amplitude
	aenv line 1, idur, 0
	aosc =    aosc * aenv


	; Output with panning
	outs aosc * sqrt( 1 - ipan ), aosc * sqrt( ipan )
endin




instr $paramGlobal
	ikf    = p3
	inull  = p4
	inull  = p5
	ivalue = p6
	inull  = p7
	inull  = p8
	inull  = p9
	inull  = p10
	inull  = p11


	; Get global values
	iamp   = giamp
	ipitch = gipitch
	ipan   = gipan


	; Instrument duration
	idur = 0.5          ; Fixed time of 0.5 seconds
	xtratim idur - ikf  ; Extend time of current i-event to 0.5 seconds


	; Oscillator
	iamp =      iamp * ( ivalue / 15 ) * 0dbfs
	aosc oscils iamp, cpspch( ipitch ), 0


	; Amplitude
	aenv line 1, idur, 0
	aosc =    aosc * aenv


	; Output with panning
	outs aosc * sqrt( 1 - ipan ), aosc * sqrt( ipan )
endin




instr $paramTable
	ikf    = p3
	inull  = p4
	inull  = p5
	ivalue = p6
	iamp   = p7  ; Amplitude
	itable = p8  ; Table storing parameters
	inull  = p9
	inull  = p10
	inull  = p11


	; Get values from table
	ipitch   table 0, itable  ; Pitch
	iwave    table 1, itable  ; Wave shape
	ivibfreq table 2, itable  ; Vibrato frequency
	ivibamt  table 3, itable  ; Vibrato amount, in half steps
	ivibwave table 4, itable  ; Vibrato wave shape
	iatt     table 5, itable  ; Attack of envelope
	ipan     table 6, itable  ; Pan
	

	; Instrument duration
	idur = 0.5
	xtratim idur - ikf


	; Pitch
	ipitch = cpspch( ipitch )


	; Amplitude Envelope
	iamp  =     iamp * ( ivalue / 15 ) * 0dbfs
	aenv linseg 0, iatt * idur, iamp, idur * ( 1 - iatt ), 0


	; Vibrato lfo
	klfo oscil 0.5, ivibfreq, ivibwave, -1
	klfo =     2^(( klfo + 0.5 ) * ivibamt / 12)


	; Oscillator
	aosc oscil aenv, ipitch * klfo, iwave, -1


	; Output with panning
	outs aosc * sqrt( 1 - ipan ), aosc * sqrt( ipan )
endin




instr $durFixed
	ikf   = p3
	inull = p4
	inull = p5
	inull = p6
	inull = p7
	inull = p8
	inull = p9
	inull = p10
	inull = p11

	; Instrument duration
	idur = 1
	xtratim idur - ikf  ; Extend time to idur


	; Oscillator
	aosc oscil 0dbfs, 262, 1


	; Output with panning
	outs aosc, aosc
endin




instr $durAbsolute
	ikf   = p3
	inull = p4
	inull = p5
	inull = p6
	iamp  = p7  ; Amplitude
	idur  = p8  ; Duration in seconds
	inull = p9
	inull = p10
	inull = p11

	; Instrument duration
	xtratim idur - ikf  ; Extend time to idur


	; Amplitude
	iamp =      iamp * 0dbfs
	aenv linseg iamp, idur - 0.005, iamp, 0.005, 0  ; Remove click


	; Oscillator
	aosc oscil aenv, 440, 1


	; Output with panning
	outs aosc, aosc
endin




instr $durBeatTime
	ikf   = p3
	ispb  = p4  ; Seconds per beat
	inull = p5
	inull = p6
	iamp  = p7  ; Amplitude
	idur  = p8  ; Duration in beats
	inull = p9
	inull = p10
	inull = p11


	; Instrument duration
	idur = idur * ispb  ; Convert to relative time
	xtratim idur - ikf  ; Extend time to idur


	; Amplitude
	iamp =      iamp * 0dbfs
	aenv linseg iamp, idur - 0.005, iamp, 0.005, 0  ; Remove click


	; Oscillator
	aosc oscil aenv, 440, 1


	; Output with panning
	outs aosc, aosc
endin




instr $durDivision
	ikf   = p3
	ispb  = p4  ; Seconds per beat
	ires  = p5  ; Resolution of trigger
	inull = p6
	iamp  = p7  ; Amplitude
	inull = p8
	inull = p9
	inull = p10
	inull = p11


	; Instrument duration
	idur = ispb * ires  ; Set duration to note division
	xtratim idur - ikf  ; Extend time to idur


	; Amplitude
	iamp =      iamp * 0dbfs
	aenv linseg iamp, idur - 0.005, iamp, 0.005, 0  ; Remove click


	; Oscillator
	aosc oscil aenv, 440, 1


	; Output with panning
	outs aosc, aosc
endin




</CsInstruments>
<CsScore>

; Instrument List
# define dseq          # 1 #
# define dseqTemplate  # 2 #
# define valueAmp      # 3 #
# define valuePitch    # 4 #
# define paramStandard # 5 #
# define paramGlobal   # 6 #
# define paramTable    # 7 #
# define durFixed      # 8 #
# define durAbsolute   # 9 #
# define durBeatTime   # 10 #
# define durDivision   # 11 #


; Wave shapes
f 1 0 [2^16+1] 10 1                          ; Sine
f 2 0 [2^16+1] -7 -1 [2^15] 1 [2^15] -1      ; Triangle
f 3 0 [2^16+1] -7 1 [2^16] -1                ; Saw
f 4 0 [2^16+1] -7 1 [2^15] 1 0 -1 [2^15] -1  ; Square


; Parameter Table
f 100 0 8 -2 8.00 2 7 5 4 0.1 0.24 0


; Tempo
t 0 90



i $dseq 0  1 $valueAmp      0   0    0   0 0 "f.2. 4.6. 8.a. 0.f." 
i $dseq 4  1 $valuePitch    0.5 8.00 0   0 0 "0.2. 4.5. 7.2. 7.0." 
i $dseq 8  1 $paramStandard 0.5 8.07 0.1 0 0 "f.2. 4.6. 8.a. 0.f." 
i $dseq 12 1 $paramGlobal   0   0    0   0 0 "f.2. 4.6. 8.a. 0.f." 
i $dseq 16 1 $paramTable    0.5 100  0   0 0 "2... 6... c84. f..." 
i $dseq 20 1 $durFixed      0   0    0   0 0 "f... .... f... ...." 
i $dseq 24 1 $durAbsolute   0.5 0.5  0   0 0 "f... f... f... f..." 
i $dseq 28 1 $durBeatTime   0.5 0.5  0   0 0 "f... f... f... f..." 
i $dseq 32 1 $durDivision   0.5 0.5  0   0 0 "f... f... f... f..." 

e 36

</CsScore>
</CsoundSynthesizer>
