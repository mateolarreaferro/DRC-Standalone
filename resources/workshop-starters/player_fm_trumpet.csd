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

giSine ftgen 0, 0, 4096, 10, 1

chn_k "amplitude", 3, 2, 0.55, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "attack", 3, 3, 0.008, 0.001, 0.05, 0, 0, 0, 0, "unit=s label=Attack"
chn_k "release", 3, 3, 0.14, 0.03, 0.8, 0, 0, 0, 0, "unit=s label=Release"
chn_k "peakIndex", 3, 2, 7, 1, 14, 0, 0, 0, 0, "unit= label=FM_Brightness"
chn_k "modRatio", 3, 2, 1, 0.5, 2, 0, 0, 0, 0, "unit= label=Mod_Ratio"
chn_k "reverbMix", 3, 2, 0.22, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.75, 0.5, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"

chnset 0.55, "amplitude"
chnset 0.008, "attack"
chnset 0.14, "release"
chnset 7, "peakIndex"
chnset 1, "modRatio"
chnset 0.22, "reverbMix"
chnset 0.75, "reverbSize"

instr 1
  iAtt     chnget "attack"
  iRel     chnget "release"
  iPeak    chnget "peakIndex"
  iIdxDrop = min(0.065, max(0.035, iAtt * 2.5))
  kAmp     chnget "amplitude"
  kRatio   chnget "modRatio"
  kAmp     port kAmp, 0.02
  kRatio   port kRatio, 0.02
  kEnv     linsegr 0, iAtt, 1, iAtt + 0.015, 0.92, iRel, 0
  iVel     = p5
  kIdx     linsegr 0, 0.006, iPeak, iIdxDrop, iPeak * 0.34, max(p3 - iIdxDrop - 0.006, 0.01), iPeak * 0.34
  aSig     foscili kEnv * kAmp * iVel, p4, 1, kRatio, kIdx, giSine
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
