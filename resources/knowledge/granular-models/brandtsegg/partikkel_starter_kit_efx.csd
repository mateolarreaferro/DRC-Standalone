<CsoundSynthesizer>
<CsOptions>
-opartikkel_start_kit.wav
</CsOptions>
<CsInstruments>

;***************************************************
; globals
;***************************************************

	sr 	= 44100
	ksmps 	= 10
	nchnls 	= 2
	0dbfs	= 1

;***************************************************
;ftables
;***************************************************

	; live input buffer table for granular effects processing
	giLiveFeedLen		= 524288
	giLiveFeedLenSec	= giLiveFeedLen/sr
	giLiveFeed		ftgen	0, 0, giLiveFeedLen+1, 2, 0				; create empty buffer for live input

	; classic waveforms
	giSine		ftgen	0, 0, 65537, 10, 1					; sine wave
	giCosine	ftgen	0, 0, 8193, 9, 1, 1, 90					; cosine wave
	giTri		ftgen	0, 0, 8193, 7, 0, 2048, 1, 4096, -1, 2048, 0		; triangle wave

	; grain envelope tables
	giSigmoRise 	ftgen	0, 0, 8193, 19, 0.5, 1, 270, 1				; rising sigmoid
	giSigmoFall 	ftgen	0, 0, 8193, 19, 0.5, 1, 90, 1				; falling sigmoid
	giExpFall	ftgen	0, 0, 8193, 5, 1, 8193, 0.00001				; exponential decay
	giTriangleWin 	ftgen	0, 0, 8193, 7, 0, 4096, 1, 4096, 0			; triangular window


;***************************************************
;record input to buffer
;***************************************************
	instr 1

	a1	inch	1					; signal input

	 ;test signal
	a1	inch 1
	aout	= a1 * 0.1
		;outch 1, aout


	aFeed	chnget	"partikkelFeedback"			; feedback from partikkel audio output
	kFeed	= 0.20						; feedback gain
	a1	= a1 + (aFeed*kFeed)				; mix feedback with live input

; write audio to table
	iAudioTable	= giLiveFeed
	iLength		= ftlen(iAudioTable)
	gkstartFollow	tablewa	iAudioTable, a1, 0      				; write audio a1 to table
	gkstartFollow	= (gkstartFollow > (giLiveFeedLen-1) ? 0 : gkstartFollow)	; reset kstart when table is full
			tablegpw iAudioTable                                            ; update table guard point (for interpolation)
			chnset	gkstartFollow, "kstartFollow"				; output the buffer position to chn

	endin

;******************************************************
; partikkel instr
;******************************************************
		instr 2

; --- inlined: partikkel_basic_settings.inc ---
;*******************************
; setup of source waveforms
; (needs to be done first, because grain pitch and time pointer depends on source waveform lengths)
;*******************************

; select source waveforms 
	kwaveform1	= giLiveFeed		; source audio waveform 1
	kwaveform2	= giLiveFeed		; source audio waveform 2
	kwaveform3	= giLiveFeed		; source audio waveform 3
	kwaveform4	= giLiveFeed		; source audio waveform 4

	kwave1Single	= 0			; flag to set if waveform is single cycle (set to zero for sampled waveforms)
	kwave2Single	= 0			; flag to set if waveform is single cycle (set to zero for sampled waveforms)
	kwave3Single	= 0			; flag to set if waveform is single cycle (set to zero for sampled waveforms)
	kwave4Single	= 0			; flag to set if waveform is single cycle (set to zero for sampled waveforms)

; get source waveform length (used when calculating transposition and time pointer)
	kfilen1		tableng	 kwaveform1		; get length of the first source waveform
	kfilen2		tableng	 kwaveform2		; same as above, for source waveform 2
	kfilen3		tableng	 kwaveform3		; same as above, for source waveform 3
	kfilen4		tableng	 kwaveform4		; same as above, for source waveform 4
	kfildur1	= kfilen1 / sr			; length in seconds, for the first source waveform
	kfildur2	= kfilen2 / sr			; same as above, for source waveform 2
	kfildur3	= kfilen3 / sr			; same as above, for source waveform 3
	kfildur4	= kfilen4 / sr			; same as above, for source waveform 4

; original pitch for each waveform, use if they should be transposed individually
; can also be used as a "cycles per second" parameter for single cycle waveforms (assuming that the kwavfreq parameter has a value of 1.0)
	kwavekey1	= 1
	kwavekey2	= 1
	kwavekey3	= 1
	kwavekey4	= 1

; set original key dependant on waveform length (only for sampled waveforms, not for single cycle waves)
	kwavekey1	= (kwave1Single > 0 ? kwavekey1 : kwavekey1/kfildur1)
	kwavekey2	= (kwave2Single > 0 ? kwavekey2 : kwavekey2/kfildur2)
	kwavekey3	= (kwave3Single > 0 ? kwavekey3 : kwavekey3/kfildur3)
	kwavekey4	= (kwave4Single > 0 ? kwavekey4 : kwavekey4/kfildur4)

; time pointer (phase). This can be independent for each source waveform.
	isamplepos1	= 0				; initial phase for wave source 1
	isamplepos2	= 0				; initial phase for wave source 2
	isamplepos3	= 0				; initial phase for wave source 3
	isamplepos4	= 0				; initial phase for wave source 4

	kTimeRate	= 1				; time pointer rate
	asamplepos1	phasor kTimeRate / kfildur1	; phasor from 0 to 1, scaled to the length of the first source waveform
	asamplepos2	phasor kTimeRate / kfildur2	; same as above, scaled for source wave 2
	asamplepos3	phasor kTimeRate / kfildur3	; same as above, scaled for source wave 3
	asamplepos4	phasor kTimeRate / kfildur4	; same as above, scaled for source wave 4

	; mix initial phase and moving phase value (moving phase only for sampled waveforms, single cycle waveforms use static samplepos)
	asamplepos1	= asamplepos1*(1-kwave1Single) + isamplepos1
	asamplepos2	= asamplepos2*(1-kwave2Single) + isamplepos2
	asamplepos3	= asamplepos3*(1-kwave3Single) + isamplepos3
	asamplepos4	= asamplepos4*(1-kwave4Single) + isamplepos4

;*******************************
; other granular synthesis parameters
;*******************************

; amplitude
	kamp		= ampdbfs(-3)				; output amplitude

; sync
	async 		= 0.0					; set the sync input to zero (disable external sync)

; grain rate
	kGrainRate	= 12.0					; number of grains per second

; grain rate FM
	kGrFmFreq	= kGrainRate/4				; FM freq for modulating the grainrate 
	kGrFmIndex	= 0.0					; FM index for modulating the grainrate (normally kept in a 0.0 to 1.0 range)
	iGrFmWave	= giSine				; FM waveform, for modulating the grainrate 
	aGrFmSig	oscil kGrFmIndex, kGrFmFreq, iGrFmWave	; audio signal for frequency modulation of grain rate
	agrainrate	= kGrainRate + (aGrFmSig*kGrainRate)	; add the modulator signal to the grain rate signal

; distribution 
	kdistribution	= 0.0						; grain random distribution in time
	idisttab	ftgentmp	0, 0, 16, 16, 1, 16, -10, 0	; probability distribution for random grain masking

; grain shape
	kGrainDur	= 2.5					; length of each grain relative to grain rate 
	kduration	= (kGrainDur*1000)/kGrainRate		; grain dur in milliseconds, relative to grain rate

	ienv_attack	= giSigmoRise 				; grain attack shape (from table)
	ienv_decay	= giSigmoFall 				; grain decay shape (from table)
	ksustain_amount	= 0.0					; balance between enveloped time(attack+decay) and sustain level time, 0.0 = no time at sustain level
	ka_d_ratio	= 0.5					; balance between attack time and decay time, 0.0 = zero attack time and full decay time

	kenv2amt	= 0.0					; amount of secondary enveloping per grain (e.g. for fof synthesis)
	ienv2tab	= giExpFall 				; secondary grain shape (from table), enveloping the whole grain if used

; grain pitch (transpose, or "playback speed")
	kwavfreq	= 1					; transposition factor (playback speed) of audio inside grains, 

; pitch sweep
	ksweepshape		= 0.5						; grain wave pitch sweep shape (sweep speed), 0.5 is linear sweep
	iwavfreqstarttab 	ftgentmp	0, 0, 16, -2, 0, 0,   1		; start freq scalers, per grain
	iwavfreqendtab		ftgentmp	0, 0, 16, -2, 0, 0,   1		; end freq scalers, per grain

; FM of grain pitch (playback speed)
	kPtchFmFreq	= 440							; FM freq, modulating waveform pitch
	kPtchFmIndex	= 0							; FM index, modulating waveform pitch
	iPtchFmWave	= giSine						; FM waveform, modulating waveform pitch
	ifmamptab	ftgentmp	0, 0, 16, -2, 0, 0,   1			; FM index scalers, per grain
	ifmenv		= giTriangleWin 					; FM index envelope, over each grain (from table)
	kPtchFmIndex	= kPtchFmIndex + (kPtchFmIndex*kPtchFmFreq*0.00001) 	; FM index scaling formula
	awavfm		oscil	kPtchFmIndex, kPtchFmFreq, iPtchFmWave		; Modulator signal for frequency modulation inside grain

; trainlet parameters
	icosine		= giCosine				; needs to be a cosine wave to create trainlets
	kTrainCps	= kGrainRate				; set cps equal to grain freq, creating a single cycle of a trainlet inside each grain
	knumpartials	= 7					; number of partials in trainlet
	kchroma		= 3					; chroma, falloff of partial amplitude towards sr/2

; masking
	; gain masking table, amplitude for individual grains
	igainmasks	ftgentmp	0, 0, 16, -2, 0, 0,   1

	; channel masking table, output routing for individual grains (zero based, a value of 0.0 routes to output 1)
	ichannelmasks	ftgentmp	0, 0, 16, -2,  0, 0,  0.5
	
	; random masking (muting) of individual grains
	krandommask	= 0

	; wave mix masking. 
	; Set gain per source waveform per grain, 
	; in groups of 5 amp values, reflecting source1, source2, source3, source4, and the 5th slot is for trainlet amplitude.
	iwaveamptab	ftgentmp	0, 0, 32, -2, 0, 0,   1,0,0,0,0

; system parameter
	imax_grains	= 100				; max number of grains per k-period


; --- end partikkel_basic_settings.inc ---


; a selection of parameters to start experimentation with partikkel
	kamp		= ampdbfs(-8)					; amp
	kgrainrate	= 20   					        ; number of grains per second
	kwavfreq	= 1.0						; playback speed inside each grain
	kRelDur		= 4						; grain duration
	kduration	= (kRelDur*1000)/kgrainrate			; grain dur in milliseconds, relative to grain rate
	krandommask	= 0						; random muting of single grains
	ksamplepos1	= 0.02						; in granular effect processing, this parameter will set the "grain delay" time, as a fraction of the input buffer length
	kpos1Deviation	randh 0.2, kgrainrate
	ksamplepos1	= ksamplepos1 + kpos1Deviation


	; if samplepos is close to zero, see to it that grain playback does not cross the record pointer border,
	; as this will delay the (live feed) sound for the length of a livefeed sample buffer.
	; So, check grain duration and transpose, limit samplepos accordingly
	ksamplepos1		limit ksamplepos1, (kduration*kwavfreq)/(giLiveFeedLenSec*1000), 1

	; make samplepos follow the record pointer instead of staying at a stationary value, makes live follow samplepos into "grain delay time"
	kstartFollow 		chnget	"kstartFollow"					; the current buffer write position for live follow mode
	ksamplepos1 		= (kstartFollow/giLiveFeedLen) - ksamplepos1		; move samplepos in parallel with the write pointer for the input buffer
	ksamplepos1		= (ksamplepos1 < 0 ? ksamplepos1+1 : ksamplepos1)	; wrap around on undershoot
	ksamplepos1		= (ksamplepos1 > 1 ? ksamplepos1-1 : ksamplepos1)	; wrap around on overshoot
	asamplepos1		upsamp ksamplepos1					; upsample

	a1,a2,a3,a4,a5,a6,a7,a8	partikkel \					; 					(beginner)
			kgrainrate, \						; grains per second			*
			kdistribution, idisttab, async, \			; synchronous/asynchronous
			kenv2amt, ienv2tab, ienv_attack, ienv_decay, \		; grain envelope (advanced)
			ksustain_amount, ka_d_ratio, kduration, \		; grain envelope 			*
			1, \							; amp					*
			igainmasks, \						; gain masks (advanced)
			kwavfreq, \						; grain pitch (playback frequency)	*
			ksweepshape, iwavfreqstarttab, iwavfreqendtab, \	; grain pith sweeps (advanced)
			awavfm, ifmamptab, ifmenv, \				; grain pitch FM (advanced)
			icosine, kTrainCps, knumpartials, kchroma, \		; trainlets
			ichannelmasks, \ 					; channel mask (advanced)
			krandommask, \						; random masking of single grains	*
			kwaveform1, kwaveform2, kwaveform3, kwaveform4, \	; set source waveforms			* (using only waveform 1)
			iwaveamptab, \						; mix source waveforms
			asamplepos1, asamplepos2, asamplepos3, asamplepos4, \	; read position for source waves	* (using only samplepos 1)
			kwavekey1, kwavekey2, kwavekey3, kwavekey4, \		; individual transpose for each source
			imax_grains						; system parameter (advanced)

; audio feedback in granular processing
	aSum		sum a1,a2,a3,a4,a5,a6,a7,a8
	aSum		dcblock aSum
			chnset	aSum, "partikkelFeedback"

; audio out
	outs	a1*kamp, a2*kamp
		endin

;******************************************************

</CsInstruments>
<CsScore>

;  start  dur
i1   0 	  30
i2   0 	  30

</CsScore>

</CsoundSynthesizer>
