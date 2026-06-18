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

; Triangle Wave 1/n^2 odd series
f4 0 16384 10 1 0  .1111  0  .04  0  .0204 0 .012346 0 .008264 0 .005917

; Irregular Wave
f5 0 1024 10 1 .3 .1 0 .2 .02 0 .1 .04

; Pulse Wave 1/n odd series 1 point missing
f6 0 16384 10 1 0  .5  0   .333  0  0  0 .2 0 .167

f10 0 32768 1 "pluckbas.aif" 0 4 0

; Sonatina in G major, Hob. XVI:8 Haydn
; Treble
;  Sta  Dur   Amp   Freq   Table
i1 0.0  .15   5000  8.02   3
i1 +    .05   .     8.07   .
;
i1 0.2  .20   .     8.02  .
i1 +    .15   .     7.11  .
i1 .    .05   .     8.02  .
i1 .    .20   .     7.11  .
i1 .    .15   .     7.07  .
i1 .    .05   .     7.11  .
;
i1 1.0  .40   .     7.07  .
i1 1.6  .20   10000 8.02  2
;
i1 1.8  .0667 .     8.00  .
i1 +    .0667 .     8.02  .
i1 .    .0666 .     8.04  .
i1 .    .20   .     8.02  .
i1 2.4  .20   .     7.07  .
;
i1 2.6  .0667 .     7.09  .
i1 +    .0667 .     7.11  .
i1 .    .0666 .     8.00  .
i1 .    .20   .     7.11  .
; Bass
i2 0.2  .80   20000 5.11  4
i2 .    .80   .     5.07  .

</CsScore>
</CsoundSynthesizer>
