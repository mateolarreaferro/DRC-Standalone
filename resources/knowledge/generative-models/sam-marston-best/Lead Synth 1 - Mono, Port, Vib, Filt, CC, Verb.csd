<CsoundSynthesizer>
<CsOptions>
-odac  -dm0
--midi-key-cps=4 --midi-velocity=5
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 64
nchnls = 2
0dbfs = 1

	gaOutL init 0
	gaOutR init 0

	alwayson 3

	#define C1 #70#
	#define C2 #71#
	#define C3 #72#
	#define C4 #73#
	#define C5 #7#
	#define C6 #1#
	#define C7 #76#
	#define C8 #77#

;instrument will be triggered by keyboard widget
instr 1
	
	gkFreqCC 			midic7 $C5, 0, 127
	gkMdwhl 			midic7 $C6, 0, 127
	icps  				cpsmidi
	iamp 		= 		0.25;p5/127
	giamp 		=		iamp
	gkcps 		=     	icps 	; set global variable for oscillator frequency to MIDI freq.
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
 		turnon  2
	endif

endin


instr 2

	irvbgain 	= 		0.15

	;kGS					gainslider gkMdwhl
	kMdwhl				scale2, gkMdwhl, 0, 1, 0, 127, 0.01
	kVibdpth			scale2 kMdwhl, 0, 0.05, 0, 1, 0.01

	kRate 		= 		10
	kRtRnge 			scale kMdwhl, kRate, 0
	kVib 				poscil kVibdpth, kRtRnge

	;---------------OSCILLATOR-------------------
	
	ifn			=		1
	
	kporttime	=		0.005
	kport 		=     	kporttime * linseg:k(0,0.001,1) ; change 0.05 for longer or shorter portamento times
	kcps  				portk gkcps, kport				
	
	isus		=		1
	aEnv 				linsegr 0, 0.02, giamp, 4, giamp*isus, 0.3, 0
	a1    				poscil  aEnv, (kcps+(kcps*gkpb))*(1+kVib), ifn
	a1    		*=    	linsegr:a(0,0.01,1,0.01,0)
      					
      					
   ;-----------------FILTER---------------------
	
	icf		= 	15000*giamp
	iatt 	= 0.02
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
 		turnoff2 2, 0, 0.4
	endif

endin

instr 3

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
f	1	0	1024	10	1	.2		;.3														; SINE ish
f	2	0	1024	7	1	1024	-1														; SAW
f	3	0	1024	7	1	512		1		0		-1		512		-1						; SQUARE
f0 z

</CsScore>
</CsoundSynthesizer>
