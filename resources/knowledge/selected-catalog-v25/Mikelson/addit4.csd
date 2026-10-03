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

; Saw Wave 1/n series
f2 0 16384 10 1 .5 .33 .25 .2  .167

; Square Wave 1/n odd series
f3 0 16384 10 1 0  .5  0   .333 0  .25 0 .2 0 .167

; Irregular Wave
f4 0 1024 10 1 .3 .1 0 .2 .02 0 .1 .04

; Wave 1/n series 1 point missing
f5 0 16384 10 1 .5 .33 .25 .2  0  .142  .125  .111

; Series with higher harmonics
f6 0 16384 10 1 .5 .33 .25 .2  0  .142  .125  .111 0 .100 0 .09 0 .08 .01 .06 .015

; Pitch Bend Table
f10 0 1024 -7 1 250 1 12 2 240 2 12 1.5 120 1.5 10 .5 55 .5 10 2 55 2 20 .5 240 .5
f11 0 1024 -7 1 256 .5 10 1 118 .5 10 1 246 .5 10 1 118 .5 10 1 246 .5

; Sonatina in G major, Hob. XVI:8 Haydn
; Treble
;  Sta  Dur   Amp   Freq   Table  PBend
i4 0.0  5     20000  7.02  6      10
i4 +    5     20000  6.07  6      10
i4 .    5     20000  6.04  6      11



</CsScore>
</CsoundSynthesizer>
