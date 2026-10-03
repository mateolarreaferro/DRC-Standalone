<CsoundSynthesizer>
<CsOptions>
-n -d -m0 -o /tmp/drc-fm-woodblock-midi.wav
-+rtmidi=NULL
-M0
--midi-key-cps=4
--midi-velocity-amp=5
--limiter=0.9
</CsOptions>
<CsInstruments>
sr = 44100
ksmps = 32
nchnls = 2
0dbfs = 1

massign 0, 1

instr 1
  iFreq = cpsmidinn(p4)
  iAmp  = p5
  kc1   = 5
  kc2   expsegr 5, 0.002, 4.2, 0.07, 0.75, 0.015, 0.75
  aSig  fmpercfl iAmp * 0.55, iFreq, kc1, kc2, 0.01, 9
  outs  aSig, aSig
endin
</CsInstruments>
<CsScore>
i 1 0.00 0.18 79 0.90
i 1 0.20 0.16 81 0.85
i 1 0.40 0.18 79 0.88
i 1 0.60 0.16 84 0.82
i 1 0.80 0.18 79 0.90
i 1 1.00 0.16 81 0.85
i 1 1.20 0.18 86 0.80
i 1 1.40 0.16 79 0.88
i 1 1.60 0.18 81 0.85
i 1 1.80 0.16 84 0.82
i 1 2.00 0.18 88 0.78
i 1 2.20 0.16 79 0.90
i 1 2.40 0.18 81 0.85
i 1 2.60 0.16 84 0.82
i 1 2.80 0.18 79 0.88
i 1 3.00 0.16 81 0.85
i 1 3.20 0.18 86 0.80
i 1 3.40 0.16 79 0.88
i 1 3.60 0.18 81 0.85
i 1 3.80 0.16 84 0.82
i 1 4.20 0.20 79 0.85
i 1 4.40 0.20 81 0.80
i 1 4.60 0.20 84 0.78
i 1 4.80 0.20 88 0.75
i 1 5.40 1.20 79 0.70
i 1 5.40 1.20 81 0.68
i 1 5.40 1.20 84 0.65
</CsScore>
</CsoundSynthesizer>
