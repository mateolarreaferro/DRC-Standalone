<CsoundSynthesizer>
<CsOptions>
--limiter=0.9
</CsOptions>
<CsInstruments>
; horn.orc
; instr 25 - French horn
; instr 194 - reverb
sr=44100
kr=441
ksmps=100
nchnls=2

giseed = .5
giwtsin = 1
garev   init    0
;--------------------------------------------------------------------- 

instr 25                                                ; French horn

;       parameters
;       p4      overall amplitude scaling factor
;       p5      pitch in Hertz (normal pitch range: sounding F2 - F5)
;       p6      percent vibrato depth, recommended values in range [-.5, +.5]
;                       0.0     -> no vibrato
;                       +.5     -> 1% vibrato depth, where vibrato rate increases slightly
;                       -.5     -> 1% vibrato depth, where vibrato rate decreases slightly
;       p7      attack time in seconds 

;                       recommended value:  .06 for tongued notes (up to .12 for lower notes like G2)
;                               (.03 for short notes)
;       p8      decay time in seconds 

;                       recommended value:  .25 (.04 for short notes)
;       p9      overall brightness / filter cutoff factor 

;                       1 -> least bright / minimum filter cutoff frequency (40 Hz)
;                       9 -> brightest / maximum filter cutoff frequency (10,240Hz)

                                                        ; initial variables
iampscale       =       p4                              ; overall amplitude scaling factor
ifreq           =       p5                              ; pitch in Hertz
ivibdepth       =       abs(p6*ifreq/100.0)             ; vibrato depth relative to fundamental frequency
iattack         =       p7 * (1.1 - .2*giseed)          ; attack time with up to +-10% random deviation
giseed          =       frac(giseed*105.947)            ; reset giseed
idecay          =       p8 * (1.1 - .2*giseed)          ; decay time with up to +-10% random deviation
giseed          =       frac(giseed*105.947)
ifiltcut        tablei  p9, 2                           ; lowpass filter cutoff frequency

iattack         =       (iattack < 6/kr ? 6/kr : iattack)               ; minimal attack length
idecay          =       (idecay < 6/kr ? 6/kr : idecay)                 ; minimal decay length
isustain        =       p3 - iattack - idecay
p3              =       (isustain < 5/kr ? iattack+idecay+5/kr : p3)    ; minimal sustain length
isustain        =       (isustain < 5/kr ? 5/kr : isustain)                     
iatt            =       iattack/6
isus            =       isustain/4
idec            =       idecay/6
iphase          =       giseed                          ; use same phase for all wavetables
giseed          =       frac(giseed*105.947)

                                                        ; vibrato block
kvibdepth       linseg  .1, .8*p3, 1, .2*p3, .7
kvibdepth       =       kvibdepth* ivibdepth            ; vibrato depth
kvibdepthr      randi   .1*kvibdepth, 5, giseed         ; up to 10% vibrato depth variation
giseed          =       frac(giseed*105.947)
kvibdepth       =       kvibdepth + kvibdepthr
ivibr1          =       giseed                          ; vibrato rate
giseed          =       frac(giseed*105.947)
ivibr2          =       giseed
giseed          =       frac(giseed*105.947)

if p6 < 0 goto vibrato1
kvibrate        linseg  2.5+ivibr1, p3, 4.5+ivibr2      ; if p6 positive vibrato gets faster
goto vibrato2
vibrato1:
ivibr3          =       giseed
giseed          =       frac(giseed*105.947)
kvibrate        linseg  3.5+ivibr1, .1, 4.5+ivibr2, p3-.1, 2.5+ivibr3   ; if p6 negative vibrato gets slower
vibrato2:
kvibrater       randi   .1*kvibrate, 5, giseed          ; up to 10% vibrato rate variation
giseed          =       frac(giseed*105.947)
kvibrate        =       kvibrate + kvibrater
kvib            oscil   kvibdepth, kvibrate, giwtsin

ifdev1  =       -.012 * giseed                          ; frequency deviation
giseed  =       frac(giseed*105.947)
ifdev2  =       .005 * giseed
giseed  =       frac(giseed*105.947)
ifdev3  =       -.005 * giseed
giseed  =       frac(giseed*105.947)
ifdev4  =       .009 * giseed
giseed  =       frac(giseed*105.947)
kfreqr  linseg  ifdev1, iattack, ifdev2, isustain, ifdev3, idecay, ifdev4
kfreq   =       ifreq * (1 + kfreqr) + kvib

if ifreq <  113.26 goto range1                          ; (cpspch(6.09) + cpspch(6.10))/2
if ifreq <  152.055 goto range2                         ; (cpspch(7.02) + cpspch(7.03))/2
if ifreq <  202.74 goto range3                          ; (cpspch(7.07) + cpspch(7.08))/2
if ifreq <  270.32 goto range4                          ; (cpspch(8.00) + cpspch(8.01))/2
if ifreq <  360.43 goto range5                          ; (cpspch(8.05) + cpspch(8.06))/2
if ifreq <  480.29 goto range6                          ; (cpspch(8.10) + cpspch(8.11))/2
goto range7
                                                        ; wavetable amplitude envelopes
range1:                                                 ; for low range tones
kamp1   linseg  0, iatt, 0.000, iatt, 0.000, iatt, 0.298, iatt,         \
1.478, iatt, 1.901, iatt, 2.154, isus, 2.477, isus, 2.495, isus,        \
2.489, isus, 1.980, idec, 1.759, idec, 1.506, idec, 1.000, idec,        \
0.465, idec, 0.006, idec, 0
kamp2   linseg  0, iatt, 0.000, iatt, 1.000, iatt, 2.127, iatt,         \
0.694, iatt, -0.599, iatt, -1.807, isus, -2.485, isus, -2.125, isus,    \
-2.670, isus, -0.798, idec, -0.056, idec, -0.038, idec, 0.000, idec,    \
0.781, idec, 0.133, idec, 0
kamp3   linseg  0, iatt, 1.000, iatt, 0.000, iatt, -4.131, iatt,        \
-6.188, iatt, -1.422, iatt, 1.704, isus, 6.362, isus, 3.042, isus,      \
5.736, isus, -0.188, idec, -2.558, idec, -2.409, idec, 0.000, idec,     \
-1.736, idec, 0.167, idec, 0
iwt1    =       60                                      ; wavetable numbers
iwt2    =       61
iwt3    =       62
inorm   =       5137
goto end

range2:                                                 ; for low mid-range tones 

kamp1   linseg  0, iatt, 0.000, iatt, 0.000, iatt, 0.000, iatt,         \ 
0.308, iatt, 0.926, iatt, 1.370, isus, 3.400, isus, 3.205, isus,        \
3.083, isus, 2.722, idec, 2.239, idec, 2.174, idec, 1.767, idec,        \
1.098, idec, 0.252, idec, 0
kamp2   linseg  0, iatt, 0.478, iatt, 1.000, iatt, 0.000, iatt,         \
4.648, iatt, 1.843, iatt, 5.242, isus, -.853, isus, -.722, isus,        \
-.860, isus, -.547, idec, -.462, idec, -.380, idec, -.387, idec,        \
-0.355, idec, -0.250, idec, 0
kamp3   linseg  0, iatt, -0.107, iatt, 0.000, iatt, 1.000, iatt,        \
-0.570, iatt, 0.681, iatt, -1.097, isus, 1.495, isus, 0.152, isus,      \
0.461, isus, 0.231, idec, 0.228, idec, 0.256, idec, 0.152, idec,        \
0.087, idec, 0.042, idec, 0
iwt1    =       63
iwt2    =       64
iwt3    =       65
inorm   =       35685
goto end

range3:                                                 ; for high mid-range tones 

kamp1   linseg  0, iatt, 0.039, iatt, 0.000, iatt, 0.000, iatt,         \
0.230, iatt, 0.216, iatt, 0.647, isus, 1.764, isus, 1.961, isus,        \
1.573, isus, 1.408, idec, 1.312, idec, 1.125, idec, 0.802, idec,        \
0.328, idec, 0.061, idec, 0
kamp2   linseg  0, iatt, 1.142, iatt, 1.000, iatt, 0.000, iatt,         \
-1.181, iatt, -3.005, iatt, -1.916, isus, 2.325, isus, 3.249, isus,     \
2.154, isus, 1.766, idec, 2.147, idec, 1.305, idec, 0.115, idec,        \
0.374, idec, 0.162, idec, 0
kamp3   linseg  0, iatt, -0.361, iatt, 0.000, iatt, 1.000, iatt,        \
1.369, iatt, 1.865, iatt, 1.101, isus, -.677, isus, -.833, isus,        \
-.437, isus, -.456, idec, -.465, idec, -.395, idec, -0.144, idec,       \
-0.061, idec, -0.012, idec, 0
iwt1    =       66
iwt2    =       67
iwt3    =       68
inorm   =       39632
goto end

range4:                                                 ; for high range tones 

kamp1   linseg  0, iatt, 0.000, iatt, -0.147, iatt, -0.200, iatt,       \
-0.453, iatt, -0.522, iatt, 0.000, isus, 2.164, isus, 1.594, isus,      \
2.463, isus, 1.506, idec, 1.283, idec, 0.618, idec, 0.222, idec,        \
0.047, idec, 0.006, idec, 0
kamp2   linseg  0, iatt, 1.000, iatt, 16.034, iatt, 24.359, iatt,       \
12.399, iatt, 3.148, iatt, 0.000, isus, 8.986, isus, -2.516, isus,      \
13.268, isus, 0.541, idec, -2.107, idec, -11.221, idec, -14.179,        \
idec, -7.152, idec, 5.327, idec, 0
kamp3   linseg  0, iatt, 0.000, iatt, -0.318, iatt, -0.181, iatt,       \
0.861, iatt, 1.340, iatt, 1.000, isus, -1.669, isus, -0.669, isus,      \
-2.208, isus, -0.709, idec, -0.388, idec, 0.641, idec, 1.101, idec,     \
0.817, idec, 0.018, idec, 0
iwt1    =       69
iwt2    =       70
iwt3    =       71
inorm   =       26576.1
goto end

range5:                                                 ; for high range tones 

kamp1   linseg  0, iatt, 2.298, iatt, 2.017, iatt, 2.099, iatt,         \
1.624, iatt, 0.536, iatt, 1.979, isus, -2.465, isus, -4.449, isus,      \
-4.176, isus, -1.518, idec, -0.593, idec, 0.000, idec, 0.384, idec,     \
0.386, idec, 0.256, idec, 0
kamp2   linseg  0, iatt, -1.498, iatt, -1.342, iatt, -0.983, iatt,      \
-0.402, iatt, 0.572, iatt, -0.948, isus, 4.490, isus, 6.433, isus,      \
5.822, isus, 1.845, idec, 0.618, idec, 0.000, idec, -0.345, idec,       \
-0.295, idec, -0.164, idec, 0
kamp3   linseg  0, iatt, -0.320, iatt, 0.179, iatt, -0.551, iatt,       \
-0.410, iatt, -0.417, iatt, -0.028, isus, -1.517, isus, -1.523, isus,   \
-1.057, isus, 0.883, idec, 1.273, idec, 1.000, idec, 0.660, idec,       \
0.271, idec, 0.026, idec, 0
iwt1    =       72
iwt2    =       73
iwt3    =       74
inorm   =       26866.7
goto end

range6:                                                 ; for high range tones 

kamp1   linseg  0, iatt, 6.711, iatt, 4.998, iatt, 3.792, iatt,         \
-0.554, iatt, -1.261, iatt, -5.584, isus, -4.633, isus, -0.384, isus,   \
-0.555, isus, -0.810, idec, 0.112, idec, 0.962, idec, 1.567, idec,      \
0.881, idec, 0.347, idec, 0
kamp2   linseg  0, iatt, -5.829, iatt, -4.106, iatt, -3.135, iatt,      \
1.868, iatt, 1.957, iatt, 6.851, isus, 5.135, isus, 0.097, isus,        \
0.718, isus, 1.679, idec, 0.881, idec, -0.009, idec, -0.927, idec,      \
-0.544, idec, -0.225, idec, 0
kamp3   linseg  0, iatt, 0.220, iatt, 0.177, iatt, 0.333, iatt,         \
-0.302, iatt, 0.071, iatt, -0.563, isus, 0.338, isus, 1.214, isus,      \
0.840, isus, 0.103, idec, 0.003, idec, -0.114, idec, -0.049, idec,      \
-0.031, idec, -0.017, idec, 0
iwt1    =       75
iwt2    =       76
iwt3    =       77
inorm   =       31013.2
goto end

range7:                                                 ; for high range tones 

kamp1   linseg  0, iatt, 0.046, iatt, 0.000, iatt, 0.127, iatt,         \
0.686, iatt, 1.000, iatt, 1.171, isus, 0.000, isus, 0.667, isus,        \
0.969, isus, 1.077, idec, 1.267, idec, 1.111, idec, 0.964, idec,        \
0.330, idec, 0.047, idec, 0
kamp2   linseg  0, iatt, 0.262, iatt, 1.000, iatt, 1.026, iatt,         \
0.419, iatt, 0.000, iatt, -0.172, isus, 0.000, isus, -0.764, isus,      \
-0.547, isus, -0.448, idec, -0.461, idec, -0.199, idec, -0.015, idec,   \
0.432, idec, 0.120, idec, 0
kamp3   linseg  0, iatt, -0.014, iatt, 0.000, iatt, 0.102, iatt,        \
0.006, iatt, 0.000, iatt, -0.016, isus, 1.000, isus, 0.753, isus,       \
0.367, isus, 0.163, idec, -0.030, idec, -0.118, idec, -0.207, idec,     \
-0.103, idec, -0.007, idec, 0
iwt1    =       78
iwt2    =       79
iwt3    =       80
inorm   =       26633.5
goto end

end:
kampr1  randi   .02*kamp1, 10, giseed                   ; up to 2% wavetable amplitude variation
giseed  =       frac(giseed*105.947)
kamp1   =       kamp1 + kampr1
kampr2  randi   .02*kamp2, 10, giseed                   ; up to 2% wavetable amplitude variation
giseed  =       frac(giseed*105.947)
kamp2   =       kamp2 + kampr2
kampr3  randi   .02*kamp3, 10, giseed                   ; up to 2% wavetable amplitude variation
giseed  =       frac(giseed*105.947)
kamp3   =       kamp3 + kampr3

awt1    oscili  kamp1, kfreq, iwt1, iphase              ; wavetable lookup
awt2    oscili  kamp2, kfreq, iwt2, iphase
awt3    oscili  kamp3, kfreq, iwt3, iphase
asig    =       awt1 + awt2 + awt3
asig    =       asig*(iampscale/inorm)
kcut    linseg  0, iattack, ifiltcut, isustain, ifiltcut, idecay, 0     ; lowpass filter for brightness control
afilt   tone    asig, kcut
asig    balance afilt, asig
garev   =       garev + asig
        outs    asig*.8, asig*.8
        endin

;--------------------------------------------------------------------- 

instr 194                                                                
; add reverb to global signal garev
;       parameters
;       p4      starting reverb time
;       p5      final reverb time
;       p6      % of reverb relative to source signal

irevtime        = p4                                                    ; set first duration of reverb time
ichngtime       = p5                                                    ; set final duration of reverb time
iring           = 0
iring           = (irevtime > ichngtime ? irevtime : iring)             ; set iring to the starting or ending
iring           = (ichngtime > irevtime ? ichngtime : iring)            ; reverbime, whichever is longer

ireverb         = p6                                                    ; percent for reverberated signal
idur            = p3                                                    ; set the duration at p3, and then
p3              = p3 + iring                                            ; lengthen p3 to include longer reverb time
krevtime        linseg  irevtime, idur, irevtime, iring, ichngtime      ; change duration of reverb time
arev            reverb  garev, krevtime                                 ; add reverb to the global signal
                outs  ireverb * arev, ireverb*arev                                  ; output reverberated signal
garev =         0                                                       ; set garev to 0 to prevent feedback
                endin

</CsInstruments>
<CsScore>

; horn.sco

; R. Strauss - Til Eulenspiegel's Merry Pranks
; opening horn solo

f1 0 4097 10 1 

f2 0 16 -2 40 40 80 160 320 640 1280 2560 5120 10240 10240

f60 0 4097 -10 478 1277 2340 4533 2413 873 682 532 332 364 188 258 256 114 80 68 36
f61 0 4097 -10 414 906 831 507 268 36
f62 0 4097 -10 74 50 68 156 50 48 52 66 

f63 0 4097 -10 677 2663 4420 1597 1236 780 581 325 415 201 212 202 156 26 
f64 0 4097 -10 648 1635 828 149 89 41  
f65 0 4097 -10 1419 3414 901 503 204 146 

f66 0 4097 -10 1722 14359 5103 1398 2062 696 652 266 264 176 164 75  
f67 0 4097 -10 1237 2287 237 72 
f68 0 4097 -10 2345 7796 1182 266 255 193 85 

f69 0 4097 -10 9834 16064 2259 1625 1353 344 356 621 195 155 77 98
f70 0 4097 -10 377 193 41
f71 0 4097 -10 8905 10946 1180 1013 506 125 48

f72 0 4097 -10 16460 4337 1419 1255 43 205 81 73 60 38 
f73 0 4097 -10 16569 5563 1838 1852 134 340 129 159 162 99 
f74 0 4097 -10 10383 4175 858 502 241 165 

f75 0 4097 -10 15341 5092 1554 640 101  
f76 0 4097 -10 16995 6133 1950 788 136  
f77 0 4097 -10 22560 9285 4691 1837 342 294 307 222 288 103 

f78 0 4097 -10 19417 5904 1666 913 266 55 81 46  
f79 0 4097 -10 11940 1211 111 38
f80 0 4097 -10 25132 6780 2886 1949 507 505 466 488 336 121 


t 0 324

;p1     p2      p3      p4      p5      p6      p7      p8      p9
;       start   dur     amp     Hertz   vibr    att     dec     bright
;bar 1-------------------------------------------------------------------
i25     2.000   0.700   6500    261.600 0.500   0.040   0.040   9
i25     3.000   0.700   7500    348.800 0.500   0.040   0.040   9
i25     4.000   0.700   8000    392.400 0.500   0.040   0.040   9
i25     5.000   3.100   6500    418.560 0.500   0.040   0.040   9
;bar 2-------------------------------------------------------------------
i25     8.000   0.700   6500    436.000 0.500   0.040   0.040   9
i25     9.000   0.700   7500    261.600 0.500   0.040   0.040   9
i25     10.000  0.700   8000    348.800 0.500   0.040   0.040   9
i25     11.000  0.700   6500    392.400 0.500   0.040   0.040   9
i25     12.000  3.100   7500    418.560 0.500   0.040   0.040   9
;bar 3-------------------------------------------------------------------
i25     15.000  0.700   7500    436.000 0.500   0.040   0.040   9
i25     16.000  0.700   8000    261.600 0.500   0.040   0.040   9
i25     17.000  0.700   6500    348.800 0.500   0.040   0.040   9
i25     18.000  0.700   7500    392.400 0.500   0.040   0.040   9
;bar 4-------------------------------------------------------------------
i25     19.000  1.700   10000   418.560 0.500   0.060   0.150   9
i25     21.000  1.700   10000   436.000 0.500   0.060   0.150   9
i25     23.000  0.700   6500    470.080 0.500   0.040   0.040   9
i25     24.000  0.700   7500    490.500 0.500   0.040   0.040   9
;bar 5-------------------------------------------------------------------
i25     25.000  0.700   10000   588.600 0.500   0.040   0.040   9
i25     26.000  0.700   6500    523.200 0.500   0.040   0.040   9
i25     27.000  0.700   7500    436.000 0.500   0.040   0.040   9
i25     28.000  0.700   8000    348.800 0.500   0.040   0.040   9
i25     29.000  0.700   6500    261.600 0.500   0.040   0.040   9
i25     30.000  0.700   7500    218.000 0.500   0.040   0.040   9
;bar 6-------------------------------------------------------------------
i25     31.000  2.400   10000   174.400 0.000   0.040   0.200   9
i25     34.000  2.700   8700    130.800 0.000   0.080   0.200   9
;bar 7-------------------------------------------------------------------
i25     37.000  2.700   7500    87.200  0.000   0.120   0.200   9

;reverb------------------------------------------------------------------
;p1     p2      p3      p4      p5      p6
;                       start   final   percent
;       start   dur     revtime revtime reverb
i194    0       39.700  1.2     .1      .1

e

</CsScore>

</CsoundSynthesizer>
<MacOptions>
Version: 3
Render: Real
Ask: Yes
Functions: Window
Listing: Window
WindowBounds: 121 71 1088 834
CurrentView: io
IOViewEdit: Off
Options: -b128 -A -s -m167 -R --midi-velocity-amp=4 --midi-key-cps=5 
</MacOptions>
<MacGUI>
ioView nobackground {65535, 65535, 65535}
</MacGUI>


<bsbPanel>
 <label>Widgets</label>
 <objectName/>
 <x>100</x>
 <y>100</y>
 <width>320</width>
 <height>240</height>
 <visible>true</visible>
 <uuid/>
 <bgcolor mode="background">
  <r>240</r>
  <g>240</g>
  <b>240</b>
 </bgcolor>
</bsbPanel>
<bsbPresets>
</bsbPresets>
