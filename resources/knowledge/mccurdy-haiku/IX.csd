; Csound Haiku IX
; Iain McCurdy 2011

<CsoundSynthesizer>

<CsOptions>
-odac -dm0
</CsOptions>

<CsInstruments>
sr           =                44100
ksmps        =                32
nchnls       =                2
0dbfs        =                1

gasendL      init             0
gasendR      init             0 
giwave       ftgen            0, 0, 128, 10, 1, 1/4, 1/16, 1/64
giampscl1    ftgen            0, 0, 20000, -16, 1, 20, 0, 1, 19980, -20, 0.01
             seed             0
             alwayson         "trigger_arpeggio"
             alwayson         "reverb"

             instr            trigger_arpeggio
krate        randomh          0.0005, 0.2, 0.04
ktrig        metro            krate
             schedkwhennamed  ktrig, 0, 0, "arpeggio", 0, 25
             endin

             instr            arpeggio
ibas         random           0, 24
ibas         =                cpsmidinn((int(ibas)*3)+24)
krate        rspline          0.1, 3, 0.3, 0.7
ktrig        metro            krate
kharm1       rspline          1, 14, 0.4, 0.8
kharm2       random           -3, 3
kharm        mirror           kharm1+kharm2, 1, 23
kamp         rspline          0, 0.05, 0.1, 0.2
             schedkwhen       ktrig, 0, 0, "note", 0, 4, ibas*int(kharm), kamp
             endin

             instr            note
aenv         linsegr          0, p3/2, 1, p3/2, 0, p3/2, 0  
iampscl      table            p4, giampscl1
asig         oscili           p5*aenv*iampscl, p4, giwave
adlt         rspline          0.01, 0.1, 0.2, 0.3
adelsig      vdelay           asig, adlt*1000, 0.1*1000
aL,aR        pan2             asig+adelsig, rnd(1)
             outs             aL, aR
gasendL      =                gasendL+aL
gasendR      =                gasendR+aR
             endin

             instr            reverb
aL, aR       reverbsc         gasendL, gasendR, 0.88, 10000
             outs             aL, aR
             clear            gasendL, gasendR
endin

</CsInstruments>

<CsScore>
</CsScore>

</CsoundSynthesizer>
