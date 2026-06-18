<CsoundSynthesizer>
<CsOptions>
-dm0
</CsOptions>
<CsInstruments>

ksmps = 32
nchnls = 2
0dbfs = 1

	gaOutL 			init 			0
	gaOutR 			init 			0

						alwayson		"clock"
						alwayson		"sequencer"
						alwayson		"variation"
						alwayson		"hihatvar"
						alwayson		"verb"
						;alwayson		"root"
						seed			0
						
	#define 			C1 				#70#
	#define 			C2 				#71#
	#define 			C3 				#72#
	#define 			C4 				#73#
	#define 			C5 				#7#
	#define 			C6 				#1#
	#define 			C7 				#76#
	#define 			C8 				#77#

;instrument will be triggered by keyboard widget
instr 1
	
	gkFreqCC 			midic7 $C5, 0, 127
	gkMdwhl 			midic7 $C6, 0, 127
	icps  				cpsmidi
	iamp 		= 		p5/127
	giamp 		=		iamp
	gkcps 		=     	icps 	; set global variable for oscillator frequency to MIDI freq.
                   			; coexisting notes are piled up so that the lasat note played will dictate the value of gkcps  
	;gkpb				init 0
	;					midipitchbend gkpb, 0.5, 2
	gkpb				pchbend 1, 2
	;gkpbs				scale2 gkpb, mtof(-2), mtof(2), -1, 1, 0.001
						;printk2 gkpb
	;kcps		=		kcps+kpb	

	; only turn instr 2 on for the first note of a legato phrase
	if active:i(p1) == 1 then
 		turnon  2
	endif

endin


instr 2

	irvbgain 	= 		0.025

	;kGS					gainslider gkMdwhl
	kMdwhl				scale2, gkMdwhl, 0, 1, 0, 127, 0.01
	kVibdpth			scale2 kMdwhl, 0, 0.05, 0, 1, 0.01

	kRate 		= 		10
	kRtRnge 			scale kMdwhl, kRate, 0
	kVib 				poscil kVibdpth, kRtRnge

	;---------------OSCILLATOR-------------------
	
	ifn			=		40
	
	kporttime	=		0.0075
	kport 		=     	kporttime * linseg:k(0,0.001,1) ; change 0.05 for longer or shorter portamento times
	kcps  				portk gkcps, kport				
	
	isus		=		1
	aEnv 				linsegr 0, 0.1, giamp, 4, giamp*isus, 0.1, 0
	a1    				poscil  aEnv, (kcps+(kcps*gkpb))*(1+kVib), ifn
	a1    		*=    	linsegr:a(0,0.01,1,0.01,0)
      					
      					
   ;-----------------FILTER---------------------
	
	icf		= 	15000*giamp
	iatt 	= 0.1
	idec 	= 4
	islev 	= icf*1
	irel	= 0.1
	kres 	= 0.1
	kcf 	linsegr 0.01, iatt, icf, idec, islev, irel, 0.001
	
	aFilt1 			moogladder a1, kcf, kres  			
	
	kgainslider		gainslider gkFreqCC
	kscaled			scale2 kgainslider, 150, 20000, 0, 1, 0.01
	
	aFilt2				moogvcf2 aFilt1, kscaled, 0.1		
    
      					outs	  aFilt2, aFilt2
      					
      					
   gaOutL 	= 		gaOutL + (aFilt2*irvbgain)
   gaOutR 	= 		gaOutR + (aFilt2*irvbgain)

	; when all MIDI notes (instr 1) have been released, turn this instrument off
	if active:k(1) == 0 then
 		turnoff
	endif

endin


instr clock

	gkTempo			=				130
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
	
	kKickRnd 	rspline 0, 15, 0.1, 1
	kKickRnd	=	int(kKickRnd)
	kKickRnd	table kKickRnd, 100	

	if gkCount == 1 then
	gkKickTrig = 1
	elseif gkCount == 13 then
	gkKickTrig = int(rnd(5))
	elseif gkCount == kKickRnd then
	gkKickTrig = 1
	else gkKickTrig = 0
	endif
	
	
	
	kSnareRnd 	rspline 0, 15, 0.1, 1
	kSnareRnd		=	int(kSnareRnd)
	kSnareRnd		table kSnareRnd, 100
	gkSnareRnd	=	kSnareRnd
	
	if gkCount == 9 then
	gkSnareTrig = int(rnd(5))
	gkSnareVel = 0.7
	elseif gkCount == 25 then
	gkSnareTrig = int(rnd(5))
	gkSnareVel = 0.7
	;elseif gkCount == 28 then
	;gkSnareTrig = 1
	elseif gkCount == kSnareRnd then
	gkSnareTrig = 1
	gkSnareVel random 0.1, 0.4
	else gkSnareTrig = 0
	endif
	
	
	
	if gkCount == 1 then
	gkPadTrig = 1
	else gkPadTrig = 0
	endif
	
	
	gkKickTrig		trigger		gkKickTrig, 0.5, 0
	gkSnareTrig		trigger		gkSnareTrig, 0.5, 0
	
	kPadLng			rspline			0.1, 6, 0.01, 0.1
	
	
						schedkwhen		gkKickTrig, 0, 0, "kick", 0, 2
	
						schedkwhen		gkSnareTrig, 0, 0, "snare", 0, 2, gkSnareVel
	

						;schedkwhen		gkMetro, 0, 0, "tick", 0, 0.1
	
						schedkwhen		gkMetro, 0, 2, "hihat", 0, 0.2
	
						schedkwhen		gkKickTrig, 1, 1, "pad", 0, kPadLng
						
						schedkwhen		gkKickTrig, 1, 1, "root", 0, kPadLng

endin


instr variation
	
	;TRIAD PAIR
	gkosctr			oscili			.99, 0.2
	gkosctr			=				gkosctr+1.01
	
	
	;printk2 gkosctr
	;giosctr			=				i(gkosctr)
	
	;SCALE DEGREE
	gktriad			oscili			5, 0.5
	gitriad			=				i(gktriad)
	;gksd				table			gkoscsd, gitriad
	;printk2 gkosctr
	
	gkoscph			oscili			2, 0.5
	gkoscph			=				gkoscph+2
	;gioscph			=				i(gkoscph)
	;printk2 gkoscph
	
	gksplsd			rspline		0, 4, 4, 8
	
	gkspltr			rspline		1, 2, 0.3, 4
	
	gksplrt			rspline		0, 2, 0.1, 0.5
	
	gksploct			rspline		0, 4, 0.5, 2
	;printk2 gksploct


endin




instr tick

	;TRIAD PAIR
	krndspl			rspline		0, 2, 0.00001, 0.0001
	kosctr				oscili			2, 0.1
	;indx				=				i(kosctr)
	ktriad				table			gkosctr, 10
	
	itriad				=				i(gkosctr)
	;print itriad
	ifn 				=		  		itriad
	;ipchndx 			random 		0, 4
	;kpchndx			rspline		0, 4, 0.01, 0.1
	
	;isdndx				=				i(gkosctr)
	;ktriad
	ispltr				=				i(gkspltr)
	kscaledeg			table	 		gksplsd, ispltr, 0, 0, 1
	iscaledeg			=				i(kscaledeg)
	
	;ROOT NOTE
	ksplrt				rspline		0, 2, 0.05, 0.1
	indxrt				=				i(gksplrt)
	;print indxrt
	iroot				table			indxrt, 20, 0, 0, 1	
	
	;OCT TRANSPOSITION
	ksploct			rspline		0, 3, 0.001, 0.01
	isploct			=				i(gksploct)
	ioct				table			isploct, 30
		
	

	iamp				=				0.5
	aEnv				expsegr		0.001, 0.01, 1, 0.3, 0.001, 0.1, 0.001
	aTick				oscili			aEnv*iamp, cpsmidinn(iscaledeg+iroot)
	
	outs				aTick, aTick
	
endin	



instr root

	krtspline			rspline		0, 2, 0.01, 0.1
	irtspl				=				int(i(krtspline))
	kspltrns			rspline		0, 1, 0.001, 0.01
	ktrigtrns			trigger		kspltrns, 0.5, 0
	
	krootrnd			trandom		ktrigtrns, 0, 2
	kroot				table			krootrnd, 300
	
	
	kroot				=				irtspl+kroot
	giroot				=				i(kroot)
	;print irtspl
	
endin	





;;-------------------------DRUMS-------------------------;;






instr kick
	
	aEnv				expsegr 		0.01, 0.01, 1, 2, 0.01, 0.1, 0.01
	iAmp				=				0.2

	aPchEnv			expsegr		0.01, 0.01, 1, 0.25, 0.01, 0.1, 0.01
	kscEnv				expsegr		0.01, 0.01, 1, 0.25, 0.01, 0.1, 0.01

	aKick 				oscili 		aEnv*iAmp, cpsmidinn(giroot-24)*(1+(aPchEnv*3))
	
	aDist				distort		aKick, 0.3, 50	
	
	;kKick				=				k(kscEnv)
	;kSpline			rspline		0, 1, 0.01, 0.1
	gkSCTrig			trigger		kscEnv, 0.5, 0
	
	outs				aDist, aDist
	
endin	


instr snare

	;if gkCount == gkSnareRnd then
	;iAmp = 0.2
	;else iAmp = 0.7
	;endif
	
	irvbgain			=				0.05
	
	iAmp				=				p4
	aEnv				expsegr		0.001, 0.01, 0.5, 0.3, 0.001, 0.1, 0.001
	aDEnv				expsegr		0.001, 0.01, 1, 0.2, 0.001, 0.1, 0.001
	aPchEnv			expsegr		0.01, 0.01, 1, 0.3, 0.01, 0.1, 0.01
	aPink				pinker		
	aPink				=				aPink*aEnv
	aDink				oscili			aDEnv*aDEnv, cpsmidinn(37)*(1+(aPchEnv*3))
	aNoise				pinker			
	aNoiseEnv			expsegr		0.001, 0.15, 0.15, 2, 0.001, 0.1, 0.001
	aFilt				atone			aNoise*aNoiseEnv, 10000
	
	;iClapAmp			=				1
	;aClap				pinker			
	;aClapEnv			expsegr		0.001, 0.001, 1, 0.1, 0.001, 0.001, 1, 0.1, 0.001, 0.001, 1, 0.1, 0.001, 0.001, 0.01, 0.01
	;aClap				=				aClap*aClapEnv;*iClapAmp
	
	aSnare				=				aPink+aDink+aFilt
	
	aDist				distort 		aSnare, 0.4, 50
	
	aOut 				=				aDist*iAmp
	
	outs				aOut, aOut
	
	gaOutL = gaOutL + (aOut*irvbgain)
	gaOutR = gaOutR + (aOut*irvbgain)
	
endin	


instr hihatvar

	gkOscAcc			oscili			0.15, gkTempo/60
	gaOscAcc			oscili			0.05, gkTempo/60, 50

endin


instr hihat
	
	irvbgain			=				0.2
	
	iAccVar			=				i(gkOscAcc)+0.35
	;iRndLng			random			0.05, 0.2
	kRndLng			rspline		0.05, 0.2, 0.05, 0.1
	iRndLng			=				i(kRndLng)
	kRndLng2			rspline		0.0001, 0.3, 0.001, 0.01
	iRndLng2			=				i(kRndLng2)
	iLngVar			=				i(gkOscAcc)+iRndLng;+iRndLng2
	kRndAtt			rspline		0.005, 0.03, 0.005, 0.05
	iRndAtt			=				i(kRndAtt)
	aEnv				expsegr		0.001, iRndAtt, iAccVar, iLngVar, 0.001, iRndLng2, 0.001
	aPink				pinker		
	
	aPink				atone			aPink, 10000
	
	aPink				distort 		aPink, 0.5, 50
	
	aOut				=				aPink*aEnv
	
	outs				aOut, aOut
	
	gaOutL 			= 				gaOutL + (aOut*irvbgain)
	gaOutR 			= 				gaOutR + (aOut*irvbgain)
	
	
endin	




instr pad
	
	irvbgain			=				0.5
	
	iSD1 				table			1, 200
	iSD2 				table			2, 200
	iSD3 				table			3, 200
	iSD4 				table			4, 200
	iSD5 				table			5, 200
	
	
	krtspl				rspline		54, 56, 0.01, 0.1
	irtspl				=				int(i(krtspl))
	iroot				=				irtspl
	;iroot				=				iroot
	;print iroot
	
	iAmp				=				0.05
	aEnv				expsegr		0.01, 0.1, iAmp, 3, 0.01, 0.3, 0.001
	aPad1				oscili			aEnv, cpsmidinn(iSD1+giroot)
	aPad2				oscili			aEnv, cpsmidinn(iSD2+giroot)
	aPad3				oscili			aEnv, cpsmidinn(iSD3+giroot)
	aPad4				oscili			aEnv, cpsmidinn(iSD4+giroot)
	aPad5				oscili			aEnv, cpsmidinn(iSD5+giroot)		
	
	aPad				=				aPad1+aPad2+aPad3+aPad4+aPad5
	
	aSCTrig			=				a(gkSCTrig)		

	aPad				compress2		aPad, aSCTrig, -400, -50, -30, 16, 0.01, 0.06, 0.02


	outs				aPad, aPad
	
	gaOutL 			= 				gaOutL + (aPad*irvbgain)
	gaOutR 			= 				gaOutR + (aPad*irvbgain)

endin


instr verb

	;-----------------REVERB---------------------

	irvbtime 			= 				0.95

	aL, aR 			reverbsc 		gaOutL, gaOutR, irvbtime, 5000
	
	;aCL compress2 aL, 
	
	aL					atone			aL, 800
	aR					atone			aR, 800
	
	outs aL, aR
	
	gaOutL = 0
	gaOutR = 0
	
endin	




</CsInstruments>
<CsScore>

f	50	0	1024	10	1 ;.2	;.2


;TRIADS

f 1 0 64		-2		0	4	7	12
;f 2 0 64		-2		2	5	8	11	14
f 2 0 64		-2		2	5	9	14

f 10 0 64		-2		1	2

f 20 0 64		-2		60	67

f 30 0 64		-2		12	0	-12

f	40	0	1024	10	1	.2		;.3														; SINE ish
f	41	0	1024	7	1	1024	-1														; SAW
f	42	0	1024	7	1	512		1		0		-1		512		-1						; SQUARE


f 100 0 64	-2		1	3	5	7	9	11	13	15	17	19	21	23	25	27	29	31
f 101 0 64	-2		2	4	6	8	10	12	14	16	18	20	22	24	26	28	30	32
f 102 0 64	-2		1	5	9	13	17	21	25	29


f 200 0 64	-2		0	3	7	10	14

f 300 0 64	-2		54	50




f0 z

</CsScore>
</CsoundSynthesizer>
