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

gisine ftgen 0, 0, 4096, 10, 1

chn_k "amplitude", 3, 2, 0.6, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "filterRes", 3, 2, 0.8, 0.2, 1, 0, 0, 0, 0, "unit= label=Filter_Res"
chn_k "reverbMix", 3, 2, 0.35, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.88, 0.5, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"

chnset 0.6, "amplitude"
chnset 0.8, "filterRes"
chnset 0.35, "reverbMix"
chnset 0.88, "reverbSize"

instr 1
  iFreq = p4
  iVel  = p5
  kAmp  chnget "amplitude"
  kRes  chnget "filterRes"

  aOsc1 poscil 0.6, iFreq * 0.998, gisine
  aOsc2 poscil 0.6, iFreq * 1.002, gisine
  aMix  = (aOsc1 + aOsc2) * 0.5

  kEnvAmp  linsegr 0, 0.01, 1, max(p3 - 0.02, 0.01), 0.8, 0.01, 0
  kEnvFilt linsegr 0.001, 0.05, 1, max(p3 - 0.1, 0.01), 0.5, 0.05, 0.001
  kFiltCutoff = (kEnvFilt * 0.8 + 0.2) * (iFreq * 4) + 100

  aFilt moogladder aMix * kEnvAmp * kAmp * iVel, kFiltCutoff, kRes
  aL, aR pan2 aFilt, 0.5
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
