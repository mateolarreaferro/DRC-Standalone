; Csound Haiku I
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

                seed            0
gicos           ftgen           0,0,131072,11,1
gasendL,gasendR init            0
                                 
                event_i         "i", "start_long_notes", 0, 0
                alwayson        "reverb"

                instr           start_long_notes
                event_i         "i","trombone",0,60*60*24*7
                event_i         "i","trombone",1,60*60*24*7
                event_i         "i","trombone",2,60*60*24*7
                event_i         "i","trombone",3,60*60*24*7
                event_i         "i","trombone",4,60*60*24*7
                event_i         "i","trombone",5,60*60*24*7
                endin

                instr           trombone
inote           random          54,66
knote           init            int(inote)
ktrig           metro           0.015
                if ktrig==1 then
                reinit          retrig
                endif
retrig:
inote1          init            i(knote)
inote2          random          54, 66
inote2          =               int(inote2)
inotemid        =               inote1+((inote2-inote1)/2)
idur            random          22.5,27.5
icurve          =               2
                timout          0,idur,skip
knote           transeg         inote1,idur/2,icurve,inotemid,idur/2,-icurve,inote2     
skip:
                rireturn
kenv            linseg          0,25,0.05,p3-50,0.05,25,0
kdtn            jspline         0.05,0.4,0.8     
kmul            rspline         0.3,0.82,0.04,0.2
kamp            rspline         0.02,3,0.05,0.1
a1              gbuzz           kenv*kamp,cpsmidinn(knote)*semitone(kdtn),75,1,kmul^1.75,gicos
kpan            rspline         0,1,0.1,1
a1, a2          pan2            a1,kpan
                outs            a1,a2
gasendL         =               gasendL+a1
gasendR         =               gasendR+a2
                endin

                instr           reverb
aL, aR          reverbsc        gasendL,gasendR,0.85,10000
                outs            aL,aR
                clear           gasendL, gasendR
                endin
          
</CsInstruments>

<CsScore>
f 0 [60*60*24*7]
</CsScore>

</CsoundSynthesizer>
