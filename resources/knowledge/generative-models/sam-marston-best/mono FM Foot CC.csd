<CsoundSynthesizer>
<CsOptions>
-odac
--midi-key-cps=4 --midi-velocity=5
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 64
nchnls = 2
0dbfs = 1

	gaOutL init 0
	gaOutR init 0

	alwayson 2


	#define C1 #70#
	#define C2 #71#
	#define C3 #72#
	#define C4 #73#
	#define C5 #7#
	#define C6 #75#
	#define C7 #76#
	#define C8 #77#

instr 1

	icps = p4
	iamp = p5/127
	
	kFreqCC 	midic7 $C5, 0, 127
	
	irvbgain = 0.5

	ifn = 1  ;WAVE:    1=Sineish  2=SAW   3=SQUARE
	
	kJitAmt = 1.5
	kcpsMin = 0.3
	kcpsMax = 1
	kJit1 jitter kJitAmt, kcpsMin, kcpsMax

	kdetune = 0.015


	irndphs1 random 0, 1
	
	;icps = p4
	;iamp = p5/127
	iAttack = 2 ;seconds
	iRelease = 1 ;seconds
	kndx line 0, 10, 20
	irvbgain = 0.8

	aEnv linsegr 0, iAttack, iamp, 10, iamp/6, iRelease, 0
	a1 foscil aEnv/8, icps, 1, 2, kndx
	
	icf		= 20000
	iatt 	= 0.1
	idec 	= 2
	islev 	= icf/40
	irel	= 0.1
	kres 	= 0.1
	kcf 	linsegr 0.01, iatt, icf, idec, islev, irel, 0.001
	
	;aFilt1 	moogvcf2 a1, kcf, kres


	kgainslider	gainslider kFreqCC
	kscaled		scale2 kgainslider, 20, 20000, 0, 1, 0.08
	
	aFilt2		moogvcf2 a1, kscaled, 0.1
	


	outs aFilt2, aFilt2
	
	gaOutL 	= 		gaOutL + (aFilt2*irvbgain)
   gaOutR 	= 		gaOutR + (aFilt2*irvbgain)
	
endin

instr 2

	;-----------------REVERB---------------------

	irvbtime = 0.9

	aL, aR 			reverbsc gaOutL, gaOutR, irvbtime, 5000
	
	;aCL compress2 aL, 
	
						outs aL, aR
	
	gaOutL = 0
	gaOutR = 0
	
endin


</CsInstruments>
<CsScore>
f	1	0	1024	10	1	.8		.3														; SINE ish
f	2	0	1024	7	1	1024	-1														; SAW
f	3	0	1024	7	1	512		1		0		-1		512		-1						; SQUARE

f0 z

</CsScore>
</CsoundSynthesizer>
