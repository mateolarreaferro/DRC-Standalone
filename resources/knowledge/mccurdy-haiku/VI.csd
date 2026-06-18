; Csound Haiku V
; Iain McCurdy 2011

<CsoundSynthesizer>

<CsOptions>
-odac -dm0
</CsOptions>

<CsInstruments>
sr              =             44100
ksmps           =             32
nchnls          =             2
0dbfs           =             1

gasendL         init          0
gasendR         init          0
                seed          0
                alwayson     "trigger_6_notes_and_plucks"
                alwayson     "reverb"
          
                instr         trigger_6_notes_and_plucks
                event_i       "i", "string", 0, 60*60*24*7, 40
                event_i       "i", "string", 0, 60*60*24*7, 45
                event_i       "i", "string", 0, 60*60*24*7, 50                                                                                  
                event_i       "i", "string", 0, 60*60*24*7, 55        
                event_i       "i", "string", 0, 60*60*24*7, 59
                event_i       "i", "string", 0, 60*60*24*7, 64
krate           rspline       0.005, 0.15, 0.1, 0.2
ktrig           metro         krate
                if ktrig==1 then
                reinit        update
                endif     
update:
aenv            expseg        0.0001, 0.02, 1, 0.2, 0.0001, 1, 0.0001
apluck          pinkish       aenv
                rireturn     
koct            randomi       5, 10, 2
gapluck         butlp         apluck, cpsoct(koct)
endin

                instr         string
adlt            rspline       50, 250, 0.03, 0.06
apluck          vdelay3       gapluck, adlt, 500
adtn            jspline       15, 0.002, 0.02
astring         wguide1       apluck, cpsmidinn(p4)*semitone(adtn), 5000, 0.9995
astring         dcblock       astring
kpan            rspline       0, 1, 0.1, 0.2
astrL, astrR    pan2          astring, kpan
                outs          astrL, astrR
gasendL         =             gasendL+(astrL*0.6)
gasendR         =             gasendR+(astrR*0.6)
                endin

                instr         reverb
aL, aR          reverbsc      gasendL, gasendR, 0.85, 10000
                outs          aL, aR
                clear         gasendL, gasendR
                endin

</CsInstruments>

<CsScore>
f 0 3600
e
</CsScore>

</CsoundSynthesizer>
