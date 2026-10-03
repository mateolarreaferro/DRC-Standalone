<CsoundSynthesizer>
<CsInstruments>; dizi.orc

; instr 11 - dizi
; instr 194 - reverb

ksmps = 32
nchnls=1

giseed = .5
giwtsin = 1
garev	init 	0
;-----------------------------------------------------------------------------------------------------------------------

instr 11							; dizi

; 	parameters
;	p4	overall amplitude scaling factor
;	p5	pitch in Hertz (normal pitch range: A3-G7)
;	p6	percent vibrato depth, recommended values in range [-1., +1.]
;			0.0	-> no vibrato
;			+1.	-> 1% vibrato depth, where vibrato rate increases slightly
;			-1.	-> 1% vibrato depth, where vibrato rate decreases slightly
;	p7	attack time in seconds 
;			recommended value:  .12 for slurred notes, .07 for tongued notes 
;				(.03 for short notes)
;	p8	decay time in seconds 
;			recommended value:  .14 (.04 for short notes)
;	p9	overall brightness / filter cutoff factor 
;			1 -> least bright / minimum filter cutoff frequency (40 Hz)
;			9 -> brightest / maximum filter cutoff frequency (10,240Hz)

							; initial variables
iampscale	=	p4				; overall amplitude scaling factor
ifreq		=	cpspch(p5)				; pitch in Hertz
ivibdepth	=	abs(p6*ifreq/100.0)		; vibrato depth relative to fundamental frequency
iattack		=	p7 * (1.1 - .2*giseed)		; attack time with up to +-10% random deviation
giseed		=	frac(giseed*105.947)		; reset giseed
idecay		=	p8 * (1.1 - .2*giseed)		; decay time with up to +-10% random deviation
giseed		=	frac(giseed*105.947)
ifiltcut	tablei	p9, 2				; lowpass filter cutoff frequency

iattack		=	(iattack < 6/kr ? 6/kr : iattack)		; minimal attack length
idecay		=	(idecay < 6/kr ? 6/kr : idecay)			; minimal decay length
isustain	=	p3 - iattack - idecay
p3		=	(isustain < 5/kr ? iattack+idecay+5/kr : p3)	; minimal sustain length
isustain	=	(isustain < 5/kr ? 5/kr : isustain)			
iatt		=	iattack/6
isus		=	isustain/4
idec		=	idecay/6
iphase		=	giseed				; use same phase for all wavetables
giseed		=	frac(giseed*105.947)

							; vibrato block
kvibdepth	linseg	.1, .8*.625, 1, .2*.625, .7
kvibdepth	=	kvibdepth* ivibdepth		; vibrato depth
kvibdepthr	randi	.1*kvibdepth, 5, giseed		; up to 10% vibrato depth variation
giseed		= 	frac(giseed*105.947)
kvibdepth	=	kvibdepth + kvibdepthr
ivibr1		=	giseed				; vibrato rate
giseed		=	frac(giseed*105.947)
ivibr2		=	giseed
giseed		=	frac(giseed*105.947)

if p6 < 0 goto vibrato1
kvibrate	linseg	2.5+ivibr1, .625, 4.5+ivibr2, 1, 4.5+ivibr2  	; if p6 positive vibrato gets faster
goto vibrato2
vibrato1:
ivibr3		=	giseed
giseed		= 	frac(giseed*105.947)
kvibrate	linseg	3.5+ivibr1, .1, 4.5+ivibr2, .625-.1, 2.5+ivibr3, 1, 2.5+ivibr3    ; if p6 negative vibrato gets slower
vibrato2:
kvibrater	randi	.1*kvibrate, 5, giseed		; up to 10% vibrato rate variation
giseed		= 	frac(giseed*105.947)
kvibrate	=	kvibrate + kvibrater
kvib		oscil	kvibdepth, kvibrate, giwtsin

ifdev1	= 	-.03 * giseed				; frequency deviation
giseed	=	frac(giseed*105.947)
ifdev2	= 	.003 * giseed
giseed	=	frac(giseed*105.947)
ifdev3	= 	-.0015 * giseed
giseed	=	frac(giseed*105.947)
ifdev4	= 	.012 * giseed
giseed	=	frac(giseed*105.947)
kfreqr	linseg	ifdev1, iattack, ifdev2, isustain, ifdev3, idecay, ifdev4
kfreq	= 	ifreq * (1 + kfreqr) + kvib

if ifreq <  320 goto range1				; Eb4 - E4
if ifreq <  480 goto range2				; Bb4 - B4
if ifreq <  680 goto range3				; E5 - F5
if ifreq <  905 goto range4				; A5 - Bb5
if ifreq <  1280 goto range5				; Eb6 - E6
if ifreq <  1710 goto range6				; Ab6 - A6
goto range7
							; wavetable amplitude envelopes
range1:							; for very low range tones
amp1	linseg 0, .4*iattack, 1500,  .6*iattack, 10000,  .5*isustain, 11000,  .5*isustain, 9000, .4*idecay, 8000, .3*idecay, 1500, .3*idecay, 0
amp2	linseg 0, .4*iattack, 200,  .1*iattack, 1000,   .5*iattack, 6000,  .1*isustain, 11000,  .3*isustain, 13000,  .6*isustain, 12000,  .6*idecay, 1500, .4*idecay, 0
amp3	linseg 0, .5*iattack, 30,  .5*iattack, 500,  .1*isustain, 1200,  .7*isustain, 2200,  .2*isustain, 1750, .5*idecay, 250, .2*idecay, 0, 1, 0
iwt1 = 	11
iwt2 = 	20
iwt3 = 	21
inorm = 	32875
goto end

range2:							; for very low range tones
amp1	linseg 0, .4*iattack, 2000,  .3*iattack, 6000,  .3*iattack, 25000,  .5*isustain, 24000,  .5*isustain, 20000, .4*idecay, 5000, .3*idecay, 1500, .3*idecay, 0
amp2	linseg 0, .5*iattack, 100,  .5*iattack, 3000,  .1*isustain, 4500,  .4*isustain, 2000,  .4*isustain, 2200,  .1*isustain, 500, .5*idecay, 150, .5*idecay, 0
amp3	linseg 0, .5*iattack, 30,  .5*iattack, 500,  .1*isustain, 1200,  .7*isustain, 2200,  .2*isustain, 1750, .5*idecay, 250, .2*idecay, 0, 1, 0
iwt1 = 	11
iwt2 = 	22
iwt3 = 	23
inorm = 	26080
goto end

range3:							; for low range tones
amp1	linseg 0, iatt, 0.000, iatt, 0.219, iatt, 0.500, iatt, 0.889, iatt, 1.035, iatt, 0.963, isus, 0.424, isus, 0.135, isus, 0.108, isus, 0.204, idec, 0.445, idec, 0.531, idec, 0.513, idec, 0.365, idec, 0.053, idec, 0
amp2	linseg 0, iatt, 0.000, iatt, -0.106, iatt, -0.112, iatt, -0.187, iatt, -0.091, iatt, 0.056, isus, 0.558, isus, 0.901, isus, 0.904, isus, 0.729, idec, 0.303, idec, 0.057, idec, 0.016, idec, -0.076, idec, -0.016, idec, 0
amp3	linseg 0, iatt, 1.000, iatt, 0.607, iatt, -0.116, iatt, -0.205, iatt, -0.530, iatt, -0.195, isus, 0.601, isus, 0.478, isus, -0.371, isus, -0.916, idec, -0.782, idec, -0.107, idec, -0.811, idec, -0.189, idec, -0.036, idec, 0
iwt1 = 	24
iwt2 = 	25
iwt3 = 	26
inorm = 	24364
goto end

range4:							; for low mid-range tones 
amp1	linseg 0, iatt, 0.000, iatt, 0.049, iatt, 0.027, iatt, 0.005, iatt, -0.020, iatt, 0.378, isus, 0.925, isus, 1.032, isus, 1.106, isus, 0.915, idec, 0.858, idec, 0.722, idec, 0.250, idec, -0.002, idec, 0.004, idec, 0
amp2	linseg 0, iatt, 0.000, iatt, -0.182, iatt, -0.029, iatt, 0.397, iatt, 2.065, iatt, 3.136, isus, 0.250, isus, -0.685, isus, -1.369, isus, -1.176, idec, -1.023, idec, -0.212, idec, 0.810, idec, 0.469, idec, 0.018, idec, 0
amp3	linseg 0, iatt, 1.000, iatt, 0.007, iatt, 1.039, iatt, 0.466, iatt, 0.627, iatt, 4.181, isus, -2.481, isus, -2.529, isus, -4.838, isus, 0.137, idec, -2.823, idec, -1.899, idec, 4.910, idec, 0.319, idec, 0.039, idec, 0
iwt1 = 	27
iwt2 = 	28
iwt3 = 	29
inorm = 	27832
goto end

range5:							; for high mid-range tones 
amp1	linseg 0, iatt, 0.000, iatt, 0.000, iatt, 0.018, iatt, 0.000, iatt, 0.450, iatt, 1.130, isus, 1.475, isus, 1.682, isus, 1.533, isus, 1.243, idec, 0.945, idec, 0.681, idec, 0.210, idec, 0.046, idec, 0.004, idec, 0
amp2	linseg 0, iatt, 0.000, iatt, 0.102, iatt, 0.196, iatt, 1.000, iatt, 1.108, iatt, -0.024, isus, -1.557, isus, -2.443, isus, -1.553, isus, -0.979, idec, -0.268, idec, -0.271, idec, -0.015, idec, 0.017, idec, 0.108, idec, 0
amp3	linseg 0, iatt, 1.000, iatt, 0.423, iatt, 0.287, iatt, 0.000, iatt, -0.987, iatt, -0.621, isus, 3.030, isus, 2.349, isus, 3.075, isus, 0.331, idec, 0.994, idec, -1.319, idec, -0.378, idec, 0.000, idec, -0.023, idec, 0
iwt1 = 	30
iwt2 = 	31
iwt3 = 	32
inorm = 	27918
goto end

range6:							; for high range tones
amp1	linseg 0, iatt, 0.000, iatt, 0.322, iatt, 0.115, iatt, 0.090, iatt, -0.148, iatt, 1.743, isus, 2.079, isus, 0.844, isus, 0.889, isus, 1.914, idec, 0.718, idec, 0.206, idec, 0.361, idec, -0.278, idec, -0.272, idec, 0
amp2	linseg 0, iatt, 1.000, iatt, 2.675, iatt, 1.579, iatt, -0.879, iatt, -4.025, iatt, -9.342, isus, 4.570, isus, -3.372, isus, -2.904, isus, 0.755, idec, 5.796, idec, -3.764, idec, 2.193, idec, 0.718, idec, 1.029, idec, 0
amp3	linseg 0, iatt, 0.000, iatt, -0.334, iatt, -0.108, iatt, 0.028, iatt, 0.765, iatt, -0.874, isus, -1.222, isus, 0.236, isus, 0.187, isus, -1.036, idec, 0.276, idec, 0.532, idec, -0.204, idec, 0.311, idec, 0.283, idec, 0
iwt1 = 	33
iwt2 = 	34
iwt3 = 	35
inorm = 	23538
goto end

range7:							; for very high range tones 
amp1	linseg 0, iatt, 0.000, iatt, -0.071, iatt, 0.017, iatt, 0.134, iatt, -0.068, iatt, 0.192, isus, 1.375, isus, 1.875, isus, 1.463, isus, 1.446, idec, 0.932, idec, 0.561, idec, 0.100, idec, 0.036, idec, 0.000, idec, 0
amp2	linseg 0, iatt, 1.000, iatt, 3.541, iatt, 3.665, iatt, -0.651, iatt, 1.017, iatt, 1.331, isus, -4.611, isus, -2.534, isus, -4.241, isus, -2.738, idec, -0.609, idec, -1.065, idec, 1.122, idec, 0.605, idec, 0.093, idec, 0
amp3	linseg 0, iatt, 0.000, iatt, 0.061, iatt, 0.093, iatt, 0.323, iatt, 1.011, iatt, 0.819, isus, 0.162, isus, -0.152, isus, 0.080, isus, -0.139, idec, 0.051, idec, -0.054, idec, -0.019, idec, -0.013, idec, 0.003, idec, 0
iwt1 = 	36
iwt2 = 	37
iwt3 = 	38
inorm = 	30675
goto end


end:
ampr1	randi	.02*amp1, 10, giseed			; up to 2% wavetable amplitude variation
giseed	=	frac(giseed*105.947)
amp1	=	amp1 + ampr1
ampr2	randi	.02*amp2, 10, giseed			; up to 2% wavetable amplitude variation
giseed	=	frac(giseed*105.947)
amp2	=	amp2 + ampr2
ampr3	randi	.02*amp3, 10, giseed			; up to 2% wavetable amplitude variation
giseed	=	frac(giseed*105.947)
amp3	=	amp3 + ampr3

awt1	oscili	amp1, kfreq, iwt1, iphase		; wavetable lookup
awt2	oscili	amp2, kfreq, iwt2, iphase
awt3	oscili	amp3, kfreq, iwt3, iphase
asig	= 	awt1 + awt2 + awt3
asig	= 	asig*(iampscale/inorm)
kcut	linseg	0, iattack, ifiltcut, isustain, ifiltcut, idecay, 0	; lowpass filter for brightness control
afilt 	tone	asig, kcut
asig	balance	afilt, asig
garev	= 	garev + asig
	out	asig
	endin

;-----------------------------------------------------------------------------------------------------------------------

instr 194								; add reverb to global signal garev
; 	parameters
;	p4	starting reverb time
;	p5	final reverb time
;	p6	% of reverb relative to source signal

irevtime	= p4							; set first duration of reverb time
ichngtime	= p5							; set final duration of reverb time
iring		= 0
iring		= (irevtime > ichngtime ? irevtime : iring)		; set iring to the starting or ending
iring		= (ichngtime > irevtime ? ichngtime : iring)		; reverbime, whichever is longer

ireverb		= p6							; percent for reverberated signal
idur		= p3							; set the duration at p3, and then
p3		= p3 + iring						; lengthen p3 to include longer reverb time
krevtime 	linseg	irevtime, idur, irevtime, iring, ichngtime	; change duration of reverb time
arev		reverb	garev, krevtime					; add reverb to the global signal
		out	ireverb * arev					; output reverberated signal
garev = 	0							; set garev to 0 to prevent feedback
		endin

;-----------------------------------------------------------------------------------------------------------------------
</CsInstruments>
<CsScore>
; dizi.sco from Witleben p 94-95 "Zhonghua Liuban" as performed by Lu Chunling

f1 0 4097 10 1 
f2 0 16 -2 40 40 80 160 320 640 1280 2560 5120 10240 10240

f11 0 4097 -10 1

f20 0 4097 -10 0 1 .21
f21 0 4097 -10 0 0 0 1 1.3 .66 .9 .5 .8 .6 1.2 .5 .8 .6 .75 .6 .9 1.2 .9 1.1 .85 .9 .4 .3 .45 .3 .25 .15
f22 0 4097 -10 0 1 0 .33
f23 0 4097 -10 0 0 .75 0 .28 .45 .36 1 .54 .5 .81 1 .95 .9 .08 .24 .45 .41 .25 .07
f24 0 4097 -10 20742 2870 929 899 1567 958 318 1168 838 781 192  
f25 0 4097 -10 18419 4615 1255 689 3851 1889 498 3127 3041 2262 422 136  
f26 0 4097 -10 1700 331 615 259 188 164 79 393 191 108  
f27 0 4097 -10 17040 1836 3609 4228 3600 1910 9599 3722 925 862 1292 227 
f28 0 4097 -10 4206 283 125 465 341 168 201 196 199 140  
f29 0 4097 -10 24 22 129 209 54 127 
f30 0 4097 -10 13283 1588 2948 337 9009 1040 2175 222 
f31 0 4097 -10 3831 572 332 252 209 243 91 
f32 0 4097 -10 61 59 120 196 26 
f33 0 4097 -10 22605 2267 3470 1604 2849 86 
f34 0 4097 -10 97 92 113 75 63 
f35 0 4097 -10 21615 1982 3912 1422 2987 
f36 0 4097 -10 17863 3388 257 
f37 0 4097 -10 97 136 50 
f38 0 4097 -10 28207 1745 499

t0 72

;p1	p2	p3	p4	p5		p6	p7	p8	p9
;	start	dur	amp	Hertz		vibr	att	dec	bright

;--------------------------------------------
; bar 69
i11 1.0000 .5 10000 9.06 1 0.03 0.04 9	; trill
i11 1.5 .5 7200 9.04 1 0.03 0.04 9	
i11 2 .75 8100 9.09 1 0.03 0.04 9
i11 2.75 .25 6500 9.06 1 0.03 0.04 9	; trill
i11 3 .25 9000 9.04 1 0.03 0.04 9
i11 3.25 .25 6500 9.06 1 0.03 0.04 9
i11 3.5 .25 7200 9.02 1 0.03 0.04 9
i11 3.75 .25 5900 8.11 1 0.03 0.04 9	; short trill
i11 4 .5 8100 9.04 1 0.03 0.04 9
i11 4.75 .25 6500 9.06 1 0.03 0.04 9

;--------------------------------------------
; bar 70
i11 5 .25 10000 9.04 1 0.03 0.04 9		
i11 5.25 .25 6500 9.02 1 0.03 0.04 9
i11 5.5 .125 7200 9.04 1 0.03 0.04 9
i11 5.75 .25 6500 9.11 1 0.03 0.04 9	; short trill
i11 6 .25 8100 9.09 1 0.03 0.04 9
i11 6.25 .125 6500 9.09 1 0.03 0.04 9
i11 6.375 .125 5900 9.11 1 0.03 0.04 9
i11 6.5 .25 7200 9.07 1 0.03 0.04 9
i11 6.75 .25 6500 9.09 1 0.03 0.04 9
i11 7 .5 9000 9.06 1 0.03 0.04 9	; short trill
i11 7.5 .5 7200 9.06 1 0.03 0.04 9	; short trill
i11 8 .2 7200 9.07 1 0.03 0.04 9
i11 8.1 .4 8100 9.06 1 0.03 0.04 9	; short trill
i11 8.5 .25 7200 9.06 1 0.03 0.04 9
i11 8.75 .25 6500 9.09 1 0.03 0.04 9
;--------------------------------------------
; bar 71
i11 9 .125 10000 9.11 1 0.03 0.04 9		
i11 9.25 .25 6500 10.01 1 0.03 0.04 9	; short trill
i11 9.5 .125 7200 9.11 1 0.03 0.04 9
i11 9.625 .125 5900 10.01 1 0.03 0.04 9
i11 9.75 .125 6500 9.11 1 0.03 0.04 9
i11 9.875 .125 5900 9.09 1 0.03 0.04 9
i11 10 .325 8100 9.06 1 0.03 0.04 9
i11 10.375 .125 5900 9.09 1 0.03 0.04 9
i11 10.5 .125 7200 9.06 1 0.03 0.04 9
i11 10.625 .125 5900 9.09 1 0.03 0.04 9
i11 10.75 .125 6500 9.11 1 0.03 0.04 9
i11 10.875 .125 5900 10.02 1 0.03 0.04 9
i11 11 .25 9000 9.11 1 0.03 0.04 9
i11 11.25 .25 6500 10.04 1 0.03 0.04 9	; short trill
i11 11.5 .25 7200 10.02 1 0.03 0.04 9
i11 11.75 .125 6500 10.04 1 0.03 0.04 9
i11 11.875 .125 5900 10.06 1 0.03 0.04 9
i11 12. .125 8100 9.11 1 0.03 0.04 9
i11 12.125 .125 5900 10.01 1 0.03 0.04 9
i11 12.25 .125 6500 9.11 1 0.03 0.04 9
i11 12.375 .125 5900 9.09 1 0.03 0.04 9
i11 12.5 .125 7200 9.06 1 0.03 0.04 9
i11 12.625 .125 5900 9.09 1 0.03 0.04 9
i11 12.75 .125 6500 9.11 1 0.03 0.04 9
i11 12.875 .125 5900 10.02 1 0.03 0.04 9
;--------------------------------------------
; bar 72
i11 13 .5 10000 9.09 1 0.03 0.04 9	; short trill
i11 13.5 .25 7200 9.09 1 0.03 0.04 9
i11 13.75 .25 6500 9.06 1 0.03 0.04 9
i11 14 .125 8100 9.09 1 0.03 0.04 9
i11 14.25 .25 6500 10.04 1 0.03 0.04 9	; short trill
i11 14.5 .125 7200 10.02 1 0.03 0.04 9
i11 14.75 .125 6500 10.04 1 0.03 0.04 9
i11 14.875 .125 5900 10.06 1 0.03 0.04 9
i11 15 1 9000 9.11 1 0.03 0.04 9
i11 16 .125 8100 10.06 1 0.03 0.04 9
i11 16.25 .5 6500 10.09 1 0.03 0.04 9
i11 16.75 .125 6500 10.06 1 0.03 0.04 9
i11 16.875 .125 5900 10.04 1 0.03 0.04 9
;--------------------------------------------
; bar 73
i11 17 .25 10000 10.02 1 0.03 0.04 9	; short trill
i11 17.25 .5 6500 10.02 1 0.03 0.04 9
i11 17.75 .25 6500 10.06 1 0.03 0.04 9	; short trill
i11 18 .125 8100 10.04 1 0.03 0.04 9
i11 18.125 .125 5900 10.06 1 0.03 0.04 9
i11 18.25 .125 6500 10.02 1 0.03 0.04 9
i11 18.375 .125 5900 10.04 1 0.03 0.04 9
i11 18.5 .125 7200 10.06 1 0.03 0.04 9
i11 18.625 .125 5900 10.09 1 0.03 0.04 9
i11 18.75 .125 6500 10.06 1 0.03 0.04 9
i11 18.875 .125 5900 10.04 1 0.03 0.04 9
i11 19 .25 9000 10.02 1 0.03 0.04 9	; short trill
i11 19.25 .5 6500 10.02 1 0.03 0.04 9
i11 19.75 .25 6500 10.06 1 0.03 0.04 9	; short trill
i11 20 .25 8100 10.04 1 0.03 0.04 9
i11 20.25 .125 6500 10.06 1 0.03 0.04 9
i11 20.375 .125 5900 10.09 1 0.03 0.04 9
i11 20.5 .125 7200 10.06 1 0.03 0.04 9
i11 20.625 .125 5900 10.04 1 0.03 0.04 9
i11 20.75 .125 6500 10.02 1 0.03 0.04 9
i11 20.875 .125 5900 10.01 1 0.03 0.04 9
;--------------------------------------------
; bar 74
i11 21 1 10000 9.11 1 0.03 0.04 9
i11 22 .375 8100 9.11 1 0.03 0.04 9
i11 22.375 .125 5900 9.09 1 0.03 0.04 9
i11 22.5 .25 7200 9.11 1 0.03 0.04 9
i11 22.75 .25 6500 10.02 1 0.03 0.04 9
i11 23 .25 9000 10.04 1 0.03 0.04 9
i11 23.5 1 7200 10.09 1 0.03 0.04 9	; trill
i11 24.5 .375 7200 10.06 1 0.03 0.04 9	; trill
i11 24.875 .125 5900 10.04 1 0.03 0.04 9
;--------------------------------------------
; bar 75
i11 25. .5 10000 10.02 1 0.03 0.04 9

;reverb------------------------------------------------------------------
;p1	p2	p3	p4	p5	p6
;			start	final	percent
;	start	dur	revtime	revtime	reverb
i194	0	27	1.5	1.0	.1

end
</CsScore>
</CsoundSynthesizer>
