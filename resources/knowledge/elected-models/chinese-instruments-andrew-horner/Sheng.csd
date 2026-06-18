<CsoundSynthesizer>
<CsInstruments>
; sheng.orc

; instr 11 - sheng
; instr 194 - reverb

sr=44100
kr=441
ksmps=100
nchnls=1

giseed = .5
giwtsin = 11
garev	init 	0
;-----------------------------------------------------------------------------------------------------------------------

instr 11							; sheng

; 	parameters
;	p4	overall amplitude scaling factor
;	p5	pitch in Hertz (normal pitch range: G4 - F6)
;	p6	percent vibrato depth, recommended values in range [-1., +1.]
;			0.0	-> no vibrato
;			+1.	-> 1% vibrato depth, where vibrato rate increases slightly
;			-1.	-> 1% vibrato depth, where vibrato rate decreases slightly
;	p7	attack time in seconds 
;			recommended value:  .1 (.03 for short notes)
;	p8	decay time in seconds 
;			recommended value: .2 (.04 for short notes)
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
iphase	=	giseed				; use same phase for all wavetables
giseed	=	frac(giseed*105.947)

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


amp1	linseg 0, .20*iattack, 2000, .40*iattack, 2050,  .4*iattack, 2250, .18*isustain, 2500, .78*isustain, 2300, .04*isustain, 2000, 1.0*idecay, 0, 1, 0
amp2	linseg 0, .11*iattack, 100, .12*iattack, 5000,  .12*iattack, 7500, .3*iattack, 9500,  .35*iattack, 10500, .18*isustain, 12000, .3*isustain, 11000, .48*isustain, 10000, .04*isustain, 9000, .23*idecay, 7000, .67*idecay, 0, 1, 0
amp3	linseg 0, .18*iattack, 10, .15*iattack, 1250,  .2*iattack, 1800,  .24*iattack, 1900, .23*iattack, 2200,  .03*isustain, 2600, .2*isustain, 2900, .35*isustain, 2700, .23*isustain, 2400, .15*isustain, 2000, .04*isustain, 1800, .23*idecay, 1200, .42*idecay, 20, .15*idecay, 0, 1, 0

if ifreq <  538 goto range0				; E4 - C5
if ifreq <  760 goto range1				; Db5 - Gb5
if ifreq <  1025 goto range2				; G5 - B5
goto range3							; C6 - G6

							; wavetable amplitude envelopes
range0: 				; for low range tones
iwt1 = 	11
iwt2 = 	31
iwt3 = 	32
inorm = 	34991
goto end

range1: 				; for low middle range tones
iwt1 = 	11
iwt2 = 	31
iwt3 = 	33
inorm = 	32586
goto end

range2: 				; for high middle range tones
iwt1 = 	11
iwt2 = 	31
iwt3 = 	34
inorm = 	35331
goto end

range3: 				; for high range tones
iwt1 = 	11
amp1 = 	amp1 * 6
iwt2 = 	35
iwt3 = 	36
inorm = 	37480
goto end


end:
ampr1	randi	.02*amp1, 10, giseed		; up to 2% wavetable amplitude variation
giseed	=	frac(giseed*105.947)
amp1	=	amp1 + ampr1
ampr2	randi	.02*amp2, 10, giseed		; up to 2% wavetable amplitude variation
giseed	=	frac(giseed*105.947)
amp2	=	amp2 + ampr2
ampr3	randi	.02*amp3, 10, giseed		; up to 2% wavetable amplitude variation
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
; sheng.sco from "Xingjie" (Witzleben example 3.6)


f2 0 16 -2 40 40 80 160 320 640 1280 2560 5120 10240 10240

f11 0 4097 -10 1
f31 0 4097 -9 2 1 0 3 .16 0 4 1.16 0 5 .45 0 6 .33 0
f32 0 4097 -9 7 1 0 8 .83 0 9 .85 0 10 .16 0 11 .5 0 12 .38 0 13 .05 0 14 .26 0 15 .16 0 16 .13 0 17 .12 0 18 .05 0 19 .11 0
f33 0 4097 -9 7 .21 0 8 .33 0 9 .36 0 10 .3 0 11 .76 0 12 .38 0 13 .5 0 14 .07 0
f34 0 4097 -9 7 .43 0 8 1.2 0 9 .4 0 10 .3 0 11 .1 0
f35 0 4097 -9 2 .58 0 3 .83 0 4 .83 0
f36 0 4097 -9 5 2.1 0 6 1.2 0 7 .4 0

t0 72

;p1	p2	p3	p4	p5		p6	p7	p8	p9
;	start	dur	amp	Hertz		vibr	att	dec	bright

;--------------------------------------------
; bar 1
i11 1 1 10000 9.02 0 0.1 0.2 9
i11 . . 5000 9.09 0 0.1 0.2 9
i11 . . 3300 10.02 0 0.1 0.2 9
i11 2 .5 8100 9.02 0 0.1 0.1 9
i11 . . 4000 9.09 0 0.1 0.1 9
i11 . . 2700 10.02 0 0.1 0.1 9
i11 2.5 .25 7200 9.04 0 0.05 0.05 9
i11 . . 3600 9.11 0 0.05 0.05 9
i11 2.75 .25 6500 9.06 0 0.05 0.05 9
i11 . . 3200 9.09 0 0.05 0.05 9
i11 3 .5 9000 8.11 0 0.1 0.1 9
i11 . . 4500 9.06 0 0.1 0.1 9
i11 . . 3000 9.11 0 0.1 0.1 9
i11 3.5 .25 7200 8.11 0 0.05 0.05 9
i11 . . 3600 9.06 0 0.05 0.05 9
i11 . . 2400 9.11 0 0.05 0.05 9
i11 3.75 .25 6500 9.02 0 0.05 0.05 9
i11 . . 3200 9.09 0 0.05 0.05 9
i11 . . 2200 10.02 0 0.05 0.05 9
i11 4 .5 9000 8.09 0 0.1 0.1 9
i11 . . 4500 9.04 0 0.1 0.1 9
i11 . . 3000 9.09 0 0.1 0.1 9
i11 4.5 .5 9000 9.06 0 0.1 0.1 9
i11 . . 4500 10.01 0 0.1 0.1 9
;--------------------------------------------
; bar 2
i11 5 .25 10000 8.11 0 0.05 0.05 9
i11 . . 5000 9.06 0 0.05 0.05 9
i11 . . 3300 9.11 0 0.05 0.05 9
i11 5.25 .25 6500 9.02 0 0.05 0.05 9
i11 . . 3200 9.09 0 0.05 0.05 9
i11 . . 2200 10.02 0 0.05 0.05 9
i11 5.5 .25 7200 9.04 0 0.05 0.05 9
i11 . . 3600 9.11 0 0.05 0.05 9
i11 5.75 .25 6500 9.06 0 0.05 0.05 9
i11 . . 2400 10.01 0 0.05 0.05 9
i11 6 .25 8100 9.02 0 0.05 0.05 9
i11 . . 4000 9.09 0 0.05 0.05 9
i11 . . 2700 10.02 0 0.05 0.05 9
i11 6.25 .25 6500 8.11 0 0.05 0.05 9
i11 . . 3200 9.06 0 0.05 0.05 9
i11 . . 2200 9.11 0 0.05 0.05 9
i11 6.5 .25 7200 8.09 0 0.05 0.05 9
i11 . . 3600 9.04 0 0.05 0.05 9
i11 . . 2400 9.09 0 0.05 0.05 9
i11 6.75 .2 6500 9.06 0 0.05 0.05 9
i11 . . 3200 10.01 0 0.05 0.05 9
i11 6.875 .2 5900 8.09 0 0.05 0.05 9
i11 . . 3000 9.04 0 0.05 0.05 9
i11 . . 2000 9.09 0 0.05 0.05 9
i11 7 1 9000 8.11 0 0.1 0.2 9
i11 . . 6000 9.06 0 0.1 0.2 9
i11 . . 3000 9.11 0 0.1 0.2 9
i11 8 .5 8100 8.11 0 0.1 0.1 9
i11 . . 4000 9.06 0 0.1 0.1 9
i11 . . 2700 9.11 0 0.1 0.1 9
i11 8.5 .25 7200 8.09 0 0.05 0.05 9
i11 . . 3600 9.04 0 0.05 0.05 9
i11 . . 2400 9.09 0 0.05 0.05 9
i11 8.75 .25 6500 9.06 0 0.05 0.05 9
i11 . . 3200 10.01 0 0.05 0.05 9
;--------------------------------------------
; bar 3
i11 9 .25 10000 8.11 0 0.05 0.05 9
i11 . . 5000 9.06 0 0.05 0.05 9
i11 . . 3300 9.11 0 0.05 0.05 9
i11 9.25 .25 6500 9.02 0 0.05 0.05 9
i11 . . 3200 9.09 0 0.05 0.05 9
i11 . . 2200 10.02 0 0.05 0.05 9
i11 9.5 .25 7200 9.04 0 0.05 0.05 9
i11 . . 3600 9.11 0 0.05 0.05 9
i11 9.75 .25 6500 9.06 0 0.05 0.05 9
i11 . . 3300 10.01 0 0.05 0.05 9
i11 10 .25 8100 9.02 0 0.05 0.05 9
i11 . . 4000 9.09 0 0.05 0.05 9
i11 . . 2700 10.02 0 0.05 0.05 9
i11 10.25 .25 6500 8.11 0 0.05 0.05 9
i11 . . 3200 9.06 0 0.05 0.05 9
i11 . . 2200 9.11 0 0.05 0.05 9
i11 10.5 .25 7200 8.09 0 0.05 0.05 9
i11 . . 3600 9.04 0 0.05 0.05 9
i11 . . 2400 9.09 0 0.05 0.05 9
i11 10.75 .2 6500 9.06 0 0.05 0.05 9
i11 . . 3200 10.01 0 0.05 0.05 9
i11 10.875 .2 5900 8.09 0 0.05 0.05 9
i11 . . 3000 9.04 0 0.05 0.05 9
i11 . . 2000 9.09 0 0.05 0.05 9
i11 11 .75 9000 8.11 0 0.1 0.2 9
i11 . . 4500 9.06 0 0.1 0.2 9
i11 . . 3000 9.11 0 0.1 0.2 9
i11 11.75 .25 6500 9.02 0 0.05 0.05 9
i11 . . 3200 9.09 0 0.05 0.05 9
i11 . . 2200 10.02 0 0.05 0.05 9
i11 12 .25 8100 8.11 0 0.05 0.05 9
i11 . . 4000 9.06 0 0.05 0.05 9
i11 . . 2700 9.11 0 0.05 0.05 9
i11 12.25 .25 6500 9.02 0 0.05 0.05 9
i11 . . 3200 9.09 0 0.05 0.05 9
i11 . . 2200 10.02 0 0.05 0.05 9
i11 12.5 .25 7200 8.11 0 0.05 0.05 9
i11 . . 3600 9.06 0 0.05 0.05 9
i11 . . 2400 9.11 0 0.05 0.05 9
i11 12.75 .25 6500 8.09 0 0.05 0.05 9
i11 . . 3200 9.04 0 0.05 0.05 9
i11 . . 2200 9.09 0 0.05 0.05 9
;--------------------------------------------
; bar 4
i11 13 1 10000 9.06 0 0.1 0.2 9
i11 . . 5000 10.01 0 0.1 0.2 9

;reverb------------------------------------------------------------------
;p1	p2	p3	p4	p5	p6
;			start	final	percent
;	start	dur	revtime	revtime	reverb
i194	0	15.1	1.1	1.0	.08

end
</CsScore>


</CsoundSynthesizer>
