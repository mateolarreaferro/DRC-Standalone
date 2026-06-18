<CsoundSynthesizer>
<CsOptions>
-o dac
-d
--limiter=0.9
</CsOptions>
<CsInstruments>
sr = 44100
ksmps = 64
nchnls = 2
0dbfs = 1



giSine ftgen 0, 0, 513, 10, 1
giSitarA1 ftgen 0, 0, 513, 7, 0, 64, 1, 64, 0.4, 384, 0.2
giSitarA3 ftgen 0, 0, 513, 7, 0, 64, 0.8, 128, 1, 320, 0.5
giSitarA4 ftgen 0, 0, 513, 7, 0, 64, 1, 448, 0.5
giSitarA5 ftgen 0, 0, 513, 7, 0, 16, 1, 128, 0.3, 368, 0.8



chn_k "amplitude", 3, 2, 0.55, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "reverbMix", 3, 2, 0.28, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.82, 0.5, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"
chnset 0.55, "amplitude"
chnset 0.28, "reverbMix"
chnset 0.82, "reverbSize"

giMaster = 0.28


instr 1
  iDur = p3 < 0 ? 8 : p3
  icps       =         p4               ; P4 = PCH
  ioct       =         octcps(p4)
  iamp       =         (p5 * chnget("amplitude"))                ; P5 = DB
  ilft       =         sqrt(0.5)                 ; P6 = PANNER
  irght      =         sqrt(0.5)
  iris       =         .02
  isnf = giSine
  ia3f = giSitarA3                       ; ENVLPX RISE FUNCTIONS...
  ia1f = giSitarA1
  ia5f = giSitarA5
  ia4f = giSitarA4
  idur       =         (iDur-.025)/4
  ;-------------------------  PARALLEL MOD/CAR
  kprt           linseg    0,.005,.2,.005,.07,.0025,.06,.0025,-.04,.005,-.02,.005,-.01,idur,.015,idur,.0035,idur,-.01,idur,0
  koct           =         kprt+ioct
  kcps           =         cpsoct(koct)
  kdtn1          =         cpsoct(koct*.04)
  kdtn2          =         cpsoct(koct*.07)
  k5             envlpx    iamp,iris,iDur,iDur*.25,ia5f,.9,.01
  a5             oscili    k5,kcps,isnf
  a6             oscili    .71*iamp,kcps*11,isnf
  acps4          =         a5+a6+kcps-kdtn2
  k4             envlpx    iamp,iris,iDur,iDur*.25,ia4f,.01,.01
  a4             oscili    k4,acps4,isnf
  ;-------------------------  STACKED MOD/CAR
  k3             envlpx    .75*iamp,iris,iDur,iDur*.25,ia3f,.9,.01
  a3             oscili    k3,kcps*1.15,isnf
  acps2          =         a3+kcps+kdtn1
  a2             oscili    1,acps2,isnf
  acps1          =         a2+kcps+kdtn1
  k1             envlpx    .75*iamp,iris,iDur,iDur*.25,ia1f,.01,.01
  a1             oscili    k1,acps1,isnf
  ;-------------------------  MIX/OUT
  asig           =         (a1+a4)/2
  galt           =         asig*ilft
  gart           =         asig*irght


  kGate linsegr 1, 0.002, 1, max(iDur - 0.04, 0.02), 0.45, 0.08, 0
  galt = tanh(galt * kGate * giMaster * 1.5)
  gart = tanh(gart * kGate * giMaster * 1.5)
  chnmix galt, "revL"
  chnmix gart, "revR"
  outs galt, gart
endin

instr 100
  Schan strget p4
  iVal  = p5
  chnset iVal, Schan
  turnoff
endin

instr 99
  kMix  chnget "reverbMix"
  kSize chnget "reverbSize"
  aInL  chnget "revL"
  aInR  chnget "revR"
  aL, aR reverbsc aInL, aInR, kSize, 9000
  outs aL * kMix, aR * kMix
  chnclear "revL"
  chnclear "revR"
endin

</CsInstruments>
<CsScore>
i 99 0 36000
f 0 36000
</CsScore>
</CsoundSynthesizer>
