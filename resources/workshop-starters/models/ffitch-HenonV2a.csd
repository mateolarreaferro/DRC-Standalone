<CsoundSynthesizer>
<CsOptions>
-M hw:1,0,0 -+rtmidi=NULL --daemon -dm0
--limiter=0.9
</CsOptions>
<CsInstruments>

nchnls    =         2
0dbfs     =         1

garvbL init 0
garvbR init 0

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

ctrlinit 1, $C1,110, $C2,64, $C3,0, $C4,64, $C5,12, $C6,56, $C7,60, $C8,127

           instr 1 ; MIDI version of Marimba from ffitch's Henon

ipitch   cpsmidi
iamp     ampmidi       .5
kcps			cpsmidib 1

kvol 			 midic7 $C1, 0,1
idur        midic7 $C2, .1,6
isweeptime  midic7 $C3, .03,.06
kflt1cf     midic7 $C4, 100, 1000
kflt2cf     midic7 $C5, 500, 5000
isweepend   midic7 $C6, 1,16
idev        midic7 $C7, .012,1.2
krvb        midic7 $C8, 0, .86

kenv      expsegr     .01, .03, iamp, idur, .01  ; ENV
ksweep    linseg     32, isweeptime, 3, .5, isweepend  ; Sweep for mallet hit 
asig1      gbuzz      kenv, kcps/2, ksweep, 0, 32, 4
asig2      gbuzz      kenv, kcps/2+rnd(idev), ksweep, 0, 32, 4
afilt1    reson      asig1+asig2,   kcps+kflt1cf, kcps+(50+rnd(100)), 1  
afilt2    reson      afilt1, kcps+kflt2cf, 90+rnd(200), 1 ;bpfilts in series
aout      balance    afilt2, asig1

apanL, apanR      pan2 aout*kvol, rnd(1)

          outs    apanL, apanR  
                   
vincr garvbL, apanL*krvb
vincr garvbR, apanR*krvb
       
          endin
          
instr verb
        denorm garvbL, garvbR
aL, aR  freeverb garvbL, garvbR, 0.9, 0.35, sr, 0
        outs aL, aR    
        clear garvbL, garvbR
        endin         
        
</CsInstruments>

<CsScore>
f0 z
f4  0 513 9  1 1 90    ; cosine

i "verb" 0 -1
</CsScore>

</CsoundSynthesizer>
