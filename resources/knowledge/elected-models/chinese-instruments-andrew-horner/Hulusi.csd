<CsoundSynthesizer>
<CsOptions>

;-odac:1 -iadc:1 -d -b1024 -B1024 -+rtaudio=CoreAudio -+rtmidi=null
; for internal speakers
;-m0 -odac -iadc -d -+rtaudio=CoreAudio -+rtmidi=null

;-d -g -W -oHulusi.wav

</CsOptions>
<CsInstruments>
; hulusi.orc

; instr 11 - hulusi
; instr 194 - reverb

;sr=16000
;kr=160
;ksmps=100
nchnls=1

giseed = .5
giwtsin = 11
garev	init 	0
;-----------------------------------------------------------------------------------------------------------------------

instr 11							; hulusi

; 	parameters
;	p4	overall amplitude scaling factor
;	p5	pitch in Hertz (normal pitch range: A3 - C6)
;	p6	percent vibrato depth, recommended values in range [-1., +1.]
;			0.0	-> no vibrato
;			+1.	-> 1% vibrato depth, where vibrato rate increases slightly
;			-1.	-> 1% vibrato depth, where vibrato rate decreases slightly
;	p7	attack time in seconds 
;			recommended value:  .03
;	p8	decay time in seconds 
;			recommended value: .1 (.04 for short notes)
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
kvibdepth	linseg	.1, .8*20, 1, .2*20, .7
kvibdepth	=	kvibdepth* ivibdepth		; vibrato depth
kvibdepthr	randi	.1*kvibdepth, 5, giseed		; up to 10% vibrato depth variation
giseed		= 	frac(giseed*105.947)
kvibdepth	=	kvibdepth + kvibdepthr
ivibr1		=	giseed				; vibrato rate
giseed		=	frac(giseed*105.947)
ivibr2		=	giseed
giseed		=	frac(giseed*105.947)

if p6 < 0 goto vibrato1
kvibrate	linseg	2.5+ivibr1, 20, 4.5+ivibr2, 1, 4.5+ivibr2  	; if p6 positive vibrato gets faster
goto vibrato2
vibrato1:
ivibr3		=	giseed
giseed		= 	frac(giseed*105.947)
kvibrate	linseg	3.5+ivibr1, .1, 4.5+ivibr2, 20-.1, 2.5+ivibr3, 1, 2.5+ivibr3    ; if p6 negative vibrato gets slower
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

if ifreq <  320 goto range0				; A3 - Eb4
if ifreq <  427 goto range1				; E4 - Ab4
if ifreq <  680 goto range2				; A4 - E5
goto range3							; F5 - C6

							; wavetable amplitude envelopes
range0: 				; for low range tones
amp1	linseg 0, .33*iattack, 750, .17*iattack, 2000,  .17*iattack, 5000, .16*iattack, 13000, .17*iattack, 15000, .03*isustain, 16000, .47*isustain, 15000, .5*isustain, 13500, .2*idecay, 13000, .2*idecay, 11000, .2*idecay, 6000, .2*idecay, 150, .2*idecay, 0
amp2	linseg 0, .67*iattack, 30, .33*iattack, 9000,  .05*isustain, 11000, .05*isustain, 12000, .4*isustain, 9500, .5*isustain, 7200, .2*idecay, 5600, .2*idecay, 3200, .2*idecay, 1000, .2*idecay, 50, .1*idecay, 0, .1*idecay, 0
amp3	linseg 0, .33*iattack, 0, .4*iattack, 30,  .27*iattack, 3600, .07*isustain, 2000, .43*isustain, 2800, .5*isustain, 3000, .2*idecay, 2700, .2*idecay, 1500, .2*idecay, 150, .2*idecay, 50, .08*idecay, 0, .12*idecay, 0
iwt1 = 	11
iwt2 = 	31
iwt3 = 	32
inorm = 	26985
goto end

range1: 				; for low middle range tones
amp1	linseg 0, .43*iattack, 1600, .27*iattack, 9000, .3*iattack, 5400, .5*isustain, 5500, .5*isustain, 5300, .2*idecay, 4200, .2*idecay, 3000, .2*idecay, 1000, .2*idecay, 100, .2*idecay, 0
amp2	linseg 0, .43*iattack, 20, .13*iattack, 700,  .30*iattack, 6300,  .14*iattack, 7500, .03*isustain, 9000, .14*isustain, 9200, .65*isustain, 7000, .14*isustain, 6000, .04*isustain, 5000, .2*idecay, 4600, .2*idecay, 3600, .2*idecay, 2400, .2*idecay, 600, .15*idecay, 0, .05*idecay, 0
amp3	linseg 0, .52*iattack, 10, .26*iattack, 1500,  .22*iattack, 7000, .03*isustain, 9000, .02*isustain, 10500, .15*isustain, 9700, .65*isustain, 8000, .15*isustain, 6400, .2*idecay, 4600, .2*idecay, 2600, .2*idecay, 800, .2*idecay, 10, .1*idecay, 0, .1*idecay, 0
iwt1 = 	11
iwt2 = 	33
iwt3 = 	34
inorm = 	36133
goto end

range2: 				; for high middle range tones
amp1	linseg 0, .27*iattack, 1500, .22*iattack, 8000, .51*iattack, 9000, .02*isustain, 11000, .04*isustain, 10600, .81*isustain, 10000, .09*isustain, 9000, .04*isustain, 7000, .2*idecay, 6000, .2*idecay, 4000, .2*idecay, 2000, .2*idecay, 600, .2*idecay, 0
amp2	linseg 0, .38*iattack, 20, .17*iattack, 3800, .45*iattack, 5500, .02*isustain, 6000, .5*isustain, 3800, .35*isustain, 3300, .09*isustain, 1000, .04*isustain, 750, .2*idecay, 600, .2*idecay, 350, .2*idecay, 150, .2*idecay, 40, .2*idecay, 0
amp3	linseg 0, .44*iattack, 20, .1*iattack, 1300, .08*iattack, 750, .38*iattack, 600, .5*isustain, 800, .35*isustain, 750, .1*isustain, 550,  .05*isustain, 50, .2*idecay, 30, .2*idecay, 15, .2*idecay, 7, .2*idecay, 0, .2*idecay, 0
iwt1 = 	35
iwt2 = 	36
iwt3 = 	37
inorm = 	27905
goto end

range3: 				; for high range tones
amp1	linseg 0, .15*iattack, 300, .15*iattack, 1100, .15*iattack, 4000, .15*iattack, 9000, .15*iattack, 20000, .15*iattack, 27000, .10*iattack, 29000, .12*isustain, 26000, .56*isustain, 27000, .32*isustain, 24000, .33*idecay, 23000, .33*idecay, 6000, .17*idecay, 1000, .16*idecay, 0
amp2	linseg 0, .45*iattack, 15, .15*iattack, 250, .15*iattack, 850, .15*iattack, 1800, .1*iattack, 2100, .03*isustain, 2250, .07*isustain, 2000, .25*isustain, 2100, .4*isustain, 2000, .15*isustain, 1400, .1*isustain, 800, .45*idecay, 170, .22*idecay, 120, .11*idecay, 40, .11*idecay, 15, .11*idecay, 0
amp3	linseg 0, .52*iattack, 15, .15*iattack, 400, .22*iattack, 2050, .11*iattack, 2200, .06*isustain, 1000, .15*isustain, 1500, .13*isustain, 1250, .5*isustain, 2500, .04*isustain, 2300, .12*isustain, 2000, .2*idecay, 1600, .2*idecay, 900, .2*idecay, 150, .2*idecay, 20, .1*idecay, 0, .1*idecay, 0
iwt1 = 	11
iwt2 = 	12
iwt3 = 	13
inorm = 	27507 
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
; hulusi.sco

f2 0 16 -2 40 40 80 160 320 640 1280 2560 5120 10240 10240

f11 0 1025 -10 1
f12 0 1025 -9 2 1 0
f13 0 1025 -9 3 1 0
f31 0 4097 -9 2 .46 0 3 1 0 5 .31 0 6 .17 0 9 .12 0
f32 0 4097 -9 4 1 0 7 .34 0 8 .25 0 10 .19 0 11 .25 0
f33 0 4097 -9 2 1 0 7 .33 0 10 .23 0 11 .07 0
f34 0 4097 -9 3 .77 0 4 .29 0 5 1 0 6 .5 0 8 .2 0 9 .07 0
f35 0 4097 -9 1 1 0 2 .36 0 3 1.1 0 4 .3 0
f36 0 4097 -9 5 1 0 6 .22 0
f37 0 4097 -9 7 1 0 8 .42 0 9 .17 0 10 .35 0 11 .2 0

t0 84

;p1	p2	p3	p4	p5		p6	p7	p8	p9
;	start	dur	amp	Hertz		vibr	att	dec	bright
; bar1-----------------------------
i11 0 28 3300 8.05 1 .03 .1 9
i11 0 28 3300 9.00 1 .03 .1 9
i11 0 .55 10000 9.00 1 .03 .1 9
i11 .5 .55 7200 9.00 1 .03 .1 9
i11 1 .55 9000 9.05 1 .03 .1 9
i11 1.5 1.55 7200 9.00 1 .03 .1 9
; bar2-----------------------------
i11 3 .3 10000 9.04 1 .03 .1 9
i11 3.25 .3 6500 9.02 1 .03 .1 9
i11 3.5 .55 7200 9.04 1 .03 .1 9
i11 4 .3 9000 9.00 1 .03 .1 9
i11 4.25 .3 6500 9.02 1 .03 .1 9
i11 4.5 .3 7200 9.00 1 .03 .1 9
i11 4.75 .3 6500 9.02 1 .03 .1 9
i11 5 .55 9000 9.05 1 .03 .1 9
i11 5.5 .3 7200 9.04 1 .03 .1 9
i11 5.75 .3 6500 9.02 1 .03 .1 9
; bar3-----------------------------
i11 6 .3 10000 9.00 1 .03 .1 9
i11 6.25 .3 6500 9.02 1 .03 .1 9
i11 6.5 2.45 7200 9.00 1 .03 .1 9
i11 8.9 .15 6500 9.02 1 .03 .03 9
; bar4-----------------------------
i11 9 .55 10000 9.00 1 .03 .1 9
i11 9.5 .15 6500 8.10 1 .03 .03 9
i11 9.6 .45 7200 9.00 1 .03 .1 9
i11 10 .38 9000 8.07 1 .03 .1 9
i11 10.38 .33 6500 8.10 1 .03 .1 9
i11 10.66 .38 7200 9.02 1 .03 .1 9
i11 11 .55 8100 8.05 1 .03 .1 9
i11 11.5 .3 7200 8.05 1 .03 .1 9
i11 11.75 .3 6500 8.07 1 .03 .1 9
; bar5-----------------------------
i11 12 .3 10000 8.05 1 .03 .1 9
i11 12.25 .3 6500 8.07 1 .03 .1 9
i11 12.5 .3 7200 8.10 1 .03 .1 9
i11 12.75 .3 6500 8.07 1 .03 .1 9
i11 13 .3 8100 8.10 1 .03 .1 9
i11 13.25 .3 6500 9.00 1 .03 .1 9
i11 13.5 .3 7200 9.02 1 .03 .1 9
i11 13.75 .3 8100 9.05 1 .03 .1 9
i11 14 .55 9000 9.00 1 .03 .1 9
i11 14.5 .55 7200 9.00 1 .03 .1 9
i11 15 .55 8100 8.07 1 .03 .1 9
i11 15.5 .55 7200 8.10 1 .03 .1 9
; bar6-----------------------------
i11 16 .55 10000 8.10 1 .03 .1 9
i11 16.5 .55 7200 8.07 1 .03 .1 9
i11 17 .55 8100 9.00 1 .03 .1 9
i11 17.5 1.55 7200 9.00 1 .03 .1 9
i11 19 .95 8100 9.00 1 .03 .1 9
i11 19.9 .15 6500 9.02 1 .03 .03 9
; bar7-----------------------------
i11 20 .38 10000 9.04 1 .03 .1 9
i11 20.33 .38 6500 9.02 1 .03 .1 9
i11 20.66 .38 7200 9.04 1 .03 .1 9
i11 21 .3 8100 9.00 1 .03 .1 9
i11 21.25 .3 6500 9.02 1 .03 .1 9
i11 21.5 .3 7200 9.00 1 .03 .1 9
i11 21.75 .3 6500 9.02 1 .03 .1 9
i11 22 .55 10000 9.05 1 .03 .1 9
i11 22.5 .55 6500 8.10 1 .03 .1 9
i11 23 .425 8100 9.04 1 .03 .1 9
i11 23.375 .175 6500 9.02 1 .03 .04 9
i11 23.5 .3 7200 9.00 1 .03 .1 9
i11 23.75 .3 6500 9.02 1 .03 .1 9
; bar8-----------------------------
i11 24 .3 10000 9.00 1 .03 .1 9
i11 24.25 .3 6500 9.02 1 .03 .1 9
i11 24.5 .55 8500 9.05 1 .03 .1 9
i11 25 .425 8100 9.03 1 .03 .1 9
i11 25.375 .175 6500 9.02 1 .03 .04 9
i11 25.5 .3 7200 9.00 1 .03 .1 9
i11 25.75 .3 6500 9.02 1 .03 .1 9
i11 26 2 9000 9.00 1 .03 .1 9

;reverb------------------------------------------------------------------
;p1	p2	p3	p4	p5	p6
;			start	final	percent
;	start	dur	revtime	revtime	reverb
i194	0	30	1.1	.5	.05
end
</CsScore>

</CsoundSynthesizer>
