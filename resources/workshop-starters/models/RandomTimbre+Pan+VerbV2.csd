<CsoundSynthesizer>

<CsOptions>
-dm0 -Ma
--limiter=0.9
</CsOptions>

<CsInstruments>

nchnls	=	2
0dbfs = 1

garvb  init 0 

	; turn default MIDI routing off
massign		0, 0
	; route note events on channel 1 to instr 1
massign		1, 1

	; Define MIDI controllers
#define C1 #1#
#define C2 #2#

ctrlinit  1, $C1,12, $C2,64

               instr     1
krev    midic7 $C2, 0,.8            
               
icps           cpsmidi
iamp           ampmidi   .25
ifn            init      rnd(9.5)+1
;print ifn
ipan           init      rnd(1.1)*.9
;print ipan
iatk           init      rnd(.02)+.003
idetune        midic7    $C1, 0,5
kmp            linsegr   0,iatk,iamp, 1, iamp*.2,10,iamp*.2,iatk*8, 0 ;**use relase < 7 secs
amp            interp    kmp
a1             oscili    amp, icps, ifn
a2             oscili    amp,icps*(1+ .0017*idetune),ifn
a3             oscili    amp,icps*(1+ .003 *idetune),ifn
a4             oscili    amp,icps*(1+ .00441*idetune),ifn
amix             =         a1 + a2 + a3 + a4

garvb        =  garvb+(amix*krev)

               outs      amix*ipan,amix*(1-ipan)
               endin 
               
instr 2  ;reverb instrument

arev	nreverb	garvb, 2.1, .1
		outs	arev, arev
garvb = 0

		endin
</CsInstruments>

<CsScore>
f1 0 2048 10    1 .5 .333 .25 .2 .125 .0625 .03 .01. 005
f2 0 2048 10    1 0 .6 0 .3 0 .2         ; AUDIO FUNCTION
f3 0 2048 10    0 0 0 1 1 1              ; AUDIO FUNCTION
f4 0 2048 10    1 .5 .2 .1 .05 .02       ; AUDIO FUNCTION
f5 0 2048 10    1 0 .2 0 .1              ; AUDIO FUNCTION
f6 0 2048 10    1 1
f7 0 2048 10    0 0 1 0 1 1              ; AUDIO FUNCTION
f8 0 2048 10    0 0 0 1 1 1              ; AUDIO FUNCTION
f9 0 2048 10    0 1 0 .5 .4              ; AUDIO FUNCTION
f10 0 2048 10   1 0 0 0 0 .3 .1          ; AUDIO FUNCTION
  
f0 600                             		; ALLOWS REALTIME MIDI PLAYING FOR 600 SECONDS
i2 0 600

e
</CsScore>

</CsoundSynthesizer>
