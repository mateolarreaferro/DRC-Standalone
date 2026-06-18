<CsoundSynthesizer>
<CsOptions>
-n -d -m0 -o /tmp/lac-fm-piano.wav
--limiter=0.9
</CsOptions>
<CsInstruments>
sr = 44100
ksmps = 32
nchnls = 2
0dbfs = 1
seed 0

giSine ftgen 0, 0, 4096, 10, 1

gaRvbL init 0
gaRvbR init 0

instr 1
  iFreq = cpsmidinn(p4)
  iAmp  = (p5 > 0 ? p5 : 0.28)
  kEnv  linsegr 0, 0.008, 1, p3 - 0.03, 0.75, 0.025, 0
  kIdx  line 4, p3, 1.2
  aSig  foscili kEnv * iAmp, iFreq, 1, 1.0, kIdx, giSine
  gaRvbL += aSig * 0.42
  gaRvbR += aSig * 0.42
  out(aSig, aSig)
endin

instr 99
  aWetL, aWetR reverbsc gaRvbL, gaRvbR, 0.88, 9000
  out(aWetL * 0.38, aWetR * 0.38)
  gaRvbL = 0
  gaRvbR = 0
endin
</CsInstruments>
<CsScore>
i 99 0 10
i 1 0.00 0.55 60 0.24
i 1 0.55 0.55 64 0.24
i 1 1.10 0.55 67 0.24
i 1 1.65 0.55 72 0.26
i 1 2.50 0.40 67 0.22
i 1 2.90 0.40 64 0.22
i 1 3.30 0.40 60 0.22
i 1 4.20 0.35 72 0.24
i 1 4.55 0.35 67 0.24
i 1 4.90 0.35 64 0.24
i 1 5.80 2.20 60 0.20
i 1 5.80 2.20 64 0.18
i 1 5.80 2.20 67 0.16
</CsScore>
</CsoundSynthesizer>
