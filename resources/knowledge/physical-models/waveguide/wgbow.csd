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

;====================================================================

	instr 1	; Bow
	
kamp 	= 		31129.60
kfreq 	= 		440
kpres 	= 		3.0
krat	 	= 		0.127236
kvibf 	= 		6.12723
ifn 		= 		1
  
kv	 	linseg 	0, 0.5, 0, 1, 1, p3-0.5, 1
kvamp 	= 		kv * 0.01
a1 	 	wgbow 	kamp, kfreq, kpres, krat, kvibf, kvamp, ifn
 	 	out 		a1

endin

;====================================================================

</CsInstruments>
<CsScore>

;===========;
; {_SCORE_} ;
;===========; 

;=============================
f 1 0 128 10 1		; GEN 10
;=============================

;========
i 1 0 2
e

</CsScore>
</CsoundSynthesizer>
