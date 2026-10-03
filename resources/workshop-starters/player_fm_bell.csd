<CsoundSynthesizer>
<CsOptions>
-o dac
-d
--limiter=0.9
</CsOptions>
<CsInstruments>
sr = 44100
ksmps = 64
nchnls = 2
0dbfs = 1

giSine ftgen 0, 0, 16384, 10, 1

chn_k "amplitude", 3, 2, 0.5, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "attack", 3, 3, 0.005, 0.001, 0.05, 0, 0, 0, 0, "unit=s label=Attack"
chn_k "release", 3, 3, 2.5, 0.2, 8, 0, 0, 0, 0, "unit=s label=Release"
chn_k "mod1Depth", 3, 2, 1, 0, 2, 0, 0, 0, 0, "unit= label=Shimmer_1"
chn_k "mod2Depth", 3, 2, 1, 0, 2, 0, 0, 0, 0, "unit= label=Shimmer_2"
chn_k "reverbMix", 3, 2, 0.4, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.92, 0.5, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"

chnset 0.5, "amplitude"
chnset 0.005, "attack"
chnset 2.5, "release"
chnset 1, "mod1Depth"
chnset 1, "mod2Depth"
chnset 0.4, "reverbMix"
chnset 0.92, "reverbSize"

instr 1
  iAtt  chnget "attack"
  iRel  chnget "release"
  kAmp  chnget "amplitude"
  kM1   chnget "mod1Depth"
  kM2   chnget "mod2Depth"
  kAmp  port kAmp, 0.02
  kM1   port kM1, 0.02
  kM2   port kM2, 0.02
  kEnv  linsegr 0, iAtt, 1, iAtt + 0.05, 0.7, iRel, 0
  iVel  = p5

  kMod1Idx = 3.5 * kEnv * kM1
  aMod1 oscili kMod1Idx * p4, p4 * 3.5, giSine

  kMod2Idx = 2.1 * kEnv * kM2
  aMod2 oscili kMod2Idx * p4, p4 * 5.2, giSine

  aSig oscili kEnv * kAmp * iVel * 0.6, p4 + aMod1 + aMod2, giSine

  chnmix aSig, "revL"
  chnmix aSig, "revR"
  outs aSig, aSig
endin

instr 100
  Schan strget p4
  iVal  = p5
  chnset iVal, Schan
  turnoff
endin

instr 99
  kMix  chnget "reverbMix"
  kSize chnget "reverbSize"
  aInL  chnget "revL"
  aInR  chnget "revR"
  aL, aR reverbsc aInL, aInR, kSize, 9000
  outs  aL * kMix, aR * kMix
  chnclear "revL"
  chnclear "revR"
endin
</CsInstruments>
<CsScore>
i 99 0 36000
f 0 36000
</CsScore>
</CsoundSynthesizer>
