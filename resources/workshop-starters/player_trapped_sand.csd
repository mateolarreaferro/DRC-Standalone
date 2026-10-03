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

giW1 ftgen 0, 0, 512, 10, 10, 8, 0, 6, 0, 4, 0, 1
giW2 ftgen 0, 0, 512, 10, 10, 0, 5, 5, 0, 4, 3, 0, 1
giW3 ftgen 0, 0, 2048, 10, 10, 0, 9, 0, 0, 8, 0, 7, 0, 4, 0, 2, 0, 1
giW4 ftgen 0, 0, 512, 10, 10, 0, 5, 5, 0, 4, 3, 0, 1

gadel init 0

chn_k "amplitude", 3, 2, 0.4, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "attack", 3, 3, 0.1, 0.001, 2, 0, 0, 0, 0, "unit=s label=Attack"
chn_k "release", 3, 3, 2, 0.1, 8, 0, 0, 0, 0, "unit=s label=Release"
chn_k "delaySend", 3, 2, 0.2, 0, 1, 0, 0, 0, 0, "unit= label=Delay_Send"
chn_k "randAmp", 3, 2, 4.5, 0, 12, 0, 0, 0, 0, "unit= label=Rand_Amp"
chn_k "randFreq", 3, 2, 289, 20, 800, 0, 0, 0, 0, "unit=Hz label=Rand_Freq"
chn_k "reverbMix", 3, 2, 0.35, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.88, 0.3, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"

chnset 0.4, "amplitude"
chnset 0.1, "attack"
chnset 2, "release"
chnset 0.2, "delaySend"
chnset 4.5, "randAmp"
chnset 289, "randFreq"
chnset 0.35, "reverbMix"
chnset 0.88, "reverbSize"

instr 1
  iAtt  chnget "attack"
  iRel  chnget "release"
  kAmp  chnget "amplitude"
  kDly  chnget "delaySend"
  kRa   chnget "randAmp"
  kRf   chnget "randFreq"
  kAmp  port kAmp, 0.02
  kDly  port kDly, 0.02
  kRa   port kRa, 0.02
  kRf   port kRf, 0.02
  kEnv  linsegr 0, iAtt, 1, iAtt * 0.1, 0.85, iRel, 0
  iVel  = p5
  k2    randh kRa, kRf, 0.1
  k3    randh kRa * 0.98, kRf * 0.91, 0.2
  k4    randh kRa * 1.2, kRf * 0.96, 0.3
  k5    randh kRa * 0.9, kRf * 1.3
  a1    oscil kEnv * kAmp * iVel, p4 + k2, giW1, 0.2
  a2    oscil kEnv * kAmp * iVel * 0.91, p4 + 0.004 + k3, giW2, 0.3
  a3    oscil kEnv * kAmp * iVel * 0.85, p4 + 0.006 + k4, giW3, 0.5
  a4    oscil kEnv * kAmp * iVel * 0.95, p4 + 0.009 + k5, giW4, 0.8
  amix  = a1 + a2 + a3 + a4
  gadel = gadel + amix * kDly
  chnmix amix, "revL"
  chnmix amix, "revR"
  outs a1 + a3, a2 + a4
endin

instr 98
  asig delay gadel, 0.08
  outs asig, asig
  gadel = 0
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
i 98 0 36000
i 99 0 36000
f 0 36000
</CsScore>
</CsoundSynthesizer>
