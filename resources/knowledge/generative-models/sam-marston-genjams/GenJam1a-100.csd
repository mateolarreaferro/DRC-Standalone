<CsoundSynthesizer>
<CsOptions>
-dm0 --expression-opt 
</CsOptions>
<CsInstruments>

nchnls = 2
0dbfs = 1

		massign		1, "MIDI"

		gaOutL init 0
		gaOutR init 0		
		
	#define 			C1 				#70#
	#define 			C2 				#71#
	#define 			C3 				#72#
	#define 			C4 				#73#
	#define 			C5 				#77#
	#define 			C6 				#1#
	#define 			C7 				#74#
	#define 			C8 				#75#
		
		
		;alwayson "metronome"
		turnon "sequence"
		turnon "Verb"
		turnon "chordchange"
		turnon "trigger"
		turnon "sequencer"
		turnon "clock"
		seed		0
		
		gitranspose init 0
		
		
		
		
instr clock // master clock
isubdiv = 16
gibpm = 100
gidur = ((60/gibpm)/isubdiv) // duration of each note at chosen subdiv
kmetro metro (gibpm/60)*isubdiv //Metro clocking at chosen subdivision (16th notes)

// counter going up till isubdiv 
RESET:
gkcount init 0
if (kmetro == 1) then
gkcount += 1
endif
if (gkcount == isubdiv*50) then
reinit RESET
endif
rireturn 

gkmetro = kmetro

endin		


instr sequencer
// triggering drums at chosen rate
gkrate = 4
if (gkcount % gkrate == 0) then
ktrig = 1
else ktrig = 0
endif

// random values to weigh against chosen density of notes
if ktrig == 1 then
ksinechance random 0, 1
endif

ksinedensity = 0.2

if ksinechance < ksinedensity then
gktrigsine = 1
elseif ksinechance > ksinedensity then
gktrigsine = 0
endif



;printk2 gktrigsine

endin
		
		
		
instr trigger
	
	kspline 	rspline 	0.1, 0.4, 0.01, 1
	kchordChange metro kspline
	schedkwhen kchordChange, 0, 0, "chordchange", 0, 1

endin

		
		
instr chordchange

	ifn = 40
	ichrdndx random 0, 3
	;kchrdndx phasor 2
	ichrd table ichrdndx, ifn
	gitranspose = ichrd
	;print gitranspose

endin		

		
		
instr 	sequence

	inote	random 40, 100
	icps = cpsmidinn(int(inote))
	iamp 	random 0, 127			
	
	kspline 	rspline 	0, 4, 0.3, 15
	ktrig_out trigger   kspline, 2, 2
	
	iphsrnd	random		0, 1
	
	gkoscrng	oscili		1.25, 0.01, 3, iphsrnd
	gkoscrng	=			gkoscrng+1.7
	;printk2 gkoscrng
	
	gkdur 		rspline  	0.1, 3, 0.01, 1

	gkmaxnum	rspline	1, 8, 0.01, 0.5

	schedkwhennamed gktrigsine, 0, gkmaxnum, "sine", 0, gkdur;, icps, 0.5
	
	;schedkwhennamed gkmetro, 0, 1, "kick", 0, 1

endin		
		
		
		
instr sine

	ipan random 0, 1

	;SCALE
	ifn = 20
	ipchndx random 0, 5
	ipch table ipchndx, ifn
	
	;ktone	rspline	0, 0.5, 0.01, 0.3
	ktonespline	rspline	0, 1, 0.01, 0.1
	ktonetrig		trigger	ktonespline, 0.5, 1
	;printk2 ktonetrig
	
	ktonernd 	trandom 	ktonetrig, -2, 1
	
	kporttime	rspline	0.01, 0.1, 0.01, 0.2
	iporttime	= i(kporttime)
	
	ktone 		port 		ktonernd, iporttime
	
	
	;printk2 ktone
	
	kbrite	rspline	-2, 1, 0.002, 1
	
	kattack rspline 	0.01, 0.05, 0.001, 0.1
	;iattack = i(kattack)
	iattack = i(gkdur)*0.1
	
	
	irelease = iattack*2
		
	idur = i(gkdur)-iattack;-irelease
		
	kEnv expsegr 0.01, iattack, 0.7, idur, 0.01, irelease, 0.01
	;aSine oscili aEnv/8, cpsmidinn(ipch+gitranspose), 1
	aSine hsboscil kEnv/8, ktone, kbrite, cpsmidinn(ipch+gitranspose), 1, 50

	outs aSine*ipan, aSine*(1-ipan)
	
	irvbgain 	= 		0.1
	
	gaOutL 	= 		gaOutL + (aSine*irvbgain)
   	gaOutR 	= 		gaOutR + (aSine*irvbgain)


endin


instr MIDI
	
	gkFreqCC 			midic7 		$C5, 0, 127
	gkMdwhl 			midic7 		$C6, 0, 127
	;gkKickFilt		midic7			$C1, 0, 127
	icps  				cpsmidi
	iamp 				= 				0.15;p5/127
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
	
	ifn					=				1
	
	kporttime			=				0.005
	kport 				=     			kporttime * linseg:k(0,0.001,1) ; change 0.05 for longer or shorter portamento times
	kcps  				portk 			gkcpssynth, kport				
	
	iA					=				0.02
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
	kres 				= 				0.1
	;kcf 				expsegr 		0.01, iatt, icf, idec, islev, irel, 0.001
	
	aFilt1 			moogladder 	a1, kcf*aEnv, kres  			
	
	kgainslider		gainslider 	gkFreqCC
	kscaled			scale2 		kgainslider, 50, 20000, 0, 1, 0.015
	
	aFilt2				moogvcf2 		aFilt1, kscaled, 0.1
	
	aL					=				aFilt2;*gaSC
	aR					=				aFilt2;*gaSC		
    
      					outs	  		aL, aR
      					
      					
   gaOutL 			= 				gaOutL + (aFilt2*irvbgain)
   gaOutR 			= 				gaOutR + (aFilt2*irvbgain)

	; when all MIDI notes (instr 1) have been released, turn this instrument off
	if active:k("MIDI") == 0 then
 		turnoff2 "synthlead", 0, 0.3
	endif

endin



instr kick


aEnv		expsegr 		0.01, 0.01, 1, 1, 0.01, 0.1, 0.01
iAmp		=				0.8

aPchEnv	expsegr		0.01, 0.01, 1, 0.1, 0.01, 0.1, 0.01

aKick 		oscili 		aEnv*iAmp, cpsmidinn(34)*(1+(aPchEnv*2)), 2

outs		aKick, aKick


endin


instr Verb

	;-----------------REVERB---------------------

	irvbtime = 0.7

	aL, aR 			reverbsc gaOutL, gaOutR, irvbtime, 5000
	
	;aCL compress2 aL, 
	
						outs aL, aR
	
	gaOutL = 0
	gaOutR = 0
	
	
endin




</CsInstruments>
<CsScore>


;WAVEFORMS
f	1	0	1024	10	1 .2	;.2
f	2	0	1024	10	1 ;.2	;.2
f	3	0	1024	7	1	512		-1	512		1	
f	4	0	1024	7	1	1024	-1														; SAW 

f	50 0  1024  -19  1  0.5  270  0.5 


;SCALES
f	20	0	64		-2		52	60	62	67	71	
f	21	0	64		-2		51	60	62	67	71	

;CHORD PROGRESSIONS
f	40	0	64		-2		0	4	8

f	0 z


</CsScore>
</CsoundSynthesizer>
