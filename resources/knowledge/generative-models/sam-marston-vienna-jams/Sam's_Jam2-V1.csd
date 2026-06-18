<CsoundSynthesizer>
<CsOptions>
-odac -dm0
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 64
nchnls = 2
0dbfs = 1

	gaOutL 			init 			0
	gaOutR 			init 			0

	#define 			C1 				#71#
	#define 			C2 				#72#
	#define 			C3 				#73#
	#define 			C4 				#74#
	#define 			C5 				#75#
	#define 			C6 				#7#
	#define 			C7 				#76#
	#define 			C8 				#77#



						alwayson		"clock"
						alwayson		"sequencer"
						alwayson		"root"
						seed			0


instr clock

	gkTempo			=				145
	gkSubdiv			=				4
	gkTicks			=				(gkTempo/60)*gkSubdiv
	gkMetro			metro			gkTicks
						;printk2 		gkMetro

	reset:
	gkCount			init			1
	if (gkMetro == 1)	then
	gkCount += 1
	endif
	if (gkCount == gkSubdiv*8+1) then
	reinit reset
	endif
	rireturn
	
	
	
	;printk2 gkCount

endin



instr sequencer
	
	
	;-----------------SAW------------------;
	
	kSawSpl1			rspline		2, 5, 0.01, 0.2
	kSawSplint		=				int(kSawSpl1)
	kSawRhythm		=				kSawSplint
	
	;reset:
	;gkSawSync			init			1
	;if (gkMetro == 1)	then
	;gkSawSync += 1
	;endif
	;if (gkSawSync == kSawRhythm) then
	;reinit reset
	;endif
	;rireturn
	
	;printk2 gkSawSync
	
	;gkSawSync			table			 			
	
	kSawSpl2 rspline 0, 3, 0.01, 0.2
	kSawRem = int(kSawSpl2)
	;printk2 kSawSpl
	
	if gkCount % kSawRhythm = kSawRem then
	gkSawSync = 1
	else gkSawSync = 0
	endif
	
	
	;if gkCount == 1 then
	if gkSawSync == 1 then
	kSawSig = 1
	else kSawSig = 0
	endif
	
	;-----------------KICK-----------------;
	
	kKickRhythm		=				4
	
	;RESET:
	;gkKickSync			init			1
	;if (gkMetro == 1)	then
	;gkKickSync += 1
	;endif
	;if (gkKickSync == kKickRhythm) then
	;reinit RESET
	;endif
	;rireturn
	
	if gkCount % kKickRhythm = 0 then
	gkKickSync = 1
	else gkKickSync = 0
	endif
	
	;if gkCount == 1 then
	if gkKickSync == 1 then
	gkKickSig = 1
	else gkKickSig = 0
	endif
	
	
	;-----------------BASS-----------------;
	
	kBassRhythm		=				3
	
	if gkCount % kBassRhythm = 0 then
	kBassSync = 1
	else kBassSync = 0
	endif
	
	if kBassSync == 1 then
	kBassSig = 1
	else kBassSig = 0
	endif
	
	
	;kchanged			changed			
	
	kRootTrig			trigger		gkMetro, 0.5, 0
	
	kSawTrig			trigger 		kSawSig, 0.5, 0
	kKickTrig			trigger		gkKickSig, 0.5, 0
	kBassTrig			trigger		kBassSig, 0.5, 0
	
	;gkSCTrig			trigger		kKickTrig, 0.5, 0
	
	
	
	kChordQual		trandom		kRootTrig, 10, 12
	kChordQual		=				int(kChordQual)
	iChordQual		=				10;i(kChordQual)
	
	kVoice1			table			0, iChordQual, 0
	kVoice2			table			1, iChordQual, 0
	kVoice3			table			2, iChordQual, 0
	kVoice4			table			3, iChordQual, 0
	
	kdur				=				0.2
	
						schedkwhennamed		kRootTrig, 0, 1, "root", 0, 0.1
						
						schedkwhennamed		kKickTrig, 0, 0, "kick", 0, 1
						
						schedkwhennamed		kBassTrig, 0, 0, "bass", 0, 1
	
						schedkwhennamed		kSawTrig, 0, 0, "saw", 0, kdur, kVoice1
						schedkwhennamed		kSawTrig, 0, 0, "saw", 0, kdur, kVoice2
						schedkwhennamed		kSawTrig, 0, 0, "saw", 0, kdur, kVoice3
						schedkwhennamed		kSawTrig, 0, 0, "saw", 0, kdur, kVoice4

endin


instr	root

	RESET:
	gkRootCnt			init			1
	if (gkCount == 1)	then
	gkRootCnt += 1
	endif
	if (gkRootCnt == gkSubdiv*4+1) then
	reinit RESET
	endif
	rireturn
	
	if gkCount == 1 then
	kRootSig = 1
	else kRootSig = 0
	endif
	
	kRootTrig			trigger		kRootSig, 0.5, 0

	;printk2	kRootTrig
	
	kndx				trandom		kRootTrig, 0, 7
	ifn 				=				20
	gkRoot				table			int(kndx), ifn
	;giRoot				=				i(kRoot)
	
	;printk2 kRoot

endin



instr saw
	
	;iRoot 				=				i(gkRoot)
	;iroot				=				giRoot+60
	;print iroot
	kcps 				= 				cpsmidinn(p4+gkRoot+54)
	iamp 				= 				0.1
	
	iACC 				midic7 		$C1, 0.01, 3
	iDCC 				midic7 		$C2, 0.1, 10
	iSCC 				midic7 		$C3, 0.1, 1
	iRCC 				midic7 		$C4, 0.1, 2
	kFreq 				midic7 		$C5, 0, 127
	kdtCC				midic7 		$C6, 0, 1
	
	iA					=				0.01
	iD					=				0.5
	iS					=				0.001
	iR					=				0.1

	ifn 				= 				2  ;WAVE:    1=Sineish  2=SAW   3=SQUARE
	irndphs1 			random 		0, 1
	irndphs2 			random 		0, 1
	irndphs3 			random 		0, 1

	kJitAmt 			= 				1.5
	kcpsMin 			= 				0.3
	kcpsMax 			= 				1
	kJit1 				jitter 		kJitAmt, kcpsMin, kcpsMax
	kJit2 				jitter 		kJitAmt, kcpsMin, kcpsMax
	kJit3 				jitter 		kJitAmt, kcpsMin, kcpsMax

	;kdetune 			= 				0.01
	kdetune 			= 				0.001				;kdtCC

	irvbgain 			= 				0.1
	
	;---------------OSCILLATORS-----------------
	
	iSL 				= 				0.5
	aEnv 				expsegr 		0.001, iA, 1, iD, iS, iR, 0.01
	;aEnv = 0.5
	aC 					oscili 		aEnv*iamp, kcps+kJit1, ifn, irndphs1
	aL 					oscili 		aEnv*iamp, kcps*(1-kdetune)-kJit2, ifn, irndphs2
	aR 					oscili 		aEnv*iamp, kcps*(1+kdetune)+kJit3, ifn, irndphs3
	
	
	;-----------------FILTER---------------------
	
	icf					= 				10000*iamp
	iatt 				= 				iA
	idec 				= 				iD
	islev 				= 				icf*iS
	irel				= 				iR
	kres 				= 				0.1
	kcf 				expsegr 		0.001, iatt, icf, idec, islev, irel, 0.001
	
	aFiltC 			moogladder 	aC, kcf, kres
	aFiltL				moogladder 	aL, kcf, kres
	aFiltR				moogladder 	aR, kcf, kres
	
	;aSCTrig			=				a(gkSCTrig)		

	;aFiltC				compress2		aFiltC, aSCTrig, -400, -50, -30, 16, 0.01, 0.06, 0.02
	;aFiltL				compress2		aFiltL, aSCTrig, -400, -50, -30, 16, 0.01, 0.06, 0.02
	;aFiltR				compress2		aFiltR, aSCTrig, -400, -50, -30, 16, 0.01, 0.06, 0.02
	
	aL1, aL2 			pan2 			aFiltL, 0
	aR1, aR2 			pan2 			aFiltR, 1

	
	outs 				aFiltC, aFiltC
	outs 				aL1, aL2
	outs 				aR1, aR2

	gaOutL 			= 				gaOutL + (aFiltC * irvbgain) + (aL1 * irvbgain) + (aR1 * irvbgain)
	gaOutR 			= 				gaOutR + (aFiltC * irvbgain) + (aL2 * irvbgain) + (aR2 * irvbgain)

endin


instr bass

	;kRootTrig			trigger		kRootSig, 0.5, 0

	
	kndx				random			0, 7
	ifn 				=				20
	kRoot				table			int(kndx), ifn 
	iRoot				=				i(kRoot)+36
	
	krndoct			rspline		1, 2.2, 0.1, 0.7
	koct				=				24/int(krndoct)
	;ioct				=				i(koct)
	
	kcps				=				cpsmidinn(gkRoot+54-koct)
	iamp				=				0.2
	aEnv				expsegr		0.0001, 0.01, 1, 0.3, 0.001, 0.2, 0.00001
	kndx				expsegr		0.0001, 0.01, 1, 0.3, 0.001, 0.2, 0.00001						
	aFM					foscili		aEnv, kcps, 1, 2, kndx, 7
	
	aFM					distort		aFM, 0.3, 50
	
	aFM					=				aFM*iamp
	
	;aFiltC				compress2		aFiltC, aSCTrig, -400, -50, -30, 16, 0.01, 0.06, 0.02

	outs				aFM, aFM

endin


instr kick
	
	aEnv				expsegr 		0.01, 0.01, 1, 0.25, 0.01, 0.1, 0.01
	iAmp				=				0.1

	aPchEnv			expsegr		0.01, 0.01, 1, 0.15, 0.01, 0.1, 0.01
	kscEnv				expsegr		0.01, 0.01, 1, 0.25, 0.01, 0.1, 0.01

	aKick 				oscili 		aEnv*iAmp, cpsmidinn(36)*(1+(aPchEnv*3))
	
	aDist				distort		aKick, 0.3, 50	
	
	;kKick				=				k(kscEnv)
	;kSpline			rspline		0, 1, 0.01, 0.1
	gkSCTrig			trigger		kscEnv, 0.5, 0
	
	outs				aDist, aDist
	
endin	


</CsInstruments>
<CsScore>

f	1	0	1024	10		1	.8		.3														; SINE ish
f	2	0	1024	7		1	1024	-1														; SAW
f	3	0	1024	7		1	512		1		0		-1		512		-1						; SQUARE
f	4 	0 	16384 	10 		1 	0.5 	0.3 	0.25 	0.2 	0.167 	0.14 	0.125 	.111  	; Sawtooth ish
f	5 	0 	16384 	10 		1 	0   	0.3 	0    	0.2 	0     	0.14 	0     	.111  	; Square ish
f	6 	0 	16384 	10 		1 	1   	1   	1    	0.7 	0.5   	0.3  	0.1         	; Pulse ish
f	7	0	1024	10		1																	; SINE


;CHORDS
f 	10 	0 	64		-2		0	2	7	11
f	11	0	64		-2		3	7	10	12

;CHORD QUALITY
f	30	0	64		-2		10	11


;SCALE / ROOT
f	20	0	64		-2		0	2	4	5	7	9	11




;Distortion
f	50	0	1024	10	1 ;.2	;.2


;Rhythm
;f	100	0			7		1	1	2	1	3	4



f	0 	z

</CsScore>
</CsoundSynthesizer>
