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

	#define C1 #71#
	#define C2 #72#
	#define C3 #73#
	#define C4 #74#
	#define C5 #7#
	#define C6 #7#
	#define C7 #75#
	#define C8 #76#


instr 1

	icps = p4
	iamp = p5/127
	
	iA 		midic7 $C1, 0.01, 3
	iD 		midic7 $C2, 0.01, 6
	iS 		midic7 $C3, 0.1, 1
	iR 		midic7 $C4, 0.1, 5
	kFreq 	midic7 $C5, 0, 127
	kdtCC	midic7 $C6, 0, 1
	
	kpitchoff	midic7 $C6, 0, 200
	
	kmaxdur midic7 $C7, 0.2, 1
	
	kcf midic7 $C8, 0, 127

	ifn = 1  ;WAVE:    1=Sineish  2=SAW   3=SQUARE
	irndphs1 random 0, 1
	irndphs2 random 0, 1
	irndphs3 random 0, 1

	kJitAmt = 1.5
	kcpsMin = 0.3
	kcpsMax = 1
	kJit1 jitter kJitAmt, kcpsMin, kcpsMax
	kJit2 jitter kJitAmt, kcpsMin, kcpsMax
	kJit3 jitter kJitAmt, kcpsMin, kcpsMax

	;kdetune = 0.01
	kdetune = kdtCC

	irvbgain = 0.1
	
	;---------------OSCILLATORS-----------------
	
	iSL = 0.5
	aEnv linsegr 0, iA, iamp, iD, iamp*iS, iR, 0.01
	;aEnv = 0.5
	
	kdens rspline 1, 20, 0.01, 0.5
	kgdur rspline 0.01, kmaxdur, 0.01, 2
	;kpitchoff = 
	
	
	iEnvAmp = 0.05
	aC grain aEnv*iEnvAmp, icps+kJit1, kdens, 0.2, kpitchoff, kgdur, 1, 11, 2, 1;, irndphs1
	aL oscili aEnv/8, icps*(1-kdetune)-kJit2, ifn, irndphs2
	aR oscili aEnv/8, icps*(1+kdetune)+kJit3, ifn, irndphs3
		
	;tabmorphak
	
	;-----------------FILTER---------------------
	
	icf		= 	15000*iamp
	iatt 	= iA
	idec 	= iD
	islev 	= icf*iS
	irel	= iR
	kres 	= 0.1
	kcfenv 	linsegr 0.01, iatt, icf, idec, islev, irel, 0.001
	
	kgainslider		gainslider kcf
	kcf			scale2 kgainslider, 150, 20000, 0, 1, 0.01
	
	aFiltC 	moogladder aC, kcf, kres
	aFiltL		moogladder aL, kcf, kres
	aFiltR		moogladder aR, kcf, kres

	;aL1, aL2 pan2 aL, 0
	;aR1, aR2 pan2 aR, 1
	
	aL1, aL2 pan2 aFiltL, 0
	aR1, aR2 pan2 aFiltR, 1

	;outs aC, aC
	outs aFiltC, aFiltC
	;outs aL1, aL2
	;outs aR1, aR2

	gaOutL = gaOutL + (aFiltC * irvbgain) + (aL1 * irvbgain) + (aR1 * irvbgain)
	gaOutR = gaOutR + (aFiltC * irvbgain) + (aL2 * irvbgain) + (aR2 * irvbgain)

	;chnmix

endin

instr 2

	;-----------------REVERB---------------------

	irvbtime = 0.95

	aL, aR reverbsc gaOutL, gaOutR, irvbtime, 5000
	
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
f	4 	0 	16384 	10 	1 	0.5 	0.3 	0.25 	0.2 	0.167 	0.14 	0.125 	.111  	; Sawtooth ish
f	5 	0 	16384 	10 	1 	0   	0.3 	0    	0.2 	0     	0.14 	0     	.111  	; Square ish
f	6 	0 	16384 	10 	1 	1   	1   	1    	0.7 	0.5   	0.3  	0.1         	; Pulse ish

f 	10	0	1024	-20	1	
f 	11	0	1024	-20	2	

f0 z
i 2 0 [60*60*24*7]	;start reverb

</CsScore>
</CsoundSynthesizer>
