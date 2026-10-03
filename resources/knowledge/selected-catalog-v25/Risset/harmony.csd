<CsoundSynthesizer>
<CsOptions>
</CsOptions>
<CsInstruments>
; Risset "Harmony/Timbre" #550

sr        =         44100
kr        =         4410
ksmps     =         10
nchnls    =         1

          instr 1
k1        envlpx    p4, p5, p3, p6, 1, 1, .01
a1        oscili    k1, p7, 2
a2        oscili    p8, p9, 3
          out       a1 * a2*4
          endin

          instr 2
i1        =         1/p3
k1        oscil     p4, i1, 4
a1        oscili    k1, p5, 2
          out       a1*2
          endin

</CsInstruments>
<CsScore>
; Risset "Harmony/Timbre" #550

f1 0 513 5 .01 512 1
f2 0 512 9 1 1 0
f3 0 512 9 0 42 1 172 1 84 -1 172 -1 42 0
f4 0 513 5 1 512 .00195

f0 1
s

i1  .5     .6    36    .01  .6  424 36 1000
i1  .6     .6    36    .01  .6  727 36 1000
i1  .9    3.6    36   2.30 1.2  424 36 1000
i1  .9     .6    36    .01  .6 1542 36 2000
i1 1.0    3.5    36   3.2  1.2  727 36 1000
i1 1.1     .6    36    .01  .6 1136 36 2000
i1 1.3    3.2    36   1.9  1.2 1542 36 2000
i1 1.4     .6    36    .01  .6 1342 36 2000
i1 1.5    3.0    36   1.9  1.2 1136 36 2000
i1 1.8    2.7    36   1.4  1.2 1342 36 2000
i2 4.0 10.0  4000 273.0
i2 4.0    7.5  2000 455
i2 4.0    4.5  2000 576
i2 4.0    6.5  1500 648
i2 4.0    4.0  1500 864
end
</CsScore>
</CsoundSynthesizer>
