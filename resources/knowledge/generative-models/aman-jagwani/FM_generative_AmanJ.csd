<CsoundSynthesizer>
<CsOptions>

</CsOptions>
<CsInstruments>

nchnls = 2
0dbfs = 1

chn_a "reverbsendl", 3
chn_a "reverbsendr", 3
chn_a "delaysend", 3
seed 0


// This is a generative instrument consisting of fm-based sounds only.
// The instruments from John Chowning's paper were modified and adapted for this context. Some variations include adding breath textures, filters etc.
// The generative techniques here include varying note rates, call and response and interplay between harmonic structures
// The noise based wind instrument is also FM and it sometimes whistles in key with the piece


instr 99 // master clock
isubdiv = 4
gibpm = 80
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
gkswitch metro (gibpm*0.33)/60


// Trigger two voices of brass instrument with varying rate
gkbrassrate trandom gkswitch, 32, 95
gkbrassrate = int(gkbrassrate)
if (gkcount % gkbrassrate == 0) then
gkbrasstrig = 1
else gkbrasstrig = 0
endif
schedkwhen gkbrasstrig, 0, 2, 1, 0, gidur*gkbrassrate
schedkwhen gkbrasstrig, 0, 2, 1, 0, gidur*gkbrassrate


// Trigger two voices of clarinet instrument with varying rate
gkwwrate trandom gkswitch, 32, 95
gkwwrate = int(gkwwrate)
if (gkcount % gkwwrate == 0) then
gkwwtrig = 1
else gkwwtrig = 0
endif
schedkwhen gkwwtrig, 0, 2, 2, 0, gidur*gkwwrate
schedkwhen gkwwtrig, 0, 2, 2, 0, gidur*gkwwrate


// Trigger marimba based on randomly generated number of brass events
kmarchance trandom gkswitch, 4, 10
kmarchance = int(kmarchance)
kmardur trandom gkswitch, 3, 12
kmarcount init 0
if gkbrasstrig == 1 then
kmarcount += 1
endif
if kmarcount % kmarchance == 0 then
kmartrig = 1
else kmartrig = 0
endif
schedkwhen kmartrig, 0, 1, 96, 0, kmardur


// Trigger fractal instrument based on randomly generated number of clarinet events
kfracchance trandom gkswitch, 4, 10
kfracchance = int(kfracchance)
kfracdur trandom gkswitch , 0, 3
kfraccount init 0
if gkwwtrig == 1 then
kfraccount += 1
endif
if kfraccount % kfracchance == 0 then
kfractrig = 1
else kfractrig = 0
endif
schedkwhen kfractrig, 0, 1, 95, 0, kfracdur
endin





instr 96 // marimba seq
kswitch metro gibpm/60
kmarrate trandom kswitch, 1, 5
kmarrate = int(kmarrate)
if (gkcount % kmarrate == 0) then
kmartrig = 1
else kmartrig = 0
endif
schedkwhen kmartrig, 0, 1, 3, 0, gidur*kmarrate
endin





instr 95 // fractal seq
kswitch metro gibpm/60
kfracrate trandom kswitch, 0, 5
kfracrate = int(kfracrate)
if (gkcount % kfracrate == 0) then
kfractrig = 1
else kfractrig = 0
endif
schedkwhen kfractrig, 0, 1, 4, 0, gidur*kfracrate
endin





instr 97 // scales
iScaleSelect = 2
if iScaleSelect == 1 then
    giNotes[] fillarray 0, 5, 5, 7, 9, 12, 14, 17 ;Major
 elseif iScaleSelect == 2 then
    giNotes[] fillarray 0, 3, 3, 7, 10, 12, 17, 19 ;minor
 elseif iScaleSelect == 3 then
    giNotes[] fillarray 0, 0, 3, 17, 7, 9, 12, 19  ;Dorian
    endif
 
 gioffset[] fillarray -12, 0, 12
endin





instr 1 // modified brass sound closer to flugelhorn
ioffind random 0, 3
ioffind = int(ioffind)
ioffset = gioffset[ioffind]
iindex random 0, 8
iindex = int(iindex)
knote = giNotes[iindex]
iamp = 0.2
kcps = cpsmidinn(knote+60+ioffset)
kmodf = kcps
idur = p3
aenv linseg 0, idur/6, 1, idur/6, 0.75, idur/2, 0.65, idur/6, 0
aindx linseg 0, (idur/4)+rnd(0.3), 2, idur/12, 1.5, idur/2, 0.65, idur/6, 0
kbeta rspline 0.01, 0.3, 0.05, 0.5
abreath noise iamp*0.07, 0.6 + kbeta
abreath butterhp abreath, 1000

amod oscili aindx*kmodf, kmodf+rnd(2), -1, 0.25
acar oscili 1, kcps+amod

aout = ((acar*iamp)+abreath)*aenv
aout butterlp aout, 7000+rnd(1000)

kpan rspline -1, 1, 0.5, 4
al, ar pan2 aout, kpan

outs al*iamp*0.15, ar*iamp*0.2
chnmix al*0.2, "reverbsendl"
chnmix ar*0.2, "reverbsendr"
endin





instr 2 // modified clarinet
ioffind random 0, 3
ioffind = int(ioffind)
ioffset = gioffset[ioffind]
iindex random 0, 8
iindex = int(iindex)
knote = giNotes[iindex]
iamp = 0.2

kcps = cpsmidinn(knote+48+ioffset)
kmodf = kcps*(3)

idur = p3
aenv linseg 0, 0.3*idur, 1, 0.24*idur, 1, 0.26*idur, 0
aindx linseg 0, 0.1, 3, 0.1*idur+rnd(0.2), 2, 0.44*idur, 2, 0.05*idur, 2
amod oscili aindx*kmodf, kmodf+rnd(1), -1, 0.25
acar oscili 1, kcps+amod

kbreathcf rspline 3000, 12000, 0.1, 4

abreath pinker
abreath butterlp abreath, kbreathcf
abreath butterhp abreath, 1000

aout = (acar+(abreath*0.6))*iamp*aenv

aout butterlp aout, 7000+rnd(1000)

kpan rspline -1, 1, 0.5, 4
al, ar pan2 aout, kpan

outs al*iamp*0.2, ar*iamp*0.15
chnmix al*0.2, "reverbsendl"
chnmix ar*0.2, "reverbsendr"
endin





instr 3 // marimba
iindex random 0, 8
iindex = int(iindex)
knote = giNotes[iindex]
iamp = 0.3+rnd(0.5)
idur = p3
knote = cpsmidinn(knote+60)

aindx expon 50, idur/2, 0.0001
aenv expseg 0.001, 0.001, 0.05, idur, 0.0001

a1 oscili 1, knote
a2 oscili 1, knote+rnd(2)

amod1 oscili aindx*(knote*4), knote*4, -1, 0.25
acar1 oscili 1.5, knote*2

amod2 oscili aindx*(knote*4), knote*4, -1, 0.25
acar2 oscili 1.5, (knote*2)+rnd(2)

al = (a1+acar1)*aenv*iamp
ar = (a2+acar2)*aenv*iamp

outs al*0.6, ar*0.6
chnmix al*0.6, "reverbsendl"
chnmix ar*0.6, "reverbsendr"
chnmix (al+ar)*0.5, "delaysend"
endin





instr 4 // FM spline fractals
ioffset[] fillarray -12, 0, 12
irandomoff random 0, 2
irandomoff = int(irandomoff)
ioff = ioffset[irandomoff]
iindex random 0, 8
iindex = int(iindex)
knote = giNotes[iindex]
iamp = 0.01+rnd(0.01)
idur = p3
kcps = cpsmidinn(knote+60+ioff)
kmodf1 = kcps*3
kmodf2 = kcps
aindx1 rspline 0, 2, 0.1, 1
aindx2 rspline 0, 2, 0.1, 1
aenv expseg 0.001, idur*0.2, iamp, idur*0.9, 0.001
amod1 oscili aindx1*kmodf1, kmodf1+rnd(1), -1, 0.25
amod2 oscili aindx1*kmodf2, kmodf2+rnd(1), -1, 0.25
acar oscili aenv, kcps+amod1+amod2

kpan rspline -0.5, 0.5, 0.1, 0.4
al, ar pan2 acar, kpan

outs al*0.4, ar*0.4

chnmix al, "reverbsendl"
chnmix ar, "reverbsendr"
chnmix (al+ar)*0.5, "delaysend"
endin





instr 5 // FM noise
kswitch metro gibpm/60
kindex trandom kswitch, 0, 8
kindex = int(kindex)
knote = giNotes[kindex]
iamp = 0.1
kcps = cpsmidinn(knote+72)
kmodf rspline kcps/2, kcps*2, 0.2, 2
krandrate rspline 0.2, 1, 0.1, 0.4

// When these values approach 0, there will be echos of tonal notes
krand1 randi 1, krandrate
krand2 randi 1, krandrate

amod1 randh kmodf, 6000
amod2 randh kmodf, 6000
acar1 oscili iamp, kcps+(amod1*krand1)
acar2 oscili iamp, kcps+(amod2*krand2)

acar1 butterhp acar1, 1000
acar2 butterhp acar2, 1000

kfreq1 rspline 0, 10000, 0.1, 1
kfreq2 rspline 0, 10000, 0.1, 1
acar1 reson acar1, 4000+kfreq1, 1000, 1
acar2 reson acar2, 4000+kfreq2, 1000, 1

aenv linen iamp, 1, p3, 4
outs acar1*aenv, acar2*aenv
endin





instr 10 //reverbsc
arevl chnget "reverbsendl"
arevr chnget "reverbsendr"
kfb init 0.8
kcf init 8000
arevl butterhp arevl, 300
arevr butterhp arevr, 300
al, ar reverbsc arevl, arevr, kfb, kcf
outs al*0.5, ar*0.5
chnclear "reverbsendl"
chnclear "reverbsendr"
endin





instr 11 // delay
adel chnget "delaysend"
khpf init 300
klpf init 8000
klpfmod1 lfo 1000, 4
klpfmod2 lfo 1000, 5
kfb randi 0.5, 2
irates[] fillarray 1, 2, 4, 8, 16, 32, 64, 128, 256, 512
kdelayrate = 8
afb init 0
adel butterhp adel, khpf
kdelay = ((gidur*irates[kdelayrate]))*4*100

adelayl vdelay adel+afb, kdelay, 500
adelayr vdelay adel+afb, kdelay*0.75, 500

adelayl butterlp adelayl, klpf+klpfmod1
adelayr butterlp adelayr, klpf+klpfmod2
afb = ((adelayl + adelayr)*0.5) * kfb

aoutl, aoutr freeverb adelayl, adelayr, 0.4, 0.3

al ntrpol adelayl, aoutl, 0.5
ar ntrpol adelayr, aoutr, 0.5

outs al*0.6, ar*0.6

chnclear "delaysend"
endin





</CsInstruments>
<CsScore>
i 99 0 100000
i 97 0 100000
i 98 0 100000
i 5  0 100000
i 11 0 100000
i 10 0 100000
</CsScore>
</CsoundSynthesizer>
