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
giWoodAmp ftgen 0, 0, 513, 7, 0, 13, 0.6, 23, 0.9, 25, 1, 17, 0.9, 34, 0.5, 64, 0.2, 84, 0.1, 84, 0.05, 168, 0
giWoodShp ftgen 0, 0, 513, 3, -1, 1, 1, 0.841, -0.707, -0.595, 0.5, 0.42, -0.354, -0.297, 0.25, 0.210



chn_k "amplitude", 3, 2, 0.55, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "reverbMix", 3, 2, 0.28, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.82, 0.5, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"
chnset 0.55, "amplitude"
chnset 0.28, "reverbMix"
chnset 0.82, "reverbSize"

giMaster = 0.28


instr 1
  iDur = p3 < 0 ? 8 : p3
  idur       =         iDur                            ; P4 = PCH
  iamp       =         (p5 * chnget("amplitude"))                     ; P5 = DB
  icps       =         p4*2                  ; P6 = PANNER
  ilft       =         sqrt(0.5)
  irght      =         sqrt(0.5)
  isnf = giSine 
  iampf = giWoodAmp
  itblf = giWoodShp
  k1             oscili    iamp,1/idur,iampf
  a1             oscili    k1,icps,isnf
  k2             linseg    255,.04,0,.16,0               ; DISTORTION ENV
  a2             oscili    k2,icps*.7071,isnf
  a3             =         a2+256
  a4             tablei    a3,itblf
  asig           =         a4*a1
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
