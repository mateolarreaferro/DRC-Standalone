<CsoundSynthesizer>
<CsOptions>
-odac
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 64
nchnls = 2
0dbfs = 1

						alwayson		"clock"
						alwayson		"sequencer"
						alwayson		"variation"

instr clock

	gkTempo			=				100 + rnd(14)
	gkSubdiv			=				4
	gkTicks			=				(gkTempo/60)*gkSubdiv
	gkMetro			metro			gkTicks
						;printk2 		gkMetro
						
						
	;giCnt				cntCreate 	16, 1
	;gi					count
	
	reset:
	gkCount			init			1
	if (gkMetro == 1)	then
	gkCount += 1
	endif
	if (gkCount == gkSubdiv*4+1) then
	reinit reset
	endif
	rireturn
	
	printk2 gkCount
	

	


// counter going up till isubdiv 
;RESET:
;gkcount init 0
;if (kmetro == 1) then
;gkcount += 1
;endif
;if (gkcount == isubdiv*50) then
;reinit RESET
;endif
;rireturn 




	isubdiv = 16
	gibpm = 100
	gidur = ((60/gibpm)/isubdiv) // duration of each note at chosen subdiv
	kmetro metro (gibpm/60)*isubdiv //Metro clocking at chosen subdivision (16th notes)


endin


instr sequencer


	if gkCount == 1 then
	gkTrig = 1
	else gkTrig = 0
	endif
	
	
	if gkCount == 9 then
	gkSnaretrig = 1
	else gkSnaretrig = 0
	endif
	
	
	schedkwhen		gkTrig, 0, 1, "low", 0, 1
	
	schedkwhen		gkSnaretrig, 0, 1, "snare", 0, 1
	

	schedkwhen		gkMetro, 0, 0, "tick", 0, 0.1

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
	aEnv				expsegr		0.001, rnd(0.01), rnd(1), rnd(0.03), rnd(0.001), rnd(0.01), 0.001
;	aTick				oscili			aEnv*iamp, cpsmidinn(iscaledeg+iroot)
aTick pinker
	
	outs				aTick*aEnv*rnd(.51), aTick*aEnv*rnd(.41)
	
endin	


instr low
	
	iamp				=				0.5
	aEnv				expsegr		0.001, rnd(0.01), rnd(1), rnd(1), rnd(0.001), 0.1, 0.001
	aTick				oscili			aEnv*iamp, cpsmidinn(30)
	
	outs				aTick, aTick
	
endin	



instr snare

	aEnv				expsegr		0.001, rnd(0.01), rnd(0.3), rnd(1), rnd(0.001), rnd(0.1), 0.001
	aPink				pinker		
	
	outs				aPink*aEnv, aPink*aEnv
	
endin	




</CsInstruments>
<CsScore>

;TRIADS

f 1 0 64		-2		0	4	7	12
;f 2 0 64		-2		2	5	8	11	14
f 2 0 64		-2		2	5	9	14

f 10 0 64		-2		1	2

f 20 0 64		-2		60	67

f 30 0 64		-2		12	0	-12




f0 z

</CsScore>
</CsoundSynthesizer>
