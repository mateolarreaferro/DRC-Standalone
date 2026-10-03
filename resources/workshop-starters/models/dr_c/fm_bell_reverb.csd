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

giSine ftgen 0, 0, 8192, 10, 1

chn_k "amplitude", 3, 2, 0.5, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "modRatio", 3, 2, 1.4, 0.5, 4, 0, 0, 0, 0, "unit= label=Mod_Ratio"
chn_k "fmIndex", 3, 2, 10, 1, 20, 0, 0, 0, 0, "unit= label=FM_Index"
chn_k "reverbMix", 3, 2, 0.4, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.88, 0.5, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"

chnset 0.5, "amplitude"
chnset 1.4, "modRatio"
chnset 10, "fmIndex"
chnset 0.4, "reverbMix"
chnset 0.88, "reverbSize"

instr 1
  iFreq = p4
  iVel  = p5
  iAmp  = chnget("amplitude") * iVel
  iPeak = chnget("fmIndex")
  iMod  = chnget("modRatio")

  kAmpEnv expseg iAmp, 0.002, iAmp, max(p3 - 0.002, 0.01), 0.0001
  kIdx    expseg iPeak, 0.005, iPeak, p3 * 0.3, iPeak * 0.15, max(p3 * 0.7 - 0.005, 0.01), 0.3

  aOut  foscili kAmpEnv, iFreq, 1, iMod, kIdx, giSine
  aOut2 foscili kAmpEnv * 0.7, iFreq * 1.003, 1, iMod, kIdx * 0.95, giSine
  aL = aOut * 0.7 + aOut2 * 0.3
  aR = aOut * 0.3 + aOut2 * 0.7

  outs aL, aR
  chnmix aL, "revL"
  chnmix aR, "revR"
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
  aL, aR reverbsc aInL, aInR, kSize, 8000
  outs aL * kMix, aR * kMix
  chnclear "revL"
  chnclear "revR"
endin
</CsInstruments>
<CsScore>
i 99 0 36000
f 0 36000
</CsScore>
</CsoundSynthesizer>
