;-----------------------------------------------------------------
;
; Written by Kim Ervik 2013. kimer@stud.ntnu.no
; Some parts of the code (for partikkel parameter handling) 
; borrowed from examples given by Oeyvind Brandtsegg
;
;-----------------------------------------------------------------

<CsoundSynthesizer>

<CsOptions>
-oFMGrainRate.wav
</CsOptions>


<CsInstruments>
	sr		=	96000
;	kr		=	4410
	ksmps	=	10
	0dbfs	=	1
	nchnls	=	2
;***************************************************
;ftables
;***************************************************
	; classic waveforms
	giSine		ftgen	0, 0, 65537, 10, 1				; sine wave
	giCosine	ftgen	0, 0, 8193, 9, 1, 1, 90				; cosine wave
	giTri		ftgen	0, 0, 8193, 7, 0, 2048, 1, 4096, -1, 2048, 0	; triangle wave 

	; grain envelope tables
	giSigmoRise 	ftgen	0, 0, 8193, 19, 0.5, 1, 270, 1			; rising sigmoid
	giSigmoFall 	ftgen	0, 0, 8193, 19, 0.5, 1, 90, 1			; falling sigmoid
	giExpFall	ftgen	0, 0, 8193, 5, 1, 8193, 0.00001			; exponential decay
	giTriangleWin 	ftgen	0, 0, 8193, 7, 0, 4096, 1, 4096, 0		; triangular window 

; ----- MAIN INSTRUMENT ----------

	instr 3

	
	kwaveform1	= giSine
	kwave1Single	= 1

; --- inlined: PartikkelArgs.inc ---

;-----------------------------------------------------------------
;
; Written by Kim Ervik 2013. kimer@stud.ntnu.no
; Some parts of the code (for partikkel parameter handling) 
; borrowed from examples given by Oeyvind Brandtsegg
;
;-----------------------------------------------------------------


; select source waveforms 2,3 and 4 (waveform 1 is selected outside of this include file, in the including instrument)
	kwaveform2	= giSine
	kwaveform3	= giSine
	kwaveform4	= giSine
; Set to 0 with complex waveforms, and 1 with sampled sound
	kwave2Single	= 0
	kwave3Single	= 0
	kwave4Single	= 0
; Find the lengh of a table in samples and in second. Is used to calculate the normal pitch.
	kfilen1		tableng	 kwaveform1
	kfilen2		tableng	 kwaveform2
	kfilen3		tableng	 kwaveform3
	kfilen4		tableng	 kwaveform4
	kfildur1	= kfilen1 / sr
	kfildur2	= kfilen2 / sr
	kfildur3	= kfilen3 / sr
	kfildur4	= kfilen4 / sr
; With complex waveforms this parameter gives cycles per second. With sampled sound, 1 is the normal pitch
	kwavekey1	= 1
	kwavekey2	= 220
	kwavekey3	= 220
	kwavekey4	= 220

; Calculate the normal pitchen of a sampled sound (do not apply to complex waveforms)
	kwavekey1	= (kwave1Single > 0 ? kwavekey1 : kwavekey1/kfildur1)
	kwavekey2	= (kwave2Single > 0 ? kwavekey2 : kwavekey2/kfildur2)
	kwavekey3	= (kwave3Single > 0 ? kwavekey3 : kwavekey3/kfildur3)
	kwavekey4	= (kwave4Single > 0 ? kwavekey4 : kwavekey4/kfildur4)

; Sampleposistion
	isamplepos1	= 0
	isamplepos2	= 0
	isamplepos3	= 0
	isamplepos4	= 0

	kTimeRate	= 1				; time pointer rate
	asamplepos1	phasor kTimeRate / kfildur1
	asamplepos2	phasor kTimeRate / kfildur2
	asamplepos3	phasor kTimeRate / kfildur3
	asamplepos4	phasor kTimeRate / kfildur4

	; mix initial phase and moving phase value (moving phase only for sampled waveforms, single cycle waveforms use static samplepos)
	asamplepos2	= 0;asamplepos2*(1-kwave2Single) + isamplepos2
	asamplepos3	= 0;asamplepos3*(1-kwave3Single) + isamplepos3
	asamplepos4	= 0;asamplepos4*(1-kwave4Single) + isamplepos4

;*******************************
; other granular synthesis parameters
;*******************************

; amplitude
	kamp		= ampdbfs(-9)	
	async 		= 0.0				; set the sync input to zero (disable external sync)
	kGrainRate	= 12.0				; number of grains per second
; grain rate FM
	kGrFmFreq	= kGrainRate/4		; FM freq for modulating the grainrate 
	kGrFmIndex	= 0.0				; FM index for modulating the grainrate (normally kept in a 0.0 to 1.0 range)
	iGrFmWave	= giSine				; FM waveform, for modulating the grainrate 
	aGrFmSig	oscil kGrFmIndex, kGrFmFreq, iGrFmWave	; audio signal for frequency modulation of grain rate
	agrainrate	= kGrainRate + (aGrFmSig*kGrainRate)	; add the modulator signal to the grain rate signal
; distribution 
	kdistribution	= 0.0						; grain random distribution in time
	idisttab	ftgentmp	0, 0, 16, 16, 1, 16, -10, 0	; probability distribution for random grain masking
; grain shape
	kGrainDur	= 2.5					; length of each grain relative to grain rate 
	kduration	= (kGrainDur*1000)/kGrainRate	; grain dur in milliseconds, relative to grain rate

	ienv_attack	= giSigmoRise 			; grain attack shape (from table)
	ienv_decay	= giSigmoFall 				; grain decay shape (from table)
	ksustain_amount	= 0.0				; balance between enveloped time(attack+decay) and sustain level time, 0.0 = no time at sustain level
	ka_d_ratio	= 0.5					; balance between attack time and decay time, 0.0 = zero attack time and full decay time

	kenv2amt	= 0.0					; amount of secondary enveloping per grain (e.g. for fof synthesis)
	ienv2tab	= giExpFall 					; secondary grain shape (from table), enveloping the whole grain if used
; grain pitch (transpose, or "playback speed")
	kwavfreq	= 1							; transposition factor (playback speed) of audio inside grains, 
; pitch sweep
	ksweepshape	= 0.5							; grain wave pitch sweep shape (sweep speed), 0.5 is linear sweep
	iwavfreqstarttab 	ftgentmp	0, 0, 16, -2, 0, 0,   1		; start freq scalers, per grain
	iwavfreqendtab		ftgentmp	0, 0, 16, -2, 0, 0,   1		; end freq scalers, per grain
; FM of grain pitch (playback speed)
	kPtchFmFreq	= 440							; FM freq, modulating waveform pitch
	kPtchFmIndex	= 0								; FM index, modulating waveform pitch
	iPtchFmWave	= giSine							; FM waveform, modulating waveform pitch
	ifmamptab	ftgentmp	0, 0, 16, -2, 0, 0,   1		; FM index scalers, per grain
	ifmenv		= giTriangleWin 					; FM index envelope, over each grain (from table)
	kPtchFmIndex	= kPtchFmIndex + (kPtchFmIndex*kPtchFmFreq*0.00001) 	; FM index scaling formula
	awavfm		oscil	kPtchFmIndex, kPtchFmFreq, iPtchFmWave		; Modulator signal for frequency modulation inside grain
; trainlet parameters
	icosine		= giCosine				; needs to be a cosine wave to create trainlets
	kTrainCps	= kGrainRate				; set cps equal to grain freq, creating a single cycle of a trainlet inside each grain
	knumpartials	= 7						; number of partials in trainlet
	kchroma		= 3						; chroma, falloff of partial amplitude towards sr/2
; masking
	; gain masking table, amplitude for individual grains
	igainmasks	ftgentmp	0, 0, 16, -2, 0, 0,   1
	; channel masking table, output routing for individual grains (zero based, a value of 0.0 routes to output 1)
	ichannelmasks	ftgentmp	0, 0, 16, -2,  0, 0,  0.5	
	; random masking (muting) of individual grains
	krandommask	= 0
	; Set gain per source waveform per grain, 
	; in groups of 5 amp values, reflecting source1, source2, source3, source4, and the 5th slot is for trainlet amplitude.
	iwaveamptab	ftgentmp	0, 0, 32, -2, 0, 0,   1,0,0,0,0
; system parameter
	imax_grains	= 100				; max number of grains per k-period


; --- end PartikkelArgs.inc ---



; Per grain control tabel
	kamp	 	= p4
	kgrainrate	= cpspch(p5)					
	kwavfreq	= kgrainrate * p6
	kRelDur		= 1
	kduration	= (kRelDur*1000)/kgrainrate

; FM av grain rate
	kFMratio	= p8
	kFmIndex	= p7
	kFMmodFrek	= kFMratio * kgrainrate			; FM freq, 	modulating waveform pitch
	iFmWave		= giSine				; FM waveform, 	modulating waveform
	kFmIndex	= kFmIndex * kgrainrate 		; FM index scaling formula
	aGrRateFm	oscil	kFmIndex, kFMmodFrek, iFmWave	; Modulator signal for frequency modulation of grain rate
	agrainrate	= kgrainrate + aGrRateFm

	kRelDur		= 1
	kgrainrate	downsamp agrainrate
	kduration		= (kRelDur*1000)/kgrainrate



a1,a2,a3,a4,a5,a6,a7,a8	partikkel \
		  agrainrate, \
		  kdistribution, idisttab, async, \
		  kenv2amt, ienv2tab, ienv_attack, ienv_decay, \
		  ksustain_amount, ka_d_ratio, kduration, \
		  kamp, \
		  igainmasks, \			
               	  kwavfreq, \
		  ksweepshape, iwavfreqstarttab, iwavfreqendtab, \
		  awavfm, ifmamptab, ifmenv, \
		  icosine, kTrainCps, knumpartials, kchroma, \
		  ichannelmasks, \
		  krandommask, \
		  kwaveform1, kwaveform2, kwaveform3, kwaveform4, \
		  iwaveamptab, \
		  asamplepos1, asamplepos2, asamplepos3, asamplepos4, \	
               	  kwavekey1, kwavekey2, kwavekey3, kwavekey4, \	
		  imax_grains


iAttack = 0.001
iDecay = 0
iSustain = 1
iRel = 0.1

kAmpEnv linsegr 0, iAttack, 1, iDecay, iSustain, iRel, 0

	outs	a1*kAmpEnv, a2*kAmpEnv	
		
	endin

</CsInstruments>


<CsScore>


; Modulation frequency bellow 20 Hz. Resulting in vibrato
	;instr     start	dur	amp	pch	grPitch	FMindex	FMratio
	i	3	0	.7	.5	8	1	0.5	0.01
	i	3	^+1	.7	.	8.04	.	.	.
	i	3	^+1	1.5	.	8.02	.	.	.

; FM ratio at 1, showing similar spectral behaviour as grain rate FM
	;instr     start	dur	amp	pch	grPitch	FMindex	FMratio
	i	3	^+2	.7	.	8	.	.	1
	i	3	^+1	.7	.	8.04	.	.	.
	i	3	^+1	1.5	.	8.02	.	.	.

; FM ratio at 2, showing the same spectra as with FM ratio at 1 
	;instr     start	dur	amp	pch	grPitch	FMindex	FMratio
	i	3	^+2	.7	.	8	.	.	2
	i	3	^+1	.7	.	8.04	.	.	.
	i	3	^+1	1.5	.	8.02	.	.	.

; Complex FM ratio, resulting in drop of pitch, showing similar spectral behaviour as grain rate FM
	;instr     start	dur	amp	pch	grPitch	FMindex	FMratio
	i	3	^+2	.7	.	8	.	.	.5
	i	3	^+1	.7	.	8.04	.	.	.
	i	3	^+1	1.5	.	8.02	.	.	.

; FM ratio at 1 with high grain pitch, resulting in a shift in the spectral energy
	;instr     start	dur	amp	pch	grPitch	FMindex	FMratio
	i	3	^+2	.7	.	8	5	.	1
	i	3	^+1	.7	.	8.04	.	.	.
	i	3	^+1	1.5	.	8.02	.	.	.

; FM index above 1 showing alteration of pitch due to negative grain rates
	;instr     start	dur	amp	pch	grPitch	FMindex	FMratio
	i	3	^+2	.7	.	8	1	0.8	1
	i	3	^+1	.7	.	8.04	.	1	.
	i	3	^+1	1.5	.	8.02	.	1.5	.




</CsScore>


</CsoundSynthesizer>
