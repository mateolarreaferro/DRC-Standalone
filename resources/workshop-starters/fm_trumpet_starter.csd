<CsoundSynthesizer>
<CsOptions>
-n -d -m0 -o /tmp/lac-trumpet.wav
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
  iAmp = p5

  ; Chowning brass: harmonic FM (c:m = 1:1), tongued index, flat sustain
  iRel = min(0.09, p3 * 0.22)
  kAmp linsegr 0, 0.006, 1, max(0.001, p3 - iRel - 0.006), 0.94, iRel, 0
  kIdx linsegr 0, 0.008, 7, 0.05, 2.45, max(p3 - 0.058, 0.01), 2.45

  aSig foscili kAmp * iAmp, iFreq, 1, 1, kIdx, giSine
  out(aSig, aSig)
endin

</CsInstruments>
<CsScore>
; Fanfare-ish test phrase — mid register trumpet
i 1 0.0  0.35 67 0.55
i 1 0.35 0.35 71 0.52
i 1 0.70 0.45 74 0.58
i 1 1.20 0.55 67 0.50
i 1 1.80 0.40 62 0.48
i 1 2.25 0.70 59 0.52
e
</CsScore>
</CsoundSynthesizer>
