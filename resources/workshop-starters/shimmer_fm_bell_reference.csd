<CsoundSynthesizer>
<CsOptions>
-odac -d -m0
--limiter=0.9
</CsOptions>
<CsInstruments>
sr = 44100
ksmps = 32
nchnls = 2
0dbfs = 1

chnset 0.7, "masterVolume"
chnset 0.4, "reverbMix"

giSine ftgen 0, 0, 16384, 10, 1

gaRvbL init 0
gaRvbR init 0

instr 1
  iFreq = cpsmidinn(p4)
  iAmp = p5
  iRvb = p6

  kEnv expsegr 1, 0.001, 0.8, 0.3, 0.4, 2.5, 0.001, 0.001, 0.001

  kMod1Idx = 3.5 * kEnv
  aMod1 oscili kMod1Idx * iFreq, iFreq * 3.5, giSine

  kMod2Idx = 2.1 * kEnv
  aMod2 oscili kMod2Idx * iFreq, iFreq * 5.2, giSine

  aSig oscili kEnv * iAmp * 0.6, iFreq + aMod1 + aMod2, giSine

  aL, aR pan2 aSig, 0.5

  gaRvbL = gaRvbL + aL * iRvb
  gaRvbR = gaRvbR + aR * iRvb

  outs aL, aR
endin

instr 99
  kMasterVol = portk(chnget:k("masterVolume"), 0.05)
  kRvbMix = portk(chnget:k("reverbMix"), 0.05)

  aWetL, aWetR reverbsc gaRvbL, gaRvbR, 0.92, 9000
  outs aWetL * kRvbMix * kMasterVol, aWetR * kRvbMix * kMasterVol

  clear gaRvbL, gaRvbR
endin

</CsInstruments>
<CsScore>
i 99 0 60

i 1 0   4.5  72 0.5 0.5
i 1 1.5 4.0  69 0.4 0.5
i 1 3   3.5  67 0.45 0.5
i 1 4.5 5.0  64 0.5 0.6
i 1 6   4.5  60 0.55 0.6
i 1 8   5.0  67 0.35 0.5
i 1 8.1 5.0  71 0.3  0.5
i 1 8.2 5.0  74 0.32 0.5
i 1 12  6.0  48 0.6 0.7

e
</CsScore>
</CsoundSynthesizer>
