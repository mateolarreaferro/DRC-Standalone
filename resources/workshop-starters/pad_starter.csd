<CsoundSynthesizer>
<CsOptions>
-n -d -m0 -o /tmp/lac-pad.wav
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
  iAmp  = p5
  kCut  = 1200
  kRes  = 0.4
  kEnv  linsegr 0, 0.5, 0.7, p3 - 1.0, 0.6, 0.5, 0
  aOsc  oscili kEnv * iAmp, iFreq, giSine
  aFilt moogladder aOsc, kCut, kRes
  aL, aR pan2 aFilt, 0.5
  gaRvbL += aL * 0.4
  gaRvbR += aR * 0.4
  out(aL, aR)
endin

instr 99
  aWetL, aWetR reverbsc gaRvbL, gaRvbR, 0.85, 6000
  out(aWetL * 0.35, aWetR * 0.35)
  gaRvbL = 0
  gaRvbR = 0
endin
</CsInstruments>
<CsScore>
i 99 0 8
i 1  0.00 1.20 55 0.25
i 1  1.50 1.20 60 0.25
i 1  3.00 0.80 64 0.22
i 1  3.80 0.80 67 0.22
i 1  4.60 0.80 71 0.22
i 1  5.50 2.50 60 0.18
i 1  5.50 2.50 64 0.16
i 1  5.50 2.50 67 0.14
</CsScore>
</CsoundSynthesizer>
