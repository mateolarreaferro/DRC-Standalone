<CsoundSynthesizer>
<CsOptions>

; XO
;-+rtmidi=alsa  --midi-device=hw:1,0 -+rtaudio=alsa -odac -r16000 -k160 ;-O stdout
; Mac
;-odac -r44100 -k441

</CsOptions>
<CsInstruments>

;===============;
; {_ORCHESTRA_} ;
;===============; 

;====================================================================================

	instr 1
	
kamp 	init 	31129.60
kfreq 	= 		440
kstiff 	= 		-0.3
iatt 	= 		0.1
idetk	= 		0.1
kngain 	= 		0.2
kvibf 	= 		5.735
kvamp 	= 		0.1
ifn 		= 		1

a1 		wgclar 	kamp, kfreq, kstiff, iatt, idetk, kngain, kvibf, kvamp, ifn
		out 		a1
		
endin

;====================================================================================

</CsInstruments>
<CsScore>

;===========;
; {_SCORE_} ;
;===========; 


;====================================
f 1 0 16384 10 1		; GEN10
;====================================

;========
i 1 0 1
e

</CsScore>
</CsoundSynthesizer>
