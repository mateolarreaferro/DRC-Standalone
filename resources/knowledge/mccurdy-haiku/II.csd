; Csound Haiku II
; Iain McCurdy 2011

<CsoundSynthesizer>

<CsOptions>
-odac -dm0
</CsOptions>

<CsInstruments>
sr               =                44100
ksmps            =                64
nchnls           =                2
0dbfs            =                1

giampscl         ftgen            0, 0, 20000, -16, 1, 20, 0, 1, 19980, -5, 1
giwave1          ftgen            0,0,131073,9,  6,1,0,    9,1/10,0, 13,1/14,0, 17,1/18,0, 21,1/22,0,  25,1/26,0,  29,1/30,0,  33,1/34,0
giwave2          ftgen            0,0,131073,9,  7,1,0,   10,1/10,0, 14,1/14,0, 18,1/18,0, 22,1/22,0,  26,1/26,0,  30,1/30,0,  34,1/34,0
giwave3          ftgen            0,0,131073,9,  8,1,0,   11,1/10,0, 15,1/14,0, 19,1/18,0, 23,1/22,0,  27,1/26,0,  31,1/30,0,  35,1/34,0
giwave4          ftgen            0,0,131073,9,  9,1,0,   12,1/10,0, 16,1/14,0, 20,1/18,0, 24,1/22,0,  28,1/26,0,  32,1/30,0,  36,1/34,0
giwave5          ftgen            0,0,131073,9, 10,1,0,   13,1/10,0, 17,1/14,0, 21,1/18,0, 25,1/22,0,  29,1/26,0,  33,1/30,0,  37,1/34,0
giwave6          ftgen            0,0,131073,9, 11,1,0,   19,1/10,0, 28,1/14,0, 37,1/18,0, 46,1/22,0,  55,1/26,0,  64,1/30,0,  73,1/34,0
giwave7          ftgen            0,0,131073,9, 12,1/4,0, 25,1,0,    39,1/14,0, 63,1/18,0, 87,1/22,0, 111,1/26,0, 135,1/30,0, 159,1/34,0
giseq            ftgen            0,0,12,-2,      1, 1/3, 1/3, 1/3, 1, 1/3, 1/3, 1/3, 1/2, 1/2, 1/2, 1/2
gidurs           ftgen            0,0,100,-17,      0, 0.4, 50, 0.8, 90, 1.5
gasendL          init             0
gasendR          init             0
gamixL           init             0
gamixR           init             0

girescales       ftgen            0,0,-7,-2,6,7,8,9,10,11,12

                 alwayson         "start_sequences"
                 alwayson         "sound_output"
                 alwayson         "reverb"
                 seed             0
            
                 opcode           tonea,a,aii
                 setksmps         1
ain,icps,iDecay  xin
kcfenv           transeg          icps*4, iDecay, -8, 1, 1, 0, 1
aout             tone             ain, kcfenv
                 xout             aout
                 endop

                 instr            start_sequences
ktrig            metro            1/4
                 schedkwhennamed  ktrig, 0, 0, "play_sequence", 0, 48
                 endin

                 instr            play_sequence
itime_unit       random           2, 5
istart           random           0, 6
iloop            random           6, 13
ktrig_in         init             0
ktrig_out        seqtime          int(itime_unit)/3, int(istart), int(iloop), 0, giseq
inote            random           48, 100
ienvscl          =                ((1-(inote-48)/(100-48))*0.8)+0.2
ienvscl          limit            ienvscl,0.3,1
icps             =                cpsmidinn(int(inote))
ipan             random           0, 1
isend            random           0.3, 0.5
kamp             rspline          0.007, 0.6, 0.05, 0.2
kflam            random           0, 0.02
ifn              random           0, 7
                 schedkwhennamed  ktrig_out, 0, 0, "play_note", kflam, 0.01, icps, ipan, isend, kamp, int(ifn), ienvscl
                 endin

                 instr            play_note
idurndx          random           0, 100
p3               table            idurndx, gidurs                 
ijit             random           0.1, 1
acps             expseg           8000, 0.003, p4, 1, p4
aenv             expsega          0.001, 0.003, ijit^2, (p3-0.2-0.002)*p9, 0.002, 0.2, 0.001, 1, 0.001
adip             transeg          1, p3, 4, 0.99
iampscl          table            p4, giampscl
irescale         table            p8, girescales
idtn             random           0.995,1.005
a1               oscili           p7*aenv*iampscl, (acps*adip*idtn)/(6+irescale), giwave1+p8
adlt             rspline          1, 10, 0.1, 0.2
aramp            linseg           0, 0.02, 1
acho             vdelay           a1*aramp, adlt, 40
icf              random           0, 2
kcfenv           transeg          p4+(p4*icf^3), p9, -8, 1, 1, 0, 1
a1               tonex            a1, kcfenv
a1, a2           pan2             a1,p5
                 outs             a1,a2
gamixL           =                gamixL + a1
gamixR           =                gamixR + a2
gasendL          =                gasendL + (a1*(p6^2))
gasendR          =                gasendR + (a2*(p6^2))
                 endin

                 instr            sound_output
a1,a2            reverbsc         gamixL, gamixR, 0.01, 500
a1               =                a1*100
a2               =                a2*100
a1               atone            a1, 250
a2               atone            a2, 250
                 outs             a1, a2      
                 clear            gamixL, gamixR
                 endin
            
                 instr            reverb
aL, aR           reverbsc         gasendL, gasendR, 0.75, 4000
                 outs             aL, aR
                 clear            gasendL, gasendR
                 endin

</CsInstruments>

<CsScore>
f 0 3600
e
</CsScore>

</CsoundSynthesizer>
