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

;====================================================

	instr 1
	
iplk 	= 	0.75
kamp 	= 	30000
icps 	= 	220
kpick 	= 	0.75
krefl 	= 	0.5

apluck 	wgpluck2 	iplk, kamp, icps, kpick, krefl
  		out 		apluck
  		
endin

;====================================================

</CsInstruments>
<CsScore>

;===========;
; {_SCORE_} ;
;===========; 

; Play Instrument #1 for two seconds.
;======================================
i 1 0 2
e

</CsScore>
</CsoundSynthesizer>
