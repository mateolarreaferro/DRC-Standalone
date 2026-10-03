<CsoundSynthesizer>
<CsOptions>
-d -o dac
</CsOptions>
<CsInstruments>

instr 1
k1 expon p4,p3/p6,p4*0.001
a1 oscil3 k1, p5*(1+log(p6)), 1
out a1
if p6 < p7 then
iharm = p6+1
event_i "i",p1,0,p3,(0dbfs*0.2)/iharm,p5,iharm,p7
endif
endin

</CsInstruments>
<CsScore>
f 1 0 32768 10 1
i1 0 2 10000 200 1 100
i1 1 2 10000 250 1 100
i1 2 2 10000 310 1 100
i1 3 2 10000 80 1 100
</CsScore>
</CsoundSynthesizer>

Dr Victor Lazzarini
Senior Lecturer
Dept. of Music
NUI Maynooth Ireland
tel.: +353 1 708 3545
Victor dot Lazzarini AT nuim dot ie
