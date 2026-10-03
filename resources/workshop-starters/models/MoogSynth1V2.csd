<CsoundSynthesizer>

<CsOptions>
-odac -Ma -+rtmidi=null
--limiter=0.9
</CsOptions>

<CsInstruments>

nchnls = 2
0dbfs = 1

	; turn default MIDI routing off
massign		0, 0
	; route note events on channel 1 to instr 1
massign		1, "midiSynth1"

	; Define MIDI controllers
#define C1 #21#
#define C2 #22#
#define C3 #23#
#define C4 #24#

ctrlinit 1, $C1,120, $C2,25, $C3,89, $C4,25  


instr midiSynth1

iamp ampmidi .5
kcps cpsmidib 2

kvol  midic7 $C1, 0,1
kvol  port kvol, .01

kpwR  midic7 $C2, .01,.5
kpwR  port kpwR, .01

kCut  midic7 $C3, 80,4000
kCut  port kCut, .01

kRes  midic7 $C4, .01,.88
kRes  port kRes, .01

klfo  oscil .42, kpwR
klfo = klfo + .42

asigL vco2 iamp, (kcps+rnd(.3))*1.01, 2, klfo, 1, .25
asigR vco2 iamp, kcps+rnd(.3), 2, klfo, 1, .25

afiltL moogvcf2 asigL, (kCut+rnd(10)), kRes+rnd(.1)
afiltR moogvcf2 asigR, (kCut+rnd(20)), kRes+rnd(.1)

amixL = afiltL + asigL
amixR = afiltR + asigR

kgate madsr .01, .1, .7, .65

outs amixL*kgate*kvol, amixR*kgate*kvol 

endin

</CsInstruments>
<CsScore>
f0 600
</CsScore>
</CsoundSynthesizer>
