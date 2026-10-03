<CsoundSynthesizer>

<CsOptions>
; XO
;-+rtmidi=alsa  --midi-device=hw:1,0 -+rtaudio=alsa -odac -r16000 -k160 ;-O stdout
; Mac
-odac -r44100 -k44100
--limiter=0.9
</CsOptions>
<CsInstruments>
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
           instr 1; very simple feedback simulator
 ; does feedback work this way???
 ; coded by Josep M Comajuncosas / sept.´98
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
 kfreq     init      1152
 kfdbk     linseg    .9, p3/5, 1.4, p3/5, .9, p3/5, 1.2, 2*p3/5, 1
 asig      pluck     1, 123, 123, 0, 1
 
 atemp     delayr    1/20
 
 acomb     deltapi   1/kfreq
 
 aiir      dcblock   asig + kfdbk*acomb
 aiir      =         aiir - aiir*aiir*aiir/6
 
 delayw    aiir
 
           out       acomb*20000
 
           endin
 
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
           instr 2; repluck feedback simulator?
 ; coded by Josep M Comajuncosas / sept.´98
 ; This instrument is an accident ;-)
 ; but it gives wonderful noises !
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
 kenv      linseg    0 ,.05, 0 ,p3/3, 1, p3/3, 1, p3/3, 0
 kfreq     linseg    1152, p3/2, 673, p3/2, 451
 acomb     init      0
 kfdbk     linseg    .5, p3/5, 1.1, p3/5, .9, p3/5, 1.2, 2*p3/5, 1
 asig      repluck   .4, 1, 123, .7, .1, acomb
 
 
 atemp     delayr    1/20
 acomb     deltapi   1/kfreq                  ; acomb ROUTED BACK TO REPLUCK
 aiir      =         asig + kfdbk*acomb
 
 ; CHEAP CLIPPER
 kiir      downsamp  aiir
 kiir      =         (kiir > 1 ? 1:kiir)
 kiir      =         (kiir < -1 ? -1:kiir) 
 aiir      upsamp    kiir
 
 delayw    aiir
 
 ; CHEAP CLIPPER (BIS)
 ksig      downsamp  asig
 ksig      =         (ksig > 1 ? 1:ksig)
 ksig      =         (ksig < -1 ? -1:ksig) 
 asig      upsamp    ksig
 
           out       asig*20000*kenv 
           endin
</CsInstruments>

<CsScore>
;f1 0 8192 21 1
f1 0 8192 10 1
 i1 0 15
s
 i2 0 10
 e
</CsScore>

</CsoundSynthesizer>