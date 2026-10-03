<CsoundSynthesizer>
<CsInstruments>
sr     = 44100
kr     = 4410
ksmps  = 10
nchnls = 2




; Instrument List
# define dseq         # 1 #
# define kick         # 2 #
# define snare        # 3 #
# define hihat        # 4 #
# define sineKick     # 5 #
# define gaussBurst   # 6 #
# define triKick      # 7 #
# define lofiSnare    # 8 #
# define fugwhump     # 9 #
# define fmBumper     # 10 #
# define clapper      # 11 #
# define simpleRez    # 12 #
# define blue         # 13 #
# define black        # 14 #
# define copper       # 15 #
# define psyKick      # 16 #
# define psyBass      # 17 #
# define fofVoice     # 18 #




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




instr $sineKick
	ikf    = p3
	inull  = p4
	inull  = p5
	ivalue = p6
	iamp   = p7 * ( ivalue / 15 ) * 0dbfs  ; Amplitude
	ifreq  = p8                            ; Starting frequency
	ifreqr = p9 * ifreq                    ; Frequency envelope amount
	idecay = p10                           ; Decay rate / duration
	itrans = p11 * 0.25                    ; Initial transient [0.0 - 1.0] 


	; Extend time of instrument
	xtratim idecay - ikf


	; Envelopes
	apitch expon ifreq, idecay, ifreqr
	aamp   line iamp, idecay, 0


	; Sine Oscillator w/ initial click transient
	a1 poscil aamp, apitch, 1, itrans


	; Output Audio
	outs a1, a1
endin




instr $gaussBurst
	ikf    = p3
	inull  = p4
	inull  = p5
	ivalue = p6 / 15
	iamp   = p7 * ivalue * 0dbfs  ; Amplitude
	idur   = p8                   ; Duration
	ipan   = p9                   ; Pan
	inull  = p10
	inull  = p11


	; Extend time of instrument
	xtratim idur - ikf

	anoise1 gauss iamp
	anoise2 gauss iamp

	outs anoise1 * sqrt( 1 - ipan ), anoise2 * sqrt( ipan )
endin




instr $triKick
	ikf    = p3
	inull  = p4
	inull  = p5
	ivalue = p6 / 15
	iamp   = p7 * ivalue * 0dbfs  ; Amplitude
	ifreq  = p8                   ; Starting frequency
	ifreqr = p9 * ifreq           ; Frequency envelope amount
	idur   = p10                  ; Duration
	ipan   = p11                  ; Pan


	; Extend time of instrument
	xtratim idur - ikf


	igate = 0.002
	kenv  linseg  0.333, igate, 0.333, 0, 0, idur - igate, 0

	anoise1 gauss kenv
	anoise2 gauss kenv

	kenv2 expon ifreq, idur, ifreqr 
	aosc vco2 1, kenv2, 12

	aenv expon iamp + 1, idur, 1
	aenv = aenv - 1

	asig1 = ( aosc + anoise1 ) * aenv
	asig2 = ( aosc + anoise2 ) * aenv

	outs asig1 * sqrt( 1 - ipan ), asig2 * sqrt( ipan )
endin




instr $lofiSnare
	ikf    = p3
	inull  = p4
	inull  = p5
	ivalue = p6 / 15
	iamp   = p7 * ivalue * 0dbfs  ; Amplitude
	idur   = p8                   ; Duration
	isnap  = p9                   ; Amount of snap
	ipan   = p10                  ; Pan
	inull  = p11


	; Extend time of instrument
	xtratim idur - ikf



	anoise randh 1, 15125
	anoise limit anoise, -1, 1

	alpf butterlp anoise, 4000
	ahpf butterhp alpf, 2000


	aenv expon 2, idur, 1
	alpf =     alpf * ( aenv - 1 )
	ahpf =     ahpf * ( aenv - 1 )
	amix =     ( alpf + ahpf ) * iamp * 0.5

	isnap = ( isnap < 1 ? 1 : isnap )

	agate linseg isnap, 0.01, isnap, 0, 1, idur - 0.01, 1
	amix  =      amix * agate / isnap

	outs amix * sqrt( 1 - ipan ), amix * sqrt( ipan )
endin




instr $fugwhump
	ikf      = p3
	ispb     = p4
	ires     = p5
	ivalue   = p6 / 15
	iamp     = p7 * ivalue * 0dbfs  ; Amplitude
	idur     = p8                   ; Duration, 0.8 recommended
	ipunch   = p9                   ; Punch, 0.3 - 0.6 recommended
	itune    = p10                  ; Tune instrument, in Hz
	isubtune = p11                  ; Tun subtone, in Hz

	
	; Extend time of instrument
	xtratim idur - ikf


	ipunch = ( ipunch < 0.11 ? 0.11 : ipunch )  ; Ensure ipunch is not less than 0.11
	idur   = ( idur < ipunch ? ipunch : idur )  ; Ensure idur is not less than ipunch


	; Transient
	anoise     randh  1, 1000
	itranstime =      0.008
	aenv       linseg 1, itranstime, 1, 0, 0, idur - itranstime, 0
	anoise     =      anoise * aenv * 0.025


	; Punch
	aenv3   linseg 1, ipunch * 0.25, 0.5, ipunch * 0.75, 0, idur - ipunch, 0
	aoscil2 oscils 1, itune, 0
	aoscil2 =      aoscil2 * aenv3


	; Sub-tone
	ifadein =      0.1
	aenv2   linseg 0, ifadein, 1, idur - ifadein, 0
	aoscil  oscils 1, isubtune, 0
	aoscil  =      aoscil * aenv2


	; Mix
	amix = ( anoise + aoscil * 0.5 + aoscil2 ) * iamp

	outs amix, amix
endin




instr $fmBumper
	ikf    = p3
	inull  = p4
	inull  = p5
	ivalue = p6 / 15
	iamp   = p7 * ivalue * 0dbfs  ; Amplitude
	itable = p8                   ; Parameter table number
	inull  = p9
	inull  = p10
	inull  = p11


	; Read parameters from table
	ipch      table 0, itable      ; Pitch
	ipch      =     cpspch( ipch )
	ipchr     table 1, itable      ; Pitch envelope amount
	ipchr     =     ipchr * ipch
	indxstart table 2, itable      ; Index of Modulator start
	indxend   table 3, itable      ; Index of Modulator end
	idur      table 4, itable      ; Duration
	ipan      table 5, itable      ; Pan



	; Extend time of instrument
	xtratim idur - ikf

	
	aenv  line  ipchr, idur, ipch
	aenv2 expon indxstart, idur, indxend
	amod  oscil aenv2, aenv, 1
	acar  oscil 1, amod * ipch, 1

	agate linseg 1, idur - 0.01, 1, 0.01, 0
	amix  =      acar * iamp * agate

	outs amix * sqrt( 1 - ipan ), amix * sqrt( ipan )
endin




instr $clapper
	ikf    = p3
	inull  = p4
	inull  = p5
	ivalue = p6 / 15
	iamp   = p7 * ivalue * 0dbfs  ; Amplitude
	ipchr  = p8                   ; Pitch ration
	itight = p9                   ; Tightness amount of clap echos
	isnap  = p10                  ; Snap amount
	ipan   = p11                  ; Pan


	isnap = ( isnap < 1 ? 1 : isnap )  ; Ensure snap is greater than 1


	; Times of clap echos
	id1 = ( 0.0065 + rnd( 0.003 ) ) * itight
	id2 = ( 0.0085 + rnd( 0.003 ) ) * itight
	id3 = ( 0.0095 + rnd( 0.003 ) ) * itight


	; Extend time of instrument
	idur = 0.155 + id3
	xtratim idur - ikf


	anoise noise 1, 0
	ifreq  =     ( 2000 * ipchr ) * ( 2^(  rnd( 1 ) / 12 ) )
	ires   =     ifreq * 0.3
	abp    butbp anoise, ifreq, ires


	aenv linseg 0, 0.001, 1, 0.032, 1, 0.308, 0, idur - 0.032 - 0.308, 0
	alp moogvcf abp, ifreq * ( 1 + ivalue * 2.5 ) * aenv, 0


	aenv linseg 0, 0.001, isnap, 0.002, isnap, 0.002, 1, 0.15, 0, idur - 0.155, 0
	aenv =      aenv / isnap
	alp  =      alp * aenv


	adelay1 delay aenv, id1
	adelay2 delay aenv * -1, id1 + id2
	adelay3 delay aenv, id1 + id2 + id3

	
	amix = ( alp * aenv + alp * adelay1 + alp * adelay2 + alp * adelay3 ) * iamp * 2

	outs amix * sqrt( 1 - ipan ), amix * sqrt( ipan )
endin




instr $simpleRez
	ikf      = p3
	ispb     = p4
	ires     = p5
	ivalue   = p6
	iamp     = p7 * 0dbfs  ; Amplitude
	ibasepch = p8          ; Base pitch
	inull    = p9
	inull    = p10
	inull    = p11

	; Calculate pitch
	ipch = cpspch( ibasepch + ( 0.01 * ivalue ) )
	

	; Extend time of instrument
	idur = ires * ispb + 0.25 * ispb
	xtratim idur - ikf


	; Envelope
	iatt = 0.005
	isus = 0.0003
	idec = 0.05
	irel = idur - ( iatt + isus + idec )

	aenv linseg 0, iatt, 1, isus, 1, idec, 0.6, irel, 0


	; Oscillators
	iwave = 2
	asig  vco2 iamp, ipch, iwave, 0.01
	asig2 vco2 iamp, ipch * 1.01, iwave, 0.1
	asig3 vco2 iamp, ipch * 0.5, iwave, 0.3


	; Filter and Gate Envelope
	agate linseg     1, idur - 0.001, 1, 0.001, 0
	asig  =          ( asig + asig2 + asig3 )
	asig  moogladder asig, ipch * 6, 0.6
	asig  =          asig * aenv * agate


	; Random Pan
	ipan = rnd( 1 )

	outs asig * sqrt( 1 - ipan ), asig * sqrt( ipan )
endin




instr $blue
/*
	Instrument adapted from:
		Trapped in Convert
		by Dr. Richard Boulanger

	Table reference:
		f1 0 8192 10 1
		f15 0 8192 9 1 1 90
*/
	ikf    = p3
	ispb   = p4
	ires   = p5
	ivalue = p6
	iamp   = p7 * ( ivalue / 15 ) * 0dbfs
	ifreq  = p8
	ilfo   = p9
	inharm = p10
	ipan   = p11

	isweep = 0.5
	idur   = 4 * ires * ispb  ; Duration based on note division and tempo

	; Extend time of instrument
	xtratim idur - ikf

	ifreq = cpspch( ifreq )
					
	k1 randi  1, 30
	k2 linseg 0, idur * 0.5, 1, idur * 0.5, 0
	k3 linseg 0.005, idur * 0.71, 0.015, idur * 0.29, 0.01
	k4 oscil  k2, ilfo, 1 ,0.2
	k5 =      k4 + 2

	ksweep linseg inharm, idur * isweep, 1, idur * (idur - (idur * isweep)), 1

	kenv expseg 0.001, idur * 0.01, iamp, idur * 0.99, 0.001
	asig gbuzz  kenv, ifreq + k3, k5, ksweep, k1, 15

	outs asig * sqrt( 1 - ipan ), asig * sqrt( ipan )

endin




instr $black
/*
	Instrument adapted from:
		Trapped in Convert
		by Dr. Richard Boulanger

	Table reference:
		f1 0 8192 10 1
		f15 0 8192 9 1 1 90
*/
	ikf    = p3
	ispb   = p4
	ires   = p5
	ivalue = p6
	iamp   = p7 * ( ivalue / 15 ) * 0dbfs  ; Amplitude
	ifreq  = cpspch( p8 )                  ; Pitch
	istart = p9                            ; Frequency sweep start
	iend   = p10                           ; Frequency sweep end
	ibw    = p11                           ; Bandwidth


	; Extend time of instrument
	idur = ispb * ires
	xtratim idur - ikf


	k1     expon   istart, idur, iend
	anoise rand    8000
	a1     reson   anoise, k1, k1 / ibw, 1
	k2     oscil   .6, 11.3, 1, .1
	k3     expseg  .001,idur * .001, iamp, idur * .999, .001
	a2     oscil   k3, ifreq + k2, 15
	
	outs   (a1 * .8) + a2, (a1 * .6) + (a2 * .7)
endin




instr  $copper
/*
	Instrument adapted from:
		Trapped in Convert
		by Dr. Richard Boulanger

	Table reference:
		f19 0 16 2 1 7 10 7 6 5 4 2 1 1 1 1 1 1 1 1
*/
	ikf    = p3
	ispb   = p4
	ires   = p5
	ivalue = p6
	iamp   = p7 * ( ivalue / 15 ) * 0dbfs  ; Amplitude
	ilfo   = p8 * ispb / 8                 ; Rate of incrementing through table
	istart = p9                            ; Frequency sweep start
	iend   = p10                           ; Frequency sweep end
	ibw    = p11                           ; Bandwidth


	; Extend duration
	idur  = ispb * ires  ; Duration equals note resolution
	xtratim idur - ikf


	ifuncl = 8

	k1      phasor ilfo
	k2      table  k1 * ifuncl, 19
	anoise  rand   1
	k3      expon  istart, idur, iend
	a1      reson  anoise, k3 * k2, k3 / ibw, 1
	
	kenv    linen  iamp, .01, idur, .05
	asig    =      a1 * kenv
	
	outs   asig, asig
endin




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




instr $fofVoice
/*
	Original Instrument by:
		Jean-Luc Cohen

	Web:
		http://www.jeanluccohen.com/

	Table Reference:
		f 20 0 1024 19 .5 .5 270 .5
*/
	ikf      = p3
	ispb     = p4
	inull    = p5
	ivalue   = p6
	iamp     = p7 * 0dbfs 
	ibasepch = p8
	iatt     = p9
	isus     = p10
	idecay   = p11

	; Extend time of instrument
	iatt   = iatt * ispb
	isus   = isus * ispb
	idecay = idecay * ispb
	idur   = iatt + isus + idecay
	xtratim idur - ikf

	ipch = cpspch( ibasepch + ( ivalue * 0.01 ) )

	k1 linseg 2, idur + idecay, 6
	k2 oscil  2, k1, 1
	
	a1 fof 1, ipch + k2,  500, 2, 60, .001, .07, .107, 1120, 1, 20, idur
	a2 fof 0.355, ipch + k2, 1050, 2, 70, .001, .07, .107, 1120, 1, 20, idur
	a3 fof 0.277, ipch + k2, 2250, 2,110, .001, .07, .107, 1120, 1, 20, idur
	a4 fof 0.191, ipch + k2, 2450, 2,120, .001, .07, .107, 1120, 1, 20, idur
	a5 fof 0.133, ipch + k2, 2750, 2,130, .001, .07, .107, 1120, 1, 20, idur
	a6 fof 0.066, ipch + k2, 3500, 2,140, .0001,.07, .107, 1120, 1, 20, idur
	a7 fof 1, ipch + k2,  500, 1,150, .001, .07, .107, 1120, 1, 20, idur
	
	aenv linseg 0, iatt, iamp, isus, iamp, idecay, 0

	al = ( a1 + a3 + a5 + a6 ) * aenv * 0.5
	ar = ( a7 + a2 + a4 + a6 ) * aenv * 0.5

	outs al, ar
endin




</CsInstruments>
<CsScore>

; Instrument List
# define dseq         # 1 #
# define kick         # 2 #
# define snare        # 3 #
# define hihat        # 4 #
# define sineKick     # 5 #
# define gaussBurst   # 6 #
# define triKick      # 7 #
# define lofiSnare    # 8 #
# define fugwhump     # 9 #
# define fmBumper     # 10 #
# define clapper      # 11 #
# define simpleRez    # 12 #
# define blue         # 13 #
# define black        # 14 #
# define copper       # 15 #
# define psyKick      # 16 #
# define psyBass      # 17 #
# define fofVoice     # 18 #


; Tables
f 1 0 [2^16+1] 10 1                     ; Sine
f 2 0 8192     -7 -1 4096 1 4096 -1     ; Triangle
f 5 0 8192     -7 1 200 1 0 -1 7912 -1


; Tables for Trapped in Convert Instruments
f15 0 8192 9 1 1 90
f19 0 16   2 1 7 10 7 6 5 4 2 1 1 1 1 1 1 1 1

; Table for fofVoice
f 20 0 1024 19 .5 .5 270 .5


; Parameters for $fmBumper
f 100 0 8 -2 4.02 3 32 2 0.2 0.45


; Tempo
t 0 120


; ---- quick guide ----
/*
i $dseq start 1 $sineKick   amp freq    freqr  decay trans   "." 
i $dseq start 1 $kick       amp -       -      -     -       "." 
i $dseq start 1 $snare      amp -       -      -     -       "." 
i $dseq start 1 $hihat      amp decay   -      -     -       "." 
i $dseq start 1 $gaussBurst amp sus     pan    -     -       "." 
i $dseq start 1 $triKick    amp freq    freqr  time  pan     "." 
i $dseq start 1 $lofiSnare  amp time    snap   pan   -       "." 
i $dseq start 1 $fugwhump   amp time    punch  tune  subtune "." 
i $dseq start 1 $fmBumper   amp table   -      -     -       "." 
i $dseq start 1 $clapper    amp pchr    tight  snap  pan     "." 
i $dseq start 1 $simpleRez  amp basepch -      -     -       "." 
i $dseq start 1 $blue       amp freq    lfo    nharm pan     "." 
i $dseq start 1 $black      amp freq    start  end   bw      "." 
i $dseq start 1 $copper     amp lfo     start  end   bw      "." 
i $dseq start 1 $psyKick    amp freq    reverb -     -       "." 
i $dseq start 1 $psyBass    amp basepch reverb -     -       "." 
i $dseq start 1 $fofVoice   amp basepch att    sus   decay   "." 
*/	


i $dseq 0  1 $kick       0.5 0      0     0    0     "f... 8... f.48 c.f." 
i $dseq 4  1 $snare      0.5 0      0     0    0     "f... 8... f.48 c.f." 
i $dseq 8  1 $hihat      0.5 0      0     0    0     "f... 8... f.48 c.f." 
i $dseq 12 1 $sineKick   0.5 70     0.7   0.5  0.1   "f... 8... f.48 c.f." 
i $dseq 16 1 $gaussBurst 0.5 0.05   0.7   0    0     "f... 8... f.48 c.f." 
i $dseq 20 1 $triKick    0.5 100    0.5   2    0.5   "f... 8... f.48 c.f." 
i $dseq 24 1 $lofiSnare  0.5 0.15   2     0.25 0     "f... 8... f.48 c.f." 
i $dseq 28 1 $fugwhump   0.5 2      0.3   100  50    "f... 8... f.48 c.f." 
i $dseq 32 1 $fmBumper   0.5 100    0     0    0     "f... 8... f.48 c.f." 
i $dseq 36 1 $clapper    0.5 1      1     1.5  0.65  "f... 8... f.48 c.f." 
i $dseq 40 1 $simpleRez  0.5 5.10   0     0    0     "0020 0300 5007 0032" 
i $dseq 44 1 $blue       0.5 9.029  23    10   0     "r2 f r4 8 4"         
i $dseq 48 1 $black      0.5 13.045 6000  8000 30    "f... 8... f.48 c.f." 
i $dseq 52 1 $copper     1   8      3000  50   10    "r2 f r4 8 c"         
i $dseq 56 1 $psyKick    0.5 44     0.01  0    0     "f... 8... f.48 c.f." 
i $dseq 60 1 $psyBass    0.5 5.09   0.04  0.5  0     "..0. ..c. ..0a ..c." 
i $dseq 64 1 $fofVoice   0.5 8.00   0.125 0.5  0.125 "f... 8... f.48 c.f." 


e 68

</CsScore>
</CsoundSynthesizer>
