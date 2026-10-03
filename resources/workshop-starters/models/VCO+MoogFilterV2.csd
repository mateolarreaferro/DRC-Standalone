<CsoundSynthesizer>

<CsOptions>
-dm0 -Ma
--limiter=0.9
</CsOptions>

<CsInstruments>

gisin    ftgen    1, 0, 16384, 10, 1

	; turn default MIDI routing off
massign		0, 0
	; route note events on channel 1 to instr 1
massign		1, 1

	; Define MIDI controllers
#define C1 #21#
#define C2 #22#
#define C3 #23#

         ctrlinit 1, $C1,100, $C2,64, $C3,64

         instr    1
iscale = 0dbfs
iamp     ampmidi  0dbfs
icps     cpsmidi

kvol			midic7   $C1, 0,1

kfiltfrq midic7   $C2, 0,8000
kfiltres midic7   $C3, .2,.75

kfrqmod	madsr    .001, .3, .5, .6
kampenv  madsr    .01,  .2, .6, .5

aosc     vco      kampenv, icps, 1
afilt    moogvcf  aosc, 100+(kfiltfrq*kfrqmod), kfiltres, iscale

         out      afilt*(iamp*kvol)
         endin
          
</CsInstruments>

<CsScore>
f0 z
</CsScore>

</CsoundSynthesizer>
