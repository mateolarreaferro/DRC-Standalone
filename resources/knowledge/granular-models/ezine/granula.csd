<CsoundSynthesizer>
<CsOptions>
-n -d -m0
</CsOptions>
<CsInstruments>
;--------------------------------------
; Granular Synthesis Instruments
; Coded by Hans Mikelson February 2000
;--------------------------------------
sr      =     44100      ; Sample rate
kr      =     44100      ; Control rate
ksmps   =     1          ; Samples per control rate
nchnls  =     2          ; Number of channels

;--------------------------------------
; Simple Granular Synthesis Instrument
;--------------------------------------
        instr  1

idur    =      p3         ; Duration
iamp    =      p4         ; Amplitude
ifqc    =      cpspch(p5) ; Pitch to frequency
iaoff   =      p6         ; Amplitude offset
ipoff   =      p7         ; Pitch offset
idens   =      p8         ; Density
ifn     =      p9         ; Function
iri     =      p10        ; Fade in time
iro     =      p11        ; Fade out time
igdtab  =      p12        ; Grain duration table
iwnd    =      2          ; Window function
imxgdur =      1          ; Maximum grain duration

; Amplitude envelope for fading in and out
kamp    linseg 0, iri*idur, 1, (1-iri-iro)*idur, 1, iro*idur, 0

; Grain envelope
kgrn    oscil  1, 1/idur, igdtab    ; Grain density envelope
kpoff   oscil  ifqc, 1/idur, ipoff  ; Pitch variation envelope

;               Amp, Pitch, Density, AmpOff, PitchOff, GrainDur,  Fn, Window, ImgDur, [Grnd]
agrnl   grain  iamp, ifqc,  idens,   iaoff,  kpoff,    kgrn,      ifn, iwnd, imxgdur      
agrnr   grain  iamp, ifqc,  idens,   iaoff,  kpoff,    kgrn,      ifn, iwnd, imxgdur      

aoutl   =      agrnl*kamp           ; Scale and output the left
aoutr   =      agrnr*kamp           ; and right signals
        outs   aoutl, aoutr         ; Output the result

        endin

;--------------------------------------
; Granular Synthesis Instrument 2
;--------------------------------------
        instr  2

idur    =      p3   ; Duration
iamp    =      p4   ; Amplitude
iptch   =      p5   ; Pitch
iaoff   =      p6   ; Amplitude offset
ipoff   =      p7   ; Pitch offset
idens   =      p8   ; Density
ifn     =      p9   ; Waveform
iri     =      p10  ; Fade in time
iro     =      p11  ; Fade out time
igdtab  =      p12  ; Grain duration table
iwnd    =      2    ; Grain window function
imxgdur =      1    ; Maximum grain duration

; Amplitude envelope to fade in and out
kamp    linseg 0, iri*idur, 1, (1-iri-iro)*idur, 1, iro*idur, 0

kgrn    oscil  1, 1/idur, igdtab      ; Grain duration envelope
kpoff   oscil  iptch, 1/idur, ipoff   ; Pitch offset envelope
i1	=  sr/ftlen(ifn)              ;scaling to reflect sample rate and table length


;               Amp, Pitch,     Density, AmpOff, PitchOff, GrainDur, Fn,  Window, ImgDur, [Grnd]
agrnl   grain  iamp, iptch*i1,  idens,   iaoff,  kpoff,    kgrn,     ifn, iwnd, imxgdur      
agrnr   grain  iamp, iptch*i1,  idens,   iaoff,  kpoff,    kgrn,     ifn, iwnd, imxgdur      

aoutl   =      agrnl*kamp    ; Scale left and right channels and output.
aoutr   =      agrnr*kamp
        outs   aoutl, aoutr

        endin


</CsInstruments>
<CsScore>
;--------------------------------------
; Granular Synthesis Instruments
; Coded by Hans Mikelson February 2000
;--------------------------------------
f1 0 65536 10 1                   ; Sine wave
f2 0 65536 20 2                   ; Hanning envelope
f3 0 65536 10 1 .1 .2 .4 .1       ; Waveform 1
f4 0 65536 10 1 0  .1 .1          ; Waveform 2
f5 0 65536 10 1 0  0  0  1        ; Waveform 3
f6 0 262144 1 "limit.wav" 0 0 0   ; 204164 samples

f10 0 1024 -7 1  512 .5 512 .1
f11 0 1024 -7 .1 512 .2 512 .1
f12 0 1024 -7 .1 512 .2 512 .1
f13 0 1024 -7 1  1024 1
f14 0 1024 -7 0  1024 0

f20 0 1024 -7 .015  512 .05 512 .023
f21 0 1024 -7 .01 512 .1 512 .01
f22 0 1024 -7 .005 1024 .005
f23 0 1024 -7 .001 1024 .001
f24 0 1024 -7 .05  1024 .05
f25 0 1024 -7 .5   1024 .5
f26 0 1024 -7 .001  1024 .001

;   Sta  Dur  Amp     Pitch  Arnd   PRnd  Dense  Fn  RampIn  RampOut GrainDur
i1  0    1    16000   8.00   .000   13    10     1   .1      .1      20
i1  +    1    16000   8.00   .000   13    20     1   .1      .1      22
i1  .    1    16000   8.00   .000   13    80     1   .1      .1      23
i1  .    1    16000   8.00   .0001  10    10     3   .1      .1      20
s

;   Sta  Dur  Amp    Pitch  Arnd   PRnd  Dense  Fn  RampIn  RampOut GrainDur
i1  0    15   1600   8.00   .0001  10    400    3   .6      .3      20
i1  12   16   2000   8.07   .0001  11    500    4   .3      .4      21
i1  20   8    2000   9.00   .0001  10    300    5   .3      .5      20
i1  26   3    1400   10.00  .0001  11    350    3   .2      .3      20
i1  28   4    1600   10.03  .0001  12    400    4   .2      .5      21
i1  30   6    1400   10.05  .0001  11    450    3   .2      .5      21
i1  28   20   1600   7.00   .0001  10    500    4   .3      .4      20
i1  36   16   1900   8.05   .0001  11    200    5   .3      .4      20
i1  40   16   1700   9.00   .0001  12    600    4   .3      .6      21
s

;   Sta  Dur  Amp    Pitch  Arnd   PRnd  Dense  Fn  RampIn  RampOut GrainDur
i2  0    6    6000   1      0      14    100    6   .5      .5      25
i2  4    6    6000   .8     0      12    150    6   .5      .5      24
i2  8    6    6000   1.2    0      11    200    6   .5      .5      20


</CsScore>
</CsoundSynthesizer>
