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

ctrlinit 1, $C1,110, $C2,106, $C3,20, $C4,10, $C5,20, $C6,12, $C7,0, $C8,95

           instr 1 ; MIDI version3 of Marimba from ffitch's Henon

ipitch   cpsmidi
iamp     ampmidi  1
kcps			cpsmidib 1

kvol 			 midic7 $C1, 0,1
idur        midic7 $C2, .1,5
ibuzsweep   midic7 $C3, .03,.05
klfamp      midic7 $C4, 0,20
klfreq      midic7 $C5, .1,12
kflt3cf     midic7 $C6, 500,6000
klowharm    midic7 $C7, 1,40
krvb        midic7 $C8, 0,.6

kenv      expsegr     .0001, .03, iamp, idur, .0001   ; ENV
kbuzsweep    linseg     32, ibuzsweep, 3, .5, 2        ; Sweep for mallet hit

klfo      lfo        klfamp, klfreq, 3
asig      gbuzz      kenv, kcps, kbuzsweep, klowharm+klfo, 5, 4

kfltswp1  linseg  rnd(500), rnd(ibuzsweep), rnd(10), .5, rnd(1)
kfltswp2  linseg  rnd(1000), rnd(ibuzsweep), rnd(20), .5, rnd(2)
afilt1   reson      asig,   (kcps+100)+kfltswp1, 50+rnd(100), 1    
afilt2   reson      afilt1, (kcps+500)+kfltswp2, 90+rnd(200), 1 
 
kfltswp3  linseg  rnd(5000), rnd(ibuzsweep), rnd(30), .5, rnd(3)
afilt3   reson      asig, (kcps+kflt3cf)+kfltswp3, 150+rnd(300), 1  

afiltmix =  afilt2+(afilt3*.6)

aout      balance    afiltmix, asig

apanL, apanR      pan2 aout*kvol, rnd(1)  ; Random Panning 

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
f4  0 8193 9  1 1 90    ; cosine

i "verb" 0 -1
</CsScore>

</CsoundSynthesizer>
