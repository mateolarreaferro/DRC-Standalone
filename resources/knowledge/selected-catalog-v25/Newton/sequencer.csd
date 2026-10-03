<CsoundSynthesizer>
<CsOptions>
</CsOptions>
<CsInstruments>
;FROM: E.G.NEWTON@ITI.SALFORD.AC.UK
;HERE IS A CSOUND EXAMPLE I WROTE A FE DAYS AGO TO ALLOW NOTE PATTERNS TO BE
;GENERATED FROM WITHIN CSOUND. IT USES F2 TO STORE PARAMETER LISTS WHICH ARE
;THEN TRANSFERED INTO SETTINGS FOR PITCH, DURATION VOLUME AND GATING SPEED.
;IT IS A STRIPPED DOWN VERSION OF A COMPOSITION I PRODUCED USING SAMPLED
;SOUNDS AS WELL, SO PLEASE STICK WITH IT IF IT SOUNDS TO EMPTY! I APOLOGISE
;FOR LACK OF ANY MUSICAL KNOWLEDGE, IT IS THE SEQUENCING IT IS
;DEMONSTRATING. FEEL FREE TO CHANGE THE CODE, AND IF YOU HAVE ANY EXAMPLES
;ALONG SIMILAR LINES PLEASE SEND. ANYWAY HERE IT IS, I HOPE IT WORKS...




; *****************  ORCHESTRA  *****************

sr             =         44100
kr             =         4410
ksmps          =         10
nchnls         =         1

gimult         init      3
; I ALWAYS SET VOLUMES TOO LOW SO THIS BOOSTS EVERYTHING



instr          8
  kfade        line      p17, p3, p18
  kgoto        reset                              ; TRANSFER PAST COUNTER INIT ON PASSES
  kc1          =         0                        ; INIT COUNTERS
  kc2          =         0                        ; INIT COUNTERS
  kc3          =         0                        ; INIT COUNTERS
  kc4          =         0                        ; INIT COUNTERS
reset:
  krfr         table     kc1, p5                  ; READ FREQ COUNTER POSITION
  krvol        table     kc2, p7                  ; USE GEN02
  kdur         table     kc3, p9
  kmisc        table     kc4, p11
  kphs         phasor    1/kdur                   ; KPHS GOES FROM 0>1 OVER NOTE
  if (kphs < 0.998)      goto process             ; GOTO PROCESS IF IN NOTE, ELSE..
  kc1          =         kc1 + 1                  ; ADD ONE TO COUNTER
  kc1          =         ( kc1 < p6 ? kc1 : 0 )   ; IF COUNTER PAST LAST, RESET
  kc2          =         kc2 + 1
  kc2          =         ( kc2 < p8 ? kc2 : 0 )
  kc3          =         kc3 + 1
  kc3          =         ( kc3 < p10 ? kc3 : 0 )
  kc4          =         kc4 + 1
  kc4          =         ( kc4 < p12 ? kc4 : 0 )
  reinit       reset                              ; REINIT ALL OSCILS ETC
process:
; NORMAL INSTRUMENT. p3 ref > kdur

  agatea       oscil     1, kmisc, p16
  asig         buzz      1, 100, 150, 1
  kfreq        oscil     1, 1/kdur, p6
  kcf          =         krfr + (kfreq*krfr)
  afilt        reson     asig, kcf, 35
  asig         balance   afilt, asig
  krvol        =         ampdb(krvol)
  asig         =         asig * agatea * krvol * kfade * p4
               out       asig * gimult
endin

</CsInstruments>
<CsScore>
; ***************  Score  *******************

f1  0  2048 10 1                                                      ; SINE
f2  0  1025  3  -1  1  5  4  3  2  2  1                               ; POLYNOMIAL
f3  0  65    8  0 16 0 .1  0 15.9 1 15.9  0 .1  0 16 0                ; HUMP WITH GAP
f4  0 256    7  1 256 1                                               ; LINE ACROSS
f5  0 256    7  0 20  1 36  0.5 100 0 100 0                           ; ADSR
f6  0 256    7  0 5  1 36  0.5 100 0 115 0                            ; HARD ADSR
f7  0 1024  19 .5  1  270 1                                           ; SIGMOID RISE FOR ATTACK

f8  0  16   -2  1 1.1 4
f9  0  16   -2  80 65 50
f10 0  16   -2  1 2.5 1.5
f11 0  16   -2  4 3
f12 0  16   -2  300 800 500


f30 0  16   -2  0.1
f31 0  16   -2  1000 2000 3000
f32 0  16   -2  8000 2000 3000 4000
f33 0  16   -2  0.8 0.9 4
f34 0  16   -2  1000 500 2000 500 3000 500 4000 500
f35 0  16   -2  0.25 0.25 0.1
f36 0  16   -2  5 2.5 1
f37 0  16   -2  0.3
f38 0  16   -2  1 2 3 4


;a 0 0 50                                                             ; USED FOR SKIPPING THRU WHEN TESTING

        ; rel    ffn,seq  vfn,seq  dfn,seq  gfn,seq envfn freqfn gatefn
ABfade
i8 0 60  3     12 3    9 2     10 2    11 2     0 2     7     5     0.4 1
i8 10 15 1     31 3    9 2     30 1    11 2     0 2     7     5     0 0.5
i8 25 5  2     32 4    9 2     30 1    11 2     0 2     7     1     0 0.4
i8 30 15 1.5   31 3    9 2     30 1    10 3     0 2     7     5     0.4 0.1
i8 60 20 3     12 3    9 2     10 2    11 2     0 2     7     5     1 0.3
i8 55 30 0.4   32 4    9 2     30 1    11 2     0 2     7     7     0.6 0
i8 75 30 0.4   12 4    9 2     30 1    33 3     0 2     1     6     0.4 0.2
i8 75.5 30 .4  31 4    9 2     30 1    33 3     0 2     1     6     0.3 0
i8 95 40 1     34 8    9 3     35 3    33 3     0 2     1     1     0.1 0.4
i8 95 50 1     34 8    9 3     36 3    33 3     0 2     1     1     0.2 0.4
e
</CsScore>
</CsoundSynthesizer>
