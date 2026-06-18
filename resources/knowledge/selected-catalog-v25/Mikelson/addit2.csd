<CsoundSynthesizer>
<CsOptions>
</CsOptions>
<CsInstruments>
sr		=		44100
kr		=		4410
ksmps	=		10
nchnls	=		2

;----------------------------------------------------------------------------------
; Basic Additive Synthesis
;----------------------------------------------------------------------------------
       instr    1

idur    =       p3
iamp    =       p4
ifqc    =       cpspch(p5)*2
itable  =       p6

kdvib   linseg  0, .1, 0, .1, .01, idur-.2, .01
kvibr   oscil   kdvib, 6, 1
kamp    linseg  0, .01, iamp, idur-.02, iamp*.8, .01, 0
aamp    interp  kamp

;              AMP   FQC
aoutl   oscil  aamp, ifqc*(1.001+kvibr), itable
aoutr   oscil  aamp, ifqc*(0.999+kvibr), itable

        outs   aoutl, aoutr

      endin

;----------------------------------------------------------------------------------
; Linear Synthesis
;----------------------------------------------------------------------------------
       instr    2

idur    =       p3
iamp    =       p4
ifqc    =       cpspch(p5)*2
itable  =       p6

kdvib   linseg  0, .2, 0, .2, .007, idur-.4, .01
kvibr   oscil   kdvib, 6, 1
kamp    linseg  0, .05, iamp, .1, iamp*.7, idur-.25, iamp*.5, .1, 0

aamp    interp  kamp
attk    loscil  iamp/4, 440, 10, 261.262
;asamp1 loscil  iamp, ifqc, iwav, ibase

;              AMP   FQC             TABLE
aout    oscil  aamp, ifqc*(1+kvibr), itable

        outs   attk+aout, attk+aout

      endin

;----------------------------------------------------------------------------------
; Additive Synthesis 2
;----------------------------------------------------------------------------------
       instr    3

idur   =       p3
iamp   =       p4
ifqc   =       cpspch(p5)
itabl0 =       p6
itab1  =       p7
itab2  =       p8
itab3  =       p9
itab4  =       p10
ipch1  =       p11
ipch2  =       p12
ipch3  =       p13
ipch4  =       p14

aamp1  oscil  1, 1/idur, itab1
apch1  oscil  1, 1/idur, ipch1
aout1  oscil  aamp1, ifqc*apch1, itabl0

aamp2  oscil  1, 1/idur, itab2
apch2  oscil  1, 1/idur, ipch2
aout2  oscil  aamp2, ifqc*apch2, itabl0

aamp3  oscil  1, 1/idur, itab3
apch3  oscil  1, 1/idur, ipch3
aout3  oscil  aamp3, ifqc*apch3, itabl0

aamp4  oscil  1, 1/idur, itab4
apch4  oscil  1, 1/idur, ipch4
aout4  oscil  aamp4, ifqc*apch4, itabl0

aoutl  =      aout1+aout2+aout3
aoutr  =      aout1-aout3+aout4
       outs   aoutl*iamp, aoutr*iamp

       endin

;----------------------------------------------------------------------------------
; Basic Additive Synthesis
;----------------------------------------------------------------------------------
       instr    4

idur    =       p3
iamp    =       p4
ifqc    =       cpspch(p5)*2
itable  =       p6
ipbend  =       p7

kpbend  oscili  1, 1/idur, ipbend

kdvib   linseg  0, .1, 0, .1, .01, idur-.2, .01
kvibr   oscil   kdvib, 6, 1
kamp    linseg  0, .01, iamp, idur-.02, iamp*.8, .01, 0
aamp    interp  kamp

;              AMP   FQC
aoutl   oscil  aamp, ifqc*(1.001+kvibr)*kpbend, itable
aoutr   oscil  aamp, ifqc*(0.999+kvibr)*kpbend, itable

        outs   aoutl, aoutr

      endin

;----------------------------------------------------------------------------------
; Tremelo
;----------------------------------------------------------------------------------
       instr    20

idur    =       p3
iamp    =       p4
ifqc    =       cpspch(p5)
iwave   =       p6
ilfofqc =       p7
ilfowav =       p8

;              AMP   FQC   TABLE
kampo   oscil  iamp,    ilfofqc, ilfowav
kamp    =      (kampo+iamp*.5)
asig    oscil  kamp, ifqc, iwave

        outs   asig, asig

      endin

;----------------------------------------------------------------------------------
; Panning
;----------------------------------------------------------------------------------
       instr    21

idur    =       p3
iamp    =       p4
ifqc    =       cpspch(p5)
iwave   =       p6
ilfofqc =       p7
ilfowav =       p8

;              AMP   FQC   TABLE
kampo   oscil  1,    ilfofqc, ilfowav
kamp    =      (kampo+.5)
asig    oscil  iamp, ifqc, iwave

        outs   asig*sqrt(kamp), asig*sqrt(1-kamp)

      endin


</CsInstruments>
<CsScore>
; Sine Wave
f1 0 16384 10 1

; Amplitude envelopes
f2 0 1025 -7 0 212 1 600 1 213 0
f3 0 1025 -7 0 112 .5 200 1 400 .8 100 .5 113 0
f4 0 1025 -7 0 112 1 200 2 500 .8 213 0
f5 0 1025 -7 0 212 2 100 .5 400 .2 200 1 113 0

; Pitch envelopes
f6 0 1025 -7 1   212 1.01 600 .99 213 1
f7 0 1025 -7 .2  112 .5   200 1   400 .8  100 .5 113 .6
f8 0 1025 -7 2.1 212 2.2  100 2   200 1.8 513 2
f9 0 1025 -7 6   212 6    100 6   400 7   200 7  113 6

;  Sta   Dur  Amp  Freq  Sine  Amp1  Amp2  Amp3  Amp4  Pch1 Pch2  Pch3  Pch4
i3 0.0   11  1500  7.02  1     2     3     4     5     6    7     8     9
i3 2.0   10  .     8.04  .     .     .     .     .     .    .     .     .
i3 6.0   9   .     8.00  .     .     .     .     .     .    .     .     .
i3 7.0   8   .     6.04  .     .     .     .     .     .    .     .     .
i3 8.0   6   .     9.00  .     .     .     .     .     .    .     .     .
;
i3 12.0  6   2000  7.00  1     2     3     4     5     6    7     8     9
i3 14.0  7   .     8.02  .     .     .     .     .     .    .     .     .
i3 16.5  9   .     7.10  .     .     .     .     .     .    .     .     .
i3 17.5  8   .     6.02  .     .     .     .     .     .    .     .     .
i3 18.5  8   .     9.04  .     .     .     .     .     .    .     .     .
;
i3 20.0  3   1000  7.00  1     2     3     4     5     6    7     8     9
i3 21.0  4   .     8.02  .     .     .     .     .     .    .     .     .
i3 22.5  4   .     7.10  .     .     .     .     .     .    .     .     .
i3 23.5  2   .     6.02  .     .     .     .     .     .    .     .     .
i3 24.5  2   .     9.04  .     .     .     .     .     .    .     .     .
i3 25.5  2   .     7.02  .     .     .     .     .     .    .     .     .
i3 26.5  2   .     9.00  .     .     .     .     .     .    .     .     .



</CsScore>
</CsoundSynthesizer>
