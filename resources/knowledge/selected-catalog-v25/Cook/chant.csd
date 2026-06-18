<CsoundSynthesizer>
<CsOptions>
</CsOptions>
<CsInstruments>
sr     = 44100
kr     = 2205
ksmps  = 20
nchnls = 1

instr    1 ; Random vowel FOF instrument

ilevl    = p4*10000   ; Output level
ipitch   = cpspch(p5) ; Pitch
ivibr    = p6         ; Vibrato rate
ivibd    = p7         ; Vibrato depth
irate    = p8         ; Random vowel rate
idet     = p9         ; Detune
ileng    = p3

kenv     linseg  0, .1, 1, p3 - .2, 1, .1, 0
iseed    = rnd(1)
k1       randi  .5, irate, iseed
k1       = k1 + .5
k2       linseg  0, p3, ivibd
k3       oscil  k2, ivibr, 1
k1f      table  k1, 11, 1
k2f      table  k1, 12, 1
k3f      table  k1, 13, 1
k4f      table  k1, 14, 1
k5f      table  k1, 15, 1
k1b      table  k1, 21, 1
k2b      table  k1, 22, 1
k3b      table  k1, 23, 1
k4b      table  k1, 24, 1
k5b      table  k1, 25, 1
kpitch   = ipitch + k3 + idet
a1       fof  1.0, kpitch, k1f, 0, k1b, .003, .02, .007, 1000, 1, 2, ileng
a2       fof  0.7, kpitch, k2f, 0, k2b, .003, .02, .007, 1000, 1, 2, ileng
a3       fof  0.5, kpitch, k3f, 0, k3b, .003, .02, .007, 1000, 1, 2, ileng
a4       fof  0.4, kpitch, k4f, 0, k4b, .003, .02, .007, 1000, 1, 2, ileng
a5       fof  0.3, kpitch, k5f, 0, k5b, .003, .02, .007, 1000, 1, 2, ileng
out      (a1 + a2 + a3 + a4 + a5)*ilevl*kenv

endin

</CsInstruments>
<CsScore>
f1 0 4096 10 1 ; Sine
f2 0 1024 19 .5 .5 270 .5 ; Rising sigmoid

f11 0 1024 -7  600 256  400 256  250 256  400 256  350
f12 0 1024 -7 1040 256 1620 256 1750 256  750 256  600
f13 0 1024 -7 2250 256 2400 256 2600 256 2400 256 2400
f14 0 1024 -7 2450 256 2800 256 3050 256 2600 256 2675
f15 0 1024 -7 2750 256 3100 256 3340 256 2900 256 2950

f21 0 1024 -7   60 256   40 256   60 256   40 256   40
f22 0 1024 -7   70 256   80 256   90 256   80 256   80
f23 0 1024 -7  110 256  100 256  100 256  100 256  100
f24 0 1024 -7  120 256  120 256  120 256  120 256  120
f25 0 1024 -7  130 256  120 256  120 256  120 256  120

;     Strt  Leng  Levl  Pitch VibR  VibD  Rate  Detune
i1    0.00  4.00  0.25  06.00 5.05  0.5  1.00  0.02
i1    .     .     .     .     .     .     .     0.27
i1    .     .     .     .     .     .     .     0.51
i1    .     .     .     .     .     .     .     0.77
e
</CsScore>
</CsoundSynthesizer>
