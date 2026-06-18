<CsoundSynthesizer>
<CsInstruments>
;sr             =         44100
; kr             =         44100
; ksmps          =         1
 
                instr 1
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ; BASSLINE ROLAND TB-303 EMULATOR
 ; CODED BY JOSEP Mª COMAJUNCOSAS
 ; Sept - Nov 1997
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
 ; INITIAL SETTINGS; CONTROL THE OVERAL CHARACTER OF THE SOUND
 
 itranspose     init      0              ; 1 raise the whole seq. 1 octave, etc.
 imaxfreq       =         1000           ; max.filter cutoff freq. when ienvmod = 0
 imaxsweep      =         10000          ; sr/2... max.filter freq. at kenvmod & kaccent= 1
 imaxamp        =         20000          ; maximum amplitude. Max 32768 for 16 bit output
 ireson         =         1              ;scale the resonance as you like (you can make the filter to oscillate...)
 
 ; INIT VARIABLES; DON´T TOUCH THIS!
 ibpm           =         p14                                ; 4/4 bars per minute (or beats?)
 inotedur       =         15/ibpm
 icount         init      0                                  ; sequence counter (for notes)
 icount2        init      0                                  ; id. for durations
 ipcount2       init      0
 idecaydur      =         inotedur
 imindecay      =         (idecaydur<.2 ? .2 : idecaydur)    ; set minimum decay to .2 or inotedur
 ipitch         table     0,4; first note in the sequence
 ipitch         =         cpspch(itranspose + 6 + ipitch/100)
 kaccurve       init      0
 
 ; TWISTING THE KNOBS FROM THE SCORE
 kfco           line      p4, p3, p5
 kres           line      p6, p3, p7
 kenvmod        line      p8, p3, p9
 kdecay         line      p10, p3, p11
 kaccent        line      p12, p3, p13
 
 start:
 ; PITCH FROM THE SEQUENCE + PORTAMENTO
 ippitch        =         ipitch
 ipitch         table     ftlen(4)*frac(icount/ftlen(4)),4
 ipitch         =         cpspch(itranspose + 6 + ipitch/100)
 
 if ipcount2    !=        icount2 goto noslide
 kpitch         linseg    ippitch, .06, ipitch, inotedur-.06, ipitch
 goto next
 
 noslide:
 kpitch         =         ipitch
 
 next:
 ipcount2       =         icount2
                timout    0,inotedur,contin
 icount         =         icount + 1
                reinit    start
                rireturn
 
 contin:
 ; ACCENT DETECTOR
 iacc           table     ftlen(5)*frac((icount-1)/ftlen(5)), 5
 if iacc == 0 goto noaccent
 ienvdecay      =         0                                            ; accented notes are the shortest ones
 iremacc        =         i(kaccurve)
 kaccurve       oscil1i   0, 1, .4, 3
 kaccurve       =         kaccurve+iremacc                             ; successive accents cause hysterical raising cutoff
 
 goto sequencer
 
 noaccent:
 kaccurve       =         0                                            ; no accent & "discharges" accent curve
 ienvdecay      =         i(kdecay)
 
 sequencer:
 aremovedc      init      0                                            ; set feedback to 0 at every event
 imult          table     ftlen(6)*frac(icount2/ftlen(6)),6
 if imult       !=        0 goto noproblemo                            ; compensate for zero padding in the sequencer
 icount2        =         icount2 + 1
 goto sequencer
 
 noproblemo:
 ieventdur      =         inotedur*imult
 
 ; TWO ENVELOPES
 kmeg           expseg    1, imindecay+((ieventdur-imindecay)*ienvdecay),ienvdecay+.000001
 kveg           linen     1, .01, ieventdur, .016                      ; attack should be 4 ms. but there would be clicks...
 
 ; AMPLITUDE ENVELOPE
 kamp           =         kveg*((1-i(kenvmod)) + kmeg*i(kenvmod)*(.5+.5*iacc*kaccent))
 
 ; FILTER ENVELOPE
 ksweep         =         kveg * (imaxfreq + (.75*kmeg+.25*kaccurve*kaccent)*kenvmod*(imaxsweep-imaxfreq))
 kfco           =         20 + kfco * ksweep                           ; cutoff always greater than 20 Hz ...
 kfco           =         (kfco > sr/2 ? sr/2 : kfco)                  ; could be necessary
 
                timout    0, ieventdur, out
 icount2        =         icount2 + 1
                reinit    contin
 
 out:
 ; GENERATE BANDLIMITED SAWTOOTH WAVE
 abuzz          buzz      kamp, kpitch, sr/(2*kpitch), 1 ,0            ; bandlimited pulse
 asaw           integ     abuzz,0
 asawdc         atone     asaw,1
 
 ; RESONANT 4-POLE LPF
 ainpt          =         asawdc - aremovedc*kres*ireson
 alpf           tone      ainpt,kfco
 alpf           tone      alpf,kfco
 alpf           tone      alpf,kfco
 alpf           tone      alpf,kfco
 
                aout      balance alpf,asawdc
 
 ; FINAL OUTPUT ... AT LAST!
 aremovedc      atone     aout,10
                out       imaxamp*aremovedc
                endin
 
</CsInstruments>
<CsScore>
f1 0 8192 10 1                                                                                                          ; sine wave
 f3  0 8193   8  0 512 1 1024 1 512 .5 2048 .2 4096  0                                                    ; accent curve
 f4  0  16  -2  12 24 12 14 15 12 0 12 12 24 12 14 15 6 13 16                                             ; sequencer (pitches are 6.00 + p/100)
 f5  0  32  -2   0  1  0  0  0  0 0  0  0  1  0  1  1 1  0  0 0 1 0 0 1 0 1 1 1 1 0 0 0 0 0 1   ; accent sequence
 f6  0  16  -2   2     1  1  2    1  1  1  2     1  1 3       1 4 0 0 0                                   ; fill with zeroes till next power of 2
 
 ; f6 = durations of events, 1 = note per note, 2 = two tied notes... .
 ; note: f4-f5-f6 don´t need to be syncronized... like here (16-32-21)
 
 f7 0 1024   8 -.8 42 -.78  200 -.74 200 -.7 140 .7  200 .74 200 .78 42 .8                           ; distortion table
                                                                                                                         ; f7 borrowed from H.Mikelson´s TB-303 emulator. Tnx!
 
 ;------------ KNOB POSITION : INITIAL AND FINAL VALUES FROM 0 TO 1--------------------
 ;   cutoff freq resonance envelope mod. decay       accent     bpm
 ;     0   -   1  0 ~ 1  ~ .1 - 1  0 - 1       0 - 1   40-300
 ;       start    end  st  end   st  end  st  end     st  end
 
 i1   0 10  .1       .3  .2    .2        .1   .4   .05  .8    0   0    120
 i1  11 10  .95      1         .1   1    .8   1          .1       .01  0         1      120
 i1  22 10  0        1    .5   1         .1   .4   1    1     1   1    120
 i1  33 10   .5      1         .95  1     1   .9         .1       0         1         1      120
 i1  44 10  .05      1    .5   1         .1   .1   .5   1    .5   1         120
 
 ;------------------------------END OF SCORE-------------------------------------------
 e
 
</CsScore>

</CsoundSynthesizer>
