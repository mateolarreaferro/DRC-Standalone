<CsoundSynthesizer>
<CsInstruments>

sr    = 44100
kr    = 441

;===============;
; {_ORCHESTRA_} ;
;===============; 

;===================================================================

	instr 1	; Hand Clap
iamp     	= 		p4
kamp1 	expon 	1.25, .03,  .0001		; Exponential Curve
kamp2 	expseg 	.001,.005,1, .35, .001	; Expo

anoise 	rand 	1					; Noise

anoise1 	= 		anoise*kamp1		
anoise2 	= 		anoise*kamp2
  
adel1     = 	 	anoise1			; Delayed Noise
adel2 	delay 	anoise1, .01
adel3 	delay 	anoise1, .02
adel4 	delay 	anoise2, .03
  
abp1 	resonz 	adel1,  400,  1100	; Delayed Band Pass Filter
abp2 	resonz 	adel2,  600,  1100
abp3 	resonz 	adel3,  800,  1100
abp4 	resonz 	adel4,  1100, 1100
  		out 		iamp*2*(abp1+abp2+abp3+abp4)
endin

;===================================================

</CsInstruments>
<CsScore>

;===========;
; {_SCORE_} ;
;===========; 

;=============
i1 0 1 2000
i1 1 1 1000
i1 2 1  500
i1 3 1  250

</CsScore>
</CsoundSynthesizer>

;_Notes_

;rene.nyffenegger@adp-gmbh.ch
