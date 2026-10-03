<CsoundSynthesizer>

<CsOptions>

--nodisplays --output=dac

</CsOptions>

<CsInstruments>

sr = 44100
ksmps = 64
nchnls = 2
0dbfs = 1.0
giPort init 1
opcode FreePort, i, 0
xout giPort
giPort = giPort + 1
endop

; AnalogDelay
; ----------------
; A analog style delay with signal degradation and saturation options
;
; aout  AnalogDelay  ain,kmix,ktime,kfback,ktone
;
; Performance
; -----------
; ain    --  input audio to which the flanging effect will be applied
; kmix   --  dry / wet mix of the output signal (range 0 to 1)
; ktime  --  delay time of the effect in seconds
; kfback --  control of the amount of output signal fed back into the input of the effect (exceeding 1 (100%) is possible and will result in saturation clipping effects)
; ktone  --  control of the amount of output signal fed back into the input of the effect (range 0 to 1)


opcode	AnalogDelay,a,aKKKK
	ain,kmix,ktime,kfback,ktone	xin			;READ IN INPUT ARGUMENTS
	ktone	expcurve	ktone,4				;CREATE AN EXPONENTIAL REMAPPING OF ktone
	ktone	scale	ktone,12000,100				;RESCALE 0 - 1 VALUE
	iWet	ftgentmp	0,0,1024,-7,0,512,1,512,1	;RESCALING FUNCTION FOR WET LEVEL CONTROL
	iDry	ftgentmp	0,0,1024,-7,1,512,1,512,0	;RESCALING FUNCTION FOR DRY LEVEL CONTROL
	kWet	table	kmix, iWet, 1				;RESCALE WET LEVEL CONTROL ACCORDING TO FUNCTION TABLE iWet
	kDry	table	kmix, iDry, 1                 		;RESCALE DRY LEVEL CONTROL ACCORDING TO FUNCTION TABLE iWet
	kporttime	linseg	0,0.001,0.1			;RAMPING UP PORTAMENTO TIME
	kTime	portk	ktime, kporttime*3			;APPLY PORTAMENTO SMOOTHING TO DELAY TIME PARAMETER
	kTone	portk	ktone, kporttime			;APPLY PORTAMENTO SMOOTHING TO TONE PARAMETER
	aTime	interp	kTime					;INTERPOLATE AND CREAT A-RATE VERSION OF DELAY TIME PARAMETER
	aBuffer	delayr	5					;READ FROM (AND INITIALIZE) BUFFER
	atap	deltap3	aTime					;TAP DELAY BUFFER
	atap	clip	atap, 0, 0dbfs*0.8			;SIGNAL IS CLIPPED AT MAXIMUM AMPLITUDE USING BRAM DE JONG METHOD
	atap	tone	atap, kTone				;LOW-PASS FILTER DELAY TAP WITHIN DELAY BUFFER 
		delayw	ain+(atap*kfback)			;WRITE INPUT AUDIO AND FEEDBACK SIGNAL INTO DELAY BUFFER
	aout	sum	ain*kDry, atap*kWet			;MIX DRY AND WET SIGNALS 
		xout	aout					;SEND AUDIO BACK TO CALLER INSTRUMENT
endop



instr 79

endin

instr 78
 event_i "i", 77, 604800.0, 1.0e-2
endin

instr 77
ir1 = 76
ir2 = 0.0
 turnoff2 ir1, ir2, ir2
ir5 = 75
 turnoff2 ir5, ir2, ir2
ir8 = 74
 turnoff2 ir8, ir2, ir2
ir11 = 73
 turnoff2 ir11, ir2, ir2
ir14 = 72
 turnoff2 ir14, ir2, ir2
ir17 = 71
 turnoff2 ir17, ir2, ir2
ir20 = 70
 turnoff2 ir20, ir2, ir2
ir23 = 69
 turnoff2 ir23, ir2, ir2
ir26 = 68
 turnoff2 ir26, ir2, ir2
ir29 = 67
 turnoff2 ir29, ir2, ir2
ir32 = 66
 turnoff2 ir32, ir2, ir2
ir35 = 65
 turnoff2 ir35, ir2, ir2
ir38 = 64
 turnoff2 ir38, ir2, ir2
ir41 = 63
 turnoff2 ir41, ir2, ir2
ir44 = 62
 turnoff2 ir44, ir2, ir2
ir47 = 61
 turnoff2 ir47, ir2, ir2
ir50 = 60
 turnoff2 ir50, ir2, ir2
ir53 = 59
 turnoff2 ir53, ir2, ir2
ir56 = 58
 turnoff2 ir56, ir2, ir2
ir59 = 57
 turnoff2 ir59, ir2, ir2
ir62 = 56
 turnoff2 ir62, ir2, ir2
ir65 = 55
 turnoff2 ir65, ir2, ir2
ir68 = 54
 turnoff2 ir68, ir2, ir2
ir71 = 53
 turnoff2 ir71, ir2, ir2
ir74 = 52
 turnoff2 ir74, ir2, ir2
ir77 = 51
 turnoff2 ir77, ir2, ir2
ir80 = 50
 turnoff2 ir80, ir2, ir2
ir83 = 49
 turnoff2 ir83, ir2, ir2
ir86 = 48
 turnoff2 ir86, ir2, ir2
ir89 = 47
 turnoff2 ir89, ir2, ir2
ir92 = 46
 turnoff2 ir92, ir2, ir2
ir95 = 45
 turnoff2 ir95, ir2, ir2
ir98 = 44
 turnoff2 ir98, ir2, ir2
ir101 = 43
 turnoff2 ir101, ir2, ir2
ir104 = 42
 turnoff2 ir104, ir2, ir2
ir107 = 41
 turnoff2 ir107, ir2, ir2
ir110 = 40
 turnoff2 ir110, ir2, ir2
ir113 = 39
 turnoff2 ir113, ir2, ir2
ir116 = 38
 turnoff2 ir116, ir2, ir2
ir119 = 37
 turnoff2 ir119, ir2, ir2
ir122 = 36
 turnoff2 ir122, ir2, ir2
ir125 = 35
 turnoff2 ir125, ir2, ir2
ir128 = 34
 turnoff2 ir128, ir2, ir2
ir131 = 33
 turnoff2 ir131, ir2, ir2
ir134 = 32
 turnoff2 ir134, ir2, ir2
ir137 = 31
 turnoff2 ir137, ir2, ir2
ir140 = 30
 turnoff2 ir140, ir2, ir2
ir143 = 29
 turnoff2 ir143, ir2, ir2
ir146 = 28
 turnoff2 ir146, ir2, ir2
ir149 = 27
 turnoff2 ir149, ir2, ir2
ir152 = 26
 turnoff2 ir152, ir2, ir2
ir155 = 25
 turnoff2 ir155, ir2, ir2
ir158 = 24
 turnoff2 ir158, ir2, ir2
ir161 = 23
 turnoff2 ir161, ir2, ir2
ir164 = 22
 turnoff2 ir164, ir2, ir2
ir167 = 21
 turnoff2 ir167, ir2, ir2
ir170 = 20
 turnoff2 ir170, ir2, ir2
ir173 = 19
 turnoff2 ir173, ir2, ir2
ir176 = 18
 turnoff2 ir176, ir2, ir2
 exitnow 
endin

instr 76
ir1 = 5.0e-2
kr0 = birnd(ir1)
kr1 = birnd(ir1)
ir6 = 5.0e-3
kr2 = birnd(ir6)
 xtratim 0.1
ir11 = 9.0e-2
kr3 = birnd(ir11)
ir14 = 8.5e-2
kr4 = birnd(ir14)
kr5 = birnd(ir14)
ir19 = 8.5e-3
kr6 = birnd(ir19)
ir22 = 1.0
ar0 upsamp k(ir22)
kr7 = rnd(ir22)
kr8 = rnd(ir22)
ir27 = 0.75
ir28 = 0.0
ar1 noise ir27, ir28
 xtratim 0.1
kr9 = birnd(ir11)
kr10 = birnd(ir1)
kr11 = birnd(ir1)
kr12 = birnd(ir6)
 xtratim 0.1
kr13 = birnd(ir11)
kr14 = birnd(ir14)
kr15 = birnd(ir14)
kr16 = birnd(ir19)
kr17 = rnd(ir22)
kr18 = rnd(ir22)
ar2 noise ir27, ir28
 xtratim 0.1
kr19 = birnd(ir11)
kr20 = rnd(ir22)
kr21 = rnd(ir22)
kr22 = rnd(ir22)
kr23 = rnd(ir22)
kr24 = rnd(ir22)
kr25 = rnd(ir22)
ir73 = 0.8
ar3 noise ir73, ir28
 xtratim 0.1
kr26 = birnd(ir11)
ar4 noise ir27, ir28
 xtratim 0.1
kr27 = birnd(ir11)
kr28 = rnd(ir22)
ir88 = 0.4
ar5 noise ir22, ir88
 xtratim 0.1
kr29 = birnd(ir11)
kr30 = rnd(ir22)
ar6 noise ir22, ir88
 xtratim 0.1
kr31 = birnd(ir11)
kr32 = rnd(ir22)
ar7 noise ir22, ir88
 xtratim 0.1
kr33 = birnd(ir11)
arl0 init 0.0
arl1 init 0.0
ar8, ar9 subinstr 51
ar10 = (0.9 * ar8)
ir119 = 0.6
ir120 = 12000.0
ar11, ar12 reverbsc ar8, ar9, ir119, ir120
ar13 = (ar8 + ar11)
ar8 = (0.1 * ar13)
ar11 = (ar10 + ar8)
ar8, ar10 subinstr 57
ir128 = 0.14285714285714285
ir129 = 2.0
kr34 lpshold ir128, ir28, 0.0, ir22, ir22, ir28, ir22, ir28, ir22, ir22, ir22, ir28, ir22, ir22, ir22, ir129, ir22
ir131 = 1.0e-3
kr35 portk kr34, ir131
kr34 = (0.25 * kr35)
ir134 = 6.25e-2
ir135 = 0.5
ir136 = 0.25
kr35 lpshold ir134, ir28, 0.0, ir22, ir22, ir135, ir22, ir136, ir22, ir22, ir22
kr36 portk kr35, ir131
kr35 = (0.25 * kr36)
ar13 AnalogDelay ar8, kr34, kr35, ir135, ir135
ar8 AnalogDelay ar10, kr34, kr35, ir135, ir135
ar10, ar14 bbcuts ar13, ar8, 4.0, 8.0, 4.0, 1.0, 2.0
ar8 oscil3 ir22, ir136, 4
ar13 = (500.0 * ar8)
ar15 = (2500.0 + ar13)
ir148 = 0.1
ar13 oscil3 ir22, ir148, 4
ar16 = (0.5 * ar13)
ar13 = (0.5 + ar16)
ar16 = (0.25 * ar13)
ar13 = (0.1 + ar16)
ar16 moogvcf ar10, ar15, ar13
ar10 = (0.85 * ar16)
ar17 moogvcf ar14, ar15, ar13
ar13, ar14 reverbsc ar16, ar17, ir119, ir120
ar15 = (ar16 + ar13)
ar13 = (0.15 * ar15)
ar15 = (ar10 + ar13)
ar10 = (8.0 * ar15)
ar13 = (ar11 + ar10)
ar10, ar11 subinstr 63
ir167 = 4.0
kr34 lpshold ir148, ir28, 0.0, ir22, ir22, ir28, ir22, ir28, ir22, ir22, ir22, ir28, ir22, ir167, ir22, ir22, ir22, ir28, ir22, ir22, ir22, ir129, ir22
kr35 portk kr34, ir131
kr34 = (0.25 * kr35)
kr35 = (0.5 * kr36)
ar15 AnalogDelay ar10, kr34, kr35, ir135, ir135
ar10 AnalogDelay ar11, kr34, kr35, ir135, ir135
ar11, ar16 bbcuts ar15, ar10, 4.0, 8.0, 4.0, 1.0, 2.0
ir177 = 0.15
ar10 oscil3 ir22, ir177, 4
ar15 = (1000.0 * ar10)
ar10 = (4500.0 + ar15)
ar15 moogvcf ar11, ar10, ir148
ar11 moogvcf ar16, ar10, ir148
ar10 = (ar15 + ar11)
ar11 = (ar10 / 2.0)
ar10 oscil3 ir22, ir22, 4
ar15 = (0.5 * ar10)
ar10 = (0.5 + ar15)
ar15 = (0.6 * ar10)
ar10 = (0.2 + ar15)
ar15, ar16 pan2 ar11, ar10
ar10 = (0.85 * ar15)
ar11, ar18 reverbsc ar15, ar16, ir73, ir120
ar19 = (ar15 + ar11)
ar11 = (0.15 * ar19)
ar15 = (ar10 + ar11)
ar10 = (8.0 * ar15)
ar11 = (ar13 + ar10)
ar10, ar13 subinstr 75
ar15 = (0.88 * ar10)
ar19, ar20 reverbsc ar10, ar13, ir73, ir120
ar21 = (ar10 + ar19)
ar10 = (0.12 * ar21)
ar19 = (ar15 + ar10)
ir211 = 420.0
ar10 = (0.5 * ar8)
ar8 = (0.5 + ar10)
ar10 = (0.23 * ar8)
ar8 = (0.72 + ar10)
ar10 moogvcf ar19, ir211, ar8
ar15 = (ar11 + ar10)
ir218 = 90.0
ir219 = 100.0
ar10 compress ar15, ar0, ir28, ir218, ir218, ir219, ir28, ir28, 0.0
ar11 = (ar10 * 0.8)
arl0 = ar11
ar10 = (0.9 * ar9)
ar11 = (ar9 + ar12)
ar9 = (0.1 * ar11)
ar11 = (ar10 + ar9)
ar9 = (0.85 * ar17)
ar10 = (ar17 + ar14)
ar12 = (0.15 * ar10)
ar10 = (ar9 + ar12)
ar9 = (8.0 * ar10)
ar10 = (ar11 + ar9)
ar9 = (0.85 * ar16)
ar11 = (ar16 + ar18)
ar12 = (0.15 * ar11)
ar11 = (ar9 + ar12)
ar9 = (8.0 * ar11)
ar11 = (ar10 + ar9)
ar9 = (0.88 * ar13)
ar10 = (ar13 + ar20)
ar12 = (0.12 * ar10)
ar10 = (ar9 + ar12)
ar9 moogvcf ar10, ir211, ar8
ar8 = (ar11 + ar9)
ar9 compress ar8, ar0, ir28, ir218, ir218, ir219, ir28, ir28, 0.0
ar0 = (ar9 * 0.8)
arl1 = ar0
ar0 = arl0
ar8 = arl1
 outs ar0, ar8
endin

instr 75
krl0 init 10.0
ir3 FreePort 
ir5 = 0.125
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 18.0
    ir11 = 74
    ir12 = 0.0
    ir13 = 1.0
     event "i", ir11, ir12, ir13, ir3
    ir16 = 74
    ir17 = 0.875
    ir18 = 1.0
     event "i", ir16, ir17, ir18, ir3
    ir21 = 74
    ir22 = 1.125
    ir23 = 1.0
     event "i", ir21, ir22, ir23, ir3
    ir26 = 74
    ir27 = 2.625
    ir28 = 1.0
     event "i", ir26, ir27, ir28, ir3
    ir31 = 74
    ir32 = 3.5
    ir33 = 1.0
     event "i", ir31, ir32, ir33, ir3
    ir36 = 74
    ir37 = 3.75
    ir38 = 1.0
     event "i", ir36, ir37, ir38, ir3
    ir41 = 74
    ir42 = 7.25
    ir43 = 1.0
     event "i", ir41, ir42, ir43, ir3
    ir46 = 74
    ir47 = 7.75
    ir48 = 1.0
     event "i", ir46, ir47, ir48, ir3
    ir51 = 74
    ir52 = 7.875
    ir53 = 1.0
     event "i", ir51, ir52, ir53, ir3
endif
S58 sprintf "p1_%d", ir3
ar0 chnget S58
S61 sprintf "p2_%d", ir3
ar1 chnget S61
 chnclear S58
 chnclear S61
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S84 sprintf "alive_%d", ir3
 chnset kr0, S84
endin

instr 74
arl0 init 0.0
ar0, ar1 subinstr 73
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 73
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 72
    ir13 = 1.0
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 72
arl0 init 0.0
ar0, ar1 subinstr 71
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 71
krl0 init 10.0
ir3 FreePort 
krl1 init 0.0
ir7 = 1.0
kr0 metro ir7
if (kr0 == 1.0) then
    kr0 = krl1
    ir13 = 0.0
    ar0 random ir13, ir7
    krl0 = 2.0
    ir18 = 70
    ir19 = 0.0
    ir20 = 0.0
    kr1 random ir20, ir7
    ir22 = 0.0
    kr2 random ir22, ir7
    ir24 = 0.0
    kr3 random ir24, ir7
    if (kr3 < 1.0) then
    kr4 = 0.125
else
    kr4 = 0.125
endif
    if (kr2 < 0.75) then
    kr3 = 0.125
else
    kr3 = kr4
endif
    if (kr1 < 0.5) then
    kr2 = 0.125
else
    kr2 = kr3
endif
    kr1 = (kr2 * 1.0)
    ir30 = 0.0
    kr2 random ir30, ir7
    ir32 = 0.0
    kr3 random ir32, ir7
    ir34 = 0.0
    kr4 random ir34, ir7
    if (kr4 < 1.0) then
    kr5 = 2.0
else
    kr5 = 2.0
endif
    if (kr3 < 0.75) then
    kr4 = 1.0
else
    kr4 = kr5
endif
    if (kr2 < 0.5) then
    kr3 = 0.0
else
    kr3 = kr4
endif
     event "i", ir18, ir19, kr1, kr3, ir3
    kr1 = krl1
    krl1 = kr1
endif
S46 sprintf "p1_%d", ir3
ar1 chnget S46
S49 sprintf "p2_%d", ir3
ar2 chnget S49
 chnclear S46
 chnclear S49
arl2 init 0.0
arl3 init 0.0
arl2 = ar1
arl3 = ar2
ar1 = arl2
ar2 = arl3
 outs ar1, ar2
kr1 = krl0
S72 sprintf "alive_%d", ir3
 chnset kr1, S72
endin

instr 70
arl0 init 0.0
ar0, ar1 subinstr 65
ar2 = (ar0 + ar1)
ar0 = (ar2 / 2.0)
ir8 = 0.35
ar1, ar2 pan2 ar0, ir8
ar0, ar3 subinstr 67
ar4 = (ar0 + ar3)
ar0 = (ar4 / 2.0)
ir16 = 0.65
ar3, ar4 pan2 ar0, ir16
ar0, ar5 subinstr 69
ar6 = (ar0 + ar5)
ar0 = (ar6 / 2.0)
ar5, ar6 pan2 ar0, ir16
if (2.0 == p4) then
    ar0 = ar5
else
    ar0 = ar1
endif
if (1.0 == p4) then
    ar5 = ar3
else
    ar5 = ar0
endif
if (0.0 == p4) then
    ar0 = ar1
else
    ar0 = ar5
endif
arl0 = ar0
ar0 = arl0
S33 sprintf "p1_%d", p5
 chnmix ar0, S33
arl1 init 0.0
if (2.0 == p4) then
    ar0 = ar6
else
    ar0 = ar2
endif
if (1.0 == p4) then
    ar1 = ar4
else
    ar1 = ar0
endif
if (0.0 == p4) then
    ar0 = ar2
else
    ar0 = ar1
endif
arl1 = ar0
ar0 = arl1
S48 sprintf "p2_%d", p5
 chnmix ar0, S48
S51 sprintf "alive_%d", p5
kr0 chnget S51
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S51
endin

instr 69
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 68
    ir13 = 0.125
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 68
arl0 init 0.0
kr0 transeg 1.0, 0.48, -10.0, 1.0e-3, 1.0, 0.0, 1.0e-3
ar0 upsamp kr0
ar1 = (-ar0)
ir5 = 1.0
ir6 = 0.0
ir7 = octave(ir6)
kr0 = (90.0 * ir7)
ar0 upsamp kr0
ir9 = (90.0 * ir7)
ir10 = (0.125 / ir9)
ar2 expsega 5.0, ir10, 1.0, 1.0, 1.0
ar3 = (ar0 * ar2)
ir13 = rnd(ir5)
ar0 oscil3 ir5, ar3, 4, ir13
ar2 = (ar1 * ar0)
kr0 transeg 1.0, 0.48, -6.0, 1.0e-3, 1.0, 0.0, 1.0e-3
ar0 upsamp kr0
ir17 = 0.4
ar1 noise ir5, ir17
kr0 = octave(ir6)
kr1 = (40.0 * kr0)
ir21 = 800.0
ar3 reson ar1, kr1, ir21, 1.0
kr1 = (100.0 * kr0)
ar1 buthp ar3, kr1
kr1 = (600.0 * kr0)
ar3 butlp ar1, kr1
ar1 = (ar0 * ar3)
ar0 = (ar2 + ar1)
ir29 = 9.0e-2
kr0 = birnd(ir29)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S37 sprintf "p1_%d", p4
 chnmix ar0, S37
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S46 sprintf "p2_%d", p4
 chnmix ar0, S46
S49 sprintf "alive_%d", p4
kr0 chnget S49
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S49
endin

instr 67
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 66
    ir13 = 0.125
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 66
arl0 init 0.0
kr0 transeg 1.0, 0.48, -10.0, 1.0e-3, 1.0, 0.0, 1.0e-3
ar0 upsamp kr0
ar1 = (-ar0)
ir5 = 1.0
ir6 = 0.0
ir7 = octave(ir6)
kr0 = (133.0 * ir7)
ar0 upsamp kr0
ir9 = (133.0 * ir7)
ir10 = (0.125 / ir9)
ar2 expsega 5.0, ir10, 1.0, 1.0, 1.0
ar3 = (ar0 * ar2)
ir13 = rnd(ir5)
ar0 oscil3 ir5, ar3, 4, ir13
ar2 = (ar1 * ar0)
kr0 transeg 1.0, 0.48, -6.0, 1.0e-3, 1.0, 0.0, 1.0e-3
ar0 upsamp kr0
ir17 = 0.4
ar1 noise ir5, ir17
kr0 = octave(ir6)
kr1 = (400.0 * kr0)
ir21 = 800.0
ar3 reson ar1, kr1, ir21, 1.0
kr1 = (100.0 * kr0)
ar1 buthp ar3, kr1
kr1 = (600.0 * kr0)
ar3 butlp ar1, kr1
ar1 = (ar0 * ar3)
ar0 = (ar2 + ar1)
ir29 = 9.0e-2
kr0 = birnd(ir29)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S37 sprintf "p1_%d", p4
 chnmix ar0, S37
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S46 sprintf "p2_%d", p4
 chnmix ar0, S46
S49 sprintf "alive_%d", p4
kr0 chnget S49
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S49
endin

instr 65
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 64
    ir13 = 0.125
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 64
arl0 init 0.0
kr0 transeg 1.0, 0.48, -10.0, 1.0e-3, 1.0, 0.0, 1.0e-3
ar0 upsamp kr0
ar1 = (-ar0)
ir5 = 1.0
ir6 = 0.0
ir7 = octave(ir6)
kr0 = (133.0 * ir7)
ar0 upsamp kr0
ir9 = (133.0 * ir7)
ir10 = (0.125 / ir9)
ar2 expsega 5.0, ir10, 1.0, 1.0, 1.0
ar3 = (ar0 * ar2)
ir13 = rnd(ir5)
ar0 oscil3 ir5, ar3, 4, ir13
ar2 = (ar1 * ar0)
kr0 transeg 1.0, 0.48, -6.0, 1.0e-3, 1.0, 0.0, 1.0e-3
ar0 upsamp kr0
ir17 = 0.4
ar1 noise ir5, ir17
kr0 = octave(ir6)
kr1 = (400.0 * kr0)
ir21 = 800.0
ar3 reson ar1, kr1, ir21, 1.0
kr1 = (100.0 * kr0)
ar1 buthp ar3, kr1
kr1 = (600.0 * kr0)
ar3 butlp ar1, kr1
ar1 = (ar0 * ar3)
ar0 = (ar2 + ar1)
ir29 = 9.0e-2
kr0 = birnd(ir29)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S37 sprintf "p1_%d", p4
 chnmix ar0, S37
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S46 sprintf "p2_%d", p4
 chnmix ar0, S46
S49 sprintf "alive_%d", p4
kr0 chnget S49
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S49
endin

instr 63
krl0 init 10.0
ir3 FreePort 
ir5 = 0.12121212121212122
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 30.0
    ir11 = 62
    ir12 = 0.0
    ir13 = 1.0
    ir14 = 1.0
     event "i", ir11, ir12, ir13, ir14, ir3
    ir17 = 62
    ir18 = 0.875
    ir19 = 1.0
    ir20 = 0.5
     event "i", ir17, ir18, ir19, ir20, ir3
    ir23 = 62
    ir24 = 1.25
    ir25 = 1.0
    ir26 = 0.25
     event "i", ir23, ir24, ir25, ir26, ir3
    ir29 = 62
    ir30 = 1.375
    ir31 = 1.0
    ir32 = 1.0
     event "i", ir29, ir30, ir31, ir32, ir3
    ir35 = 62
    ir36 = 1.5
    ir37 = 1.0
    ir38 = 0.5
     event "i", ir35, ir36, ir37, ir38, ir3
    ir41 = 62
    ir42 = 2.75
    ir43 = 1.0
    ir44 = 0.25
     event "i", ir41, ir42, ir43, ir44, ir3
    ir47 = 62
    ir48 = 3.625
    ir49 = 1.0
    ir50 = 1.0
     event "i", ir47, ir48, ir49, ir50, ir3
    ir53 = 62
    ir54 = 4.0
    ir55 = 1.0
    ir56 = 0.5
     event "i", ir53, ir54, ir55, ir56, ir3
    ir59 = 62
    ir60 = 4.125
    ir61 = 1.0
    ir62 = 0.25
     event "i", ir59, ir60, ir61, ir62, ir3
    ir65 = 62
    ir66 = 4.25
    ir67 = 1.0
    ir68 = 1.0
     event "i", ir65, ir66, ir67, ir68, ir3
    ir71 = 62
    ir72 = 5.5
    ir73 = 1.0
    ir74 = 0.5
     event "i", ir71, ir72, ir73, ir74, ir3
    ir77 = 62
    ir78 = 6.375
    ir79 = 1.0
    ir80 = 0.25
     event "i", ir77, ir78, ir79, ir80, ir3
    ir83 = 62
    ir84 = 6.75
    ir85 = 1.0
    ir86 = 1.0
     event "i", ir83, ir84, ir85, ir86, ir3
    ir89 = 62
    ir90 = 6.875
    ir91 = 1.0
    ir92 = 0.5
     event "i", ir89, ir90, ir91, ir92, ir3
    ir95 = 62
    ir96 = 7.0
    ir97 = 1.0
    ir98 = 0.25
     event "i", ir95, ir96, ir97, ir98, ir3
endif
S103 sprintf "p1_%d", ir3
ar0 chnget S103
S106 sprintf "p2_%d", ir3
ar1 chnget S106
 chnclear S103
 chnclear S106
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S129 sprintf "alive_%d", ir3
 chnset kr0, S129
endin

instr 62
arl0 init 0.0
arl1 init 0.0
ir5 = 0.0
ir6 = 1.0
ir7 random ir5, ir6
if (ir7 < 0.6) then
    ar0, ar1 subinstr 61
    arl0 = ar0
    ar0, ar2 subinstr 61
    arl1 = ar2
endif
if (ir7 >= 0.6) then
    arl0 = 0.0
    arl1 = 0.0
endif
ar2 = arl0
ar3 = arl1
arl2 init 0.0
ar4 = (p4 * ar2)
arl2 = ar4
ar2 = arl2
S40 sprintf "p1_%d", p5
 chnmix ar2, S40
arl3 init 0.0
ar2 = (p4 * ar3)
arl3 = ar2
ar2 = arl3
S50 sprintf "p2_%d", p5
 chnmix ar2, S50
S53 sprintf "alive_%d", p5
kr0 chnget S53
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S53
endin

instr 61
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 60
    ir13 = 1.0
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 60
arl0 init 0.0
ar0, ar1 subinstr 59
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 59
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 58
    ir13 = 0.125
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 58
arl0 init 0.0
ar0 expsega 0.4, 1.1200000000000002e-2, 1.0, 8.0e-3, 5.0e-2, 4.000000000000001e-2, 1.0e-3, 1.0, 1.0e-3
ir4 = 0.75
ir5 = 0.0
ar1 noise ir4, ir5
kr0 = octave(ir5)
kr1 = (6000.0 * kr0)
ir9 = 20.0
kr2 = (sr / 2.0)
kr3 limit kr1, ir9, kr2
ar2 buthp ar1, kr3
kr1 = (12000.0 * kr0)
kr0 = (sr / 3.0)
kr2 limit kr1, ir9, kr0
ar1 butlp ar2, kr2
ar2 = (ar0 * ar1)
ir18 = 9.0e-2
kr0 = birnd(ir18)
ar0 upsamp kr0
ar1 = (1.0 + ar0)
ar0 = (ar2 * ar1)
arl0 = ar0
ar1 = arl0
S26 sprintf "p1_%d", p4
 chnmix ar1, S26
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S35 sprintf "p2_%d", p4
 chnmix ar0, S35
S38 sprintf "alive_%d", p4
kr0 chnget S38
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S38
endin

instr 57
krl0 init 10.0
ir3 FreePort 
ir5 = 0.25
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 18.0
    ir11 = 56
    ir12 = 0.0
    ir13 = 1.0
     event "i", ir11, ir12, ir5, ir13, ir3
    ir16 = 56
    ir17 = 0.375
    ir18 = 0.5
     event "i", ir16, ir17, ir5, ir18, ir3
    ir21 = 56
    ir22 = 0.75
     event "i", ir21, ir22, ir5, ir5, ir3
    ir25 = 56
    ir26 = 1.0
    ir27 = 1.0
     event "i", ir25, ir26, ir5, ir27, ir3
    ir30 = 56
    ir31 = 1.375
    ir32 = 0.5
     event "i", ir30, ir31, ir5, ir32, ir3
    ir35 = 56
    ir36 = 1.75
     event "i", ir35, ir36, ir5, ir5, ir3
    ir39 = 56
    ir40 = 2.0
    ir41 = 1.0
     event "i", ir39, ir40, ir5, ir41, ir3
    ir44 = 56
    ir45 = 2.375
    ir46 = 0.5
     event "i", ir44, ir45, ir5, ir46, ir3
    ir49 = 56
    ir50 = 2.75
     event "i", ir49, ir50, ir5, ir5, ir3
endif
S55 sprintf "p1_%d", ir3
ar0 chnget S55
S58 sprintf "p2_%d", ir3
ar1 chnget S58
 chnclear S55
 chnclear S58
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S81 sprintf "alive_%d", ir3
 chnset kr0, S81
endin

instr 56
arl0 init 0.0
arl1 init 0.0
ir5 = 0.0
ir6 = 1.0
ir7 random ir5, ir6
if (ir7 < 0.8) then
    ar0, ar1 subinstr 55
    arl0 = ar0
    ar0, ar2 subinstr 55
    arl1 = ar2
endif
if (ir7 >= 0.8) then
    arl0 = 0.0
    arl1 = 0.0
endif
ar2 = arl0
ar3 = arl1
arl2 init 0.0
ar4 = (p4 * ar2)
arl2 = ar4
ar2 = arl2
S40 sprintf "p1_%d", p5
 chnmix ar2, S40
arl3 init 0.0
ar2 = (p4 * ar3)
arl3 = ar2
ar2 = arl3
S50 sprintf "p2_%d", p5
 chnmix ar2, S50
S53 sprintf "alive_%d", p5
kr0 chnget S53
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S53
endin

instr 55
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 54
    ir13 = 0.25
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 54
arl0 init 0.0
ar0, ar1 subinstr 53
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 53
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 52
    ir13 = 0.125
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 52
arl0 init 0.0
ar0 expsega 1.0, 0.4, 1.0e-3, 1.0, 1.0e-3
ir4 = 1.0
ir5 = 0.0
kr0 = octave(ir5)
kr1 = (296.0 * kr0)
kr0 = (1.0 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
kr0 = (0.962 * kr1)
kr2 = rnd(ir4)
ar2 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar1 + ar2)
kr0 = (1.233 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar2 = (ar3 + ar1)
kr0 = (1.175 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar2 + ar1)
kr0 = (1.419 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar2 = (ar3 + ar1)
kr0 = (2.821 * kr1)
kr1 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr1
ar3 = (ar2 + ar1)
ar1 = (0.5 * ar3)
ir32 = 0.0
kr0 = octave(ir32)
kr1 = (5000.0 * kr0)
ir35 = 5000.0
ar2 reson ar1, kr1, ir35, 1.0
ar1 buthp ar2, ir35
ar2 buthp ar1, ir35
ar1 = (ar0 * ar2)
ir40 = 0.8
ar2 noise ir40, ir5
kr0 expseg 20000.0, 0.7, 9000.0, 0.30000000000000004, 9000.0, 1.0, 9000.0
ar3 butlp ar2, kr0
ir44 = 8000.0
ar2 buthp ar3, ir44
ar3 = (ar0 * ar2)
ar0 = (ar1 + ar3)
ir48 = 9.0e-2
kr0 = birnd(ir48)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S56 sprintf "p1_%d", p4
 chnmix ar0, S56
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S65 sprintf "p2_%d", p4
 chnmix ar0, S65
S68 sprintf "alive_%d", p4
kr0 chnget S68
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S68
endin

instr 51
krl0 init 10.0
ir3 FreePort 
ir5 = 2.5e-2
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 2.0
    ir11 = 50
    ir12 = 0.0
    ir13 = 40.0
     event "i", ir11, ir12, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 50
arl0 init 0.0
ar0, ar1 subinstr 31
ar2, ar3 subinstr 49
ar4 = (ar0 + ar2)
arl0 = ar4
ar0 = arl0
S12 sprintf "p1_%d", p4
 chnmix ar0, S12
arl1 init 0.0
ar0 = (ar1 + ar3)
arl1 = ar0
ar0 = arl1
S24 sprintf "p2_%d", p4
 chnmix ar0, S24
S27 sprintf "alive_%d", p4
kr0 chnget S27
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S27
endin

instr 49
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 48
    ir13 = 16.0
    ir14 = 604800.0
     event "i", ir12, ir13, ir14, ir3
endif
S19 sprintf "p1_%d", ir3
ar0 chnget S19
S22 sprintf "p2_%d", ir3
ar1 chnget S22
 chnclear S19
 chnclear S22
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S45 sprintf "alive_%d", ir3
 chnset kr0, S45
endin

instr 48
arl0 init 0.0
ar0, ar1 subinstr 47
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 47
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 46
    ir13 = 8.0
    ir14 = 604800.0
     event "i", ir12, ir13, ir14, ir3
endif
S19 sprintf "p1_%d", ir3
ar0 chnget S19
S22 sprintf "p2_%d", ir3
ar1 chnget S22
 chnclear S19
 chnclear S22
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S45 sprintf "alive_%d", ir3
 chnset kr0, S45
endin

instr 46
arl0 init 0.0
ar0, ar1 subinstr 45
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 45
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 44
    ir13 = 16.0
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 44
arl0 init 0.0
ar0, ar1 subinstr 37
ar2 = (9.0 * ar0)
ar0 = (ar2 / 20.0)
ar2 tablei ar0, 6, 1.0, 0.5
ar0, ar3 subinstr 43
ar4 = (8.0 * ar0)
ar0 = (ar4 / 20.0)
ar4 tablei ar0, 6, 1.0, 0.5
ar0 = (ar2 + ar4)
arl0 = ar0
ar0 = arl0
S18 sprintf "p1_%d", p4
 chnmix ar0, S18
arl1 init 0.0
ar0 = (9.0 * ar1)
ar1 = (ar0 / 20.0)
ar0 tablei ar1, 6, 1.0, 0.5
ar1 = (8.0 * ar3)
ar2 = (ar1 / 20.0)
ar1 tablei ar2, 6, 1.0, 0.5
ar2 = (ar0 + ar1)
arl1 = ar2
ar0 = arl1
S36 sprintf "p2_%d", p4
 chnmix ar0, S36
S39 sprintf "alive_%d", p4
kr0 chnget S39
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S39
endin

instr 43
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 42
    ir13 = 0.5
    ir14 = 604800.0
     event "i", ir12, ir13, ir14, ir3
endif
S19 sprintf "p1_%d", ir3
ar0 chnget S19
S22 sprintf "p2_%d", ir3
ar1 chnget S22
 chnclear S19
 chnclear S22
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S45 sprintf "alive_%d", ir3
 chnset kr0, S45
endin

instr 42
arl0 init 0.0
ar0, ar1 subinstr 41
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 41
krl0 init 10.0
ir3 FreePort 
ir5 = 1.0
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 2.0
    ir11 = 40
    ir12 = 0.0
    ir13 = 0.125
     event "i", ir11, ir12, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 40
arl0 init 0.0
ar0, ar1 subinstr 39
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 39
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 38
    ir13 = 0.125
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 38
arl0 init 0.0
ir3 = 8.5e-2
ir4 = birnd(ir3)
ir5 = (ir4 * 0.8)
ir6 = (0.8 + ir5)
ir7 = (ir6 * 0.1)
ir8 = (ir6 * 0.3)
kr0 expsegr 1.0, ir7, 1.0e-4, 1.0, 1.0e-4, ir8, 1.0e-4
ar0 upsamp kr0
ar1 = (0.75 * ar0)
ir11 = 1.0
ir12 = 8.5e-3
kr0 = birnd(ir12)
kr1 = (kr0 * 342.0)
kr0 = (342.0 + kr1)
ar0 upsamp kr0
ir16 = rnd(ir11)
ar2 oscil3 ir11, kr0, 4, ir16
ar3 = (0.5 * ar0)
ir19 = rnd(ir11)
ar0 oscil3 ir11, ar3, 4, ir19
ar3 = (ar2 + ar0)
ar0 = (ar1 * ar3)
ar1 expon 1.0, ir8, 5.0e-4
ir24 = 0.75
ir25 = 0.0
ar2 noise ir24, ir25
kr0 = birnd(ir3)
kr1 = (kr0 * 0.7)
kr0 = octave(kr1)
kr1 = (10000.0 * kr0)
ir31 = 10000.0
ar3 butbp ar2, kr1, ir31
ir33 = 1000.0
ar2 buthp ar3, ir33
kr0 expsegr 5000.0, 0.1, 3000.0, 1.0, 3000.0, ir8, 1.0e-4
ar3 butlp ar2, kr0
ar2 = (ar1 * ar3)
ar1 = (ar0 + ar2)
ir39 = 9.0e-2
kr0 = birnd(ir39)
ar0 upsamp kr0
ar2 = (1.0 + ar0)
ar0 = (ar1 * ar2)
arl0 = ar0
ar1 = arl0
S47 sprintf "p1_%d", p4
 chnmix ar1, S47
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S56 sprintf "p2_%d", p4
 chnmix ar0, S56
S59 sprintf "alive_%d", p4
kr0 chnget S59
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S59
endin

instr 37
krl0 init 10.0
ir3 FreePort 
ir5 = 0.3333333333333333
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 16.0
    ir11 = 36
    ir12 = 0.0
    ir13 = 1.0
    ir14 = 1.0
     event "i", ir11, ir12, ir13, ir14, ir3
    ir17 = 36
    ir18 = 0.5
    ir19 = 1.0
    ir20 = 0.8
     event "i", ir17, ir18, ir19, ir20, ir3
    ir23 = 36
    ir24 = 1.0
    ir25 = 1.0
    ir26 = 0.9
     event "i", ir23, ir24, ir25, ir26, ir3
    ir29 = 36
    ir30 = 1.5
    ir31 = 1.0
    ir32 = 1.0
     event "i", ir29, ir30, ir31, ir32, ir3
    ir35 = 36
    ir36 = 1.875
    ir37 = 1.0
    ir38 = 0.5
     event "i", ir35, ir36, ir37, ir38, ir3
    ir41 = 36
    ir42 = 1.9375
    ir43 = 1.0
    ir44 = 0.75
     event "i", ir41, ir42, ir43, ir44, ir3
    ir47 = 36
    ir48 = 2.0
    ir49 = 1.0
    ir50 = 0.8
     event "i", ir47, ir48, ir49, ir50, ir3
    ir53 = 36
    ir54 = 2.5
    ir55 = 1.0
    ir56 = 0.9
     event "i", ir53, ir54, ir55, ir56, ir3
endif
S61 sprintf "p1_%d", ir3
ar0 chnget S61
S64 sprintf "p2_%d", ir3
ar1 chnget S64
 chnclear S61
 chnclear S64
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S87 sprintf "alive_%d", ir3
 chnset kr0, S87
endin

instr 36
arl0 init 0.0
ar0, ar1 subinstr 35
ar2 = (p4 * ar0)
arl0 = ar2
ar0 = arl0
S10 sprintf "p1_%d", p5
 chnmix ar0, S10
arl1 init 0.0
ar0 = (p4 * ar1)
arl1 = ar0
ar0 = arl1
S21 sprintf "p2_%d", p5
 chnmix ar0, S21
S24 sprintf "alive_%d", p5
kr0 chnget S24
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S24
endin

instr 35
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 34
    ir13 = 1.0
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 34
arl0 init 0.0
ar0, ar1 subinstr 33
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 33
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 32
    ir13 = 0.125
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 32
arl0 init 0.0
ir3 = 0.5
ir4 = 5.0e-3
ir5 = birnd(ir4)
ir6 = (ir5 * 55.0)
kr0 = (55.0 + ir6)
ar0 upsamp kr0
ir8 = 5.0e-2
ir9 = birnd(ir8)
ir10 = (ir9 * 0.95)
ir11 = (0.95 + ir10)
kr0 transegr 0.5, 1.2, -4.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, ir11, 0.0, 0.0
ar1 upsamp kr0
ar2 = semitone(ar1)
ar1 = (ar0 * ar2)
ir15 = 20.0
ir16 = 1.0
ir17 = (ir11 * 0.5)
kr0 transegr 0.2, ir17, -15.0, 1.0e-2, ir17, 0.0, 0.0, 1.0, 0.0, 0.0, ir11, 0.0, 0.0
ar0 gbuzz ir3, ar1, ir15, ir16, kr0, 2
ir20 = (ir11 - 4.0e-3)
kr0 transeg 1.0, ir20, -6.0, 0.0, 1.0, 0.0, 0.0
ar1 upsamp kr0
ar2 = (ar0 * ar1)
kr0 linseg 0.0, 4.0e-3, 1.0, 1.0, 1.0
ar0 upsamp kr0
ar1 = (ar2 * ar0)
ar0 = (ar1 * 0.7)
kr0 linseg 1.0, 7.0e-2, 0.0, 1.0, 0.0
ir27 = (55.0 + ir6)
ir28 = (8.0 * ir27)
ar1 expsega ir28, 7.0e-2, 1.0e-3, 1.0, 1.0e-3
ar2 oscili kr0, ar1, 4
ar1 = (ar2 * 0.25)
ar2 = (ar0 + ar1)
ir33 = 9.0e-2
kr0 = birnd(ir33)
ar0 upsamp kr0
ar1 = (1.0 + ar0)
ar0 = (ar2 * ar1)
arl0 = ar0
ar1 = arl0
S41 sprintf "p1_%d", p4
 chnmix ar1, S41
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S50 sprintf "p2_%d", p4
 chnmix ar0, S50
S53 sprintf "alive_%d", p4
kr0 chnget S53
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S53
endin

instr 31
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 30
    ir13 = 16.0
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 30
arl0 init 0.0
ar0, ar1 subinstr 23
ar2 = (9.0 * ar0)
ar0 = (ar2 / 20.0)
ar2 tablei ar0, 6, 1.0, 0.5
ar0, ar3 subinstr 29
ar4 = (8.0 * ar0)
ar0 = (ar4 / 20.0)
ar4 tablei ar0, 6, 1.0, 0.5
ar0 = (ar2 + ar4)
arl0 = ar0
ar0 = arl0
S18 sprintf "p1_%d", p4
 chnmix ar0, S18
arl1 init 0.0
ar0 = (9.0 * ar1)
ar1 = (ar0 / 20.0)
ar0 tablei ar1, 6, 1.0, 0.5
ar1 = (8.0 * ar3)
ar2 = (ar1 / 20.0)
ar1 tablei ar2, 6, 1.0, 0.5
ar2 = (ar0 + ar1)
arl1 = ar2
ar0 = arl1
S36 sprintf "p2_%d", p4
 chnmix ar0, S36
S39 sprintf "alive_%d", p4
kr0 chnget S39
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S39
endin

instr 29
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 28
    ir13 = 0.5
    ir14 = 604800.0
     event "i", ir12, ir13, ir14, ir3
endif
S19 sprintf "p1_%d", ir3
ar0 chnget S19
S22 sprintf "p2_%d", ir3
ar1 chnget S22
 chnclear S19
 chnclear S22
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S45 sprintf "alive_%d", ir3
 chnset kr0, S45
endin

instr 28
arl0 init 0.0
ar0, ar1 subinstr 27
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 27
krl0 init 10.0
ir3 FreePort 
ir5 = 1.0
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 2.0
    ir11 = 26
    ir12 = 0.0
    ir13 = 0.125
     event "i", ir11, ir12, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 26
arl0 init 0.0
ar0, ar1 subinstr 25
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 25
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 24
    ir13 = 0.125
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 24
arl0 init 0.0
ir3 = 8.5e-2
ir4 = birnd(ir3)
ir5 = (ir4 * 0.8)
ir6 = (0.8 + ir5)
ir7 = (ir6 * 0.1)
ir8 = (ir6 * 0.3)
kr0 expsegr 1.0, ir7, 1.0e-4, 1.0, 1.0e-4, ir8, 1.0e-4
ar0 upsamp kr0
ar1 = (0.75 * ar0)
ir11 = 1.0
ir12 = 8.5e-3
kr0 = birnd(ir12)
kr1 = (kr0 * 342.0)
kr0 = (342.0 + kr1)
ar0 upsamp kr0
ir16 = rnd(ir11)
ar2 oscil3 ir11, kr0, 4, ir16
ar3 = (0.5 * ar0)
ir19 = rnd(ir11)
ar0 oscil3 ir11, ar3, 4, ir19
ar3 = (ar2 + ar0)
ar0 = (ar1 * ar3)
ar1 expon 1.0, ir8, 5.0e-4
ir24 = 0.75
ir25 = 0.0
ar2 noise ir24, ir25
kr0 = birnd(ir3)
kr1 = (kr0 * 0.7)
kr0 = octave(kr1)
kr1 = (10000.0 * kr0)
ir31 = 10000.0
ar3 butbp ar2, kr1, ir31
ir33 = 1000.0
ar2 buthp ar3, ir33
kr0 expsegr 5000.0, 0.1, 3000.0, 1.0, 3000.0, ir8, 1.0e-4
ar3 butlp ar2, kr0
ar2 = (ar1 * ar3)
ar1 = (ar0 + ar2)
ir39 = 9.0e-2
kr0 = birnd(ir39)
ar0 upsamp kr0
ar2 = (1.0 + ar0)
ar0 = (ar1 * ar2)
arl0 = ar0
ar1 = arl0
S47 sprintf "p1_%d", p4
 chnmix ar1, S47
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S56 sprintf "p2_%d", p4
 chnmix ar0, S56
S59 sprintf "alive_%d", p4
kr0 chnget S59
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S59
endin

instr 23
krl0 init 10.0
ir3 FreePort 
ir5 = 0.3333333333333333
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 16.0
    ir11 = 22
    ir12 = 0.0
    ir13 = 1.0
    ir14 = 1.0
     event "i", ir11, ir12, ir13, ir14, ir3
    ir17 = 22
    ir18 = 0.5
    ir19 = 1.0
    ir20 = 0.8
     event "i", ir17, ir18, ir19, ir20, ir3
    ir23 = 22
    ir24 = 1.0
    ir25 = 1.0
    ir26 = 0.9
     event "i", ir23, ir24, ir25, ir26, ir3
    ir29 = 22
    ir30 = 1.5
    ir31 = 1.0
    ir32 = 1.0
     event "i", ir29, ir30, ir31, ir32, ir3
    ir35 = 22
    ir36 = 1.875
    ir37 = 1.0
    ir38 = 0.5
     event "i", ir35, ir36, ir37, ir38, ir3
    ir41 = 22
    ir42 = 1.9375
    ir43 = 1.0
    ir44 = 0.75
     event "i", ir41, ir42, ir43, ir44, ir3
    ir47 = 22
    ir48 = 2.0
    ir49 = 1.0
    ir50 = 0.8
     event "i", ir47, ir48, ir49, ir50, ir3
    ir53 = 22
    ir54 = 2.5
    ir55 = 1.0
    ir56 = 0.9
     event "i", ir53, ir54, ir55, ir56, ir3
endif
S61 sprintf "p1_%d", ir3
ar0 chnget S61
S64 sprintf "p2_%d", ir3
ar1 chnget S64
 chnclear S61
 chnclear S64
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S87 sprintf "alive_%d", ir3
 chnset kr0, S87
endin

instr 22
arl0 init 0.0
ar0, ar1 subinstr 21
ar2 = (p4 * ar0)
arl0 = ar2
ar0 = arl0
S10 sprintf "p1_%d", p5
 chnmix ar0, S10
arl1 init 0.0
ar0 = (p4 * ar1)
arl1 = ar0
ar0 = arl1
S21 sprintf "p2_%d", p5
 chnmix ar0, S21
S24 sprintf "alive_%d", p5
kr0 chnget S24
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S24
endin

instr 21
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 20
    ir13 = 1.0
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 20
arl0 init 0.0
ar0, ar1 subinstr 19
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 19
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 18
    ir13 = 0.125
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 18
arl0 init 0.0
ir3 = 0.5
ir4 = 5.0e-3
ir5 = birnd(ir4)
ir6 = (ir5 * 55.0)
kr0 = (55.0 + ir6)
ar0 upsamp kr0
ir8 = 5.0e-2
ir9 = birnd(ir8)
ir10 = (ir9 * 0.95)
ir11 = (0.95 + ir10)
kr0 transegr 0.5, 1.2, -4.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, ir11, 0.0, 0.0
ar1 upsamp kr0
ar2 = semitone(ar1)
ar1 = (ar0 * ar2)
ir15 = 20.0
ir16 = 1.0
ir17 = (ir11 * 0.5)
kr0 transegr 0.2, ir17, -15.0, 1.0e-2, ir17, 0.0, 0.0, 1.0, 0.0, 0.0, ir11, 0.0, 0.0
ar0 gbuzz ir3, ar1, ir15, ir16, kr0, 2
ir20 = (ir11 - 4.0e-3)
kr0 transeg 1.0, ir20, -6.0, 0.0, 1.0, 0.0, 0.0
ar1 upsamp kr0
ar2 = (ar0 * ar1)
kr0 linseg 0.0, 4.0e-3, 1.0, 1.0, 1.0
ar0 upsamp kr0
ar1 = (ar2 * ar0)
ar0 = (ar1 * 0.7)
kr0 linseg 1.0, 7.0e-2, 0.0, 1.0, 0.0
ir27 = (55.0 + ir6)
ir28 = (8.0 * ir27)
ar1 expsega ir28, 7.0e-2, 1.0e-3, 1.0, 1.0e-3
ar2 oscili kr0, ar1, 4
ar1 = (ar2 * 0.25)
ar2 = (ar0 + ar1)
ir33 = 9.0e-2
kr0 = birnd(ir33)
ar0 upsamp kr0
ar1 = (1.0 + ar0)
ar0 = (ar2 * ar1)
arl0 = ar0
ar1 = arl0
S41 sprintf "p1_%d", p4
 chnmix ar1, S41
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S50 sprintf "p2_%d", p4
 chnmix ar0, S50
S53 sprintf "alive_%d", p4
kr0 chnget S53
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S53
endin

</CsInstruments>

<CsScore>

f6 0 2048 8  -0.9981778976111987 146.0 -0.9950547536867305 146.0 -0.9866142981514303 146.0 -0.9640275800758169 146.0 -0.9051482536448664 146.0 -0.7615941559557649 146.0 -0.46211715726000974 146.0 0.0 146.0 0.46211715726000974 146.0 0.7615941559557649 146.0 0.9051482536448664 146.0 0.9640275800758169 146.0 0.9866142981514303 146.0 0.9950547536867305 146.0 0.9981778976111987
f4 0 8192 10  1.0
f2 0 8192 11  1.0

f0 604800.0

i 79 0.0 -1.0 
i 78 0.0 -1.0 
i 76 0.0 -1.0 

</CsScore>




</CsoundSynthesizer>
