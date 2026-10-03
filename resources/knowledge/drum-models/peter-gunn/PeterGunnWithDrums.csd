<CsoundSynthesizer>
<CsOptions>

; XO
;-+rtmidi=alsa  --midi-device=hw:1,0 -+rtaudio=alsa -odac -r16000 -k160 ;-O stdout
; Mac
-odac -r44100 -k441

</CsOptions>
<CsInstruments>

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~;
;   peterGunnWithDrums.csd   ;	
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~;

nchnls 	= 	2

gaDL	init	0
gaDR	init	0

;===============;
; {_ORCHESTRA_} ;
;===============; 

;=========================================================================================================================================================

	instr 1	;Bass drum
idur		=		p3
iamp		=		p4
iwave	=		p5
ipulse	=		p6
ienv		=		p7
irhytable	=		p8
icps		=		cpspch (p9)
igliss	=		p10
isend	=		p11

krhythm	phasor	ipulse/ftlen(irhytable)				; Rhythms
krhythm	table	krhythm*ftlen(irhytable), irhytable
kenvindex	phasor	ipulse							; Envelope
kenv		tablei	kenvindex*ftlen(ienv), ienv
kgliss	phasor	ipulse							; Gliss
kgliss	tablei	kgliss * ftlen (igliss), igliss
athump	oscili	1,icps*kgliss*.5, iwave				; Sound
athump	=		athump * kenv * krhythm * iamp		; Mixed Signal

kpan		=		.5								; Panning
aL		=		athump*kpan					
aR		=		athump*(1-kpan)
		outs		aL, aR

gaDL		=		aL*isend + gaDL
gaDR		=		aR*isend + gaDR

endin

;=========================================================================================================================================================

	instr 2	; Hi-Hat
	
idur 		=		p3
iamp			=		p4
ipulse		=		p5
irhytable		=		p6
ienv			=		p7
ienv2		=		p8
ipan			=		p9
isend		=		p10

; [Rhythm]
krhythm		phasor	ipulse/(ftlen (irhytable))
krhythm		table	krhythm*(ftlen(irhytable)), irhytable

; [Open : Long Envelope]
kenvindex		phasor	ipulse
kenv			tablei	kenvindex*ftlen(ienv), ienv

; [Closed : Short Envelope]
kenv2		tablei	kenvindex*ftlen(ienv2), ienv2

; [Random Envelope]
kwhichenv		randh	8, ipulse, 1
kwhichenv		=		abs (kwhichenv)
kwhichenv		=		(kwhichenv < 2 ? 0 : 1 )

; [Mix Envelopes]
kenv			=		kenv*kwhichenv + kenv2 * (1- kwhichenv)

asound		rand		1
asound		=		asound*kenv

asound		butterbp	asound, cpspch (5.08+8), cpspch (5.08+8) * .5
asound		moogvcf	asound, cpspch (5.08+8), .7
a1			comb		asound, .5, 1/cpspch(8)
asound		=		a1*.03 + asound*.93
asound		=		asound*iamp*krhythm

ipan			=		.7

aL			=		asound*ipan
aR			=		asound*(1-ipan)
			outs		aL, aR

gaDL			=		aL*isend + gaDL
gaDR			=		aR*isend + gaDR

endin

;=========================================================================================================================================================

	instr 3	; Snare

idur			=		p3
iamp			=		p4
ipulse		=		p5
ienv			=		p6
ienv2		=		p7
irhytable		=		p8
ipan			=		p9
isend		=		p10

; [Noise]
asound		rand		1

; [Filtered Noise]
as1			butterbp	asound, 210, 55

; [Sharp Noise Envelope]
kenv2		phasor	ipulse
kenv2		table	kenv2*ftlen(ienv2), ienv2

asound		=		as1*.9 + asound*.8*kenv2

; [Another Envelope]
kenv			phasor	ipulse
kenv			tablei	kenv*ftlen(ienv), ienv

; [Rhythms]
krhythm		phasor	ipulse/ftlen(irhytable)
krhythm		table		krhythm*ftlen(irhytable), irhytable

asound		=		asound*kenv*krhythm*iamp

aL			=		asound*ipan
aR			=		asound*(1-ipan)
			outs		aL, aR

gaDL			=		aL*isend + gaDL
gaDR			=		aR*isend + gaDR

endin

;=========================================================================================================================================================

	instr 4	; Crash

idur 		=		p3
iamp			=		p4
ipulse		=		p5
irhytable		=		p6
ienv			=		p7
ienv2		=		p8
ipan			=		p9
isend		=		p10
icps			=		p11

; ;[Rhythm]
krhythm		phasor	ipulse/(ftlen (irhytable))
krhythm		table	krhythm*(ftlen(irhytable)), irhytable

; [Open : Long Envelope]
kenvindex		phasor	ipulse
kenv			tablei	kenvindex*ftlen(ienv), ienv
kenv2		tablei	kenvindex*ftlen(ienv2), ienv2

asound		rand		1
asound		=		asound

; [Filtered Sound]
icps			=		cpspch (icps)
kenv11		oscili	.333, ipulse, 111
kenv12		oscili	.333, ipulse, 112
kenv13		oscili	.333, ipulse, 113
kenv14		oscili	.333, ipulse, 114
kenv15		oscili	.333, ipulse, 115
kenv16		oscili	.333, ipulse, 116
kenv17		oscili	.333, ipulse, 117
kenv18		oscili	1, ipulse, 118

a11			oscili	kenv11,	icps, 1
a111			oscili	kenv11,	icps*.89, 1
a112			oscili	kenv11,	icps*1.12341, 1
a11			=		a11+a111+a112
a12			oscili	kenv12, 	icps*2.24, 1
a121			oscili	kenv12, 	icps*2.4*.98, 1
a122			oscili	kenv12, 	icps*2.14*1.02, 1
a12			=		a12+a121+a122
a13			oscili	kenv13, 	icps*3.3312, 1
a131			oscili	kenv13, 	icps*3.513312*.89, 1
a132			oscili	kenv13, 	icps*3.123312*1.11, 1
a13			=		a13+a131+a132

a14			oscili	kenv14, 	icps*4.89, 1
a141			oscili	kenv14, 	icps*5.89*.89, 1
a142			oscili	kenv14, 	icps*6.89*1.03, 1
a14			=		a14+a141+a142

a15 			oscili	kenv15, 	icps*5.12, 1
a151			oscili	kenv15, 	icps*5.5612*1.02, 1
a152 		oscili	kenv15, 	icps*5.7312*.998, 1
a15			=		a15+a151+a152

a16			oscili	kenv16, 	icps*6.97, 1
a161			oscili	kenv16, 	icps*6.97*1.02, 1
a162			oscili	kenv16, 	icps*6.97*.98, 1
a16			=		a16+a161+a162

a17			oscili	kenv17, 	icps*7.89, 1
a171			oscili	kenv17, 	icps*7.89*1.02, 1
a172			oscili	kenv17, 	icps*7.89*.98, 1
a17			=		a17+a171+a172

a18			oscili	kenv13, 	icps*1.25, 1
a181			oscili	kenv13, 	icps*1.125*1.004, 1
a182			oscili	kenv13, 	icps*1.134*.996, 1
a18			=		a18+a181+a182


aall			=		(a11*.2+ a12*.2+ a13*.2+ a14*.2 + a15*.2 + a16*.2 + a17*.2+a18*.1) ; + a18*.2
asound		=		aall + asound * kenv2
a2			butterbp	asound, icps, icps * .5
a3			butterbp	asound, icps*2.1,icps * .5
a4			butterbp	asound,icps*2.8, icps*.5
asound		=		a2+a3+a4


a1			comb		asound, .5, 1/icps*.5
asound		=		aall*.5  +asound*.7 + a1*.6 *kenv18

asound		=		asound*iamp*krhythm

aL			=		asound*ipan
aR			=		asound*(1-ipan)
			outs		aL, aR

gaDL			=		aL*isend + gaDL
gaDR			=		aR*isend + gaDR

endin

;=========================================================================================================================================================

instr 6 ; Pulser with pitch and amplitude changes, random panning 12 bar blues!

; [Peter Gunn Theme]

idur				=		p3
iwavefn 			=		p4		; what type of wave form to use
ienvtable			=		p5		; what type of envelope to use
iPulseFreq		=		p6
iPitchtable 		= 		p7		; specifies the pitch table
iAmptable			=		p8		; specifies the amp. table
iChordTable		=		p9
iRandseed			=		p10
iDoChorus			=		p11
isend			=		p12

; [GENERATE PITCHES]

;	this is tricky --- what must happen is that phasor reading the pitch table must change to a new pitch every time the envelope reattacks.
;	study the following code, and it should be clear

kpitchampindex		phasor	iPulseFreq/(ftlen (iPitchtable))
kcps				table	kpitchampindex*ftlen(iPitchtable), iPitchtable

; [CHORD CHANGES]
;
ichordpulse		=		1/((ftlen (iPitchtable)/ iPulseFreq) * 12)
kchordindex		phasor	ichordpulse
kchord			table	kchordindex*12, iChordTable
kcps				=		cpspch (kcps + kchord)


; [GENERATE AMPLITUDES]
kamp				table	kpitchampindex*ftlen(iAmptable), iAmptable

; [ENVELOPE]
kenvindex			phasor	iPulseFreq	;	how often a new envelope is created
kenv				table	kenvindex*ftlen(ienvtable), ienvtable

;#########################################################################################################################################################

	if 	(iDoChorus	==  1)	goto Chorus
		asignal	oscili	1, kcps, iwavefn
		asignal	=		asignal * kamp * kenv
goto Output

;#########################################################################################################################################################

Chorus:	;	chorused waveforms
	asignal	oscili	.333, kcps, iwavefn
	asignal2	oscili	.333, kcps*1.005, iwavefn
	asignal3	oscili	.333, kcps*.995, iwavefn
	asignal	=		(asignal + asignal2 + asignal3) * kamp * kenv

;---------------------------------------------------------------------------------------------------------------------------------------------------------

Output:	;	Panning
	kpan		randh		1, iPulseFreq, iRandseed
	kpan		=		abs (kpan)		; here is another method for getting a value of 0-1.
								; the opcode ABS gets the absolute value
	aoutL	=		asignal * kpan
	aoutR 	=		asignal * (1-kpan)
			outs		aoutL, aoutR
	gaDL		=		aoutL*isend + gaDL
	gaDR		=		aoutR*isend + gaDR

;---------------------------------------------------------------------------------------------------------------------------------------------------------

endin

;=========================================================================================================================================================

	instr 12  ;	BASIC OSCILLATOR WITH PHASOR/TABLE ENVELOPES

idur			=		p3
iamp			=		p4*.333	; scaling for chorus
icps			=		cpspch (p5)
iwavefn 		=		p6		; what type of wave form to use
ienvtable		=		p7		; what type of envelope to use
ipan			=		p8
isend		=		p9

; [Creat Envelope]

kenvindex		phasor	1/idur   ;	phasor works in frequency, idur is in period, so we take the inverse
kenvindex		=		kenvindex* (ftlen (ienvtable)
kenv			tablei	kenvindex, ienvtable

; [Chorused Waveforms]
asignal		oscili	iamp, icps, iwavefn
asignal2		oscili	iamp, icps*1.002, iwavefn
asignal3		oscili	iamp, icps*.998, iwavefn
asignal		=		asignal + asignal2 + asignal3
aoutL		=		asignal * kenv * ipan
aoutR		=		asignal * kenv * (1-ipan)
			outs		aoutL, aoutR
			
gaDL			=		aoutL*isend + gaDL
gaDR			=		aoutR*isend + gaDR

endin

;=========================================================================================================================================================

	instr 199	; Reverb

itime	=		1/p4
kenv		linen	1, 0, p3, 2
aDL		=		gaDL
aDR		=		gaDR

aFL		init		0
aFR		init		0

aDL		multitap	aDL+aFL, itime*3, .7, itime*5, .5, itime*7, .3, itime*9, .2
aDR		multitap	aDR+aFR, itime*4, .7, itime*6, .5, itime*8, .3, itime*2, .4

aFL		=		aDL*.1+aDR*.2
aFR		=		aDR*.1+aDL*.2
		outs		aDL*kenv, aDR*kenv

gaDL		=		0
gaDR		=		0

endin

;=========================================================================================================================================================

</CsInstruments>
<CsScore>

;===========;
; {_SCORE_} ;
;===========; 

; [Wavetables]
;===========================================================================
f1 0 32   10 1									; GEN10
f2 0 8192 10 1									; GEN10
f3 0	8192	10 1 0.5 0.333 0.25 0.2  0.167 0.143 0.125 	; GEN10/Sawtooth
f4 0	8192	10 1 0 .333 0 .2 0 .143 0 .111 		    	; GEN10/Square
;===========================================================================

; Envelopes
;======================================
f10 0 2048 7 0 20 1 1000 0	; GEN7
f11 0 2048 7 0 10 1 500 0	; GEN7
f12 0 2048 7 0 40 1 1200 0	; GEN7
;======================================

;==============================================
f13 0 2048 7 0 10 1 700 0			; GEN7	
f14 0 2048 5 .01 3 1 445 .01 1400 .01	; GEN5
f15 0 2048 5 .01 10 1 848 .01			; GEN5
;==============================================

;===================================================================
f16 0  512	5	.01		70 		1		442	.01	; GEN5
f17 0  512  	7 	0 		70 		1 		442 	0	; GEN7
f18 0  512  	7 	0 		384 		1 		128 	0	; GEN7
f19 0  512  	7 	0 		12 		1 		450 	0	; GEN7
;===================================================================

; [Gliss]
;==========================================
f20 0 1024 -5 	10 650 1 724 1		; GEN5
f21 0 1024 -5    6 350 1 724 1	; GEN5
f22 0 1024 -5	.75 250 1 724 1	; GEN5
f23 0 1024 -5    1.5  250 1 724 1	; GEN5
;==========================================

; [Rhythm]
;==================================================================================================
f30  0 16 -2 1 0 0 .5 1 0 1 0 1 0 0 .5 1 0 1 .5									; GEN2
f32	0 16  2 1 0 1 0   1 0 1 0   1 1 0 1   0 1 0 1								; GEN2
f31  0 32 -2 1 0 0 0 1 0 0 .5   	1 0 0 0 1 0 0 .5 1 0 0 1  0 0 1 0  0 1 0 0  1 0 0 .5	; GEN2
f33  0 16  2 0 0 1 0   0 1 0 1   0 0 1 0  0 1 1 0									; GEN2
f34	0 4   2 	1 0 1 0 ; 0 0 1 0												; GEN2
f35  0 16  2 0 1 1 0   0 1 1 1   0 1 1 0  1 1 1 1									; GEN2
f36  0 16  2 1 1 1 1   1 1 1 1   1 1 1 1  1 1 1 1									; GEN2
;==================================================================================================



; [Amp]
;========================================================================
f40 0  8		-2	8000 8000 12000 8000 14000 8000 16000 14000	; GEN2
;========================================================================

; [Pitch]
;===================================================================
f50 0  8 		-2 	5.05 5.05 5.07 5.05 5.08 5.05 5.10 5.09	; GEN2
f51 0 16		-2	0 0 0 0 .05 .05 0 0 .07 .05 0 0		; GEN2
f52 0 16		-2	1 1 1 1 1.05 1.05 1 1 1.07 1.05 1 1	; GEN2
;===================================================================

;=========================================================
f132 0 16 -2 1 1 0 0 0 0 1 0 0 0 0 0 1 1 0 0		; GEN2
f133 0 16 -2 0 0 1 1 0 0 0 1 0 1 0 0 0 0 1 0		; GEN2
f134 0 16 -2  0 0 0 0 1 1  0 0 1 0 1 1  0 0 0 1	; GEN2
;=========================================================

;==========================================
f111 0 2048 5 .01 10 1 1448 .01	; GEN5
f112 0 2048 5 .01 10 1 1500 .01	; GEN5
f113 0 2048 5 .01 10 1 1900 .01	; GEN5
f114 0 2048 5 .01 10 1 1600 .01	; GEN5
f115 0 2048 5 .01 10 1 1400 .01	; GEN5
f116 0 2048 5 .01 10 1 1200 .01	; GEN5
f117 0 2048 5 .01 10 1 1000 .01	; GEN5
f118 0 2048 5 .01 1 1 200 .01		; GEN5
;==========================================

;===========
i199 0 32 8

; [BASS]
;in star 	     dur	amp			wave  	pulse	env		rhyth	cps			gliss
;======================================================================================================
i1 	0 		16  	30000		1 		8		10		30		5.07 		20 		.1
i1 	16 		8  	30000		1 		8		10		31		5.07 		20		.1
i1 	24		8  	30000		1 		8		10		30		5.07 		20		.1
;i1 	6.75 	1.25 15000		1 		8		10		132		8.045 		22		.1
;i1 	6.75 	1.25	15000		1		8		10		133		8.005		22		.1
;i1 	6.75 	1.25	15000		1		8		10		134		8.091		22		.1
;i1 	6.75 	1.25 15000		1 		8		10		132		8.045 		23		.1
;i1 	6.75 	1.25	15000		1		8		10		133		8.005		23		.1
;i1 	6.75 	1.25	15000		1		8		10		134		8.091		23		.1

;i1 22.75 	1.25  15000		1 		8		10		132		8.045 		22		.1
;i1 22.75 	1.25	15000		1		8		10		133		8.005		22		.1
;i1 22.75 	1.25	15000		1		8		10		134		8.091		22		.1
;i1 22.75 	1.25  15000		1 		8		10		132		8.045 		23		.1
;i1 22.75 	1.25	15000		1		8		10		133		8.005		23		.1
;i1 22.75 	1.25	15000		1		8		10		134		8.091		23		.1

; [HIHAT]
;in star 		dur	amp		 	pulse	rhythm	env1	env2	pan
;=========================================================================
i2 	0		16	20000		8		32		12	11	.7	.2
i2 	16		8	20000		8		36		12	11	.7	.2
i2 	24		8	20000		8		32		12	11	.7	.2

; [SNARE]
;in star 		dur	amp			pulse 	env1	env2	rhythm	pan
;=========================================================================
i3 	0		16	30000		8		13	14	33   	.3	.2
i3 	16		8	30000		8		13	14	32   	.3	.2
i3 	24		8	30000		8		13	14	33   	.3	.2

;in star 		dur	amp			pulse 	env1	env2	rhythm	pan
;================================================================================
i4 0			16	1800			.25		34	12	15		.2	.15	13.03
i4 0			16	1800			.25		34	12	15		.2	.15	13.10
i4 0			16	1800			.25		34	12	15		.2	.15	13.15

i4 16		2	1800			.25		34	12	15		.2	.15	13.03
i4 16		2	1800			.25		34	12	15		.2	.15	13.10
i4 16		2	1800			.25		34	12	15		.2	.15	13.15

i4 18		2	1800			.25		34	12	15		.2	.15	13.03
i4 18		2	1800			.25		34	12	15		.2	.15	13.10
i4 18		2	1800			.25		34	12	15		.2	.15	13.15

i4 20		1	1800			.5		34	12	15		.2	.15	13.03
i4 20		1	1800			.5		34	12	15		.2	.15	13.10
i4 20		1	1800			.5		34	12	15		.2	.15	13.15
	
i4 21		1	1800			.5		34	12	15		.2	.15	13.03
i4 21		1	1800			.5		34	12	15		.2	.15	13.10
i4 21		1	1800			.5		34	12	15		.2	.15	13.15

i4 22		1	1800			.5		34	12	15		.2	.15	13.03
i4 .			1	1800			.5		34	12	15		.2	.15	13.10
i4 .			1	1800			.5		34	12	15		.2	.15	13.15

i4 22.5		1	1800			.5		34	12	15		.2	.15	13.03
i4 .			1	1800			.5		34	12	15		.2	.15	13.10
i4 .			1	1800			.5		34	12	15		.2	.15	13.15

i4 23		1	1800			.5		34	12	15		.2	.15	13.03
i4 .			1	1800			.5		34	12	15		.2	.15	13.10
i4 .			1	1800			.5		34	12	15		.2	.15	13.15

i4 23.5		1	1800			.5		34	12	15		.2	.15	13.03
i4 .			1	1800			.5		34	12	15		.2	.15	13.10
i4 .			1	1800			.5		34	12	15		.2	.15	13.15
	
i4 24		8	1800			.25		34	12	15		.2	.15	13.03
i4 24		.	1800			.25		34	12	15		.2	.15	13.10
i4 24		.	1800			.25		34	12	15		.2	.15	13.15

i4 26		2	1800			.25		34	12	15		.2	.15	13.03
i4 26		.	1800			.25		34	12	15		.2	.15	13.10
i4 26		.	1800			.25		34	12	15		.2	.15	13.15

;i4 4		32	2500			.25		34	12	15		.2	.2	13.03
;i4 4		32	2500			.25		34	12	15		.2	.2	13.10

; [INSTRUMENT 6]
;inst	start 	dur	wavefn	envtable	pulsefrequency	Pitch Table	Amp Table		chordtable  	Seed		do chorus (1 yes, 0 no)
;========================================================================================================================================
i6		8 		24	3		16		4			50			40			51			.3		1				.1
i6		8		24	4		17		4			50			40			51			.8		1				.1
i6		8 		24	3		16		4			50			40			52			.4		0				.1

i12		12	4	5000	6.05  	3		18		.5	.6
i12		12	4	5000	7.05		3		18		.9	.6
i12		12	.	.	7.09		.		.		.7	.
i12		12	.	.	8.00 	.		.		.3	.
i12		12	.	.	8.03		.		.		.1	.

i12		0	8	5000	6.05  	3		18		.5	.
i12		0	8	5000	7.05		3		18		.9	.
i12		0	.	.	7.09		.		.		.7	.
i12		0	.	.	8.00 	.		.		.3	.
i12		0	.	.	8.03		.		.		.1	.

i12		16	1	5000	6.10  	3		19		.9	.
i12		16	1	5000	7.10		3		19		.9	.
i12		16	.	.	7.14		.		.		.9	.
i12		16	.	.	8.05 	.		.		.9	.
i12		16	.	.	8.08		.		.		.9	.

i12		18	1	5000	6.10  	3		19		.1	.
i12		.	1	5000	7.10		3		19		.1	.
i12		.	.	.	7.14		.		.		.1	.
i12		.	.	.	8.05 	.		.		.1	.
i12		.	.	.	8.08		.		.		.1	.

i12		20	1	5000	6.05 	3		18		.5	.
i12		.	.	5000	7.05		3		18		.9	.
i12		.	.	.	7.09		.		.		.7	.
i12		.	.	.	8.00 	.		.		.3	.
i12		.	.	.	8.03		.		.		.1	.

i12		21	1	5000	7.05  	3		18		.5	.
i12		.	.	5000	8.05		3		18		.9	.
i12		.	.	.	8.09		.		.		.7	.
i12		.	.	.	9.00 	.		.		.3	.
i12		.	.	.	9.03		.		.		.1	.

i12		22	1	5000	6.05  	3		18		.5	.
i12		.	.	5000	7.05		3		18		.9	.
i12		.	.	.	7.09		.		.		.7	.
i12		.	.	.	8.00 	.		.		.3	.
i12		.	.	.	8.03		.		.		.1	.

i12		22.5	1	5000	7.05 	3		18		.5	.
i12		.	.	5000	8.05		3		18		.9	.
i12		.	.	.	8.09		.		.		.7	.
i12		.	.	.	9.00 	.		.		.3	.
i12		.	.	.	9.03		.		.		.1	.

i12		23	1	5000	7.05  	3		18		.5	.
i12		.	.	5000	8.05		3		18		.9	.
i12		.	.	.	8.09		.		.		.7	.
i12		.	.	.	9.00 	.		.		.3	.
i12		.	.	.	9.03		.		.		.1	.

i12		23.5	1	5000	7.05  	3		18		.5	.
i12		.	.	5000	8.05		3		18		.9	.
i12		.	.	.	8.09		.		.		.7	.
i12		.	.	.	9.00 	.		.		.3	.
i12		.	.	.	9.03		.		.		.1	.

i12		24	2	5000	7.00 	3		19		.5	.
i12		.	2	5000	8.00		3		19		.9	.
i12		.	.	.	8.03		.		.		.7	.
i12		.	.	.	8.07 	.		.		.3	.
i12		.	.	.	8.10		.		.		.1	.
i12		.	.	3000	8.07 	.		.		.3	.
i12		.	.	.	8.10		.		.		.1	.

i12		26	2	5000	6.10  	3		19		.5	.
i12		26	2	5000	7.10		3		19		.9	.
i12		26	.	.	7.14		.		.		.7	.
i12		26	.	.	8.05 	.		.		.3	.
i12		26	.	.	8.08		.		.		.1	.


i12		28	4	5000	6.05  	3		19		.5	.
i12		28	4	5000	7.05		3		19		.9	.
i12		28	.	.	7.09		.		.		.7	.
i12		28	.	.	8.00 	.		.		.3	.
i12		28	.	.	8.03		.		.		.1	.

i12		28	8	5000	6.05 	3		18		.5	.
i12		28	8	5000	7.05		3		18		.9	.
i12		28	.	.	7.09		.		.		.7	.
i12		28	.	.	8.00 	.		.		.3	.
i12		28	.	.	8.03		.		.		.1	.

</CsScore>
</CsoundSynthesizer>
