; Csound Haiku V
; Iain McCurdy 2011

<CsoundSynthesizer>

<CsOptions>
-odac -dm0 -b1000
</CsOptions>

<CsInstruments>
sr              =                44100
ksmps           =                32
nchnls          =                2
0dbfs           =                1

gisine          ftgen            0, 0, 4096, 10, 1
gasendL         init             0
gasendR         init             0
                seed             0
                alwayson         "start_sequences"
                alwayson         "reverb"

                instr            start_sequences
iBaseRate       random           1, 2.5
                event_i          "i", "sound_instr",           0, 3600*24*7, iBaseRate, 0.9, 0.03, 0.06, 7, 0.5, 1
                event_i          "i", "sound_instr", 1/(2*iBaseRate), 3600*24*7, iBaseRate, 0.9, 0.03, 0.06, 7, 0.5, 1
                event_i          "i", "sound_instr", 1/(4*iBaseRate), 3600*24*7, iBaseRate, 0.9, 0.03, 0.06, 7, 0.5, 1
                event_i          "i", "sound_instr", 3/(4*iBaseRate), 3600*24*7, iBaseRate, 0.9, 0.03, 0.06, 7, 0.5, 1
ktrig1          metro            iBaseRate/64
                schedkwhennamed  ktrig1, 0, 0, "sound_instr", 1/iBaseRate, 64/iBaseRate, iBaseRate/16, 0.996, 0.003, 0.01, 3, 0.7, 1
                schedkwhennamed  ktrig1, 0, 0, "sound_instr", 2/iBaseRate, 64/iBaseRate, iBaseRate/16, 0.996, 0.003, 0.01, 4, 0.7, 1
ktrig2          metro            iBaseRate/72
                schedkwhennamed  ktrig2, 0, 0, "sound_instr", 3/iBaseRate, 72/iBaseRate, iBaseRate/20, 0.996, 0.003, 0.01, 5, 0.7, 1
                schedkwhennamed  ktrig2, 0, 0, "sound_instr", 4/iBaseRate, 72/iBaseRate, iBaseRate/20, 0.996, 0.003, 0.01, 6, 0.7, 1
                endin

                instr            sound_instr
ktrig           metro            p4
                if ktrig=1 then
                reinit           PULSE
                endif
PULSE:
ioct            random           7.3, 10.5
icps            init             cpsoct(ioct)
aptr            linseg           0, 1/icps, 1
                rireturn
a1              tablei           aptr, gisine, 1
kamp            rspline          0.2, 0.7, 0.1, 0.8
a1              =                a1*(kamp^3)
kphsoct         rspline          6, 10, p6, p7
isep            random           0.5, 0.75
ksep            transeg          isep+1, 0.02, -50, isep
kfeedback       rspline          0.85, 0.99, 0.01, 0.1
aphs2           phaser2          a1, cpsoct(kphsoct), 0.3, p8, p10, isep, p5
iChoRate        random           0.5,2
aDlyMod         oscili           0.0005,iChoRate,gisine
acho            vdelay3          aphs2+a1, (aDlyMod+0.0005+0.0001)*1000,100
aphs2           sum              aphs2, acho
aphs2           butlp            aphs2, 1000
kenv            linseg           1, p3-4, 1, 4, 0
kpan            rspline          0, 1, 0.1, 0.8
kattrel         linsegr          1, 1, 0
a1, a2          pan2             aphs2*kenv*p9*kattrel, kpan
a1              delay            a1, rnd(0.01)+0.0001
a2              delay            a2, rnd(0.01)+0.0001
ksend           rspline          0.2, 0.7, 0.05, 0.1
ksend           =                ksend^2
                outs             a1*(1-ksend), a2*(1-ksend)
gasendL         =                gasendL+(a1*ksend)
gasendR         =                gasendR+(a2*ksend)
                endin

                instr            reverb
aL, aR          reverbsc         gasendL, gasendR, 0.85, 5000
                outs             aL, aR
                clear            gasendL, gasendR
                endin

</CsInstruments>

<CsScore>
f 0 3600
e
</CsScore>

</CsoundSynthesizer>
