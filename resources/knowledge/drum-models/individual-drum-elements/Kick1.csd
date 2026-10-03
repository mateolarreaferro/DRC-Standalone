<CsoundSynthesizer>
<CsOptions>

; XO
;-+rtmidi=alsa  --midi-device=hw:1,0 -+rtaudio=alsa -odac -r16000 -k160 ;-O stdout
; Mac
-odac -r44100 -k441

</CsOptions>
<CsInstruments>

nchnls 	= 	2

;===============;
; {_ORCHESTRA_} ;
;===============; 

;=======================================================================

	instr 1	; Kick Drum
idur		=		p3
iamp		=		p4
iwave	=		p5
ipulse	=		p6
ienv		=		p7
irhytable	=		p8
icps		=		cpspch (p9)
igliss	=		p10

krhythm	phasor	ipulse/ftlen(irhytable)				; Rhythms
krhythm	table	krhythm*ftlen(irhytable), irhytable	; Rhythm Table Env

kenvindex	phasor	ipulse							; Phasor
kenv		tablei	kenvindex*ftlen(ienv), ienv			; Phasor Table Env

kgliss	phasor	ipulse							; Kick Gliss [phasor]
kgliss	tablei	kgliss * ftlen (igliss), igliss		; Kick Table
athump	oscili	1, icps*kgliss*.5, iwave				; Oscillator
athump	=		athump * kenv * krhythm * iamp		; Mixed Signals

kpan		=		.5								; Panning
aL		=		athump*kpan
aR		=		athump*(1-kpan)
		outs		aL, aR
endin

;=======================================================================

</CsInstruments>
<CsScore>

;===========;
; {_SCORE_} ;
;===========; 

; wave tables
;low res works well!
;========================
f1 0 32   10 1		; GEN10
f2 0 8192 10 1		; GEN10
;========================

; envelopes 
;=========================
f10 0 2048 7 0 20 1 800 0 ; GEN7
;=========================

;for gliss
;==============================
f20 0 1024 -5 	 10 650 1 724 1 ; GEN5
f21 0 1024 -5    6 350 1 724 1 ; GEN5
;==============================

;rhythm tables
;===============================================================================================
f30 0 16 -2 1 0 0 .5 1 0 1 0 1 0 0 .5 1 0 1 .5										 ; GEN2
f31 0 32 -2 1 0 0 0 1 0 0 .5   	1 0 0 0 1 0 0 .5 		1 0 0 1  0 0 1 0  0 1 0 0  1 0 0 .5 ; GEN2
;===============================================================================================

;in star 	dur	amp		wave  	pulse	env		rhyth	cps		gliss
;==================================================================================
i1 	0 	8  	40000	1 		8		10		30		5.07 	20
s
i1 	0 	8  	40000	2 		10		10		31		6.07 	21

</CsScore>
</CsoundSynthesizer>
