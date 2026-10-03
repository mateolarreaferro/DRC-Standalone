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


giSine  ftgen 0, 0, 1024, 10, 1
giBellIdx ftgen 0, 0, 1024, 5, 1, 1000, 0.01
giWoodIdx ftgen 0, 0, 1024, 8, 0.8, 50, 1, 100, 0.7, 824, 0
giWoodAmp ftgen 0, 0, 512, 7, 1, 100, 0
giBrassEnv ftgen 0, 0, 1024, 7, 0, 100, 1, 124, 0.7, 600, 0.7, 100, 0
giClarEnv ftgen 0, 0, 1024, 7, 0, 100, 1, 824, 1, 100, 0


giFcRatio = 0.45454545454545453
giFmRatio = 0.6363636363636364
giPeak    = 10
giCarAmp  = 0.38


chn_k "amplitude", 3, 2, 0.55, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "reverbMix", 3, 2, 0.28, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.82, 0.5, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"
chnset 0.55, "amplitude"
chnset 0.28, "reverbMix"
chnset 0.82, "reverbSize"

giMaster = 0.28


instr 1
  iFreq = p4
  iVel  = p5 * chnget("amplitude")
  iDur  = p3 < 0 ? 8 : p3
  ifc   = iFreq * giFcRatio
  ifm   = iFreq * giFmRatio
  id    = giPeak * ifm
  iamp  = iVel * giCarAmp
  km    oscil id, 1/iDur, giBellIdx
  kc    oscil iamp, 1/iDur, giBellIdx
  am    oscil km, ifm, giSine
  ac    oscil kc, ifc + am, giSine
  kGate linsegr 1, 0.002, 1, max(iDur - 0.02, 0.02), 0.35, 0.06, 0
  aOut  = tanh(ac * kGate * giMaster * 1.4)
  chnmix aOut, "revL"
  chnmix aOut, "revR"
  outs aOut, aOut
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
