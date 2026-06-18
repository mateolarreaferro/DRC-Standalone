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

;================================================================

  instr 1
  
; pos      =        [0, 1]
; bowpress =        [1, 10]
; gain     =        [0.8, 1]
; intr     =        [0,1]
; trackvel =        [0, 1]
; bowpos   =        [0, 1]

kb      	line			0.5, p3, 0.1
kp      	line 		0.6, p3, 0.7
kc      	line 		1, p3, 1

a1      	wgbowedbar 	p4, cpspch(p5), kb, kp, 0.995, p6, 0
          out a1
          
endin

;================================================================

</CsInstruments>
<CsScore>

;===========;
; {_SCORE_} ;
;===========; 

;==========================
i1      0  3 32000 7.00 0
e

</CsScore>
</CsoundSynthesizer>
