<CsoundSynthesizer>

<CsOptions>
-dm0 -Ma
--limiter=0.9
</CsOptions>

<CsInstruments>

garvb init 0

nchnls	=	2
0dbfs = 1

	; turn default MIDI routing off
massign		0, 0
	; route note events on channel 1 to instr 1
massign		1, 1

	; Define MIDI controllers
#define C1 #21#
#define C2 #22#
#define C3 #23#
#define C4 #24#
#define C5 #25#
#define C6 #26#
#define C7 #27#
#define C8 #28#

ctrlinit	1, $C1,100, $C1,0, $C1,0, $C1,10, $C1,1, $C1,33, $C1,2, $C1,20

instr	1

icps		cpsmidi
iamp   ampmidi 	1

ipan      = rnd(1)

kgain		midic7	$C1, 0,1

kcarRatio	midic7	$C2, 1,10
kmodRatio	midic7	$C3, 1,10
kmodRatio	port kmodRatio,.1 ; smoothing the controller

kmodIndex	midic7	$C4, 1,30
kmodIndex	port kmodIndex,.01 ; smoothing the controller

iatk		midic7	$C5, .01,1
klfodepth	   midic7	$C6, 1,7

klforate midic7 $C7,.1,10

krev      midic7 $C8, 0,.5

klfo   lfo  5, klforate, 1   

kmgate	linsegr	0, iatk, 1, 1, 0
asig	foscil	iamp*kmgate*kgain, icps, int(kcarRatio), kmodRatio, kmodIndex+klfo, 1

	outs asig*ipan, asig*(1-ipan)
	
garvb = garvb+(asig*krev)

endin

	instr 2 
arev nreverb garvb, 2.1, 0.1 
	outs arev, arev 
garvb = 0 
	endin

</CsInstruments>

<CsScore>
f0	  z
f1		0		8192		10		1
i2 0 -1
</CsScore>

</CsoundSynthesizer>
