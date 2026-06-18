<CsoundSynthesizer>
<CsOptions>
-odac
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 64
nchnls = 2
0dbfs = 1

instr 1
 out(expon(1, p3, 0.001)*rand(p4))
 schedule(1, 0.1, 0.3, 0.2)
endin
schedule(1,0,0.3,0.2)


</CsInstruments>
<CsScore>

</CsScore>
</CsoundSynthesizer>
