; Csound Haiku VIII
; Iain McCurdy 2011

<CsoundSynthesizer>

<CsOptions>
-odac -dm0
</CsOptions>

<CsInstruments>
sr              =               44100
ksmps           =               32
nchnls          =               2
0dbfs           =               1

gigaps          ftgen           0, 0, 100, -17, 0,32, 5,2, 45,1/2, 70,1/8, 90,2/9
gidurs          ftgen           0, 0, 100, -17, 0,0.4, 85,4
giwave          ftgen           0, 0, 131072, 10, 1, 0, 0, 0, 0.05
gisine          ftgen           0, 0, 4096, 10, 1
gasendL         init            0
gasendR         init            0
                seed            0
                event_i         "i","start_layers",0,0
                alwayson        "reverb"

                instr           start_layers
                event_i         "i", "layer", 0, 3600*24*7
                event_i         "i", "layer", 0, 3600*24*7
                event_i         "i", "layer", 0, 3600*24*7
                endin

                instr           layer
kndx            randomh         0, 1, 1
kgap            table           kndx, gigaps, 1
ktrig           metro           1/kgap
knote           randomh         0, 12, 0.1
kamp            rspline         0, 0.1, 1, 2
kpan            rspline         0.1, 0.9, 0.1, 1
kmul            rspline         0.1, 0.9, 0.1, 0.3
                schedkwhen      ktrig, 0, 0, "note", rnd(0.1), 0.01, int(knote)*3, kamp, kpan, kmul
                endin

                instr           note
iratio          =               int(rnd(20))+1
p3              table           rnd(1), gidurs, 1
aenv            expseg          1, p3, 0.001
aperc           expseg          5, 0.001, 1, 1, 1
iprob           random          0, 1
                if iprob<=0.1   then
irange          random          -8, 4
icurve          random          -4, 4
abend           linseg          1, p3, semitone(irange)
aperc           =               aperc*abend
                endif
kmul            expon           abs(p7), p3, 0.0001
a1              gbuzz           p5*aenv, cpsmidinn(p4)*iratio*aperc, int(rnd(500))+1, rnd(12)+1, kmul, giwave
iprob2          random          0,1
                if iprob2<=0.2&&p3>1 then
kfshift         transeg         0, p3, -15, rnd(200)-100
ar,ai           hilbert         a1
asin            oscili          1, kfshift, gisine, 0
acos            oscili          1, kfshift, gisine, 0.25
amod1           =               ar*acos
amod2           =               ai*asin
a1              =               ((amod1-amod2)/3)+a1
                endif
a1              butlp           a1, cpsoct(rnd(8)+4)
a1,a2           pan2            a1, p6
a1              delay           a1, rnd(0.03)+0.001
a2              delay           a2, rnd(0.03)+0.001
                outs            a1, a2
gasendL         =               gasendL+a1*0.3
gasendR         =               gasendR+a2*0.3
                endin

                instr           reverb
aL,aR           reverbsc        gasendL, gasendR, 0.75, 10000
                outs            aL, aR
                clear           gasendL, gasendR
                endin

</CsInstruments>

<CsScore>
</CsScore>

</CsoundSynthesizer>
