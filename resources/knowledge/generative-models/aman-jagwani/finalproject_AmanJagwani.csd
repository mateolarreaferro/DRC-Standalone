<CsoundSynthesizer>
<CsOptions>
-odac
</CsOptions>
<CsInstruments>

nchnls = 2
0dbfs = 1

gisine					ftgen			0,0,4096,10, 1 // sine wave function for gbuzz
gife ftgen 0,0,16384,20,2,1 // window function for granular
seed 0


instr 70 // samplebank loader
inum ftsamplebank "Mumbai_Samples", 60, 0, 0, 0
irandsamp random 60, 64
gifw = int(irandsamp)+1
print gifw
endin


instr 99 // master clock
isubdiv = 4
gibpm = 130
gidur = ((60/gibpm)/isubdiv) // duration of each note at chosen subdiv
kmetro metro (gibpm/60)*isubdiv
gkbpm = (gibpm/60)*isubdiv //Metro clocking at chosen subdivision (16th notes)

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


instr 90 // Note Arrays
gkoffset[] fillarray 0, 12, 12, 0, -12, -24, 0

gkmajor[] fillarray 60, 65, 67, 69, 64, 69, 71, 72, 67, 72, 74, 76, 71, 76, 77, 79
gkdorian[] fillarray 60, 65, 70, 62,  63, 69, 74, 65,  67,72, 77, 69,  70, 77, 81, 72
gkaeolian[] fillarray 60, 65, 68, 63,  63, 68, 72, 67,  67,72, 75, 70,  70, 75, 79, 74

kswitch metro ((gibpm/2)*0.125)/60

gkmode[] = gkaeolian // general mode for harmonic choices

gkseq[] fillarray 65, 60, 67, 68, 67, 58, 67, 70, 67, 60, 70, 65, 67, 63, 60, 62, 65 // melodic motif sequence
endin


instr 100 //sequencer
gkswitch metro (gibpm*0.33)/128 // rateswitching
gkrate trandom gkswitch, 16, 32 // randomized note rates
gkslow metro gibpm/1024 // a slow clock for very rare events

gkmelrand metro gibpm/(gkrate*8) // clock for harmony instruments
gkbasstrig metro gibpm/(gkrate*4) // clock for bass


//random note choice for harmony
kindex trandom gkmelrand, 0, 15
koffsetindx random 0, 6
kindex = int(kindex)
koffsetindx = int(koffsetindx)

//SEQUENCE
gkseqindx init 0
if gkmelrand == 1 then
gkseqindx = gkseqindx<15 ? gkseqindx+1 : 0
endif


// switching between random notes and sequence for harmony
kseqchance trandom gkswitch, 10, 30
kseqchance = int(kseqchance)

gkseqcount init 0
if gkmelrand == 1 then
gkseqcount += 1
endif
if gkseqcount % kseqchance == 0 then
ksequenceon = 1
endif
if ksequenceon == 1 && gkseqindx % 16 == 0 then
ksequenceon = 0
endif

if ksequenceon == 1 then
gknote1 = gkseq[gkseqindx]
elseif ksequenceon == 0 then 
gknote1 = gkmode[kindex]
endif
endin

instr 60
//printk2 gkseqcount
schedkwhen gkmelrand, 0, 2, 20, 0, gidur*gkrate, gknote1-24
schedkwhen gkmelrand ,0, 2, 20, 0,  gidur*gkrate, gkseq[gkseqindx]
schedkwhen gkbasstrig, 0, 1, 104, 0, gidur*gkrate*4
endin


instr 200 // dependancy sequencer to trigger events based on probabilities or other events
kmarimbachance trandom gkswitch, 15, 30 // probability of marimba part entering
kmarimbaduration trandom gkswitch, 10, 20 // random duration of marimba part
if gkseqcount % int(kmarimbachance) == 0 then // after certain number of harmonic events only marimba will enter
kmarimba = 1
else kmarimba = 0
endif
schedkwhen kmarimba, 0, 1, 101, 0, kmarimbaduration

khornchance trandom gkswitch, 20, 60 //probabilty of horn part entering
khornduration trandom gkswitch, 15, 80 // random duration of horn part
if gkseqcount % int(khornchance) == 0 then // after certain number of harmonic events only will horn part enter
khorn = 1 
else khorn = 0
endif 
schedkwhen khorn, 0, 1, 80, 0, khornduration

khornon active 80 
if khornon == 1 then // when horn is active, stop gbuzz harmony and bass, also start spectral effects.
gkspectralsend = 1
turnoff2 60, 0, 10
elseif khornon == 0 then
gkspectralsend = 0
event "i", 60, 0, -1
endif

kgranchance trandom gkswitch, 15, 30 // probability of granular 
kgrandur trandom gkswitch, 10, 40 // random duration of granularisation
if gkseqcount % int(kgranchance) == 0 then // if certain number of harmonic events occur, granular will be triggered
kgran = 1 
kcross = 1
else 
kgran = 0
kcross = 1
endif 
schedkwhen kgran, 0, 1, 71, 0, kgrandur
//schedkwhen gkslow, 0, 1, 71, 0, kgrandur
schedkwhen kcross, 0, 1, 301, 0, kgrandur


kfofchance trandom gkswitch, 30, 60 // probability of fof 
kfofdur trandom gkswitch, 4, 12 // random duration of fof
if gkseqcount % int(kfofchance) == 0 then // if certain number of harmonic events occur, fof will be triggered
kfof = 1 
else 
kfof = 0
endif 
schedkwhen kfof, 0, 2, 400, 0, kfofdur, 128, 0.6
schedkwhen kfof, 0, 2, 400, 0, kfofdur, 64, 1

endin


instr 101 // marimba and melody sequencer
kswitch metro (gibpm*0.33)/64 // rateswitching
krate trandom gkswitch, 4, 16 // randomized note rates
printk2 krate
kmetro metro gibpm/((krate)+8)
kseqindx init 0
if kmetro == 1 then
kseqindx = kseqindx<15 ? kseqindx+1 : 0
endif
schedkwhen kmetro, 0, 1, 102, 0, gidur*krate, gkseq[kseqindx]
schedkwhen kmetro, 0, 1, 103, 0, gidur*krate, gkseq[kseqindx]
endin


instr 80 // Horn Sequencer
kindx trandom gkmelrand, 0, 4
kindx = int(kindx)
schedkwhen gkmelrand, 0, 5, 105, 0, gidur*gkrate, gkmode[kindx], 0.2
schedkwhen gkmelrand, 0, 5, 105, 0, gidur*gkrate, gkmode[kindx+4], 0.2
schedkwhen gkmelrand, 0, 5, 105, 0, gidur*gkrate, gkmode[kindx+8], 0.2
schedkwhen gkmelrand, 0, 5, 105, 0, gidur*gkrate, gkmode[kindx+12], 0.2
schedkwhen gkmelrand, 0, 5, 105, 0, gidur*gkrate, gkmode[kindx]-36, 0.8
endin


instr 20 //gbuzz harmony instrument
krevamt init 0.3
kdelamt init 0.2
kenv linseg 0, p3*0.25, 1, p3*0.25, 0.8, p3*0.25 ,0.8,  p3*0.25, 0
kdetune1 rspline 0.01, 1, 0.1, 0.5
kdetune2 rspline 0.01, 1, 0.1, 0.5
kmul rspline 0.1, 0.9, 0.01, 0.3
kamp rspline 0.3, 0.4, 0.01, 1
a1 gbuzz kenv*kamp*0.2, cpsmidinn(p4-12)+kdetune1, 30, 1, kmul, gisine
a2 gbuzz kenv*kamp*0.2, cpsmidinn(p4-12)+kdetune2, 30, 1, kmul, gisine

icf1 random 3000, 6000
icf2 random 3000, 6000
icfmodrange random 200, 1000

kmodcf lfo 1, 0.5 + rnd(1)

afilt1 moogladder a1+a2, icf1+(kmodcf*icfmodrange), 0.4
afilt2 moogladder a1+a2, icf2+(kmodcf*icfmodrange), 0.4

aclip1 clip afilt1, 0, 0.8
aclip2 clip afilt2, 0, 0.8

kpan1 rspline -1, 0, 0.1, 2
kpan2 rspline 0, 1, 0.1, 2

al1, ar1 pan2 aclip1, kpan1
al2, ar2 pan2 aclip2, kpan1

//outs (al1+al2)*0.3, (ar1+ar2)*0.3

chnmix (afilt1+afilt2)*krevamt, "reverbsend"
chnmix (afilt1+afilt2)*kdelamt, "delaysend"

chnmix (al1+al2)*0.3, "harmony1l"
chnmix (ar1+ar2)*0.3, "harmony2r"
endin

instr 104 // bass
kmul rspline 0.1, 0.3, 0.01, 0.05
kamp linseg 0, p3/4, 0.5, p3/4, 0.5, p3/8, 0.3, p3/16, 0.3, p3/16, 0
kindx trandom gkmelrand, 0, 16
kindx = int(kindx)

knotechoice = cpsmidinn(gkmode[kindx]-36)
knote portk knotechoice, 0.03

kcf linseg 500, p3/4, 3000, p3/2, 1000, p3/4, 500
kdist linseg 0, p3*0.75, 0.5
icps random 0.3, 3
klfoamp linseg 0, p3/2, 0.1
kcfmod random 100, 300
klfo lfo klfoamp, icps

asaw1 vco2 kamp*0.3+(klfo*0.1), knote, 0, 0, 0.25
asaw2 vco2 kamp*0.3+(klfo*0.1), knote+rnd(0.3), 0, 0, 0.25+rnd(0.05)
apulse gbuzz kamp*0.3+(klfo*0.1), knote+rnd(0.3), 10, 1, kmul, gisine

asum sum asaw1, asaw2, apulse
afilt lpf18 asum, kcf+(klfo*kcfmod), 0.2, kdist

//outs afilt*0.2, afilt*0.2
chnmix afilt*0.1, "bass"
endin

instr 102 // marimba
knote = p4
iamp = 0.3+rnd(0.5)
idur = p3
knote = cpsmidinn(knote)

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

//outs al*0.8, ar*0.8
chnmix al*0.6, "reverbsendl"
chnmix ar*0.6, "reverbsendr"
chnmix (al+ar)*0.8, "delaysend"
chnmix al*0.8, "marimbal"
chnmix ar*0.8, "marimbar"
chnmix (al+ar)*0.2, "spectral"
endin

instr 103 // melody
kenv linen 0.1, 0.2, p3, 0.4
kenv1 linseg 500, p3/4, 3000, p3/4, 1000
kenv2 linseg 500, p3/4+rnd(1), 3200, p3/4-rnd(1), 1300

knote = cpsmidinn(p4)
kport portk knote, rnd(0.03)

asig vco2 kenv, kport
asig2 vco2, kenv, kport+rnd(1)
asig moogladder asig, kenv1, 0.2
asig2 moogladder asig2, kenv2, 0.2

//outs asig*0.1+asig2*0.1, asig2*0.1+asig*0.1

chnmix (asig+asig2)*0.01, "reverbsend"
chnmix (asig+asig2)*0.4, "delaysend"
chnmix asig*0.1+asig2*0.1, "melodyl"
chnmix asig2*0.1+asig*0.1, "melodyl"
endin

instr 105 // horn instrument
knote = p4
iamp = p5
kcps = cpsmidinn(knote-24)
kmodf = kcps
idur = p3
aenv linseg 0, idur/6, 1, idur/6, 1, idur/2, 0.65, idur/6, 0
aindx linseg 0, (idur/4)+rnd(0.3), 2, idur/12, 1.5, idur/2, 0.65, idur/6, 0
kbeta rspline 0.01, 0.3, 0.05, 0.5
abreath noise iamp*0.04, 0.6 + kbeta
abreath butterhp abreath, 1000

amod oscili aindx*kmodf, kmodf+rnd(2), -1, 0.25
acar oscili 1, kcps+amod

aout = ((acar*iamp)+abreath)*aenv
aout butterlp aout, 7000+rnd(200)

kpan rspline -1, 1, 0.5, 4
al, ar pan2 aout, kpan

//outs al*iamp*0.2, ar*iamp*0.2
chnmix al*0.2, "reverbsendl"
chnmix ar*0.2, "reverbsendr"
chnmix al*0.3, "delaysend"
chnmix ar*0.3, "delaysend"
chnmix al*iamp*0.2, "hornsl"
chnmix ar*iamp*0.2, "hornsr"
endin


instr 71 // Sample Granulator
krandpitch rspline 1, 1.5, 0.1, 5
krandgd rspline 0, -0.01, 0.1, 2
  
kpitch = 1*krandpitch
ktime = 1
ksyncgain = 1
krgain linseg 0, p3/2, 0.3, p3/8, 0.8, p3/8, 0.7, p3/4, 0 // randomized granulators enter later
kdelaysend linseg 0, p3/2, 0, p3/8, 0, p3/8, 0.2, p3/4, 0.5 // send to delay towards the end of granularisation
kglob = 0.3
kgd linseg 0.08, p3/8, 0.02, p3/8, 0.01, p3/2, 0.02, p3/4, 0.05
//kgd = 0.02+krandgd //  grain duration 
kds linseg 0.01, p3/8, 10, p3/8, 50, p3/8, 100, p3/4, 100, p3/4, 40, p3/8, 10
                         
kpr = ktime/(kds*kgd)       //  pointer rate 
  
kprandom rspline -2, 2, 1, 5 
ilen nsamp gifw
ilens = ilen/sr 
klstartl rspline 0, 1, 0.4, 10
klendl rspline 0, 2, 0.3, 11
klstartr rspline 0, 1, 0.4, 10
klendr rspline 0, 2, 0.3, 11
kgain rspline 0.5, 1, 0.05, 0.5
kcf1 rspline 4000, 16000, 0.01, 2
kcf2 rspline 4000, 16000, 0.01, 2
 

asig1 syncloop  ksyncgain, kds, kpitch, kgd, kpr, 0, 2, gifw, gife, 4 // synchronous granularisation

asigl syncloop  krgain*0.5, kds, kpitch*2, kgd, kprandom, klstartl, klendl, gifw, gife, 2 // some randomization 
asigr syncloop  krgain*0.5, kds, kpitch*2, kgd, kprandom, klstartr, klendr, gifw, gife, 2

// high pass to remove muddiness
ahpl butterhp asig1*0.5+asigl*0.3, 300
ahpr butterhp asig1*0.5+asigr*0.3, 300

// subtle lowpass modulation to create front to back spactialisation
ahpl butterlp ahpl, kcf1
ahpr butterlp ahpl, kcf2


//outs ahpl*(kglob*kgain), ahpr*kglob*(1-kgain)
chnmix ahpl*0.1, "reverbsendl"
chnmix ahpr*0.1, "reverbsendr"
chnmix ahpl*kdelaysend, "delaysend"
chnmix ahpr*kdelaysend, "delaysend"
chnmix ahpl*(kglob*kgain), "granl"
chnmix ahpl*(kglob*kgain), "granr"
endin


instr 300 // mixer
aharmonyl chnget "harmony1l"
aharmonyr chnget "harmony2r"
abass chnget "bass"
amarimbal chnget "marimbal"
amarimbar chnget "marimbar"
amelodyl chnget "melodyl"
amelodyr chnget "melodyr"
ahornsl chnget "hornsl"
ahornsr chnget "hornsr"
agranl chnget "granl"
agranr chnget "granr"

atonalL sum aharmonyl*0.7, amarimbal*0.6, amelodyl, ahornsl, abass*0.8
atonalR sum aharmonyr*0.7, amarimbar*0.6, amelodyr, ahornsr, abass*0.8

agranularL sum agranl
agranularR sum agranr

gkcrossamp rspline 0, 1, 0.1, 4
agranularL = agranularL*(1-gkcrossamp)
agranularR = agranularR*(1-gkcrossamp)

outs atonalL+agranularL*0.7, atonalR+agranularR*0.7


chnclear "harmony1l"
chnclear "harmony2r"
chnclear "bass"
chnclear "marimbal"
chnclear "marimbar"
chnclear "melodyl"
chnclear "melodyr"
chnclear "hornsl"
chnclear "hornsr"
chnclear "granl"
chnclear "granr"

chnmix (atonalL+atonalR)*0.5, "tonal"
chnmix (agranularL+agranularR)*0.5, "granularmix"
chnmix ((atonalL+atonalR)*0.5+(agranularL+agranularR)*0.5)*gkspectralsend, "spectral"
endin


instr 301 // cross synthesizing granulated samples with tonal parts
kamp1 rspline 0.1, 1, 0.3, 10
kamp2 = 1-kamp1
atonal chnget "tonal"
agranular chnget "granular"
ftonal pvsanal atonal, 512, 128, 512, 1
fgranular pvsanal agranular, 512, 128, 512, 1
fcross pvscross ftonal, fgranular, kamp1, kamp2
across pvsynth fcross

across = across*gkcrossamp
kpan rspline -1, 1, 0.1, 3
al, ar pan2 across, kpan
outs al, ar
chnclear "granular"
chnclear "tonal"
endin

instr 302 // stereo spectral glitchy effects
kdelay jspline 2, 5, 30
kblurtime rspline 0, 0.3, 0.1, 0.2
kfeedback rspline 0.1, 0.5, 0.1, 4
kspeed rspline 1, 8, 0.4, 4
kmin rspline 200, 600, 0.3, 5
kmax rspline 4000, 16000, 0.2, 10
ain chnget "spectral"
aFB = 0
fsig pvsanal    ain + aFB, 4096, 4096/4, 4096, 1
gih, gkt pvsbuffer fsig, 4
kh init gih 

iphasor        ftgen        0, 0, 65536, 7, 0, 65536, 1 
	         
   
aread         osciliktp     kspeed/4, iphasor, 0        
kread        downsamp    aread
kread        =        kread * 4

fbuf pvsbufread kread - kdelay, kh   
    fbp pvsbandp fbuf, kmin, kmin+150, kmax, kmax-150
    fscale pvscale fbp, 2 
    fblur pvsblur fscale, kblurtime, 1
    aresyn pvsynth fblur
    aFB = aresyn*kfeedback
    
fbufr pvsbufread kread - kdelay+rnd(1), kh   
    fbpr pvsbandp fbufr, kmin+200, kmin+200+150, kmax+1000, kmax+1000-150
    fscaler pvscale fbpr, 2 
    fblurr pvsblur fscaler, kblurtime+rnd(0.1), 1
    aresynr pvsynth fblurr
    aFB = aresynr*kfeedback
    outs aresyn*0.5, aresynr*0.5
    chnclear "spectral"
endin




instr 10 //reverbsc
arev chnget "reverbsend"
kfb init 0.8
kcf init 8000
arev butterhp arev, 450
al, ar reverbsc arev, arev, kfb, kcf
outs al*0.7, ar*0.7
chnclear "reverbsend"
endin




instr 11 // delay
adel chnget "delaysend"
khpf init 450
klpf init 7500
klpfmod1 lfo 1000, 4
klpfmod2 lfo 1000, 5
kfb init 0.5
irates[] fillarray 1, 2, 4, 8, 16, 32, 64, 128, 256, 512
kdelayrate = 8
afb init 0
adel butterhp adel, khpf
kdelay = ((gidur*irates[kdelayrate])*100)*16

adelayl vdelay adel+afb, kdelay, 500
adelayr vdelay adel+afb, kdelay*0.75, 500
afb = ((adelayl + adelayr)*0.5) * kfb
adelayl butterlp adelayl, klpf+klpfmod1
adelayr butterlp adelayr, klpf+klpfmod2

aoutl, aoutr freeverb adelayl, adelayr, 0.8, 0.3

al ntrpol adelayl, aoutl, 0.7
ar ntrpol adelayr, aoutr, 0.7

outs al*0.7, ar*0.7

chnclear "delaysend"
endin


gifn1 ftgen 10,0,1025,19,0.5,0.5,270,0.5
gifn2 ftgen 12,0,1025,7,0,1024,1

// e, a, i, o, u, e, a, i
gif1 ftgen 0,0,8,-2, 400, 650, 650, 400, 400, 400, 650, 650
gif2 ftgen 0,0,8,-2,1700,1870,1870, 1700, 1700, 1700, 1870, 1870
gif3 ftgen 0,0,8,-2,2600,2800,2800, 2600, 2600, 2600, 2800, 2800
gif4 ftgen 0,0,8,-2,3200,3250,3250, 3200, 3200, 3200, 3250, 3250
gif5 ftgen 0,0,8,-2,3580,3100,3100, 3580, 3580, 3580, 3100, 3100

gib1 ftgen 0,0,8,-2, 70, 80, 80, 70 , 70, 70, 80, 70
gib2 ftgen 0,0,8,-2, 80, 90, 90, 80 , 80, 80, 90, 60
gib3 ftgen 0,0,8,-2,100,120, 120, 100, 100, 100, 120, 120
gib4 ftgen 0,0,8,-2,120,130, 130, 120, 120, 120, 130, 130
gib5 ftgen 0,0,8,-2,120,140, 140, 120, 120, 120, 140, 140


instr 400 // fof synthesis
gifn = gifn1
kn phasor 0.2

kf1 tablei kn, gif1, 1, 0, 1 
kf2 tablei kn, gif2, 1, 0, 1 
kf3 tablei kn, gif3, 1, 0, 1 
kf4 tablei kn, gif4, 1, 0, 1 
kf5 tablei kn, gif5, 1, 0, 1 
 
kb1 tablei kn, gib1, 1, 0, 1 
kb2 tablei kn, gib2, 1, 0, 1 
kb3 tablei kn, gib3, 1, 0, 1 
kb4 tablei kn, gib4, 1, 0, 1 
kb5 tablei kn, gib5, 1, 0, 1 
 
iamp = p5
ifo = p4
koct = 0
kdur = 0.02
kris = 0.002
kdec = 0.007
iol = 0.02*ifo + 2
 
avibr oscili ifo*0.02, 4
ajit  randi  ifo*0.005, 1.2
afo = ifo + ajit + avibr
kamp2 rspline 0, 1, 0.3, 10
kamp3 rspline 0, 1, 0.3, 10
kamp4 rspline 0, 1, 0.3, 10
kamp5 rspline 0, 1, 0.3, 10
  
 
a1 fof   1, afo, kf1, koct, kb1, kris, kdur, kdec, iol, -1, gifn, p3 
a2 fof kamp2, afo, kf2, koct, kb2, kris, kdur, kdec, iol, -1, gifn, p3 
a3 fof kamp3, afo, kf3, koct, kb3, kris, kdur, kdec, iol, -1, gifn, p3 
a4 fof kamp4, afo, kf4, koct, kb4, kris, kdur, kdec, iol, -1, gifn, p3 
a5 fof kamp5, afo, kf5, koct, kb5, kris, kdur, kdec, iol, -1, gifn, p3 
 
amix = (a1 + a2 + a3 + a4 + a5)*0.03*iamp
asig linen amix*0.3, 0.5, p3, 0.3
kspectral linseg 0, p3/2, 0.5, p3/2, 1 // sending to spectral glitch over time.
 
chnmix asig*0.7*kspectral, "spectral"
chnmix asig*0.9, "delaysend"
chnmix asig, "reverb"
       outs asig*(0.3+rnd(0.3)), asig*(0.3+rnd(0.3))
endin


</CsInstruments>
<CsScore>
i99 0 1000000
i100 0 1000000
i90 0 1000000
i70 0 1000000
i10 0 1000000
i11 0 1000000
i200 0 1000000
i300 0 10000000
i302 0 10000000
</CsScore>
</CsoundSynthesizer>
