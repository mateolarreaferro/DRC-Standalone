<CsoundSynthesizer>
<CsOptions>
</CsOptions>
<CsInstruments>
sr             =         44100
kr             =         2205
ksmps          =         20
nchnls         =         2

ga1            init      0
ga2            init      0


instr          1

iwindfun       =         1
isampfun       =         2
ibeg           =         0
iwindsize      =         2000
iwindrand      =         1500
ioverlap       =         83
idur           =         p3
ibegtime       =         p4
iendtime       =         p5
iamp           =         p6
ibegpitch      =         p7
iendpitch      =         p8
ichan1         =         sqrt(p9)
ichan2         =         sqrt(1-p9)
ienv           =         p10

ktimpnt        linseg    ibegtime, idur, iendtime
aresamp        linseg    ibegpitch, idur, iendpitch

asig           sndwarp   .1, ktimpnt, aresamp, isampfun, ibeg, iwindsize, iwindrand, ioverlap, iwindfun, 1

kenv           linseg    0, idur * ienv, iamp, idur - (idur * 2 * ienv), iamp, idur * ienv, 0

aout           =         asig * kenv
achan1         =         ichan1 * aout
achan2         =         ichan2 * aout

               outs      achan1, achan2

endin


instr          2

idur           =         p3
ifreq          =         p4
iamp           =         p5
iwherebeg      =         0
iwhereend      =         .55
aspeed         linseg    iwherebeg, idur, iwhereend
koct           linseg    0, idur, 0.5
kdistance      linseg    1, idur * .4, 3, idur * .3, 1, idur * .3, 2
kfreq          =         (ifreq * 340) / (340 + 3 * kdistance)

krnd           randi     2, 15
krndw          randi     .008, 20
kosc           oscili    3, 5, 4
asig1          fog       .25, ifreq + krnd + kosc, 1, aspeed, koct, 10, .005, .028 + krndw, .005, 300, 2, 3, p3

krnd2          randi     1.7, 13
kosc2          oscili    3.2, 5.7, 4
krndw2         randi     .01, 15   
asig2          fog       .25, ifreq + krnd2 + kosc2 +2, 1, aspeed + .011, koct, 10, .005, .028 + krndw2, .005, 300, 2, 3, p3

krnd3          randi     1.6, 17
kosc3          oscili    3.4, 4.3, 4
krndw3         randi     .007, 13  
asig3          fog       .25, ifreq + krnd3 + kosc3 - 1.7, 1, aspeed + .019, koct, 10, .005, .028 + krndw3, .005, 300, 2, 3, p3

krnd4          randi     1.8, 11
kosc4          oscili    3.1, 4.83, 4
krndw4         randi     .009, 14  
asig4          fog       .25, ifreq + krnd4 + kosc4 + 0.8, 1, aspeed + .0273, koct, 10, .005, .028 + krndw4, .005, 300, 2, 3, p3

kenv           linseg    0, 2, iamp, idur - 5, iamp, 3, 0

asum           =         (asig1 + asig2 + asig3 + asig4) * kenv

krndist        randi     40, ifreq * .0019 
kdegree        linseg    0, idur * .6, 90, idur * .4, 22

a2, a1         locsig    asum, kdegree + krndist, kdistance, .1
ar2, ar1       locsend

ga1            =         ga1 + ar1
ga2            =         ga2 + ar2

               outs      a1, a2

endin


instr          3

idur           =         p3
ifreq          =         p4
iamp           =         p5
ivibbeg        =         p6
ivibend        =         p7
iwherebeg      =         .16
iwhereend      =         .223
ibegdist       =         p8
imiddist1      =         p9
imiddist2      =         p10
ienddist       =         p11

aspeed         linseg    iwherebeg, idur, iwhereend
koct           linseg    0, idur, 0.5
kfreq          linseg    ivibbeg, idur, ivibend
kdepth         linseg    25, idur, 100
kosc1          oscili    kdepth, kfreq, 5
kosc2          oscili    kosc1, 15, 4
kdistance      linseg    ibegdist, idur * .4, imiddist1, idur * .3, imiddist2, idur * .3, ienddist
kfreq          =         (ifreq * 340) / (340 +  kdistance)

asig1          fog       .25, kfreq + kosc2, 1, aspeed, koct, 10, .005, .028, .005, 300, 2, 3, p3

asig2          fog       .25, kfreq + 1.7 + kosc2, 1, aspeed, koct, 10, .005, .028, .005, 300, 2, 3, p3

asig3          fog       .25, kfreq - 1.3 + kosc2, 1, aspeed, koct, 10, .005, .028, .005, 300, 2, 3, p3
 
kenv           linseg    0, idur * .1, iamp, idur - (idur * .4), iamp, idur * .3, 0

asum           =         (asig1 + asig2 + asig3) * kenv * .8

kfc1           linseg    ifreq, idur * .5, 3500 * iamp, idur * .5, ifreq
kfq1           expseg    100, idur * .3, 1000, idur * .7, 5000
kfq2           expseg    50, idur * .6, 10000, idur * .4, 2000
afilt1         reson     asum, kfc1, kfq1, 1
afilt2         reson     asum, ifreq, kfq2, 1

asum2          =         afilt1 + afilt2

krndist        randi     25, ifreq * .0007
kline          linseg    p12, idur * .6, p13, idur * .4, p14
kdegree        =         krndist + kline

a1, a2         locsig    asum2, kdegree, kdistance, .1
ar1, ar2       locsend

ga1            =         ga1 + ar1
ga2            =         ga2 + ar2

               outs      a1, a2

endin



instr 99 ; reverb instrument

a1   reverb2 ga1, 3.2, .5
a2   reverb2 ga2, 3.33, .5
     
outs a1, a2

ga1 = 0
ga2 = 0

endin



</CsInstruments>
<CsScore>
f1 0 16384 9 .5 1 0
f2 0 65536 -1 "apocalypse.aiff" 0 4 0
f3 0 1024 19 .5  1 270 1
f4 0 16384 10 1
f5 0 1024 1 "angle.aiff" 0 0 1

i1  3 20  .1 .13 5   1   .8  .3  .37
i1  4 20 .04 .14 5  .7    1  .7  .36
i1 10 20 .36 .39 2   1   .8  .1  .4
i1 13 18 .38 .36 2  .9  1.03 .9  .42
i1 20 40 .13 .04 3  .2   .6  .44 .35
i1 25 34 .05 .12 3 1.4  1.7  .63 .31
i1 30 29 .12 .04 3  .25  .7  .63 .33

i2  14    45   82.5  1.3
i2  15    44  137.5  1
i2  17    40  165    1.2
i2  16    44  198    1
i2  20.1  39  275    1
i2  25.5  34  247.5  1
i2  30    30  137.5  1
i2  18    42  330    1
i2  35    24   82.5  1.5
i2  37    22  138    1.1
i2  42    18  248    1.7
i2  42.3  17  309    1.7

i3 0 7 660 1.7 1.3 4.2 9 1 1 8 90 0 90
i3 5 20 618 1.3 4.1 1.98 1 9 1 10 0 90 37
i3 11 17 330 1.2 1.8 3.1 10 1 10 1 22 87 0
i3 15 18 275 1 3.9 2.3 10 5 1 10 77 11 90
i3 21 15 550 1.2 6.4 2.1 1 3 10 1 45 90 0
i3 25 33 396 1.3 2.3 3.2 10 1 1 8 45 0 90
i3 40 20 495 1.5 4.5 1.3 1 8 1 10 90 0 90

i99 0 64
e
</CsScore>
</CsoundSynthesizer>
