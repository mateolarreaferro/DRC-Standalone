<CsoundSynthesizer>
<CsOptions>
-dm16
</CsOptions>
<CsInstruments>

nchnls = 2
0dbfs = 1

	gaOutL 			init 	  0
	gaOutR 			init 	  0
	gaBIGL				init			0
	gaBIGR				init			0
	giRoot				init			54
	gkRoot 			init			54

	#define 			C1 				#71#
	#define 			C2 				#72#
	#define 			C3 				#73#
	#define 			C4 				#74#
	#define 			C5 				#75#
	#define 			C6 				#7#
	#define 			C7 				#76#
	#define 			C8 				#77#



						turnon		"clock"
						turnon		"sequencer"
						turnon		"rootseq"
						;alwayson		"sawseq"
						turnon		"verb"
						turnon		"verbBIG"
						turnon		"measurecount"
						seed			0
						

instr clock

	gkTempo			=				145
	gkSubdiv			=				4
	gkTicks			=				(gkTempo/60)*gkSubdiv
	gkMetro			metro			gkTicks, 0.0000000001
						;printk2 		gkMetro
	
	gk16				=				1/gkTicks
	gk8					=				2/gkTicks					
	gk4					=				4/gkTicks
	gk2					=				8/gkTicks
	gk1					=				16/gkTicks
	gkdb1				=				32/gkTicks
	
	
	
	
	;printk2 gk8

	reset:
	gkCount			init			1
	if (gkMetro == 1)	then
	gkCount += 1
	endif
	if (gkCount == gkSubdiv*8+1) then
	reinit reset
	endif
	rireturn
	
	
	if gkCount == 1 then
	gkb1 = 1
	elseif gkCount == 17 then
	gkb1 = 1
	else gkb1 = 0
	endif
	
	
	
	;printk2 gkCount
	
	
	if gkCount == 1 then
	knotedurSig = 1
	else knotedurSig = 0
	endif
	
	knotedurTrig		trigger		knotedurSig, 0.5, 0
	
	schedkwhennamed	knotedurTrig, 0, 0, "notedur", 0, 0.1

endin



instr notedur

	gi16				=				i(gk16)
	gi8					=				i(gk8)				
	gi4					=				i(gk4)
	gi2					=				i(gk2)
	gi1					=				i(gk1)
	gidb1				=				i(gkdb1)

endin


instr measurecount
	
	if gkCount == 1 then
	gkCountSig = 1
	elseif gkCount == 17 then
	gkCountSig = 1
	else gkCountSig = 0
	endif
	
	gkCountTrig		trigger		gkCountSig, 0.5, 0
	
	redo:
	gkMeasure			init			0
	if (gkCountTrig == 1)	then
	gkMeasure += 1
	endif
	if (gkCountTrig == gkSubdiv*8+1) then
	reinit redo
	endif
	rireturn
	
	;printk2 gkMeasure

endin


instr	rootseq

	if gkCount == 1 then
	kRootSig = 1
	else kRootSig = 0
	endif
	
	gkRootTrig		trigger				kRootSig, 0.5, 0
	
						schedkwhennamed		gkRootTrig, 0, 1, "root", 0, 0.2	

endin



instr	root

	;RESET:
	;gkRootCnt			init			1
	;if (gkCount == 1)	then
	;gkRootCnt += 1
	;endif
	;if (gkRootCnt == gkSubdiv*4+1) then
	;reinit RESET
	;endif
	;rireturn
	
	;if gkCount == 1 then
	;kRootSig = 1
	;else kRootSig = 0
	;endif
	
	;kRootTrig			trigger		kRootSig, 0.5, 0

	;printk2	kRootTrig
	
	kndx				random			0, 6.999
	ifn 				=				20
	indx				=				i(kndx)
	giRoot				table			int(indx), ifn
	giRoot				=				giRoot+54
	
	;kndx				random		0, 6.999
	;ifn 				=				20
	gkRoot				table			int(kndx), ifn
	gkRoot				=				gkRoot+54
	
	;giRoot				=				i(kRoot)
	
	;printk2 kRoot

endin



instr sequencer
	
	;;-----------------SAW-----------------------------------------------------------------------------;
	
	kVar			init			2
	kVar			trandom		gkRootTrig, 1, 3
	kVar			=				int(kVar)
	;kSawVar			=				2
	
	
	if (kVar == 1) then
	
	kSawSpl1			rspline		2, 7, 0.1, 0.4
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
	
	kSawSpl2 rspline 0, 3, 0.1, 0.4
	kSawRem = 0;int(kSawSpl2)
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
	
	iChordQual		init			10
	kChordQual		init			10
	kChordQual		trandom		gkRootTrig, 10, 12
	kChordQual		=				int(kChordQual)
	iChordQual		=				i(kChordQual)
	
	kVoice1			tablekt		0, kChordQual, 0
	kVoice2			tablekt		1, kChordQual, 0
	kVoice3			tablekt		2, kChordQual, 0
	kVoice4			tablekt		3, kChordQual, 0
	
	kVoice1			=				kVoice1+giRoot
	kVoice2			=				kVoice2+giRoot
	kVoice3			=				kVoice3+giRoot
	kVoice4			=				kVoice4+giRoot	
	
	kdur				=				1
	kdec				=				0.6
	ksus				trandom		kSawSig, 0.0001, 0.01;		0.0001
	kff					=				15000
	
	
	elseif (kVar == 2) then
	
	if gkRootTrig == 1 then
	gkSawSync = 1
	else gkSawSync = 0
	endif
	
	if gkSawSync == 1 then
	kSawSig = 1
	else kSawSig = 0
	endif	
	
	iChordQual		init			10
	kChordQual		init			10
	kChordQual		trandom		gkRootTrig, 10, 12
	
	kChordQual		=				int(kChordQual)
	iChordQual		=				i(kChordQual)
	
	;print iChordQual
	;printk2 kChordQual
	
	kVoice1			tablekt		0, kChordQual
	kVoice2			tablekt		1, kChordQual
	kVoice3			tablekt		2, kChordQual
	kVoice4			tablekt		3, kChordQual
	
	kVoice1			=				kVoice1+gkRoot
	kVoice2			=				kVoice2+gkRoot
	kVoice3			=				kVoice3+gkRoot
	kVoice4			=				kVoice4+gkRoot	
	
	kdur				=				gkdb1
	kdec 				=				gkdb1
	ksus				=				1;0.1
	kff					=				1000
	
	;printk2 kff
	
	else kSawSig = 0
	
	endif
	
	;;-----------------KICK--------------------------------------------------------------------------;
	
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
	
	;if gkCount % kKickRhythm = 0 then
	;gkKickSync = 1
	;else gkKickSync = 0
	;endif
	
	if gkCount == 1 then
	gkKickSync = 1
	elseif gkCount == 5 then
	gkKickSync = 1
	elseif gkCount == 9 then
	gkKickSync = 1
	elseif gkCount == 13 then
	gkKickSync = 1
	elseif gkCount == 17 then
	gkKickSync = 1
	elseif gkCount == 21 then
	gkKickSync = 1
	elseif gkCount == 25 then
	gkKickSync = 1
	elseif gkCount == 29 then
	gkKickSync = 1
	else gkKickSync = 0
	endif
	

	
	;if gkCount == 1 then
	;if gkKickSync == 1 then
	;gkKickSig = 1
	;else gkKickSig = 0
	;endif
	
	
	;;-----------------BASS---------------------------------------------------------------------------;
	
	if (kVar == 1) then
	
	kBassRhythm		=				3
	
	if gkCount % kBassRhythm = 1 then
	kBassSync = 1
	else kBassSync = 0
	endif
	
	if kBassSync == 1 then
	kBassSig = 1
	else kBassSig = 0
	endif
	
	
	elseif (kVar == 2) then	
	
	;;---------------SUSBASS--------------------------------------------------------------------------;
	
	
	if gkCount == 1 then
	kSusBassSig = 1
	else kSusBassSig = 0
	endif

	else 
	kBassSig = 0
	kSusBassSig = 0
	endif

	
	;;----------------CRASH----------------------------------------------------------------------------;
	
	if gkCount == 1 then
	kCrashSig = 1
	else kCrashSig = 0
	endif
	
	
	;;-----------------CLAP----------------------------------------------------------------------------;
	
;	if gkCount == 5 then
;	kClapSig = 1
;	elseif gkCount == 13 then
;	kClapSig = 1
;	elseif gkCount == 21 then
;	kClapSig = 1
;	elseif gkCount == 29 then
;	kClapSig = 1
;	else kClapSig = 0
;	endif
	
	if gkCount == 29 then
		kcointoss trandom gkMetro, 0, 1
		if kcointoss <= 0.5 then
		kClapSig = 1
		;kSnareVel = 1
		else kClapSig = 0
		endif
	endif	
	
	
	;;----------------SNARE-----------------------------------------------------------------------------;
	
	
	if gkCount == 4 then
	kSnareSig = 1
	kSnareVel = 1
	elseif gkCount == 7 then
	kSnareSig = 1
	kSnareVel = 1
	elseif gkCount == 13 then
		kcointoss trandom gkMetro, 0, 1
		if kcointoss <= 0.7 then
		kSnareSig = 1
		kSnareVel = 1
		else kSnareSig = 0
		endif
	elseif gkCount == 4+16 then
	kSnareSig = 1
	kSnareVel = 1
	elseif gkCount == 7+16 then
	kSnareSig = 1
	kSnareVel = 1
	elseif gkCount == 13+16 then
		kcointoss trandom gkMetro, 0, 1
		if kcointoss <= 0.7 then
		kSnareSig = 1
		kSnareVel = 1
		else kSnareSig = 0
		endif
	elseif gkMetro == 1 then
		kcointoss trandom gkMetro, 0, 1
		if kcointoss <= 0.2 then
		kSnareSig = 1
		kSnareVel trandom gkMetro, 0.1, 0.4
		else kSnareSig = 0
		endif
	else kSnareSig = 0
	endif
	
	gkSnareDur trandom gkMetro, gk4, gk16
	
	;kchanged			changed			
	
	;gkRootTrig			trigger		kRootSig, 0.5, 0
	
	kSawTrig			trigger 		kSawSig, 0.5, 0
	kBassTrig			trigger		kBassSig, 0.5, 0
	kSusBassTrig		trigger		kSusBassSig, 0.5, 0
	kKickTrig			trigger		gkKickSync, 0.5, 0
	kCrashTrig		trigger		kCrashSig, 0.5, 0
	kClapTrig			trigger		kClapSig, 0.5, 0
	kSnareTrig		trigger		kSnareSig, 0.5, 0
	
	;gkSCTrig			trigger		kKickTrig, 0.5, 0
	
	
	

	
	kdel				=				0
	;kdur				=				gk1
	
						;schedkwhennamed		gkRootTrig, 0, 1, "root", 0, 0.2
						
						schedkwhennamed		kKickTrig, 0, 0, "kick", 0, gk4
						schedkwhennamed		kKickTrig, 0, 0, "sidechain", 0, gk4
						schedkwhennamed		kCrashTrig, 0, 0, "crash", 0, 0.3
						schedkwhennamed		kClapTrig, 0, 0, "clap", 0, 0.3
						schedkwhennamed		kSnareTrig, 0, 0, "snare", 0, gkSnareDur, kSnareVel
						schedkwhennamed		kKickTrig, 0, 0, "shaker", 0, gi4
						
						schedkwhennamed		kBassTrig, 0, 0, "bass", 0, gk4;, giRoot
						
						schedkwhennamed		kSusBassTrig, 0, 0, "susbassnotes", 0, gkdb1+0.2;, giRoot
	
						schedkwhennamed		kSawTrig, 0, 0, "saw2", kdel, kdur, kVoice1, kdec, ksus, kff
						schedkwhennamed		kSawTrig, 0, 0, "saw2", kdel, kdur, kVoice2, kdec, ksus, kff
						schedkwhennamed		kSawTrig, 0, 0, "saw2", kdel, kdur, kVoice3, kdec, ksus, kff
						schedkwhennamed		kSawTrig, 0, 0, "saw2", kdel, kdur, kVoice4, kdec, ksus, kff
						
						schedkwhennamed		gkRootTrig, 0, 0, "sawfilt", kdel, kdur

endin



instr sidechain

	;iBeatLength		=			i(gkBeatLength)

	ia					=			1
	idur1				=			0.01				
	ib					=			0.001;0.1;0.001				;SIDECHAIIN FLOOR
	idur2				=			i(gk8)				;SIDECHAIN ATTACK
	ic					=			1
	idur3				=			0.01
	id					=			1
	
	gaSC				expseg			ia, idur1, ib, idur2, ic, idur3, id;, idur4;, ie

endin


instr	sawfilt
	
	
	
	gaFiltEnv			linseg			0.1, gi1, 5, gi1, 0.5


endin



instr saw2
	
	iAmp				=				0.04
	
	kcps				=				cpsmidinn(p4)
	
	;icps				=				i(kcps)
	
	;kcps				portk			kcps, 0.1
	
	iA					=				0.015
	iD					=				p5;0.6;0.25
	iS					=				p6;0.1;0.0001
	iR					=				0.2
	
	ifn 				=				2
	
	irndphs1 			random 		0, 1
	irndphs2 			random 		0, 1
	irndphs3 			random 		0, 1
	
	kJitAmt 			= 				0.005
	kcpsMin 			= 				0.1
	kcpsMax 			= 				0.3
	kJit1 				jitter 		kJitAmt, kcpsMin, kcpsMax
	kJit1				=				0-kJit1
	kJit2 				jitter 		kJitAmt, kcpsMin, kcpsMax
	kJit3 				jitter 		kJitAmt, kcpsMin, kcpsMax

	kdetune 			= 				0.01
	
	aEnv1				mxadsr			iA, iD, iS, iR
	aEnv				=				aEnv1*iAmp 
	aSawC 				oscili 		aEnv, kcps*(1+kJit1), ifn, irndphs1
	aSawL 				oscili 		aEnv, kcps*(1+kJit2)*(1+kdetune), ifn, irndphs2
	aSawR 				oscili 		aEnv, kcps*(1-kJit3)*(1-kdetune), ifn, irndphs3
	aNoise1			noise			aEnv*0.7, 0
	aNoise1			atone			aNoise1, 4000
	aNoise2			noise			aEnv*0.7, 0
	aNoise2			atone			aNoise2, 4000
	
	aSawL				sum				aSawC+aSawL+aNoise1
	aSawR				sum				aSawC+aSawR+aNoise2
	
	kcf					=				p7
	acfenv				=				aEnv1*gaFiltEnv*kcf
	aSawL				moogladder	aSawL, acfenv, 0.01
	aSawR				moogladder	aSawR, acfenv, 0.01
	
	aL1, aL2			pan2			aSawL, 0
	aR1, aR2			pan2			aSawR, 1
	
	aL					=				aL1+aR1
	aR					=				aL2+aR2
	
	aSC					=				gaSC
	
	aL					=				aL*aSC
	aR					=				aR*aSC
	
	outs				aL, aR
	
	irvbgain			=				0.1
	
	gaOutL 			= 				gaOutL + (aL*irvbgain)
  	gaOutR 			= 				gaOutR + (aR*irvbgain)	
	
	
endin	


instr bass

	;kRootTrig			trigger		kRootSig, 0.5, 0
	
	idur				=				i(gk2)
	
	;kndx				random			0, 7
	;ifn 				=				20
	;kRoot				table			int(kndx), ifn 
	;iRoot				=				i(kRoot)+36
	
	krndoct			rspline		1, 2.2, 0.1, 0.7
	koct				=				24/int(krndoct)
	ioct				=				i(koct)
	
	kcps				=				cpsmidinn(giRoot-ioct);cpsmidinn(gkRoot+54-koct)
	iamp				=				0.25
	aEnv				expsegr		0.0001, 0.01, 1, idur, 0.001, 0.2, 0.00001
	kndx				expsegr		0.0001, 0.01, 1, idur, 0.001, 0.2, 0.00001						
	aFM					foscili		aEnv, kcps, 1, 2, kndx, 7
	aNoise				pinker
	aNoise				atone			aNoise, 5000
	aNoise 			moogladder	aNoise, 15000, 0
	aNoise 			=				(aNoise*0.1)*aEnv
	aFM					=				aFM+aNoise
	
	aFM					distort		aFM, 0.5, 50
	
	aFM					=				aFM*iamp*gaSC
	
	;aFiltC				compress2		aFiltC, aSCTrig, -400, -50, -30, 16, 0.01, 0.06, 0.02

	outs				aFM, aFM
	
	irvbgain			=				0.1
	
	gaOutL 			= 				gaOutL + (aFM*irvbgain)
  	gaOutR 			= 				gaOutR + (aFM*irvbgain)	
	

endin


instr susbassnotes
	
	;gkFreqCC 			midic7 $C5, 0, 127
	;gkMdwhl 			midic7 $C6, 0, 127
	krndoct			rspline		1, 2.2, 0.1, 0.7
	koct				=				24/int(krndoct)
	;ioct				=				i(koct)
	kcps  				=				cpsmidinn(giRoot-24)
	;iamp 		= 		p5/127
	;giamp 		=		iamp
	gkcpsbass 		=     	kcps 	; set global variable for oscillator frequency to MIDI freq.
                   			; coexisting notes are piled up so that the lasat note played will dictate the value of gkcps  
	;gkpb				init 0
	;					midipitchbend gkpb, 0.5, 2
	gkpb				pchbend 1, 2
	;gkpb				portk gkpb1, 0.01
	;printk2			gkpb
	;gkpbs				scale2 gkpb, mtof(-2), mtof(2), -1, 1, 0.001
						;printk2 gkpb
	;kcps		=		kcps+kpb	

	; only turn instr 2 on for the first note of a legato phrase
	if active:i(p1) == 1 then
 		turnon  "susbass"
	endif

endin


instr susbass
	
	iAmp 				=				0.03
	
	iA					=				0.2
	iD					=				0.6
	iS					=				1
	iR					=				0.3
	
	ifn 				=				2
	
	irndphs1 			random 		0, 1
	irndphs2 			random 		0, 1
	irndphs3 			random 		0, 1
	
	kJitAmt 			= 				0.005
	kcpsMin 			= 				0.1
	kcpsMax 			= 				0.3
	kJit1 				jitter 		kJitAmt, kcpsMin, kcpsMax
	kJit1				=				0-kJit1
	kJit2 				jitter 		kJitAmt, kcpsMin, kcpsMax
	kJit3 				jitter 		kJitAmt, kcpsMin, kcpsMax

	;kJit1				=				kJit1*0
	;kJit2				=				kJit2*0
	;kJit3				=				kJit3*0
	
	kdetune 			= 				0.004
	
	kporttime	=		0.05
	kport 		=     	kporttime * linseg:k(0,0.001,1) ; change 0.05 for longer or shorter portamento times
	kcps  				portk gkcpsbass, kport
	
	isus		=		1
	aEnv1 				linsegr 		0, 0.1, 1, 4, 1*isus, 0.3, 0
	aEnv 				=				aEnv1*iAmp 
	aSine				oscili 		aEnv1*(iAmp*1.3), kcps, 7
	aSawC 				oscili 		aEnv, kcps*(1+kJit1), ifn, irndphs1
	aSawL 				oscili 		aEnv, kcps*(1+kJit2)*(1+kdetune), ifn, irndphs2
	aSawR 				oscili 		aEnv, kcps*(1-kJit3)*(1-kdetune), ifn, irndphs3
	aSawL2 			oscili 		aEnv, kcps*(1+(kJit2*2))*(1+(kdetune*2)), ifn, irndphs3
	aSawR2				oscili 		aEnv, kcps*(1-(kJit3*2))*(1-(kdetune*2)), ifn, irndphs2
	aNoise1			noise			aEnv*0.7, 0
	aNoise1			atone			aNoise1, 4000
	aNoise2			noise			aEnv*0.7, 0
	aNoise2			atone			aNoise2, 4000
	
	aSawC    			*=    			linsegr:a(0,0.01,1,0.01,0)
	aSawL    			*=    			linsegr:a(0,0.01,1,0.01,0)
	aSawR    			*=    			linsegr:a(0,0.01,1,0.01,0)
	
	aSawC				=				aSine+aSawC
	aSawL				sum				aSawC, aSawL, aSawL2, aNoise1
	aSawR				sum				aSawC, aSawR, aSawR2, aNoise2
	
	kcf					=				1000+gkcpsbass
	acfenv				=				aEnv1*kcf
	
	aSawL				moogladder	aSawL, acfenv, 0.1
	aSawR				moogladder	aSawR, acfenv, 0.1
	
	aL1, aL2			pan2			aSawL, 0
	aR1, aR2			pan2			aSawR, 1
	
	aL					=				aL1+aR1
	aR					=				aL2+aR2
	
	aL					distort		aL, 0.2, 50
	aR					distort		aR, 0.2, 50
	
	aSC					=				gaSC
	
	aL					=				aL*aSC
	aR					=				aR*aSC
	
	outs				aL, aR
	
	irvbgain 			= 				0.1
	
   gaOutL 			= 				gaOutL + (aL*irvbgain)
   gaOutR 			= 				gaOutR + (aR*irvbgain)	
	
	; when all MIDI notes (instr 1) have been released, turn this instrument off
	if active:k("susbassnotes") == 0 then
 		turnoff
	endif

endin


instr kick
	
	aEnv				expsegr 		0.01, 0.01, 1, 0.4, 0.01, 0.2, 0.001
	iAmp				=				0.3

	aPchEnv			expsegr		0.01, 0.01, 1, 0.15, 0.005, 0.2, 0.01
	aNoiseEnv			expsegr		0.001, 0.01, 1, 0.01, 0.0001, 0.2, 0.0001
	;kscEnv				expsegr		0.01, 0.01, 1, 0.25, 0.01, 0.1, 0.01

	aKick 				oscili 		aEnv*iAmp, cpsmidinn(18)*(1+(aPchEnv*10))
	aNoise				noise			aNoiseEnv*0.03, 0.5
	aKick				=				aKick+aNoise
	
	
	aDist				distort		aKick, 0.5, 50	
	
	;kKick				=				k(kscEnv)
	;kSpline			rspline		0, 1, 0.01, 0.1
	;gkSCTrig			trigger		kscEnv, 0.5, 0
	
	;aDist				compress2		aDist, 
	
	outs				aDist, aDist
	
endin	


instr	snare
	
	iAmp 				=				0.1*p4
	iDur				=				i(gkSnareDur)
	aEnv				expsegr		0.001, 0.01, 1, iDur, 0.001, 0.1, 0.001
	aEnv				=				aEnv*iAmp
	aPchEnv			expsegr		0.01, 0.01, 1, 0.05, 0.1, 0.2, 0.01
	aSnare				oscili			aEnv, cpsmidinn(54)*(aPchEnv*2)
	aNoise				noise			aEnv*0.6, 0.5
	aNoise 			atone 			aNoise, 2000
	aSnare				=				aSnare+aNoise
	
	aSnare				distort		aSnare, 0.2, 50
	
	outs				aSnare, aSnare
	
	irvbgain			=				0.1
	
	;gaOutL 			= 				gaBIGL + (aSnare*irvbgain)
  	;gaOutR 			= 				gaBIGR + (aSnare*irvbgain)	

endin



instr crash
	
	idur				=				1/i(gkTicks)
	iAmp				=				0.2
	aEnv				expsegr		0.01, 0.01, 1, idur, 0.9, 0.025, 0.01, 0.2, 0.001
	aPink				pinker			
	aPink				atone			aPink, 10000
	aPink				moogladder	aPink, 20000, 0
	
	aPink				=				aPink*aEnv*iAmp
	aPink				distort		aPink, 0.3, 50
	
	outs				aPink, aPink
	
endin


instr clap

	iAmp				=				0.5
	iA					=				0.001
	iD					=				0.01
	iD2					=				0.13
	aEnv				expsegr		0.01, iA, 1, iD, 0.01, iA, 1, iD, 0.01, iA, 1, iD, 0.01, iA, 1, iD, 0.01, iA, 1, iD2, 0.0001, 0.1, 0.001
	aPinkC				pinker
	aPinkL				pinker
	aPinkR				pinker		
	
	aPinkL				sum				aPinkC, aPinkL
	aPinkR				sum				aPinkC, aPinkR
		
	aPinkL				atone			aPinkL, 1000
	aPinkR				atone			aPinkR, 1000

	aPinkL				moogladder	aPinkL, 20000, 0
	aPinkR				moogladder	aPinkR, 20000, 0
	
	aPinkL				=				aPinkL*aEnv*iAmp
	aPinkL				distort		aPinkL, 0.3, 50
	
	aPinkR				=				aPinkR*aEnv*iAmp
	aPinkR				distort		aPinkR, 0.3, 50
	
	aL1, aL2			pan2			aPinkL, 0.25
	aR1, aR2			pan2			aPinkR, 0.75
	
	aPinkL				=				aL1+aR1
	aPinkR				=				aL2+aR2
	
	
	outs				aPinkL, aPinkR
	
	irvbgain			=				0.4
	
	gaBIGL 			= 				gaBIGL + (aPinkL*irvbgain)
  	gaBIGR 			= 				gaBIGR + (aPinkR*irvbgain)	
	
endin				


instr shaker

	iAmp 				=				0.2

	aLFO				oscili			1, (gkTicks/2), 8, 0.9
	;aLFO2				oscili			1, (gkTicks/8), 8, 0.25
	aLFO3				expsegr		0.03, gi8, 1, gi8, 0.05, 0.1, 0.001
	
	iR					=				gi16/2
	
	;aLFO2				expsegr		0.001, iR, 1, iR, 0.001, iR, 1, iR, 0.001, iR, 1, iR, 0.001, iR, 1, iR, 0.001, 0.01, 0.001
	

	
	aPink 				pinker
	aPink				=				(aPink*aLFO*aLFO3)*iAmp
	aPink				atone			aPink, 10000
	
	outs				aPink, aPink
	
endin	
	


instr verb

	;-----------------REVERB---------------------

	irvbtime 			= 				0.8

	aL, aR 			reverbsc 		gaOutL, gaOutR, irvbtime, 5000
	
	;aCL compress2 aL, 
	
	aL					atone			aL, 800
	aR					atone			aR, 800
	
	aSC					=				gaSC
	
	aL					=				aL*aSC
	aR					=				aR*aSC
	
	outs aL, aR
	
	gaOutL = 0
	gaOutR = 0
	
endin	


instr verbBIG

	;-----------------REVERB---------------------

	irvbtime 			= 				0.99

	aL, aR 			reverbsc 		gaBIGL, gaBIGR, irvbtime, 8000
	
	;aCL compress2 aL, 
	
	aL					atone			aL, 1000
	aR					atone			aR, 1000
	
	aL					distort		aL, 0.1, 50
	aR					distort		aR, 0.1, 50
	
	aSC					=				gaSC
	
	aL					=				aL*aSC
	aR					=				aR*aSC
	
	outs aL, aR
	
	gaBIGL = 0
	gaBIGR = 0
	
endin	


</CsInstruments>
<CsScore>
 
f	1	0	1024	10		1	.8		.3														; SINE ish 
f	2	0	1024	7		1	1024	-1														; SAW 
f	3	0	1024	7		1	512		1		0		-1		512		-1						; SQUARE 
;f	4 	0 	16384 	10 		1 	0.5 	0.3 	0.25 	0.2 	0.167 	0.14 	0.125 	.111  	 ; Sawtooth ish 
;f	5 	0 	16384 	10 		1 	0   	0.3 	0    	0.2 	0     	0.14 	0     	.111  	 ; Square ish 
;f	6 	0 	16384 	10 		1 	1   	1   	1    	0.7 	0.5   	0.3  	0.1         	 ; Pulse ish 
f	7	0	1024	10		1																	; SINE 
f	8	0	1024	7		1	512		-1		512		1										; TRIANGLE 
 
 
;CHORDS 
f 	10 	0 	64		-2		0	2	7	11 
f	11	0	64		-2		3	7	10	14 
 
;CHORD QUALITY 
f	30	0	64		-2		10	11 
 
 
;SCALE / ROOT 
f	20	0	64		-2		0	2	4	5	7	9	11 
 
 
 
 
;Distortion 
f	50	0	1024	10	1 ;.2	 ;.2 
 
 
;Rhythm 
f	100	0	64		-2		1	1	2	1	3	4 
 
 
 
f	0 	z 
 
 </CsScore>
</CsoundSynthesizer>
