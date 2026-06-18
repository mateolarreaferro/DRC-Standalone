<CsoundSynthesizer>
<CsOptions>
-dm0
</CsOptions>
<CsInstruments>


ksmps = 32
nchnls = 2
0dbfs = 1
	
						massign		1, "MIDI"
						;massign		1, "MIDI0"
						;massign		1, "sequencer"
						
	gaOutL 			init 			0
	gaOutR 			init 			0
	gaBIGL				init			0
	gaBIGR				init			0
	giRoot				init			52
	gkRoot 			init			52
	gkKey				init			52

	#define 			C1 				#71#
	#define 			C2 				#72#
	#define 			C3 				#73#
	#define 			C4 				#74#
	#define 			C5 				#7#
	#define 			C6 				#1#
	#define 			C7 				#76#
	#define 			C8 				#77#



						alwayson		"clock"
						alwayson		"sequencer"
						alwayson		"rootseq"
						alwayson		"root"
						;alwayson		"sawseq"
						alwayson		"verb"
						alwayson		"verbBIG"
						alwayson		"measurecount"
						alwayson		"sawfilt"
						;alwayson		"MIDI0"
						;alwayson		"kick"
						;alwayson		"chordprog"
						alwayson		"chordprogtrig"
						seed			0
			
instr tempo

	gibpm				random			100, 180
	printk2 gibpm

endin			
						

instr clock

	;gkbpm				random			100, 145
	
	gkTempo			=				gibpm
	giTempo			=				i(gkTempo)
	gkSubdiv			=				4
	gkTicks			=				(gkTempo/60)*gkSubdiv
	gkMetro			metro			gkTicks, 0.0000000001
	
	k8B					metro			(gkTempo/60)*2, 0.0000000001
	k4B					metro			(gkTempo/60), 0.0000000001
	k2B					metro			(gkTempo/60)/2, 0.0000000001
	k1B					metro			(gkTempo/60)/4, 0.0000000001
	
	;print giTempo
						;printk2 		gkMetro
	
	gk16				=				1/gkTicks
	gk8					=				2/gkTicks					
	gk4					=				4/gkTicks
	gk2					=				8/gkTicks
	gk1					=				16/gkTicks
	gkdb1				=				32/gkTicks
	
	gk1S				=				gkTempo/4/60
	
	
	
	;;--------------SIXTEENTHS-------------------;
	reset:
	gkCount			init			1
	if (gkMetro == 1)	then
	gkCount += 1
	endif
	if (gkCount == gkSubdiv*8+1) then
	reinit reset
	endif
	rireturn
	
	;;---------------EIGHTHS-----------------------;
	bro:
	gkEighths			init			1
	if (k8B == 1)	then
	gkEighths += 1
	endif
	if (gkEighths == 8+1) then
	reinit bro
	endif
	rireturn
	
	;;---------------QUARTERS----------------------;
	dude:
	gkQuarters			init			1
	if (k4B == 1)	then
	gkQuarters += 1
	endif
	if (gkQuarters == 4+1) then
	reinit dude
	endif
	rireturn
	
	
	
	gk8B				metro			(gkTempo/60)*2;, 0.0000000001
	gk4B				metro			(gkTempo/60);, 0.0000000001
	gk2B				metro			(gkTempo/60)/2;, 0.0000000001
	gk1B				metro			(gkTempo/60)/4;, 0.0000000001
	
	;printk2 gkQuarters
	
	
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
	
	gkMeasureTrig		changed2		gkMeasure
	
	;printk2 gkMeasureTrig
	
	oncemore:
	gk8Measures 		init			1
	if (gkMeasureTrig == 1)	then
	gk8Measures += 1
	endif
	if (gk8Measures == 8+1) then
	reinit oncemore
	endif
	rireturn	
	
	printk2 gk8Measures, 0, 1
	
	;gk8Measures			changed2		gk8Measures
	
	if gk8Measures == 1 then
	gk8MPhraseSig = 1
	else gk8MPhraseSig = 0
	endif
	
	gk8MPhraseTrig		metro			(gkTempo/60)/4/8, 0.0000000001
	
	yeah:
	gk8MPhraseCnt 		init			1
	if (gk8MPhraseTrig == 1)	then
	gk8MPhraseCnt += 1
	endif
	if (gk8MPhraseCnt == 8+1) then
	reinit yeah
	endif
	rireturn	
	
	
	printk2 gk8MPhraseCnt, 0, 1
	
	if gk8MPhraseCnt == 1 then
	gkBIG8Sig = 1
	else gk8BIG8Sig = 0
	endif
	
	gkBIG8Trig			metro  		(gkTempo/60)/4/8/8, 0.0000000001
	
	gk8MPhrase			changed2		gk8MPhraseCnt
	
	if gk8MPhrase == 1 then
	gk8Sig = 1
	else gk8Sig = 0
	endif
	
	gk8Trig				trigger		gk8Sig, 0.5, 0
	
	yeah:
	gkBIG8			init			1
	if (gk8Trig == 1)	then
	gkBIG8 += 1
	endif
	if (gkBIG8 == 8+1) then
	reinit yeah
	endif
	rireturn	
	
	printk2 gkBIG8
	
	;gkBIG8Trig			changed2		gkBIG8
	
	;gkRootSeqTrig		trigger				gkCountTrig, 0.5, 0
	;gkRootSeqTrig2	trigger				gkRootSeqTrig, 0.5, 0
	
						;schedkwhennamed		gkRootSeqTrig, 0, 1, "rootseq", 0, gkdb1					

endin




instr	rootseq
	
;	if gkCount == 1 then
;	kRootSig = 1
;	else kRootsig = 0
;	endif
	
	gkMeasureTrig		changed				gkMeasure
	
	
	
	
	if gkMeasureTrig == 1 then
		kcointoss trandom gkMetro, 0, 1
		if kcointoss <= 0.5 then
		kRootSig = 1
		else kRootSig = 0
		endif
	else kRootSig = 0
	endif
	
	
	if gkMeasureTrig == 1 then
;		kcointoss trandom gkMetro, 0, 1
;		if kcointoss <= 0.5 then
;		kRootSig = 1
;		else kRootSig = 0
;		endif
	else kRootSig = 0
	endif	
	
	;printk2 kRootSig
	;printk2 gkRootSeqTrig2
	
	
	gkRootTrig		trigger				kRootSig, 0.5, 0
	
	;gkRootTrig2		trigger				gkRootTrig, 0.5, 1
	
	
	
						;schedkwhennamed		gkRootTrig, 0, 1, "root", 0, 0.2	
						;schedkwhennamed		gkRootTrig, 0, 1, "chordprogtrig", 0, 0.4

	;printk2 gkCount
	;printk2 gkRootTrig, 0, 1

endin


instr	chordprogtrig
	
	;kTrig				linseg			0, 0.001, 1, 0.001, 0, 0.001, 1, 0.001, 0, 0.001, 1, 0.001, 0, 0.001, 1, 0.001, 0, 0.001, 1, 0.001, 0, 0.001, 1, 0.001, 0, 0.001, 1, 0.001, 0, 0.001, 1, 0.001, 0, 0.001, 1, 0.001, 0, 0.001, 1, 0.001, 0
	
	if gkMeasure == 1 then
	kChordProgSig = 1
	else kChordProgSig = 0
	endif
	
	gkChordProgTrig	trigger		kChordProgSig, 0.5, 1
	
						;schedkwhennamed		gkRootTrig, 0, 1, "chordprog", 0, 0.1
	;printk2 gkChordProgTrig
	
endin


instr	chordprog

	ifn					=				21
	
	indx1				random			0, 10
	indx2				random			0, 10
	indx3				random			0, 10
	indx4				random			0, 10
	indx5				random			0, 10
	indx6				random			0, 10
	indx7				random			0, 10
	indx8				random			0, 10
	indx9				random			0, 10
	indx10				random			0, 10
	
	gibang1			table			int(indx1), ifn
	gibang2			table			int(indx2), ifn
	gibang3			table			int(indx3), ifn 
	gibang4			table			int(indx4), ifn 
	gibang5			table			int(indx5), ifn 
	gibang6			table			int(indx6), ifn 
	gibang7			table			int(indx7), ifn 
	gibang8			table			int(indx8), ifn 
	gibang9			table			int(indx9), ifn 
	gibang10			table			int(indx10), ifn 
	
	i1					=				gibang1
	i2					=				gibang2
	i3					=				gibang3
	i4					=				gibang4
	i5					=				gibang5
	i6					=				gibang6
	i7					=				gibang7
	i8					=				gibang8
	i9					=				gibang9
	i10					=				gibang10
	
	giChordProg		ftgen			200, 0, 64, -2, i1, i2, i3, i4, i5, i6, i7, i8, i9, i10
	
	print i1
	print i2
	print i3
	print i4
	print i5
	print i6
	print i7
	print i8
	print i9
	print i10
	
	;;------------------------------------------RHYTHM----------------------------------------------------------;	

	iB1					random			0, 2			;1
	iB2					random			0, 1.25
	iB3					random			0, 1.5
	iB4					random			0, 1.25
	iB5					random			0, 1.75			;2
	iB6					random			0, 1.25					
	iB7					random			0, 1.5
	iB8					random			0, 1.25
	iB9					random			0, 1.75			;3
	iB10				random			0, 1.25
	iB11				random			0, 1.5
	iB12				random			0, 1.25
	iB13				random			0, 1.75			;4
	iB14				random			0, 1.25
	iB15				random			0, 1.5
	iB16				random			0, 1.25						
	iB17				random			0, 1.75			;1
	iB18				random			0, 1.25
	iB19				random			0, 1.5
	iB20				random			0, 1.25						
	iB21				random			0, 1.75			;2
	iB22				random			0, 1.25
	iB23				random			0, 1.5
	iB24				random			0, 1.25
	iB25				random			0, 1.75			;3
	iB26				random			0, 1.25
	iB27				random			0, 1.5
	iB28				random			0, 1.25
	iB29				random			0, 1.75			;4
	iB30				random			0, 1.25
	iB31				random			0, 1.5
	iB32				random			0, 1.25
	
	iB1					=				int(iB1)
	iB2					=				int(iB2)
	iB3					=				int(iB3)
	iB4					=				int(iB4)
	iB5					=				int(iB5)
	iB6					=				int(iB6)
	iB7					=				int(iB7)
	iB8					=				int(iB8)
	iB9					=				int(iB9)
	iB10				=				int(iB10)
	iB11				=				int(iB11)
	iB12				=				int(iB12)
	iB13				=				int(iB13)
	iB14				=				int(iB14)
	iB15				=				int(iB15)
	iB16				=				int(iB16)
	iB17				=				int(iB17)
	iB18				=				int(iB18)
	iB19				=				int(iB19)
	iB20				=				int(iB20)
	iB21				=				int(iB21)
	iB22				=				int(iB22)
	iB23				=				int(iB23)
	iB24				=				int(iB24)
	iB25				=				int(iB25)
	iB26				=				int(iB26)
	iB27				=				int(iB27)
	iB28				=				int(iB28)
	iB29				=				int(iB29)
	iB30				=				int(iB30)
	iB31				=				int(iB31)
	iB32				=				int(iB32)
	
	
	
	
	giChordRhythm		ftgen			250, 0, 64, -2, iB1, iB2, iB3, iB4, iB5, iB6, iB7, iB8, iB9, iB10, iB11, iB12, iB13, iB14, iB15, iB16, iB17, iB18, iB19, iB20, iB21, iB22, iB23, iB24, iB25, iB26, iB27, iB28, iB29, iB30, iB31, iB32
	
	ftprint 250
	
endin



instr	root
	
;	indx				random			0, 10
;	ifn 				=				21
;	giRoot				table			indx, ifn
;	giRoot				=				giRoot+i(gkKey)
;	
;
;	gkRoot1			table			indx, ifn
;	gkRoot				=				gkRoot1+gkKey
	
	
	;indx				random			0, 10
	
	
	

	
	doover:
	kndxR			init			0
	if (gkMetro == 1)	then
	kndxR += 1
	endif
	if (kndxR == 32) then
	reinit doover
	endif
	rireturn
	
	
	ifn					=				250
	kRhythm			table			kndxR, ifn
	
	if kRhythm == 1 then
	kChordSig = 1
	else kChordSig = 0
	endif
	
	
;	if gkCount % 7 = 1 then
;	kChordSig = 1
;	else kChordSig = 0
;	endif
	
	kChordTrig		trigger		kChordSig, 0.5, 0
	gkChordTrigRoot	trigger		kChordTrig, 0.5, 0
	
	
	onemoretime:
	kndxR2			init			0
	if (kChordTrig == 1)	then
	kndxR2 += 1
	endif
	if (gk8Measures == 1) then
	reinit onemoretime
	elseif (kndxR2 == 32) then
	reinit onemoretime
	endif
	rireturn 
	
	ifn					=				250
	kRootRhythm		table			kndxR2, ifn
	
	kRootRhythmTrig	changed2		kRootRhythm
	
	restart:
	kndx			init			0
	if (kRootRhythmTrig == 1)	then
	kndx += 1
	endif
	if (kndx == 10) then
	reinit restart
	elseif (kndxR == 32) then
	reinit restart
	elseif (gk8Measures == 1) then
	reinit restart
	endif
	rireturn 
	
	;printk2 gkChordTrigRoot, 0, 1
	
	ifn 				=				200
	;indx				=				i(kndx)
	giRoot				table			i(kndx), ifn
	giRoot				=				giRoot+i(gkKey)
	
	;kndx				random		0, 6.999
	;ifn 				=				20
	gkRoot1			table			kndx, ifn
	gkRoot				=				gkRoot1+gkKey	
	
	
	
;	turnoff2	"saw2", 0, 0.1
;	turnon "saw2"
	
	;gkRoot 			tablekt		
	
	
;	if gkRoot == 0 then
;		kcointoss trandom gkRootTrig, 0, 1
;		if kcointoss <= 0.8 then
;		gkRoot = -4
;		else gkRoot = 4
;		endif
;	else gkRoot = 0
;	endif
		
	printk2 gkRoot1
	
	;gkRootTrig2		trigger		gkRootTrig, 0.5, 1
	
	;printk2 gkRootTrig2, 0, 2

endin



instr sequencer
	
	
;	kVar				init			1
;	if gk8MPhraseCnt == 1 then
;	kVar += 1
;	
	sup:
	kVar 		init			1
	if (gkBIG8Trig == 1)	then
	kVar += 1
	endif
	if (kVar == 3+1) then
	if (gkBIG8Trig == 1)	then
	kVar -= 1
	endif
	endif
	if (kVar == 1) then
	reinit sup
	endif
	rireturn	
	
	printk2 kVar, 0, 1
	;kVar = 2
	iVar random 2, 4
	kVar = int(iVar)
	
	;kVar				=				1;int(kVar)
	;kSawVar			=				2
	;printk2 kVar, 0, 1
	
	
	
	;;-----------------SAW-----------------------------------------------------------------------------;
	
	if (kVar == 2) then
	
	kSawSpl1			rspline		3, 7, 0.1, 0.4
	kSawSplint		=				int(kSawSpl1)
	kSawRhythm		=				3;kSawSplint
	
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
	
	iChordQual		init			12
	kChordQual		init			12
	;kChordQual		trandom		gkRootTrig, 10, 12
	
	if	gkRoot1 == 0 then
		kcointoss trandom gkChordTrigRoot, 0, 1
		if kcointoss <= 0.4 then
		kChordQual = 12
		else kChordQual = 13
		endif
	elseif	gkRoot1 == 1 then
		kcointoss trandom gkChordTrigRoot, 0, 1
		if kcointoss <= 1 then
		kChordQual = 12
		else kChordQual = 13
		endif
	elseif gkRoot1 == 2 then
		kcointoss trandom gkChordTrigRoot, 0, 1
		if kcointoss <= 0.9 then
		kChordQual = 13
		else kChordQual = 12
		endif
	elseif	gkRoot1 == 3 then
		kcointoss trandom gkChordTrigRoot, 0, 1
		if kcointoss <= 0.9 then
		kChordQual = 12
		else kChordQual = 13
		endif
	elseif gkRoot1 == 4 then
		kcointoss trandom gkChordTrigRoot, 0, 1
		if kcointoss <= 1 then
		kChordQual = 16
		else kChordQual = 12
		endif
	elseif gkRoot1 == 5 then
		kcointoss trandom gkChordTrigRoot, 0, 1
		if kcointoss <= 0.1 then
		kChordQual = 12
		else kChordQual = 13
		endif
	elseif gkRoot1 == 7 then
		;kcointoss trandom gkRootTrig, 0, 1
		icointoss random 0, 1
		if icointoss <= 0.5 then
		kChordQual = 17
		else kChordQual = 14
		endif
	elseif gkRoot1 == -4 then
		icointoss random 0, 1
		if icointoss <= 0.8 then
		kChordQual = 12
		else kChordQual = 13
		endif
	elseif	gkRoot1 == -3 then
;		kcointoss trandom gkRootTrig, 0, 1
;		if kcointoss <= 0.5 then
;		kChordQual = 12
;		else kChordQual = 13
;		endif
		kChordQual = 16
	elseif gkRoot1 == -2 then
		icointoss random 0, 1
		if icointoss <= 0.33 then
			icointoss random 0, 1
			if icointoss <= 0.5 then
			kChordQual = 12
			else kChordQual = 13
			endif
		else kChordQual = 14
		endif
	else kChordQual = 12
	endif
	
	kVoice1			tablekt		0, kChordQual
	kVoice2			tablekt		1, kChordQual
	kVoice3			tablekt		2, kChordQual
	kVoice4			tablekt		3, kChordQual
	kVoice5			tablekt		4, kChordQual
	kVoice6			tablekt		5, kChordQual
	
	kVoice1			=				kVoice1+gkRoot-12
	kVoice2			=				kVoice2+gkRoot-12
	kVoice3			=				kVoice3+gkRoot-12
	kVoice4			=				kVoice4+gkRoot-12
	kVoice5			=				kVoice5+gkRoot-12
	kVoice6			=				kVoice6+gkRoot-12
	
	katt				trandom		kSawSig, 0.01, 0.03;0.015
	kdur				trandom		kSawSig, 0.1, 1;1
	kdec				rspline		gk4, gk1, 0.01, 0.1;0.6
	ksus				trandom		kSawSig, 0.0001, 0.01;		0.0001
	kff					rspline		500, 20000, 0.01, 0.1
	kverb				=				0.2
	kenv				=				1
	
	
	elseif (kVar == 1) then
	
	if gkChordTrigRoot == 1 then
	kSawSig = 1
	else kSawSig = 0
	endif
	
;	if gkSawSync == 1 then
;	kSawSig = 1
;	else kSawSig = 0
;	endif	
	
	;printk2 kSawSig
	
	iChordQual		init			12
	kChordQual		init			12
	;kChordQual		trandom		gkRootTrig, 10, 12
	
	if	gkRoot1 == 0 then
		kcointoss trandom gkChordTrigRoot, 0, 1
		if kcointoss <= 0.4 then
		kChordQual = 12
		else kChordQual = 13
		endif
	elseif	gkRoot1 == 1 then
		kcointoss trandom gkChordTrigRoot, 0, 1
		if kcointoss <= 1 then
		kChordQual = 12
		else kChordQual = 13
		endif
	elseif gkRoot1 == 2 then
		kcointoss trandom gkChordTrigRoot, 0, 1
		if kcointoss <= 0.9 then
		kChordQual = 13
		else kChordQual = 12
		endif
	elseif	gkRoot1 == 3 then
		kcointoss trandom gkChordTrigRoot, 0, 1
		if kcointoss <= 0.9 then
		kChordQual = 12
		else kChordQual = 13
		endif
	elseif gkRoot1 == 4 then
		kcointoss trandom gkChordTrigRoot, 0, 1
		if kcointoss <= 1 then
		kChordQual = 16
		else kChordQual = 12
		endif
	elseif gkRoot1 == 5 then
		kcointoss trandom gkChordTrigRoot, 0, 1
		if kcointoss <= 0.1 then
		kChordQual = 12
		else kChordQual = 13
		endif
	elseif gkRoot1 == 7 then
		;kcointoss trandom gkRootTrig, 0, 1
		icointoss random 0, 1
		if icointoss <= 0.5 then
		kChordQual = 17
		else kChordQual = 14
		endif
	elseif gkRoot1 == -4 then
		icointoss random 0, 1
		if icointoss <= 0.8 then
		kChordQual = 12
		else kChordQual = 13
		endif
	elseif	gkRoot1 == -3 then
;		kcointoss trandom gkRootTrig, 0, 1
;		if kcointoss <= 0.5 then
;		kChordQual = 12
;		else kChordQual = 13
;		endif
		kChordQual = 16
	elseif gkRoot1 == -2 then
		icointoss random 0, 1
		if icointoss <= 0.33 then
			icointoss random 0, 1
			if icointoss <= 0.5 then
			kChordQual = 12
			else kChordQual = 13
			endif
		else kChordQual = 14
		endif
	else kChordQual = 12
	endif
	
	
	;kChordQual		=				12;int(kChordQual)
	;iChordQual		=				i(kChordQual)
	
	;print iChordQual
	;printk2 kChordQual
	
	kVoice1			tablekt		0, kChordQual
	kVoice2			tablekt		1, kChordQual
	kVoice3			tablekt		2, kChordQual
	kVoice4			tablekt		3, kChordQual
	kVoice5			tablekt		4, kChordQual
	kVoice6			tablekt		5, kChordQual
	
	kVoice1			=				kVoice1+gkRoot-12
	kVoice2			=				kVoice2+gkRoot-12
	kVoice3			=				kVoice3+gkRoot-12
	kVoice4			=				kVoice4+gkRoot-12
	kVoice5			=				kVoice5+gkRoot-12
	kVoice6			=				kVoice6+gkRoot-12		
	
	katt				=				0.05;gk16
	kdur				=				gkdb1*8
	kdec 				=				gk1
	ksus				=				0.1;0.1			
	kff					rspline		500, 20000, 0.01, 0.1
	kEnv				oscili			1, (gkTempo/60)/4/8/8, 4, 0
	kEnv 				expcurve		kEnv, 0.1
	kff					=				kff*kEnv
	kverb				=				0;0.2
	kenv				=				2
	
	;printk2 kff
	
	;printk2 gkRoot1
	;printk2 kChordQual
	
	elseif (kVar = 3) then
	
	if gkChordTrigRoot == 1 then
	kSawSig = 1
	else kSawSig = 0
	endif
	
;	if gkSawSync == 1 then
;	kSawSig = 1
;	else kSawSig = 0
;	endif	
	
	;printk2 kSawSig
	
	iChordQual		init			12
	kChordQual		init			12
	;kChordQual		trandom		gkRootTrig, 10, 12
	
	if	gkRoot1 == 0 then
		kcointoss trandom gkChordTrigRoot, 0, 1
		if kcointoss <= 0.2 then
		kChordQual = 12
		else kChordQual = 13
		endif
	elseif	gkRoot1 == 1 then
		kcointoss trandom gkChordTrigRoot, 0, 1
		if kcointoss <= 1 then
		kChordQual = 12
		else kChordQual = 13
		endif
	elseif gkRoot1 == 2 then
		kcointoss trandom gkChordTrigRoot, 0, 1
		if kcointoss <= 0.9 then
		kChordQual = 13
		else kChordQual = 12
		endif
	elseif	gkRoot1 == 3 then
		kcointoss trandom gkChordTrigRoot, 0, 1
		if kcointoss <= 0.9 then
		kChordQual = 12
		else kChordQual = 13
		endif
	elseif gkRoot1 == 4 then
		kcointoss trandom gkChordTrigRoot, 0, 1
		if kcointoss <= 1 then
		kChordQual = 16
		else kChordQual = 12
		endif
	elseif gkRoot1 == 5 then
		kcointoss trandom gkChordTrigRoot, 0, 1
		if kcointoss <= 0.1 then
		kChordQual = 12
		else kChordQual = 13
		endif
	elseif gkRoot1 == 7 then
		;kcointoss trandom gkRootTrig, 0, 1
		icointoss random 0, 1
		if icointoss <= 0.5 then
		kChordQual = 17
		else kChordQual = 14
		endif
	elseif gkRoot1 == -4 then
		icointoss random 0, 1
		if icointoss <= 0.8 then
		kChordQual = 12
		else kChordQual = 13
		endif
	elseif	gkRoot1 == -3 then
;		kcointoss trandom gkRootTrig, 0, 1
;		if kcointoss <= 0.5 then
;		kChordQual = 12
;		else kChordQual = 13
;		endif
		kChordQual = 16
	elseif gkRoot1 == -2 then
		icointoss random 0, 1
		if icointoss <= 0.33 then
			icointoss random 0, 1
			if icointoss <= 0.5 then
			kChordQual = 12
			else kChordQual = 13
			endif
		else kChordQual = 14
		endif
	else kChordQual = 12
	endif
	
	
	;kChordQual		=				12;int(kChordQual)
	;iChordQual		=				i(kChordQual)
	
	;print iChordQual
	;printk2 kChordQual
	
	kVoice1			tablekt		0, kChordQual
	kVoice2			tablekt		1, kChordQual
	kVoice3			tablekt		2, kChordQual
	kVoice4			tablekt		3, kChordQual
	kVoice5			tablekt		4, kChordQual
	kVoice6			tablekt		5, kChordQual
	
	kVoice1			=				kVoice1+gkRoot-12
	kVoice2			=				kVoice2+gkRoot-12
	kVoice3			=				kVoice3+gkRoot-12
	kVoice4			=				kVoice4+gkRoot-12
	kVoice5			=				kVoice5+gkRoot-12
	kVoice6			=				kVoice6+gkRoot-12		
	
	katt				=				gk16
	kdur				=				gk1;gkdb1*8
	kdec 				=				gk2
	ksus				=				0.1
	;kff					=				17000
	iff					random			1000, 20000
	kff					=				iff
	kverb				=				0.2
	kenv				=				3	
	
	
	
	else kSawSig = 0
	
	endif
	
	;;-----------------KICK--------------------------------------------------------------------------;
	
						;initc7			1, $C1, 0
	;kKickFilt			midic7			$C1, 0, 127
	
	kKickRhythm		=				4
	
	;if gkCount % kKickRhythm = 0 then
	;gkKickSync = 1
	;else gkKickSync = 0
	;endif
	
	if (kVar == 2) then
	
	gkKickSync = gk4B
	kKickFiltEnv = 1
	
	elseif (kVar == 1) then
	
	if gk8MPhraseCnt >= 2 then
	kKickFiltSig	= 1
	else kKickFiltSig = 0
	endif
	
	kKickFiltTrig 			trigger		kKickFiltSig, 0.5, 0
	
	
	kKickFiltEnv				triglinseg	kKickFiltTrig	, 0, (giTempo/60)/4/8/8, 1
	kKickFiltEnv 				expcurve		kEnv, 0.01
	
	
	
	gkKickSync = gk4B
	
	printk2 kKickFiltTrig
	
;	if gkCount == 1 then
;	gkKickSync = 1
;	elseif gkCount == 5 then
;	gkKickSync = 1
;	elseif gkCount == 9 then
;	gkKickSync = 1
;	elseif gkCount == 13 then
;	gkKickSync = 1
;	elseif gkCount == 17 then
;	gkKickSync = 1
;	elseif gkCount == 21 then
;	gkKickSync = 1
;	elseif gkCount == 25 then
;	gkKickSync = 1
;	elseif gkCount == 29 then
;	gkKickSync = 1
;	else gkKickSync = 0
;	endif
	
	
	
	elseif (kVar == 3) then
	
	kKickFiltEnv = 1
	
	if gkChordTrigRoot == 1 then
	gkKickSync = 1
	else gkKickSync = 0
	endif
	
	else gkKickSync = 0
	;printk2 gkChordTrigRoot
	
	endif
	
	
	
	;if gkCount == 1 then
	;if gkKickSync == 1 then
	;gkKickSig = 1
	;else gkKickSig = 0
	;endif
	
	
	;;-----------------BASS---------------------------------------------------------------------------;
	
	if (kVar == 2) then
	
	turnoff2	"susbass", 0, 0.1
	
	
	kBassRhythm		=				3
	
	if gkCount % kBassRhythm = 1 then
	kBassSync = 1
	else kBassSync = 0
	endif
	
	if kBassSync == 1 then
	kBassSig = 1
	elseif gkChordTrigRoot == 1 then
	kBassSig = 1
	else kBassSig = 0
	endif

	
	
	elseif (kVar == 3) then
	
	turnoff2	"susbass", 0, 0.1
	
	
	kBassRhythm		=				3
	
	if gkCount % kBassRhythm = 1 then
	kBassSync = 1
	else kBassSync = 0
	endif
	
	if kBassSync == 1 then
	kBassSig = 1
	else kBassSig = 0
	endif
	
	
	
	
	
	
	elseif (kVar == 1) then	
	
	;;---------------SUSBASS--------------------------------------------------------------------------;
	turnoff2	"bass", 0, 0.1
	
	if gkRootTrig == 1 then
	kSusBassSig = 1
	else kSusBassSig = 0
	endif

	else 
	kBassSig = 0
	kSusBassSig = 0
	endif
	

	
	;;----------------CRASH----------------------------------------------------------------------------;
	
	if (kVar == 2) then
	
	if gkCount == 1 then
	kCrashSig = 1
	else kCrashSig = 0
	endif
	
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
	
	if (kVar == 1) then
	
	if gk8MPhraseCnt >= 4 then
	
	if gkCount == 29 then
		kcointoss trandom gkMetro, 0, 1
		if kcointoss <= 0.7 then
		kClapSig = 1
		;kSnareVel = 1
		else kClapSig = 0
		endif
	endif	
	
	endif
	
	elseif (kVar == 2) then
	
	if gkCount == 29 then
		kcointoss trandom gkMetro, 0, 1
		if kcointoss <= 0.75 then
		kClapSig = 1
		;kSnareVel = 1
		else kClapSig = 0
		endif
	endif	
	
	else kClapSig = 0
	
	endif
	
	
	;;----------------SNARE-----------------------------------------------------------------------------;
	
	if (kVar == 1) then
	
	if gk8MPhraseCnt >= 5 then
	
	if gkCount == 4 then
		kcointoss trandom gkMetro, 0, 1
		if kcointoss <= 0.75 then
		kSnareSig = 1
		kSnareVel = 1
		else kSnareSig = 0
		endif
	elseif gkCount == 7 then
		kcointoss trandom gkMetro, 0, 1
		if kcointoss <= 0.75 then
		kSnareSig = 1
		kSnareVel = 1
		else kSnareSig = 0
		endif
	elseif gkCount == 13 then
		kcointoss trandom gkMetro, 0, 1
		if kcointoss <= 0.75 then
		kSnareSig = 1
		kSnareVel = 1
		else kSnareSig = 0
		endif
	elseif gkCount == 4+16 then
		kcointoss trandom gkMetro, 0, 1
		if kcointoss <= 0.75 then
		kSnareSig = 1
		kSnareVel = 1
		else kSnareSig = 0
		endif
	elseif gkCount == 7+16 then
		kcointoss trandom gkMetro, 0, 1
		if kcointoss <= 0.75 then
		kSnareSig = 1
		kSnareVel = 1
		else kSnareSig = 0
		endif
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
	
	endif
	
	
	
	elseif (kVar = 2) then
	
	if gkCount == 4 then
		kcointoss trandom gkMetro, 0, 1
		if kcointoss <= 0.75 then
		kSnareSig = 1
		kSnareVel = 1
		else kSnareSig = 0
		endif
	elseif gkCount == 7 then
		kcointoss trandom gkMetro, 0, 1
		if kcointoss <= 0.75 then
		kSnareSig = 1
		kSnareVel = 1
		else kSnareSig = 0
		endif
	elseif gkCount == 13 then
		kcointoss trandom gkMetro, 0, 1
		if kcointoss <= 0.75 then
		kSnareSig = 1
		kSnareVel = 1
		else kSnareSig = 0
		endif
	elseif gkCount == 4+16 then
		kcointoss trandom gkMetro, 0, 1
		if kcointoss <= 0.75 then
		kSnareSig = 1
		kSnareVel = 1
		else kSnareSig = 0
		endif
	elseif gkCount == 7+16 then
		kcointoss trandom gkMetro, 0, 1
		if kcointoss <= 0.75 then
		kSnareSig = 1
		kSnareVel = 1
		else kSnareSig = 0
		endif
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
	
	endif
	
	
	;;---------------TRAP-----------------------------------------------------------------------------;
	
	if (kVar == 3) then
	
	
	if gkQuarters == 3 then
	kTrapSig = 1
	else kTrapSig = 0
	endif
	
	else kTrapSig = 0
	
	endif
	
	;;---------------HIHAT----------------------------------------------------------------------------;
	
	if (kVar == 3) then
	
	kHiHatSig			=				gk4B
	
	else kHiHatSig = 0
	
	
	endif
	
	
	;;--------------SHAKER----------------------------------------------------------------------------;
	
	if (kVar == 1) then
	
	if gk8MPhraseCnt >= 2 then
	kShakerSig = gk4B
	else kShakerSig = 0
	endif
	
	elseif (kVar == 2) then
	kShakerSig = gk4B
	
	elseif (kVar ==3) then
	kShakerSig = gk4B
	else
	kShakerSig = 0
	endif
	
	
	
	;;--------------SAWFILT---------------------------------------------------------------------------;
	
;	if gkCount == 1 then
;		kcointoss trandom gkMetro, 0, 1
;		if kcointoss <= 0.5 then
;		kSawFiltSig = 1
;		else kSawFiltSig = 0
;		endif
;	else kSawFiltSig = 0
;	endif
	
	kSawOffTrig		changed		gkRoot, kChordQual, gkChordTrigRoot
	
	gkSnareDur 		trandom 		gkMetro, gk4, gk16
	
	;kchanged			changed			
	
	;gkRootTrig			trigger		kRootSig, 0.5, 0
	
	kSawTrig			trigger 		kSawSig, 0.5, 0
	kBassTrig			trigger		kBassSig, 0.5, 0
	kSusBassTrig		trigger		kSusBassSig, 0.5, 0
	kKickTrig			trigger		gkKickSync, 0.5, 0
	kCrashTrig		trigger		kCrashSig, 0.5, 0
	kClapTrig			trigger		kClapSig, 0.5, 0
	kSnareTrig		trigger		kSnareSig, 0.5, 0
	kTrapTrig			trigger		kTrapSig, 0.5, 0
	kHiHatTrig		trigger		kHiHatSig, 0.5, 0
	kShakerTrig 		trigger		kShakerSig, 0.5, 0
	;kSawFiltTrig		trigger		kSawFiltSig, 0.5, 0
	
	kSawOff			trigger		kSawOffTrig, 0.5, 0
	
	;gkSCTrig			trigger		kKickTrig, 0.5, 0
	
	;printk2 kKickTrig, 0, 1
	
	;printk2 kSawTrig, 0 , 1

	;katt = 0.2
	kdel				=				0.003
	;kdur				=				gk1
	
						;schedkwhennamed		gkRootTrig, 0, 1, "root", 0, 0.2
						
						schedkwhennamed		kKickTrig, 0, 0, "sidechain", 0, gk4
						
						schedkwhennamed		kKickTrig, 0, 0, "kick", 0, gk4, kKickFiltEnv
						schedkwhennamed		kCrashTrig, 0, 0, "crash", 0, 0.3
						schedkwhennamed		kClapTrig, 0, 0, "clap", 0, 0.3
						schedkwhennamed		kSnareTrig, 0, 0, "snare", 0, gkSnareDur, kSnareVel
						schedkwhennamed		kShakerTrig, 0, 0, "shaker", 0, gi4
						schedkwhennamed		kTrapTrig, 0, 0, "trap", 0, gi8
						schedkwhennamed		kHiHatTrig, 0, 0, "hihat", 0, gi4
						
						schedkwhennamed		kBassTrig, 0, 0, "bass", 0, gk4, giRoot
						
						schedkwhennamed		kSusBassTrig, 0, 0, "susbassnotes", 0, kdur, gkRoot

						schedkwhennamed		kSawOff, 0, 0, "sawoff", 0, 0.001, 0
						schedkwhennamed		kSawOff, 0, 0, "sawoff", 0.002, 0.001, 0
						
						schedkwhennamed		kSawTrig, 0, 0, "saw2", kdel, kdur, kVoice1, kdec, ksus, kff, kverb, katt, kenv
						schedkwhennamed		kSawTrig, 0, 0, "saw2", kdel, kdur, kVoice2, kdec, ksus, kff, kverb, katt, kenv
						schedkwhennamed		kSawTrig, 0, 0, "saw2", kdel, kdur, kVoice3, kdec, ksus, kff, kverb, katt, kenv
						schedkwhennamed		kSawTrig, 0, 0, "saw2", kdel, kdur, kVoice4, kdec, ksus, kff, kverb, katt, kenv
						schedkwhennamed		kSawTrig, 0, 0, "saw2", kdel, kdur, kVoice5, kdec, ksus, kff, kverb, katt, kenv
						schedkwhennamed		kSawTrig, 0, 0, "saw2", kdel, kdur, kVoice6, kdec, ksus, kff, kverb, katt, kenv
						
						;schedkwhennamed		kKickTrig, 0, 0, "MIDI0", 0, gkdb1*10

endin



instr sidechain

	;iBeatLength		=				i(gkBeatLength)
	iFA					=				0.001
	iFB					=				0.01
	iFC					=				0.1
	iFZ					=				1

	ia					=				1
	idur1				=				0.01				
	ib					=				iFB 				;SIDECHAIIN FLOOR
	idur2				=				i(gk8)				;SIDECHAIN ATTACK
	ic					=				1
	idur3				=				0.01
	id					=				1
	
	gaSC				expseg			ia, idur1, ib, idur2, ic, idur3, id;, idur4;, ie

endin



instr MIDI0
	
						initc7			1, $C1, 1
	gkKickFilt		ctrl7			1, $C1, 0, 127
	
	;printk2 gkKickFilt
	
endin



instr MIDI
	
	gkFreqCC 			midic7 		$C5, 0, 127
	gkMdwhl 			midic7 		$C6, 0, 127
	;gkKickFilt		midic7			$C1, 0, 127
	icps  				cpsmidi
	iamp 				= 				0.5;p5/127
	giampsynth 		=				iamp
	gkcpssynth 		=     			icps 	; set global variable for oscillator frequency to MIDI freq.
                   			; coexisting notes are piled up so that the lasat note played will dictate the value of gkcps  
	;gkpb				init 0
	;					midipitchbend gkpb, 0.5, 2
	gkpbsynth			pchbend 		1, 2
	;gkpbsynth			portk			gkpbsynth, 0.01
	;gkpbs				scale2 gkpb, mtof(-2), mtof(2), -1, 1, 0.001
						;printk2 gkpb
	;kcps				=				kcps+kpb	

	;printk2 gkFreqCC
	
	; only turn instr 2 on for the first note of a legato phrase
	if active:i(p1) == 1 then
 		turnon  "synthlead"
	endif

endin


instr synthlead

	irvbgain 			= 				0.2

	;kGS					gainslider gkMdwhl
	kMdwhl				scale2 		gkMdwhl, 0, 1, 0, 127, 0.01
	kVibdpth			scale2 		kMdwhl, 0, 0.05, 0, 1, 0.01

	kRate 				= 				10
	kRtRnge 			scale 			kMdwhl, kRate, 0
	kVib 				poscil 		kVibdpth, kRtRnge

	;---------------OSCILLATOR-------------------
	
	ifn					=				2
	
	kporttime			=				0.005
	kport 				=     			kporttime * linseg:k(0,0.001,1) ; change 0.05 for longer or shorter portamento times
	kcps  				portk 			gkcpssynth, kport				
	
	iA					=				0.01
	iD					=				4
	iS					=				1
	iR					=				0.1
	
	aEnv 				expsegr 		0.01, iA, 1, iD, iS, iR, 0.01
	aEnv				=				aEnv*giampsynth
	a1    				poscil  		aEnv, (kcps+(kcps*gkpbsynth))*(1+kVib), ifn
	a1    				*=    			linsegr:a(0,0.01,1,0.01,0)
      					
      					
   ;-----------------FILTER---------------------
	
	icf					= 				15000*giampsynth
	
	kcf					=				15000
	
	iatt 				= 				0.1
	idec 				= 				4
	islev 				= 				icf*1
	irel				= 				0.1
	kres 				= 				0.1
	;kcf 				expsegr 		0.01, iatt, icf, idec, islev, irel, 0.001
	
	aFilt1 			moogladder 	a1, kcf*aEnv, kres  			
	
	kgainslider		gainslider 	gkFreqCC
	kscaled			scale2 		kgainslider, 150, 20000, 0, 1, 0.01
	
	aFilt2				moogvcf2 		aFilt1, kscaled, 0.1
	
	aL					=				aFilt2*gaSC
	aR					=				aFilt2*gaSC		
    
      					outs	  		aL*0.5, aR*0.5
      					
      					
   gaOutL 			= 				gaOutL + (aFilt2*irvbgain)
   gaOutR 			= 				gaOutR + (aFilt2*irvbgain)

	; when all MIDI notes (instr 1) have been released, turn this instrument off
	if active:k("MIDI") == 0 then
 		turnoff
	endif

endin



instr	sawfilt
	
	
	
	;gaFiltEnv			linseg			0.1, gi1, 2, gi1, 0.3
	gaFiltEnv1		oscili			1, gk1S/16, 9
	gaFiltEnv			=				(gaFiltEnv1)+0.2
	
	if gkMeasure == 1 then
	gkFilt = 0.10
	endif



endin




instr	sawoff
	
	turnoff2	"saw2", 0, 0.05

endin


instr sawon

	turnon	"saw2"

endin


instr saw2
	
	iAmp				=				0.04
	
	kcps				=				cpsmidinn(p4)
	
	;icps				=				i(kcps)
	
	;kcps				portk			kcps, 0.1
	
	iA					=				p9; 0.015
	iD					=				p5;0.6;0.25
	iS					=				p6;0.1;0.0001
	iR					=				0.2;0.5;0.2
	
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
	
	if p10 == 1 then
	aEnv1				mxadsr			iA, iD, iS, iR
	elseif p10 == 2 then
	aEnv1				linsegr		0.01, iA, 1, iD, iS, iR, 0.01
	elseif p10 == 3 then
	aEnv1				expsegr		0.01, iA, 1, iD, iS, iR, 0.01
	else 
	aEnv1				mxadsr			iA, iD, iS, iR
	endif
	
	;aEnv1				mxadsr			iA, iD, iS, iR
	;aEnv1				linsegr		0.01, iA, 1, iD, iS, iR, 0.01
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
	
	
	kFiltEnv			=				gaFiltEnv1
	kFiltRange		scale2			kFiltEnv, 0, 20000, 0, 1
	
	;printk2 kFiltRange
	
	kcf					=				p7
	kcfenv				=				aEnv1*kcf;kFiltRange;*kcf
	
	aSawL				moogladder	aSawL, kcfenv, 0.01
	aSawR				moogladder	aSawR, kcfenv, 0.01
	
	aL1, aL2			pan2			aSawL, 0
	aR1, aR2			pan2			aSawR, 1
	
	aL					=				aL1+aR1
	aR					=				aL2+aR2
	
	aSC					=				gaSC
	
	aL					=				aL*aSC
	aR					=				aR*aSC
	
	outs				aL, aR
	
	irvbgain			=				p8
	
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
	
	kcps				=				cpsmidinn(gkRoot-ioct);cpsmidinn(gkRoot+54-koct)
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
	kcps  				=				cpsmidinn(gkRoot-12)
	;iamp 				= 				p5/127
	;giamp 			=				iamp
	gkcpsbass 		=     			kcps 	; set global variable for oscillator frequency to MIDI freq.
                   				; coexisting notes are piled up so that the last note played will dictate the value of gkcps  
	;gkpb				init 0
	;					midipitchbend gkpb, 0.5, 2
	gkpb				pchbend 1, 2
	;gkpb				portk gkpb1, 0.01
	;printk2			gkpb
	;gkpbs				scale2 gkpb, mtof(-2), mtof(2), -1, 1, 0.001
						;printk2 gkpb
	;kcps				=				kcps+kpb	

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
	acfenv				=				aEnv1*gaFiltEnv*kcf
	
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
	
	;kKickFilt			midic7			$C1, 0, 127
	
	;printk2 gkKickFilt
	
	aEnv				expsegr 		0.01, 0.01, 1, 0.4, 0.01, 0.2, 0.001
	iAmp				=				0.3

	aPchEnv			expsegr		0.01, 0.01, 1, 0.15, 0.005, 0.2, 0.01
	aNoiseEnv			expsegr		0.001, 0.01, 1, 0.01, 0.0001, 0.2, 0.0001
	;kscEnv				expsegr		0.01, 0.01, 1, 0.25, 0.01, 0.1, 0.01

	aKick 				oscili 		aEnv*iAmp, cpsmidinn(18)*(1+(aPchEnv*10))
	aNoise				noise			aNoiseEnv*0.03, 0.5
	aKick				=				aKick+aNoise
	
	aKick				distort		aKick, 0.5, 50	
	
	kgainslider		gainslider 	gkKickFilt
	kscaled			scale2 		kgainslider, 50, 20000, 0, 1, 0.01	
	
	kFiltEnv			=				gaFiltEnv1
	kFiltEnv			scale2			kFiltEnv, 20, 127, 0, 1, 0.01
	kFiltEnv			gainslider 	kFiltEnv
	kFiltEnv			scale2			kFiltEnv, 200, 20000, 0, 1, 0.01

	aKick				moogladder	aKick, kscaled*p4, 0.1
	;aKick				moogladder	aKick, kFiltEnv, 0.1
	
	;kKick				=				k(kscEnv)
	;kSpline			rspline		0, 1, 0.01, 0.1
	;gkSCTrig			trigger		kscEnv, 0.5, 0
	
	;aDist				compress2		aDist, 
	
	outs				aKick, aKick
	
endin	


instr	snare
	
	iAmp 				=				0.1*p4
	iDur				=				i(gkSnareDur)
	aEnv				expsegr		0.001, 0.01, 1, iDur, 0.001, 0.1, 0.001
	aEnv				=				aEnv*iAmp
	aPchEnv			expsegr		0.01, 0.01, 1, 0.05, 0.1, 0.2, 0.01
	aSnare				oscili			aEnv, cpsmidinn(gkKey)*(aPchEnv*2)
	aNoise				noise			aEnv*0.6, 0.5
	aNoise 			atone 			aNoise, 2000
	aSnare				=				aSnare+aNoise
	
	aSnare				distort		aSnare, 0.2, 50
	aSnare				atone			aSnare, 90
	
	
	outs				aSnare, aSnare
	
	irvbgain			=				0.1
	
	;gaOutL 			= 				gaOutL + (aSnare*irvbgain)
  	;gaOutR 			= 				gaOutR + (aSnare*irvbgain)	

endin



instr	trap

	iAmp 				=				0.04
	aEnv				expsegr		0.001, 0.01, 1, gi8, 1, 0.1, 0.01, 0.01, 0.01
	aEnv 				=				aEnv*iAmp 
	aNoise 			noise			aEnv, 0
	
	iAmp2				=				0.06
	aEnv2				expsegr		0.001, 0.01, 1, 0.01, 0.001, 0.01, 0.01
	aNoise2			noise			aEnv2, 0
	
	aEnv				expsegr		0.001, 0.01, 1, gi8, 0.001, 0.01, 0.001
	aEnv				=				aEnv*0.7
	aPchEnv			expsegr		0.01, 0.01, 1, 0.05, 0.1, 0.2, 0.01
	aSnare				oscili			aEnv, cpsmidinn(gkKey)*(aPchEnv)
	
	aNoise				=				aNoise+aNoise2+aSnare
	
	aNoise				atone			aNoise, 200
	
	
	aTrap				distort		aNoise, 1, 50
	
	outs 				aTrap, aTrap
	
	irvbgain			=				0.05
	
	gaBIGL 			= 				gaBIGL + (aTrap*irvbgain)
  	gaBIGR 			= 				gaBIGR + (aTrap*irvbgain)	

endin


instr hihat

	iAmp 				=				0.1
	aEnv				expsegr		0.01, 0.01, 1, gi4, 0.01, 0.01, 0.01
	aEnv				=				aEnv*iAmp
	aNoise				noise			aEnv, 0
	
	aPchEnv			expsegr		0.01, 0.01, 1, 0.05, 0.1, 0.2, 0.01
	aTone 				oscili			aEnv*2, cpsmidinn(gkKey+24)*aPchEnv
	
	aHiHat				=				aNoise+aTone
	aHiHat				atone			aHiHat, 8000
	
	
	outs				aHiHat, aHiHat

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
f	4	0	1024	7		0	1024		1		  	 										; Sawtooth ish 
;f	5 	0 	16384 	10 		1 	0   	0.3 	0    	0.2 	0     	0.14 	0     	.111  	 ; Square ish 
;f	6 	0 	16384 	10 		1 	1   	1   	1    	0.7 	0.5   	0.3  	0.1         	 ; Pulse ish 
f	7	0	1024	10		1																	; SINE 
f	8	0	1024	7		1	512		-1		512		1										; TRIANGLE 
f	9	0	1024	7		0	512		1		512		0										;	UNIPOLAR TRIANGLE
 
 
;CHORDS 
f 	10 	0 	64		-2		0	2	7	11 
f	11	0	64		-2		3	7	10	14 

f	12	0	64		-2		0	7	16	21	26	35					; maj7
f	13	0	64		-2		0	7	15	22	29	38					; -7
f	14	0	64		-2		0	10	17	26	33	40					; 7sus
f	15	0	64		-2		0	16	22	26	30	33					; 7#11
f	16	0	64		-2		0	8	15	19	26	34					; maj7#11/3rd
f	17	0	64		-2		0	16	22	25	32	39					; 7alt

 
;CHORD QUALITY 
f	30	0	64		-2		10	11 
 
 
;SCALE / ROOT 
f	20	0	64		-2		0	2	4	5	7	9	11 
f	21	0	64		-2		-4	-3	-2	0	1	2	3	4	5	7
 
 
 
 
;Distortion 
f	50	0	1024	10	1 ;.2	 ;.2 
 
 
;Rhythm 
f	100	0	64		-2		1	1	2	1	3	4 
 
 
 
f	0 	z 

i	"MIDI0"		0	[60*60*24*7]
i	"chordprog"	0	2
i	"tempo"		0	1

 
 </CsScore>
</CsoundSynthesizer>
