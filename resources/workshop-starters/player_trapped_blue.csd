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
giBuzz ftgen 0, 0, 8192, 9, 1, 1, 90

chn_k "amplitude", 3, 2, 0.4, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "attack", 3, 3, 0.05, 0.001, 2, 0, 0, 0, 0, "unit=s label=Attack"
chn_k "release", 3, 3, 2.5, 0.1, 8, 0, 0, 0, 0, "unit=s label=Release"
chn_k "lfoRate", 3, 2, 19, 1, 40, 0, 0, 0, 0, "unit=Hz label=LFO_Rate"
chn_k "harmonics", 3, 2, 13, 1, 24, 0, 0, 0, 0, "unit= label=Harmonics"
chn_k "sweepRate", 3, 2, 0.21, 0.01, 1, 0, 0, 0, 0, "unit= label=Sweep_Rate"
chn_k "reverbMix", 3, 2, 0.35, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.85, 0.3, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"

chnset 0.4, "amplitude"
chnset 0.05, "attack"
chnset 2.5, "release"
chnset 19, "lfoRate"
chnset 13, "harmonics"
chnset 0.21, "sweepRate"
chnset 0.35, "reverbMix"
chnset 0.85, "reverbSize"

instr 1
  iAtt  chnget "attack"
  iRel  chnget "release"
  kAmp  chnget "amplitude"
  kLfo  chnget "lfoRate"
  iHarm chnget "harmonics"
  iSwp  chnget "sweepRate"
  kAmp  port kAmp, 0.02
  kLfo  port kLfo, 0.02
  kEnv  linsegr 0, iAtt, 1, iAtt * 0.05, 0.7, iRel, 0
  iVel  = p5
  k1    randi 1, 30
  k4    oscil kEnv, kLfo, giSine, 0.2
  k5    = k4 + 2
  k3    linseg 0.005, iAtt * 0.71, 0.015, iRel, 0.01
  kSw   linseg iHarm, iAtt * iSwp, 1, iRel, 1
  aSig  gbuzz kEnv * kAmp * iVel, p4 + k3, k5, kSw, k1, giBuzz
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
