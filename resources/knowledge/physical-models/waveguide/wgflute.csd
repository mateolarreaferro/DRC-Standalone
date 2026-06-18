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

;===============================================================================

	instr 1
	
kamp 	= 	31129.60
kfreq 	= 	440
kjet 	= 	0.32
iatt 	= 	0.1
idetk 	= 	0.1
kngain 	= 	0.15
kvibf 	= 	5.925
kvamp 	= 	0.05
ifn 		= 	1

a1 		wgflute 	kamp, kfreq, kjet, iatt, idetk, kngain, kvibf, kvamp, ifn
  		out 		a1
  		
endin

;===============================================================================

</CsInstruments>
<CsScore>

;===========;
; {_SCORE_} ;
;===========; 

;=======================================
; Table #1, a sine wave.
f 1 0 16384 10 1
;=======================================

; Play Instrument #1 for two seconds.
;=======================================
i 1 0 2
e

</CsScore>
</CsoundSynthesizer>
