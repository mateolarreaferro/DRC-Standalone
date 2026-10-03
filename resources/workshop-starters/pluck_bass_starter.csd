<CsoundSynthesizer>
<CsOptions>
-n -d -m0 -o /tmp/lac-pluck-bass.wav
--limiter=0.9
</CsOptions>
<CsInstruments>
sr = 44100
ksmps = 32
nchnls = 2
0dbfs = 1

gaEcho init 0

instr 1
iFreq = cpsmidinn(p4)
iAmp = 0.6

kCarEnv = expsegr(1, 0.001, 1, 0.2, 0.0001)
kModEnv = expsegr(1, 0.0005, 0.3, 0.08, 0.01, 0.3, 0.0001)
kModIndex = kModEnv * 8
aFM = foscili(kCarEnv * iAmp, iFreq, 1, 2.01, kModIndex, 1)
aFat = butterlp(aFM, iFreq*6)

gaEcho += aFat * 0.4
out aFat, aFat
endin

instr 99
aDelL = vdelay3(gaEcho, 280, 1000)
aDelR = vdelay3(gaEcho, 420, 1000)
aFbL = vdelay3(aDelR*0.38, 280, 1000)
aFbR = vdelay3(aDelL*0.4, 420, 1000)
aEchoL = gaEcho*0.6 + (aDelL + aFbL)*0.6
aEchoR = gaEcho*0.6 + (aDelR + aFbR)*0.6
out aEchoL, aEchoR
clear gaEcho
endin

</CsInstruments>
<CsScore>
f 1 0 16384 10 1
i 99 0 10

i 1 0 1.5 36
i 1 1 1.5 43
i 1 2 1.5 48
i 1 3 2 36

e
</CsScore>
</CsoundSynthesizer>
