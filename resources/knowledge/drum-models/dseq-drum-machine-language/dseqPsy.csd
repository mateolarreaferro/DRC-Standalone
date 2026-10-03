<CsoundSynthesizer>
<CsInstruments>
sr     = 44100
kr     = 4410
ksmps  = 10
nchnls = 2




/*
Musical example, psyKick and and psyBass by:
	Joe Maffei

Web:
	www.joemaffei.com
*/




; Instrument list
# define dseq     # 1 #
# define psyKick  # 2 #
# define psyBass  # 3 #




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





instr $psyKick

; by Joe Maffei
; www.joemaffei.com

	ikf     = p3
	ispb    = p4
	inull   = p5
	ivalue  = p6 
	iamp    = p7 * 0dbfs * ( ivalue / 15 )  ; Amplitude
	ifreq   = p8                            ; Frequency
	ireverb = p9                            ; Reverb
	inull   = p10
	inull   = p11


	; Extend time
	idur = 0.5 * ispb  ; Duration in beat time
	xtratim idur - ikf

	k1 linseg 1.5, .200, .5
	k2 linseg 2, .060, 1
	k3 linseg 4, .010, 1
	k4 linseg 4, .002, 1
	klvl linseg 0, .0002, 1, .030, .8, .080, .7, idur-.1102, 0
	akick oscil iamp*klvl, ifreq*k1*k2*k3*k4, 1
	al,ar freeverb akick, akick, 0.8, 0.35, sr, 0
	al = (akick*(1-ireverb))+(al*ireverb)
	ar = (akick*(1-ireverb))+(ar*ireverb)
	outs al, ar
endin




instr $psyBass

; by Joe Maffei
; www.joemaffei.com

	ikf      = p3
	inull    = p4
	inull    = p5
	ivalue   = p6
	iamp     = p7 * 0dbfs
	ibasepch = p8
	ireverb  = p9
	inull    = p10
	inull    = p11

	; Extend Time
	idur = 0.5
	xtratim idur - ikf

	ipch = cpspch( ibasepch + ( ivalue * 0.01 ) )

	klvl expseg 1, .050, .5, .450, 0.00003
	aosc1 vco iamp*klvl, ipch, 1, .5, 1
	aosc2 vco iamp*klvl, ipch*1.01, 1, .5, 1
	aosc3 vco iamp*klvl, ipch*0.99, 1, .5, 1
	aoscall = aosc1+aosc2+aosc3
	kcut linseg 1, .030, .1
	afilt moogladder aoscall, 5000*kcut, .4
	al,ar freeverb afilt, afilt, 0.8, 0.35, sr, 0
	al = afilt+al*ireverb
	ar = afilt+ar*ireverb
	outs al, ar
endin




</CsInstruments>
<CsScore>

# define dseq     # 1 #
# define psyKick  # 2 #
# define psyBass  # 3 #


f 1 0 8192 10 1

t 0 150

; Musical example by Joe Maffei
; www.joemaffei.com

i $dseq 0 1 $psyKick 0.8 44   0.01 0   0 "f... f... f... f..." 
i $dseq 0 1 $psyBass 0.8 5.09 0.04 0.5 0 "..0. ..c. ..0a ..c." 

i $dseq 4 1 $psyKick 0.8 44   0.01 0   0 "f... f... f... f..." 
i $dseq 4 1 $psyBass 0.8 5.09 0.04 0.5 0 "..0. ..c. ..0a ..c." 

i $dseq 8 1 $psyKick 0.8 44   0.01 0   0 "f... f... f... f..." 
i $dseq 8 1 $psyBass 0.8 5.09 0.04 0.5 0 "..0. ..c. ..0a ..c." 

i $dseq 12 1 $psyKick 0.8 44   0.01 0   0 "f... f... f... f..." 
i $dseq 12 1 $psyBass 0.8 5.09 0.04 0.5 0 "..0. ..c. ..0a ..c." 


e 16

</CsScore>
</CsoundSynthesizer>
