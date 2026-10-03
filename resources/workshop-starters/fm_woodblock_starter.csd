<CsoundSynthesizer>
<CsOptions>
-n -d -m0 -o /tmp/drc-fm-woodblock.wav
--limiter=0.9
</CsOptions>
<CsInstruments>
sr = 44100
ksmps = 32
nchnls = 2
0dbfs = 1

giSine ftgen 0, 0, 4096, 10, 1

instr 1
  iFreq = cpsmidinn(p4)
  iAmp  = p5
  kAmp  expsegr 1, 0.0006, 0.85, 0.018, 0.0001
  kIdx  expsegr 12, 0.001, 8, 0.05, 0.0001
  aSig  foscili kAmp * iAmp, iFreq, 1, 2.75, kIdx, giSine
  aHp   butterhp aSig, 350
  aN    noise 0.06 * kAmp, 0.5
  aOut  = aHp + aN
  outs aOut, aOut
endin
</CsInstruments>
<CsScore>
i 1 0.00 0.16 79 0.34
i 1 0.22 0.14 81 0.32
i 1 0.44 0.16 79 0.33
i 1 0.66 0.14 84 0.30
i 1 0.88 0.16 79 0.34
i 1 1.10 0.14 81 0.32
i 1 1.32 0.16 86 0.28
i 1 1.54 0.14 79 0.33
i 1 1.76 0.16 81 0.32
i 1 1.98 0.14 84 0.30
i 1 2.20 0.16 79 0.34
i 1 2.42 0.14 81 0.32
i 1 2.64 0.16 88 0.28
i 1 2.86 0.14 79 0.33
i 1 3.08 0.16 81 0.32
i 1 3.30 0.14 84 0.30
i 1 3.52 0.16 79 0.34
i 1 3.74 0.14 81 0.32
i 1 3.96 0.16 79 0.33
i 1 4.18 0.14 84 0.30
i 1 4.60 0.18 79 0.32
i 1 4.78 0.18 81 0.30
i 1 4.96 0.18 84 0.28
i 1 5.14 0.18 88 0.26
i 1 5.80 1.20 79 0.24
i 1 5.80 1.20 81 0.22
i 1 5.80 1.20 84 0.20
</CsScore>
</CsoundSynthesizer>
