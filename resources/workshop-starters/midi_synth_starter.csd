<CsoundSynthesizer>
<CsOptions>
-n -d -m0 -+rtmidi=NULL -M0 --midi-key-cps=4 --midi-velocity-amp=5
--limiter=0.9
</CsOptions>
<CsInstruments>
sr = 44100
ksmps = 32
nchnls = 2
0dbfs = 1

chn_k "cutoff", 1
chn_k "res", 1
chn_k "volume", 1

chnset 2000, "cutoff"
chnset 0.3, "res"
chnset 0.7, "volume"

instr 1
  iFreq = p4
  iAmp  = p5
  kCut  chnget "cutoff"
  kCut  port kCut, 0.05
  kRes  chnget "res"
  kVol  chnget "volume"
  kEnv  madsr 0.01, 0.1, 0.7, 0.3
  aOsc  vco2 iAmp * kEnv * kVol, iFreq, 0
  aFilt moogladder aOsc, kCut, kRes
  out(aFilt, aFilt)
endin
</CsInstruments>
<CsScore>
f0 z
</CsScore>
</CsoundSynthesizer>
