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

gaEcho init 0

chn_k "amplitude", 3, 2, 0.6, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "attack", 3, 3, 0.001, 0.0005, 0.05, 0, 0, 0, 0, "unit=s label=Attack"
chn_k "release", 3, 3, 0.3, 0.05, 2, 0, 0, 0, 0, "unit=s label=Release"
chn_k "fmIndex", 3, 2, 8, 0, 20, 0, 0, 0, 0, "unit= label=FM_Index"
chn_k "echoSend", 3, 2, 0.4, 0, 1, 0, 0, 0, 0, "unit= label=Echo_Send"

chnset 0.6, "amplitude"
chnset 0.001, "attack"
chnset 0.3, "release"
chnset 8, "fmIndex"
chnset 0.4, "echoSend"

instr 1
  iAtt  chnget "attack"
  iRel  chnget "release"
  kAmp  chnget "amplitude"
  kFm   chnget "fmIndex"
  kEcho chnget "echoSend"
  kAmp  port kAmp, 0.02
  kFm   port kFm, 0.02
  kEcho port kEcho, 0.02
  kEnv  linsegr 0, iAtt, 1, iAtt + 0.02, 0.6, iRel, 0
  iVel  = p5
  kModIndex = kEnv * kFm
  aFM  foscili kEnv * kAmp * iVel, p4, 1, 2.01, kModIndex, 1
  aFat butterlp aFM, p4 * 6
  gaEcho += aFat * kEcho
  outs aFat, aFat
endin

instr 100
  Schan strget p4
  iVal  = p5
  chnset iVal, Schan
  turnoff
endin

instr 99
aDelL = vdelay3(gaEcho, 280, 1000)
aDelR = vdelay3(gaEcho, 420, 1000)
aFbL = vdelay3(aDelR*0.38, 280, 1000)
aFbR = vdelay3(aDelL*0.4, 420, 1000)
aEchoL = gaEcho*0.6 + (aDelL + aFbL)*0.6
aEchoR = gaEcho*0.6 + (aDelR + aFbR)*0.6
outs aEchoL, aEchoR
clear gaEcho
endin
</CsInstruments>
<CsScore>
f 1 0 16384 10 1
i 99 0 36000
f 0 36000
</CsScore>
</CsoundSynthesizer>
