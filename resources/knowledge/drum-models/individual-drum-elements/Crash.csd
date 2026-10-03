<CsoundSynthesizer>
<CsOptions>

; XO
;-+rtmidi=alsa  --midi-device=hw:1,0 -+rtaudio=alsa -odac -r16000 -k160 ;-O stdout
; Mac
-odac -r44100 -k441

</CsOptions>
<CsInstruments>

nchnls 	=	2

;===============;
; {_ORCHESTRA_} ;
;===============; 

;=================================================================================================

	instr 4	; Crash
idur 	=	p3
iamp		=	p4
ipulse	=	p5
irhytable	=	p6
ienv		=	p7
ienv2	=	p8
ipan		=	p9
icps		=	p10

krhythm	phasor	ipulse/(ftlen (irhytable))			; Rhythm
krhythm	table	krhythm*(ftlen(irhytable)), irhytable

kenvindex	phasor	ipulse							; Open (Long Env)
kenv		tablei	kenvindex*ftlen(ienv), ienv

kenv2	tablei	kenvindex*ftlen(ienv2), ienv2

asound	rand		1								; Sound
asound	=		asound

icps		=		cpspch (icps)						; Filtered Sound
kenv11	oscili	.333, ipulse, 111
kenv12	oscili	.333, ipulse, 112
kenv13	oscili	.333, ipulse, 113
kenv14	oscili	.333, ipulse, 114
kenv15	oscili	.333, ipulse, 115
kenv16	oscili	.333, ipulse, 116
kenv17	oscili	.333, ipulse, 117
kenv18	oscili	1, ipulse, 118

a11		oscili	kenv11,	icps, 1
a111		oscili	kenv11,	icps*.89, 1
a112		oscili	kenv11,	icps*1.12341, 1
a11		=		a11+a111+a112

a12		oscili	kenv12, 	icps*2.24, 1
a121		oscili	kenv12, 	icps*2.4*.98, 1
a122		oscili	kenv12, 	icps*2.14*1.02, 1
a12		=		a12+a121+a122

a13		oscili	kenv13, 	icps*3.3312, 1
a131		oscili	kenv13, 	icps*3.513312*.89, 1
a132		oscili	kenv13, 	icps*3.123312*1.11, 1
a13		=		a13+a131+a132

a14		oscili	kenv14, 	icps*4.89, 1
a141		oscili	kenv14, 	icps*5.89*.89, 1
a142		oscili	kenv14, 	icps*6.89*1.03, 1
a14		=		a14+a141+a142

a15 		oscili	kenv15, 	icps*5.12, 1
a151		oscili	kenv15, 	icps*5.5612*1.02, 1
a152 	oscili	kenv15, 	icps*5.7312*.998, 1
a15		=		a15+a151+a152

a16		oscili	kenv16, 	icps*6.97, 1
a161		oscili	kenv16, 	icps*6.97*1.02, 1
a162		oscili	kenv16, 	icps*6.97*.98, 1
a16		=		a16+a161+a162

a17		oscili	kenv17, 	icps*7.89, 1
a171		oscili	kenv17, 	icps*7.89*1.02, 1
a172		oscili	kenv17, 	icps*7.89*.98, 1
a17		=		a17+a171+a172

a18		oscili	kenv13, 	icps*1.25, 1
a181		oscili	kenv13, 	icps*1.125*1.004, 1
a182		oscili	kenv13, 	icps*1.134*.996, 1
a18		=		a18+a181+a182

aall		=		(a11*.2+ a12*.2+ a13*.2+ a14*.2 + a15*.2 + a16*.2 + a17*.2+a18*.1) ; + a18*.2
asound	=		aall + asound * kenv2
a2		butterbp	asound, icps, icps * .5
a3		butterbp	asound, icps*2.1,icps * .5
a4		butterbp	asound,icps*2.8, icps*.5
asound	=		a2+a3+a4

a1		comb		asound, .5, 1/icps*.5
asound	=		aall*.5  +asound*.7 + a1*.6 *kenv18

asound	=		asound*iamp*krhythm					; Mix

aL		=		asound*ipan						; Pan
aR		=		asound*(1-ipan)
		outs		aL, aR
endin

;=================================================================================================

</CsInstruments>
<CsScore>

;===========;
; {_SCORE_} ;
;===========; 

;==============
f1 0 8192 10 1	; GEN10
;==============

;envelopes
;===========================
f11 0 2048 7 0 10 1 300  0  ; GEN7
f12 0 2048 7 0 40 1 1200 0  ; GEN7	
;===========================

;rhythm
;====================
f32	0 2	2	1  1	 ; GEN2
;====================

;===============================
f111 0 2048 5 .01 10 1 1448 .01
f112 0 2048 5 .01 10 1 1500 .01
f113 0 2048 5 .01 10 1 1900 .01
f114 0 2048 5 .01 10 1 1600 .01
f115 0 2048 5 .01 10 1 1400 .01
f116 0 2048 5 .01 10 1 1200 .01
f117 0 2048 5 .01 10 1 1000 .01
f118 0 2048 5 .01 1  1 200  .01
;===============================

;in star 	dur	amp		 pulse	rhythm	env1	env2	pan	icps
;==================================================================
i4 0		32	2500		.25		32		12	11	.2	13.03
i4 0		32	2500		.25		32		12	11	.2	13.10

</CsScore>
</CsoundSynthesizer>
