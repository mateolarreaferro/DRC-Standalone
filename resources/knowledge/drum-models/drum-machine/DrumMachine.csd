<CsoundSynthesizer>
<CsOptions>

-odac0.aif

</CsOptions>
<CsInstruments>

sr	  = 	44100
kr 	  = 	441
nchnls =  2

;===============;
; {_ORCHESTRA_} ;
;===============; 

;===================================================

	instr 1	; Hi-Hat

ilen 	init 		p3
iamp 	init 		p4

kcutfreq  expon     	10000, 0.1, 2500
aamp      expon     	iamp,  0.1,   10
arand     rand      	aamp
alp1      butterlp  	arand,kcutfreq
alp2      butterlp  	alp1,kcutfreq
ahp1      butterhp  	alp2,3500
asigpre   butterhp  	ahp1,3500
asig      linen    		(asigpre+arand/2),0,ilen, .05  
		outs 		asig, asig
		
endin

;===================================================

	instr 2	; Snare
	
icps0  	= 			147
iamp   	= 			p4*0.7

icps1  	=  	  		2.0 * icps0
  
kcps   	port 		icps0, 0.007, icps1
kcpsx  	=  	  		kcps * 1.5
  	
kfmd   	port      	0.0, 0.01, 0.7
aenv1  	expon     	1.0, 0.03, 0.5
kenv2  	port      	1.0, 0.008, 0.0
aenv2  	interp    	kenv2
aenv3  	expon     	1.0, 0.025, 0.5
  
a_     	oscili    	1.0, kcps, 1
a1     	oscili    	1.0, kcps * (1.0 + a_*kfmd), 1
a_     	oscili    	1.0, kcpsx, 1
a2     	oscili 	  	1.0, kcpsx * (1.0 + a_*kfmd), 1
 
a3     	unirand   	2.0
a3     	=  	  		a3 - 1.0
a3     	butterbp  	a3, 5000, 7500
a3     	=  	  		a3 * aenv2

a0     	=  	  		a1 + a2*aenv3 + a3*1.0
a0     	=         	a0 * aenv1
	  	outs 	  	a0*iamp, a0*iamp
endin

;===================================================

	instr 3	; Kick

iamp      = 		p4

k1  		expon     	120, .2, 50    
k2  		expon     	500, .4, 200
a1  		oscil     	iamp, k1, 1
a2  		reson     	a1, k2, 50
a3  		butterlp  	a2+a1,k1,1
a4  		butterlp  	a3,   k1,1
a5  		butterlp  	a4,2500,1
a6  		butterhp  	a5,50
a7  		butterhp  	a6,50
a8  		linen     	a7,0.01,p3, .2  
    		outs 	    	a8, a8
    		
endin

;===================================================

	instr 4

ifrq   	init 	 	cpspch(p5)
ilen   	init     		p3
iamp   	init     		p4

k2     	expseg   		3000, 0.08, 9000, ilen, 1

ksweep 	=	      	k2-3000
  
a1     	oscil    		iamp*0.40, ifrq*0.998-.12, 2
a2     	oscil    		iamp*0.40, ifrq*1.002-.12, 1
a3     	oscil    		iamp*0.40, ifrq*1.002-.12, 2
a4     	oscil    		iamp*0.70, ifrq-.24, 1
aall		= 			a1+a2+a3+a4
  
a6     	butterlp 		aall,ksweep
a8     	butterlp 		a6, ksweep
a9     	butterhp 		a8, 65  
a10    	butterhp 		a9, 65  
a11    	butterlp 		a10,1000
asig   	linen    		a11, p6, ilen, p7
  	  	outs     		asig, 1-asig
  	  	
endin

;===================================================

</CsInstruments>
<CsScore>

;===========;
; {_SCORE_} ;
;===========; 

;===================================================
f1 0 65536 10 1				; GEN10
f2 0 2048  10 1 1 1 1 .7 .5 .3 .1  ; GEN10/Pulse
;===================================================

r 4
;===================
i1 0      0.25 5000
i1 0.25   0.25 5000
i1 0.5    0.25 5000
i1 0.75   0.25 5000
i1 1      0.25 5000
i1 1.25   0.25 5000
i1 1.5    0.25 5000
i1 1.75   0.25 5000
i1 2      0.25 5000
i1 2.25   0.25 5000
i1 2.5    0.25 5000
i1 2.75   0.25 5000
i1 3      0.25 5000
i1 3.25   0.25 5000
i1 3.5    0.25 5000
i1 3.75   0.25 5000

;===============
i2 0.5 1 	5000   
i2 1.5 1 	5000   
i2 2.5 1 	5000   
i2 3.5 .5 5000   

;===================
i3 0      0.25  100
i3 0.375  0.25  100
i3 0.75   0.25  100
i3 1.25   0.25  100
i3 2      0.25  100
i3 2.375  0.25  100
i3 2.75   0.25  100
i3 3.25   0.25  100
i3 3.75   0.25  100

;================================
i4 0      0.25 5000 6.00 .02 .01
i4 0.375  0.25 .    6.03 .   .
i4 0.75   0.25 .    6.05 .   .
i4 1.25   0.25 .    6.06 .   .
i4 2      0.25 .    6.07 .   .
i4 2.375  0.25 .    6.04 .   .
i4 2.75   0.25 .    6.10 .   .
i4 3.25   0.25 .    6.08 .   .
i4 3.75   0.25 5500 6.07 .   .
s

;==============================
i1 0 0.25 5000
i2 0 1 	5000
i3 0 0.25 100
i4 0 3.85 5000 6.00 .02 .01
s

</CsScore>
</CsoundSynthesizer>

;_Notes_

;;;http://www.united-trackers.org/resources/theory/percussive_theory.htm
