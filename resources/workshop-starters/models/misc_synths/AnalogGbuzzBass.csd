<CsoundSynthesizer>

<CsOptions>
; XO
;-+rtmidi=alsa  --midi-device=hw:1,0 -+rtaudio=alsa -odac -r16000 -k160 ;-O stdout
; Mac
-odac -r44100 -k441
--limiter=0.9
</CsOptions>

<CsInstruments>
 ; Steven Cook
 instr    1 ; Gbuzz instrument.
 
 ilevl    = p4*32767               ; Output level
 ipitch   = cpspch(p5)             ; Pitch
 ihigh    = int((.5*sr)/ipitch*p6) ; Highest harmonic < nyquist
 ilow     = p7                     ; Lowest harmonic
 iharm1   = p8                     ; Start harmonic curve
 iharm2   = p9                     ; End harmonic curve
 
 k1       line  iharm1, p3, iharm2
 a1       gbuzz  1, ipitch, ihigh, ilow, k1, 1, -1
 out      a1*ilevl
 endin 
</CsInstruments>

<CsScore>
f1 0 16384 9 1 1 90 ; Cosine
 
 t 0 280 ; 4*Tempo
 
 ;                           -------Harmonics-------
 ;     Strt  Leng  Levl  Pitch Num.  Low.  Harm1 Harm2
 i1    0.00  1.00  1.00  07.00 1     1     1.00  0.10
 i1    +     .     .     06.07 .     .     ~     ~
 i1    +     .     .     06.09 .     .     ~     ~
 i1    +     .     .     07.09 .     .     ~     ~
 i1    +     .     .     07.00 .     .     ~     ~
 i1    +     .     .     07.03 .     .     ~     ~
 i1    +     2.00  .     07.05 .     .     0.10  1.00
 e
</CsScore>


</CsoundSynthesizer>
<bsbPanel>
 <label>Widgets</label>
 <objectName/>
 <x>100</x>
 <y>100</y>
 <width>320</width>
 <height>240</height>
 <visible>true</visible>
 <uuid/>
 <bgcolor mode="background">
  <r>240</r>
  <g>240</g>
  <b>240</b>
 </bgcolor>
</bsbPanel>
<bsbPresets>
</bsbPresets>
