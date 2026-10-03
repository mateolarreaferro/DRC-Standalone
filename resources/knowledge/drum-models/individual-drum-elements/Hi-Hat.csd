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

;=========================================================================================

	instr 2	;Hi-Hat
idur 	=	p3
iamp		=	p4
ipulse	=	p5
irhytable	=	p6
ienv		=	p7
ienv2	=	p8
ipan		=	p9

krhythm		phasor	ipulse/(ftlen (irhytable))				; Rhythm
krhythm		table	krhythm*(ftlen(irhytable)), irhytable		; Rhythm Table

kenvindex		phasor	ipulse								; Phasor
kenv			tablei	kenvindex*ftlen(ienv), ienv				; Open (Long Env)
kenv2		tablei	kenvindex*ftlen(ienv2), ienv2				; Closed (Short Env)
kwhichenv		randh	5, ipulse, 1							; Randomly Choosen Env
kwhichenv		=		abs (kwhichenv)
kwhichenv		=		(kwhichenv < 2 ? 0 : 1 )
kenv			=		kenv*kwhichenv + kenv2 * (1- kwhichenv)		; Mixed Env

asound	rand		1										; Noise
asound	=		asound*kenv								; Noise Envelope
asound	butterbp	asound, cpspch (5.08+8), cpspch (5.08+8) * .5	; Band Pass Filter
asound	moogvcf	asound, cpspch (5.08+8), .7					; Moog
a1		comb		asound, .5, 1/cpspch(8)						; Comb
asound	=		a1*.05 + asound*.93
asound	=		asound*iamp*krhythm							; Mixed Sound

ipan		=		.7										; Panning
aL		=		asound*ipan	
aR		=		asound*(1-ipan)
		outs		aL, aR
endin

;=========================================================================================

</CsInstruments>
<CsScore>

;===========;
; {_SCORE_} ;
;===========; 

;envelopes
;=============================
f11 0 2048 7 0 10 1 500  0	; GEN7
f12 0 2048 7 0 40 1 1200 0	; GEN7
;=============================

;rhythm
;==================================================
f32	0 16 2 1 0 1 0   1 0 1 0   1 1 0 1   0 1 0 1	 ; GEN2
;==================================================

;in star 	dur	amp		pulse	rhythm	env1	env2	pan
;===============================================================
i2 0		8	20000	8		32		12	11	.7

</CsScore>
</CsoundSynthesizer>
