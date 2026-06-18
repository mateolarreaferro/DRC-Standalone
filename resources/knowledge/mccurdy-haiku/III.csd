; Csound Haiku III
; Iain McCurdy 2011

<CsoundSynthesizer>

<CsOptions>
-odac -dm0
</CsOptions>                                  

<CsInstruments>
                                                
sr                =                44100
ksmps             =                32
nchnls            =                2             
0dbfs             =                1

giImpulseWave     ftgen            0,0,4097,10,1,1/2,1/4,1/8
gamixL,gamixR,gasendL,gasendR      init          0     
                  seed             0
gitims            ftgen            0, 0, 128, -7, 1, 100, 0.1
                  alwayson         "start_sequences"
                  alwayson         "spatialise"
                  alwayson         "reverb"
     
                  instr            start_sequences
krate             rspline          0, 1, 0.1, 2
krate             scale            krate^2,10,0.3
ktrig             metro            krate
koct              rspline          4.3, 9.5, 0.1, 1
kcps              =                cpsoct(koct)
kpan              rspline          0.1, 4, 0.1, 1
kamp              rspline          0.1, 1, 0.25, 2
kwgoct1           rspline          6, 9, 0.05, 1
kwgoct2           rspline          6, 9, 0.05, 1
                  schedkwhennamed  ktrig, 0, 0, "wguide2_note", 0, 4, kcps, kwgoct1, kwgoct2, kamp, kpan
                  endin

                  instr            wguide2_note
aenv              expon            1,10/p4,0.001
aimpulse          poscil           aenv-0.001,p4,giImpulseWave
ioct1             random           5, 11
ioct2             random           5, 11
aplk1             transeg          1+rnd(0.2), 0.1, -15, 1
aplk2             transeg          1+rnd(0.2), 0.1, -15, 1
idmptim           random           0.1, 3
kcutoff           expseg           20000, p3-idmptim, 20000, idmptim, 200, 1, 200
awg2              wguide2          aimpulse, cpsoct(p5)*aplk1, cpsoct(p6)*aplk2, kcutoff, kcutoff, 0.27, 0.23
awg2              dcblock2         awg2
arel              linseg           1, p3-idmptim, 1, idmptim, 0
awg2              =                awg2*arel
awg2              =                awg2/(rnd(4)+3)
aL,aR             pan2             awg2,p8
gasendL           =                gasendL+(aL*0.05)
gasendR           =                gasendR+(aR*0.05)
gamixL            =                gamixL+aL
gamixR            =                gamixR+aR
                  endin

                  instr            spatialise
adlytim1          rspline          0.1, 5, 0.1, 0.4
adlytim2          rspline          0.1, 5, 0.1, 0.4
aL                vdelay           gamixL, adlytim1, 50
aR                vdelay           gamixR, adlytim2, 50
                  outs             aL, aR
gasendL           =                gasendL+(aL*0.05)
gasendR           =                gasendR+(aR*0.05)
                  clear            gamixL, gamixR
endin

                  instr            reverb
aL, aR            reverbsc         gasendL, gasendR, 0.95, 10000
                  outs             aL, aR
                  clear            gasendL, gasendR
                  endin

</CsInstruments>

<CsScore>
f 0 3600
e
</CsScore>

</CsoundSynthesizer>
