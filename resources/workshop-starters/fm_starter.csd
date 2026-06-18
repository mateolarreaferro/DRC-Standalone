<CsoundSynthesizer>
<CsOptions>
-n -d -m0 -o /tmp/lac-fm.wav
--limiter=0.9
</CsOptions>
<CsInstruments>
sr = 44100
ksmps = 32
nchnls = 2
0dbfs = 1
seed 0

giSine ftgen 0, 0, 4096, 10, 1

instr 1
  iFreq = cpsmidinn(p4)
  iAmp  = p5
  kEnv  linsegr 0, 0.01, 1, p3 - 0.02, 0.8, 0.01, 0
  kIdx  line 6, p3, 2
  aSig  foscili kEnv * iAmp, iFreq, 1, 2.4, kIdx, giSine
  out(aSig, aSig)
endin
</CsInstruments>
<CsScore>
i 1 0.00 0.45 60 0.22
i 1 0.45 0.45 64 0.22
i 1 0.90 0.45 67 0.22
i 1 1.35 0.45 72 0.24
i 1 2.50 0.35 60 0.24
i 1 2.85 0.35 64 0.24
i 1 3.20 0.35 67 0.24
i 1 3.55 0.35 71 0.24
i 1 4.50 0.20 67 0.20
i 1 4.70 0.20 64 0.20
i 1 4.90 0.20 67 0.20
i 1 5.10 0.20 72 0.20
i 1 6.00 2.00 60 0.18
i 1 6.00 2.00 64 0.16
i 1 6.00 2.00 67 0.14
i 1 6.00 2.00 72 0.12
</CsScore>
</CsoundSynthesizer>
