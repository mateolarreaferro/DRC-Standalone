<CsoundSynthesizer>

<CsOptions>
; XO
;-+rtmidi=alsa  --midi-device=hw:1,0 -+rtaudio=alsa -odac -r16000 -k160 ;-O stdout
; Mac
-odac -r44100 -k441
--limiter=0.9
</CsOptions>

<CsInstruments>
instr    1 ; Sequencer: 2*VCOs, 'Moog'VCF, VCA, Env.
 
 ilevl    = p4*32767 ; Output level
 itabl1   = p5       ; Pitch table
 imult    = p6       ; Pitch multiplier
 idet     = p7/2     ; VCO detune
 ivcf     = p8       ; VCF cut-off frequency
 
 k1       phasor  1/p3
 k2       table  k1, itabl1, 1
 kenv1    oscil  1, 8/p3, 3
 kenv2    oscil  1, 8/p3, 5
 kf       = kenv1*ivcf
 avco1    oscil  .5, cpspch(k2)*imult - idet, 8, -1
 avco2    oscil  .5, cpspch(k2)*imult + idet, 8, -1
 avcos    = avco1 + avco2
 avcf     moogvcf  avcos, kf, .1
 out      avcf*ilevl*kenv2
 
 endin
 
</CsInstruments>
<CsScore>
f1 0 8 -2  08.00  08.03  08.07  08.07  08.07  08.03  08.00  07.00 ; Pitches
 f2 0 8 -2  07.03  07.02  07.00  07.07  07.05  07.03  07.02  06.07 ; Pitches
 
 ;f3 0 1024 -7 0 14 1 1010 0 ; Linear Env
 f3 0 1024 -5 .001 14 1 1010 .001 ; Exponential Env
 
 f5 0 1024 -5 .001 12 1 1000 1 12 .001 ; VCA Env
 
 f8 0 1024 7 0 512 1 0 -1 512 0
 
 ;   Strt  Leng  Levl  Table Freq* Detun Cut-Off
 i1  0.00  1.00  0.75  2     1     1.00  4000
 i1  +     .     .     .     .     .     .
 i1  0.00  2.00  0.50  1     1     2.00  2000
 e
 
</CsScore>

</CsoundSynthesizer>