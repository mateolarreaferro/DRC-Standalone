<CsoundSynthesizer>
<CsInstruments>
ksmps = 32
nchnls = 2
0dbfs = 1

gi_cubicb ftgen 0, 0, 512, 8, 0, 128, 1, 128, 0, 256, 0
gi_cosine ftgen 0,0,16384,11,1,1

instr 1

kwobbler = oscil3(0.5, p6) + 0.5

ares1      gbuzz     p4, cpspch(p5) + jspline:k(1.7, 0.2, 7.7), 8, 1, kwobbler, gi_cosine
ares2      gbuzz     p4, (cpspch(p5)/2) + jspline:k(1.5, 2.5, 3), 8, 2, kwobbler, gi_cosine

ares3 distort ares1, (kwobbler + 0.1) * 2.3, gi_cubicb

ares = (ares1 + (ares2 * 2) + ares3)

adeclick linseg 0, 0.002, 1, p3-0.005, 1, 0.003, 0
ares = ares * adeclick

outs ares, ares
endin


</CsInstruments>

<CsScore>
i1 0 1 0.25 6.04 1
i1 1 1 0.25 7.04 6
i1 2 1 0.25 6.04 1
i1 3 1 0.25 7.07 3
i1 4 1 0.25 5.09 1
i1 5 1 0.25 6.09 2
i1 6 1 0.25 5.09 3
i1 7 1 0.25 5.11 6

i1 8 1 0.25 6.04 2
i1 9 1 0.25 7.04 6
i1 10 1 0.25 6.04 1
i1 11 1 0.25 7.07 3
i1 12 1 0.25 6.09 1
i1 13 1 0.25 7.09 2
i1 14 1 0.25 6.11 3
i1 15 1 0.25 6.07 6
i1 16 1 0.25 6.04 1

i1 17 1 0.25 7.04 6
i1 18 1 0.25 6.04 1
i1 19 1 0.25 7.07 3

</CsScore>
</CsoundSynthesizer>
