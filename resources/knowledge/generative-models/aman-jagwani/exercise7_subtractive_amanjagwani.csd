<CsoundSynthesizer>
<CsOptions>
-odac
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 64
nchnls = 2
0dbfs = 1

gisine					ftgen			0,0,4096,10, 1
seed 0

chn_a "reverbsend", 3
chn_a "delaysend", 3


instr 99 // master clock
isubdiv = 16
gibpm = 100
gidur = ((60/gibpm)/isubdiv) // duration of each note at chosen subdiv
kmetro metro (gibpm/60)*isubdiv //Metro clocking at chosen subdivision (16th notes)

// counter going up till isubdiv 
RESET:
gkcount init 0
if (kmetro == 1) then
gkcount += 1
endif
if (gkcount == isubdiv*50) then
reinit RESET
endif
rireturn 
endin




instr 98 // sequencer
// triggering drums at chosen rate
gkrate = 4
if (gkcount % gkrate == 0) then
ktrig = 1
else ktrig = 0
endif

gkpluckrate = 4
if (gkcount % gkpluckrate == 0) then
kplucktrig = 1
else kplucktrig = 0
endif

if kplucktrig == 1 then
kpluckchance random 0, 1
endif

// random values to weigh against chosen density of notes
if ktrig == 1 then
kkickchance random 0, 1
ksnarechance random 0, 1
khatchance random 0, 1

endif

kkickdensity = 0.3
ksnaredensity = 0.2
khatdensity = 0.5
kpluckdensity = 0.3

if kkickchance < kkickdensity then
ktrigkick = 1 
elseif kkickchance > kkickdensity then
ktrigkick = 0
endif
if ksnarechance < ksnaredensity then
ktrigsnare = 1 
elseif ksnarechance > ksnaredensity then
ktrigsnare = 0
endif
if khatchance < khatdensity then
ktrighat = 1 
elseif khatchance > khatdensity then
ktrighat = 0
endif
if kpluckchance < kpluckdensity then
ktrigp = 1 
elseif kpluckchance > kpluckdensity then
ktrigp = 0
endif

schedkwhen ktrig, 0, 1, 1, 0, gidur*gkrate, ktrigkick
schedkwhen ktrig, 0, 1, 2, 0, gidur*gkrate, ktrighat
schedkwhen ktrig, 0, 1, 3, 0, gidur*gkrate, ktrigsnare
schedkwhen kplucktrig, 0, 1, 6, 0, gidur*gkpluckrate, ktrigp


gkchordrate = 128
if (gkcount % gkchordrate == 0) then
kchordtrig = 1
else kchordtrig = 0
endif

schedkwhen kchordtrig, 0, 1, 4, 0, gidur*gkchordrate


gkmelodyrate = 32
if (gkcount % gkmelodyrate == 0) then
kmeltrig = 1
else kmeltrig = 0
endif

schedkwhen kmeltrig, 0, 1, 5, 0, gidur*gkmelodyrate
schedkwhen kchordtrig, 0, 1, 5, 0, gidur*(gkchordrate/2)
endin



instr 90 // Note Arrays
gkoffset[] fillarray 0, 12, 12, 0, -12, -24, 0

gkmajor[] fillarray 60, 65, 67, 69, 64, 69, 71, 72, 67, 72, 74, 76, 71, 76, 77, 79
gkdorian[] fillarray 60, 65, 70, 62,  63, 69, 74, 65,  67,72, 77, 69,  70, 77, 81, 72
gkaeolian[] fillarray 60, 65, 68, 63,  63, 68, 72, 67,  67,72, 75, 70,  70, 75, 79, 74

kswitch metro ((gibpm/2)*0.125)/60

if kswitch == 1 then
kmode random 1, 3
endif 

kmode = int(kmode)

gkmode[] init 16 
if kmode == 1 then
gkmode = gkmajor
elseif kmode == 2 then
gkmode = gkdorian
elseif kmode == 3 then
gkmode = gkaeolian
endif
endin


instr 5 // melody
iindex random 0, 15
iindex = int(iindex)
knote1 = gkmode[iindex]

kenv linen 0.1, 0.4, p3, 0.2
kenv1 expseg 500, 2, 10000, 1, 3000
kenv2 expseg 500, 2+rnd(1), 6000, 1-rnd(1), 3000


asig vco2 kenv, cpsmidinn(knote1-12)
asig2 vco2, kenv, cpsmidinn(knote1-12)+rnd(0.5)
asig moogladder asig, kenv1, 0.5
asig2 moogladder asig2, kenv2, 0.5

outs asig*0.1, asig2*0.1

chnmix (asig+asig2)*0.01, "reverbsend"
chnmix (asig+asig2)*0.3, "delaysend"

endin


instr 6 // pluck
iindex random 0, 15
iindex = int(iindex)
knote1 = gkmode[iindex]

kenv1 expseg 0.001, 0.01, 0.2+rnd(0.2), p3, 0.0011 // pluck envelope
kenv2 expseg 0.001, 0.1, 0.5+rnd(0.2), p3+0.5, 0.0011 // flute envelope
kenvf expseg 14000, p3/2, 1000
asig vco2 kenv1, cpsmidinn(knote1), 4, 0.1
asig butterlp asig, kenvf
apluck = asig*p4*0.5

outs apluck*0.6, apluck*0.6
chnmix apluck*0.3, "reverbsend"
chnmix apluck, "delaysend"

endin


instr 4 //chords
idur = p3

iindex random 0, 3
ioffsetindx random 0, 6
iindex = int(iindex)
ioffsetindx = int(ioffsetindx)
krevamt init 0.8
kdelamt init 0.8

knote1 = gkmode[iindex]
knote2 = gkmode[iindex+4]
knote3 = gkmode[iindex+8]
knote4 = gkmode[iindex+12]
koffset = gkoffset[ioffsetindx]

printk2 knote1

kenv linen 1, 1, p3, 1
kdetune rspline 0.01, 0.08, 0.1, 0.5
kmul rspline 0.1, 0.9, 0.01, 0.5
kamp rspline 0.3, 0.8, 0.01, 3
a1 gbuzz kenv*kamp*0.2, cpsmidinn(knote1-12)+kdetune, 60, 1, kmul, gisine
a2 gbuzz kenv*kamp*0.2, cpsmidinn(knote2-12)+kdetune, 60, 1, kmul^2, gisine
a3 gbuzz kenv*kamp*0.1, cpsmidinn(knote3+koffset-12)+kdetune, 40, 1, kmul^3, gisine
a4 gbuzz kenv*kamp*0.1, cpsmidinn(knote4+koffset-12)+kdetune, 40, 1, kmul^4, gisine

a5 gbuzz kenv*0.05, cpsmidinn(knote1-12-24), 20, 1, kmul, gisine


icf1 random 4000, 10000
icf2 random 4000, 10000
icfmodrange random 200, 1000


kmodcf lfo 1, 0.5 + rnd(1)

asum1 sum a1, a3
afilt1 moogladder asum1, icf1+(kmodcf*icfmodrange), 0.4

asum2 sum a2, a4
afilt2 moogladder asum2, icf2+(kmodcf*icfmodrange), 0.4

aclip1 clip afilt1+a5, 0, 0.8
aclip2 clip afilt2+a5, 0, 0.8

kpan1 rspline -1, 0, 0.1, 2
kpan2 rspline 0, 1, 0.1, 2

al1, ar1 pan2 aclip1, kpan1
al2, ar2 pan2 aclip2, kpan1

outs (al1+al2)*0.6, (ar1+ar2)*0.6

chnmix (afilt1+afilt2)*krevamt, "reverbsend"
chnmix (afilt1+afilt2)*kdelamt, "delaysend"
endin



instr 1 // Kick
aenv expseg 1*(rnd(0.9)), p3, 0.001
katkenv expseg 0.3, p3*0.25, 0.001
iatkfreq = 100
kfiltenv expseg 4000, p3, 20
anoise rand aenv
afilt reson anoise, 80, 20*(1+gauss(0.05)), 2
akatk vco2 katkenv, iatkfreq, 2, 0.3

aout moogvcf2 afilt+akatk, kfiltenv, 0.5

outs aout*p4*0.8, aout*p4*0.8

gikickval random 0, 1
endin



instr 2 // hats
ifreq random 2000, 10000
ifreq = int(ifreq)
kenv expseg 0.7, p3, 0.001
anoise noise kenv, 0
afilt butterhp anoise, 2000*(1+gauss(0.2))
alp butterlp afilt, ifreq
outs alp*rnd(0.15)*p4, alp*rnd(0.15)*p4

gihatsval random 0, 1
endin



instr 3 // snare
imodcps random 20, 200
knoiselvl init 1
kenv expseg 1, p3, 0.001
kenvsn expseg 0.09, p3, 0.001
kfiltenv expseg 60, p3*0.25, 200
kpitchenv expseg 200+rnd(200), p3*0.5, 150
asig vco2 kenv, kpitchenv, 4, 0.5
asnare fractalnoise 1, -1
asnare = asnare * kenvsn
afilt butterhp asig*(0.05+rnd(0.3))+asnare, kpitchenv
outs afilt*p4*0.7, afilt*p4*0.7
endin


instr 10 //reverbsc
arev chnget "reverbsend"
kfb init 0.8
kcf init 8000
arev butterhp arev, 300
al, ar reverbsc arev, arev, kfb, kcf
outs al*0.8, ar*0.8
chnclear "reverbsend"
endin

instr 11 // delay

adel chnget "delaysend"
khpf init 300
klpf init 6000
klpfmod1 lfo 1000, 4
klpfmod2 lfo 1000, 5
kfb init 0.2
irates[] fillarray 1, 2, 4, 8, 16, 32, 64, 128, 256, 512
kdelayrate = 8
afb init 0
adel butterhp adel, khpf
kdelay = ((gidur*irates[kdelayrate])*100)*2

adelayl vdelay adel+afb, kdelay, 500
adelayr vdelay adel+afb, kdelay*0.75, 500
afb = ((adelayl + adelayr)*0.5) * kfb
adelayl butterlp adelayl, klpf+klpfmod1
adelayr butterlp adelayr, klpf+klpfmod2

aoutl, aoutr freeverb adelayl, adelayr, 0.8, 0.3

al ntrpol adelayl, aoutl, 0.7
ar ntrpol adelayr, aoutr, 0.7


outs al*0.8, ar*0.8

chnclear "delaysend"

endin


</CsInstruments>
<CsScore>
i 99 0 1000
i 98 0 1000
i 90 0 1000
i 10 0 1000
i 11 0 1000

</CsScore>
</CsoundSynthesizer>
