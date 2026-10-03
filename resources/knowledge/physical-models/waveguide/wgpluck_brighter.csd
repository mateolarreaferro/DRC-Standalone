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

;===================================================================
	
	instr 1

icps 	= 		220
iamp 	= 		20000
kpick 	= 		0.5
iplk 	= 		0
idamp 	= 		30
ifilt 	= 		10

axcite 	oscil 	1, 1, 1
apluck 	wgpluck 	icps, iamp, kpick, iplk, idamp, ifilt, axcite
		out 		apluck
		
endin

;===================================================================

</CsInstruments>
<CsScore>

;===========;
; {_SCORE_} ;
;===========; 

;===========================
f 1 0 16384 10 1	; GEN10
;===========================

;=========
i 1 0 2
e

</CsScore>
</CsoundSynthesizer>
