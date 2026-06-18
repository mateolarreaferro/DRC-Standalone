; Csound Haiku VII
; Iain McCurdy 2011

<CsoundSynthesizer>

<CsOptions>
-odac -dm0
</CsOptions>                                 

<CsInstruments>
sr            =                44100
ksmps         =                32
nchnls        =                2
0dbfs         =                1

giampscl      ftgen            0, 0, 20000, -16, 1, 20, 0, 1, 19980, -30, 0.1
giwave        ftgen            0, 0, 4097, 9, 3, 1, 0, 10,1/10,0, 18,1/14,0, 26,1/18,0, 34,1/22,0, 42,1/26,0, 50,1/30,0, 58,1/34,0
gicos         ftgen            0, 0, 131072, 11, 1
giseq         ftgen            0, 0, 12, -2, 3/2, 2, 3, 1, 1, 3/2, 1/2, 3/4, 5/2, 2/3, 2, 1
gasendL       init             0
gasendR       init             0
              seed             0
              alwayson         "trigger_sequence"
              alwayson         "reverb"

              instr            trigger_sequence
ktrig         metro            0.2
              schedkwhennamed  ktrig,0,0,"trigger_notes",0,30
kcrossfade    rspline          0, 1, 0.01, 0.1
gkcrossfade   =                kcrossfade^3
              endin

              instr            trigger_notes
itime_unit    random           2, 10
istart        random           0, 6
iloop         random           6, 13
ktrig_out     seqtime          int(itime_unit), int(istart), int(iloop), 0, giseq
idur          random           8, 15
inote         random           0, 48
inote         =                (int(inote))+36
kSemiDrop     line             rnd(2), p3, -rnd(2)
kcps          =                cpsmidinn(inote+int(kSemiDrop))
ipan          random           0, 1
isend         random           0.05, 0.2
kflam         random           0, 0.02
kamp          rspline          0.008, 0.4, 0.05, 0.2
ioffset       random           -0.2, 0.2
kattlim       rspline          0, 1, 0.01, 0.1
              schedkwhennamed  ktrig_out, 0, 0, "long_bell", kflam, idur, kcps*semitone(ioffset), ipan, isend, kamp
              event_i          "i", "gbuzz_long_note", 0, 30, cpsmidinn(inote+19)
              endin

              instr            long_bell
acps          transeg          1, p3, 3, 0.95
iattrnd       random           0, 1
iatt          =                (iattrnd>(p8^1.5)?0.002:p3/2)
aenv          expsega          0.001, iatt, 1, p3-0.2-iatt, 0.002, 0.2, 0.001
aperc         expseg           10000, 0.003, p4, 1, p4
iampscl       table            p4, giampscl
ijit          random           0.5, 1
a1            oscili           p7*aenv*iampscl*ijit*(1-gkcrossfade), (acps*aperc                   )/2, giwave
a2            oscili           p7*aenv*iampscl*ijit*(1-gkcrossfade), (acps*aperc*semitone(rnd(.02)))/2, giwave
adlt          rspline          1, 5, 0.4, 0.8
acho          vdelay           a1, adlt, 40
a1            =                a1-acho
acho          vdelay           a2, adlt, 40
a2            =                a2-acho
icf           random           0, 1.75
icf           =                p4+(p4*(icf^3))
kcfenv        expseg           icf, 0.3, icf, p3-0.3, 20
a1            butlp            a1, kcfenv
a2            butlp            a2, kcfenv
a1            butlp            a1, kcfenv
a2            butlp            a2, kcfenv
              outs             a1, a2
gasendL       =                gasendL+(a1*p6)
gasendR       =                gasendR+(a2*p6)
              endin

              instr            gbuzz_long_note
kenv          expseg           0.001, 3, 1, p3-3, 0.001
kmul          rspline          0.01, 0.1, 0.1, 1
kNseDep       rspline          0,1,0.2,0.4
kNse          jspline          kNseDep,50,100
agbuzz        gbuzz            gkcrossfade/80, p4/2*semitone(kNse), 5, 1, kmul*kenv, gicos
a1            delay            agbuzz, rnd(0.08)+0.001
a2            delay            agbuzz, rnd(0.08)+0.001
gasendL       =                gasendL+(a1*kenv)
gasendR       =                gasendR+(a2*kenv)
              endin

              instr            reverb
aL,aR         reverbsc         gasendL, gasendR, 0.95, 10000
              outs             aL, aR
              clear            gasendL, gasendR
endin

</CsInstruments>

<CsScore>
f 0 3600
e
</CsScore>

</CsoundSynthesizer>
