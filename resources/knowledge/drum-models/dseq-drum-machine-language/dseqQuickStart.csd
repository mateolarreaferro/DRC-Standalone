<CsoundSynthesizer>
<CsInstruments>
sr     = 44100
kr     = 4410
ksmps  = 10
nchnls = 2




; Instrument List
# define dseq  # 1 #
# define kick  # 2 #
# define snare # 3 #
# define hihat # 4 #




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



instr $kick
	ikf    = p3
	inull  = p4
	inull  = p5
	ivalue = p6
	iamp   = p7 * ( ivalue / 15 ) * 0dbfs * 0.5
	inull  = p8
	inull  = p9
	inull  = p10
	inull  = p11


	; Extend time of instrument
	idur = 0.35
	xtratim idur - ikf


	
	kenv1 expseg 900, 0.01, 50, idur - 0.01, 44
	asig1 oscil3 1, kenv1, 1
	kenv2 line   1, idur, 0
	asig1 =      asig1 * kenv2

	asig2  gauss  1
	kenv5  expseg 800, 0.1, 50, idur - 0.1, 44
	asig2  tone   asig2, kenv5
	
	amix  = asig1 + asig2
	
	kenv5 expseg 500, 0.05, 60, idur - 0.05, 44
	amix  rezzy  amix, kenv5, 10

	kenv6 linseg 55, idur, 44
	aosc  oscil3 1, kenv6, 1

	kenv4 expon 2, idur, 1
	kenv4 =      kenv4 - 1

	amix =  ( amix * 0.8 + aosc  * 1.2 ) * kenv4 * iamp

	outs amix, amix
endin




instr $snare
	ikf    = p3
	inull  = p4
	inull  = p5
	ivalue = p6 / 15
	iamp   = p7 * 0.5 * ivalue * 0dbfs
	inull  = p8
	inull  = p9
	inull  = p10
	inull  = p11

	; Extend time of instrument
	idur = 0.15
	xtratim idur - ikf


	
	atri         oscil3 1, 111 + ivalue * 5, 2	
	areal, aimag hilbert atri

	ifshift =      175
	asin    oscil3 1, ifshift, 1	
	acos    oscil3 1, ifshift, 1, .25	
	amod1   =      areal * acos
	amod2   =      aimag * asin
	ashift1 =      ( amod1 + amod2 ) * 0.7

	ifshift2 =      224
	asin     oscil3 1, ifshift2, 1	
	acos     oscil3 1, ifshift2, 1, .25	
 	amod1    =      areal * acos
	amod2    =      aimag * asin
	ashift2  =      ( amod1 + amod2 ) * 0.7
	
	kenv1     line 1, 0.15, 0
	ashiftmix =    ( ashift1 + ashift2 ) * kenv1
	
	aosc1   oscil3 1, 180, 1
	aosc2   oscil3 1, 330, 1
	kenv2   linseg 1, 0.08, 0, idur - 0.08, 0
	aoscmix =      ( aosc1 + aosc2 ) * kenv2

	anoise gauss    1
	anoise butterhp anoise, 2000
	anoise butterlp anoise, 3000 + ivalue * 3000
	anoise butterbr anoise, 4000, 200
	kenv3  expon    2, 0.15, 1
	anoise =        anoise * ( kenv3 - 1 )
	
	amix = aoscmix + ashiftmix + anoise * 4
	amix = amix * iamp 

	out amix, amix
endin




instr $hihat
	ikf    = p3
	inull  = p4
	inull  = p5
	ivalue = p6 / 15
	iamp   = p7 * ivalue * 0dbfs
	inull  = p8
	inull  = p9
	inull  = p10
	inull  = p11


	; Extend time of instrument
	idur = 0.07
	xtratim idur - ikf
 

	ifreq =     125 + ( 2 * ivalue )
	a1    oscil 1, ifreq * 1, 5
	a2    oscil 1, ifreq * 2.333, 5
	a3    oscil 1, ifreq * 3.578, 5
	a4    oscil 1, ifreq * 5.123, 5
	a5    oscil 1, ifreq * 7.632, 5
	a6    oscil 1, ifreq * 9.843, 5
	amix1 = a1 + a2 + a5	
	amix2 = a3 + a4 + a6


	idecay1 =      0.08 + ( 0.03 * ( 1 - ivalue ) )
	kenv1   expseg 2, 0.01, 2, 0, 1.6, idecay1, 1, idur - idecay1 - 0.01, 1
	kenv1   =      kenv1 - 1
	amix1   =      amix1 * kenv1
	amix2   =      amix2 * kenv1

	
	idecay2 =      0.11 + 0.05 * ivalue
	kenv2   linseg 1, idecay2, 0, idur - idecay2, 0
	anoise  gauss  1
	

	amix1 =        ( anoise * kenv2 ) + amix1 * 0.5
	amix1 butterhp amix1, 7000	
	amix1 butterlp amix1, 9000 + ivalue * 3000


	amix2 =        ( anoise * kenv2 ) + amix2 * 0.5
	amix2 butterhp amix2, 7000	
	amix2 butterlp amix2, 9000 + ivalue * 3000
	
	amix1 = amix1 * iamp
	amix2 = amix2 * iamp

	out amix1, amix2
endin




</CsInstruments>
<CsScore>

; Instrument List
# define dseq  # 1 #
# define kick  # 2 #
# define snare # 3 #
# define hihat # 4 #

; Tables
f 1 0 [2^16+1] 10 1                     ; Sine
f 2 0 8192     -7 -1 4096 1 4096 -1     ; Triangle
f 5 0 8192     -7 1 200 1 0 -1 7912 -1

; Tempo
t 0 120


i $dseq 0 1 $hihat 0.5 0 0 0 0 "8.8.8.8.8.8.8.8." 
i $dseq 0 1 $snare 0.5 0 0 0 0 "....f.......f..." 
i $dseq 0 1 $kick  0.5 0 0 0 0 "f.......f......." 

i $dseq 4 1 $hihat 0.5 0 0 0 0 "8.8.8.8.8.8.8.8." 
i $dseq 4 1 $snare 0.5 0 0 0 0 "....f.......f..." 
i $dseq 4 1 $kick  0.5 0 0 0 0 "f.......f.8....." 

i $dseq 8 1 $hihat 0.5 0 0 0 0 "8.8.8.8.8.8.8.8." 
i $dseq 8 1 $snare 0.5 0 0 0 0 "....f.......f..." 
i $dseq 8 1 $kick  0.5 0 0 0 0 "f.......f......." 

i $dseq 12 1 $hihat 0.5 0 0 0 0 "8.8.8.8.8.8.8.8." 
i $dseq 12 1 $snare 0.5 0 0 0 0 "....f.......f..." 
i $dseq 12 1 $kick  0.5 0 0 0 0 "f.......f.8....." 

e 16

</CsScore>
</CsoundSynthesizer>
