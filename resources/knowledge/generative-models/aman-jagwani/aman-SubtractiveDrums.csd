<CsoundSynthesizer>
<CsOptions>
</CsOptions>
<CsInstruments>

nchnls = 2
0dbfs = 1

gisine					ftgen			0,0,4096,10, 1
seed 0

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

// random values to weigh against chosen density of notes
if ktrig == 1 then
kkickchance random 0, 1
ksnarechance random 0, 1
khatchance random 0, 1

endif

kkickdensity = 0.3
ksnaredensity = 0.2
khatdensity = 0.5

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

schedkwhen ktrig, 0, 1, 1, 0, gidur*gkrate, ktrigkick
schedkwhen ktrig, 0, 1, 2, 0, gidur*gkrate, ktrighat
schedkwhen ktrig, 0, 1, 3, 0, gidur*gkrate, ktrigsnare

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
imodcps random 50, 100
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

</CsInstruments>
<CsScore>
i 99 0 1000
i 98 0 1000
</CsScore>
</CsoundSynthesizer>
