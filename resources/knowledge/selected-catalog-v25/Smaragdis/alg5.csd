<CsoundSynthesizer>
<CsOptions>
</CsOptions>
<CsInstruments>
sr        =         44100
kr        =         4410
ksmps     =         10
nchnls    =         1

          instr 1             ; INSTRUMENT 1 / DX7     ALGORITHM 5

ifreq     =         cpspch(p4)               ; p4 = NOTE
ifreq1    =         ifreq * p5               ; p5, p6, p7 = CARRIER RATIO
ifreq2    =         ifreq * p6
ifreq3    =         ifreq * p7
isc       =         15


; CARRIER ENVELOPES

kc1eg     oscil     isc * p11, 1 / p3, 2     ; p11-p16 = OP AMPLITUDE
kc2eg     oscil     isc * p12, 1 / p3, 4
kc3eg     oscil     isc * p13, 1 / p3, 6


; MODULATOR ENVELOPES
     
km1eg     oscil     isc * p14, 1 / p3, 3
km2eg     oscil     isc * p15, 1 / p3, 5
km3eg     oscil     isc * p16, 1 / p3, 7


; MODULATOR OSCILLATORS
     
am1       oscil     km1eg, p8  * ifreq1, 1   ; p8,p9,p10 = C:M RATIO
am2       oscil     km2eg, p9  * ifreq2, 1
amf       oscil     km3eg, p10 * ifreq3, 1
am3       oscil     km3eg, p10 * ifreq3 + p17 * amf, 1 ; p17 = FEEDBACK


; CARRIER OSCILLATORS

ac1       oscil     kc1eg, ifreq1 + am1, 1
ac2       oscil     kc2eg, ifreq2 + am2, 1
ac3       oscil     kc3eg, ifreq3 + am3, 1

          out       p18 * (ac1 + ac2 + ac3)
          endin


          instr 2             ; INSTRUMENT 2 / THREE OPERATOR CHORUSED FM W/ PEG,VIB

ifreq     =         cpspch( p4)
imodrat   =         ifreq * 100 / 88
     

; ENVELOPES (CARRIER, MODULATOR, PITCH)

kenv      oscil     p5, 1 / p3, 8            ; p5 = CVL
kmen      oscil     p6, 1 / p3, 9            ; p6 = MVL
kpeg      oscil     p7, 1 / p3, 10           ; p7 = PLVL


; CHORUS AND VIBRATO
                                        
klfo      oscil     p10, p11, 1              ;p10 = CHDEPTH, p11 = CHSPEED
kvib      oscil     p8,  p9 + kmen, 1        ; p8 = VIBDEP, p9 = VIBFR


; MODULATORS

a2mod     oscil     p14 * kmen, p13 * imodrat, 1 ; p14 = 2MVL, p13 = 2MODRAT
amod      oscil     kmen, imodrat + a2mod, 1


; CARRIERS

a1        oscil     kenv, ifreq + amod + kpeg + kvib, 1
a2        oscil     p12 * kenv, 2 * ifreq + amod + klfo + kpeg + kvib, 1 ; p12 = CHLVL


          out       p15 * (a1 + a2)
          endin


          instr 3             ; INSTRUMENT 3 / TWO OPERATOR CHORUSED FM


ifreq     =         p4


; ENVELOPES

kmeg      oscil     p8, 1 / p3,    12
kceg      oscil     p7, 1 / p3,    11   


; OSCILATORS

am        oscil     kmeg, ifreq * p6,   1
ac        oscil     kceg, ifreq * p5 + am,   1
ac2       oscil     kceg, ifreq * p5 + am + 5,1


          out       ac + ac2
          endin

</CsInstruments>
<CsScore>
t 0 40

                                             ;FUNCTIONS
f01 0 4096 10 1
f02 0 2048 7 0 4 1 750 .7 330 0
f03 0 2048 7 0 5 1 550 .7 220 0
f04 0 2048 7 0 5    1 800 .9 500 0
f05 0 2048 7 0 105 1 700 .9 400 0
f06 0 2048 7 0 105 1 800 .9 400 0
f07 0 2048 7 0 105 1 700 .9 400 0
f08 0 4096 7 0 496 1 3600 0
f09 0 4096 7 0 1496 1 1600 0 1000 5
f10 0 2048 7 0 2048 1
f11 0 256 7 1 156 .3 100 0
f12 0 256 7 1 56 .3 200 0
                                             ;NOTE LIST


i3   5    .03       880       4    20   10000     10000
i3   +    .         <         .    .    .         .
i3   .    .         <         .    .    .         .
i3   .    .         <         .    .    .         .
i3   .    .         <         .    .    .         .
i3   .    .         <         .    .    .         .
i3   .    .         <         .    .    .         .
i3   .    .         <         .    .    .         .
i3   .    .         <         .    .    .         .
i3   .    .         <         .    .    .         .
i3   .    .         <         .    .    .         .
i3   .    .         <         .    .    .         .
i3   .    .         <         .    .    .         .
i3   .    .         <         .    .    .         .
i3   .    .         <         .    .    .         .
i3   .    .         <         .    .    .         .
i3   .    1         800       .    .    .         .

i1   0    2         8.00 1    1    2    12.4 4.3  1.7  73   95   95   60   89   85   0    1.5
i1   1    2         8.08 .    .    .    .    .    .    .    .    .    .    .    .    .    .    1
i1   2    3         7.11 .    .    .    .    .    .    .    .    .    .    .    .    .    .    .5

i2   0    6         7.00 200  300  100  5    5    6    6    30   1.4  20 1
e
</CsScore>
</CsoundSynthesizer>
