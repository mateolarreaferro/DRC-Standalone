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



giDsfCs ftgen 0, 0, 513, 11, 1
giSine ftgen 0, 0, 513, 10, 1
giDsfAdsr ftgen 0, 0, 513, 7, 0, 64, 1, 32, 1, 32, 0.65, 21, 0.75, 85, 0.75, 22, 0.65, 171, 0.5, 85, 0



chn_k "amplitude", 3, 2, 0.55, 0, 1, 0, 0, 0, 0, "unit= label=Amplitude"
chn_k "reverbMix", 3, 2, 0.28, 0, 1, 0, 0, 0, 0, "unit= label=Reverb_Mix"
chn_k "reverbSize", 3, 2, 0.82, 0.5, 1, 0, 0, 0, 0, "unit= label=Reverb_Size"
chnset 0.55, "amplitude"
chnset 0.28, "reverbMix"
chnset 0.82, "reverbSize"

giMaster = 0.28


instr 1
  iDur = p3 < 0 ? 8 : p3
  icps       =         p4                         ; P4 = PCH
  iamp       =         (p5 * chnget("amplitude"))                          ; P5 = DB
  iampf = giDsfAdsr                                 ; P6 = AMP ENV FN.
  ipan = 0.5                                 ; P7 = PANNER
  iamx       =         .78                                ; MAX INDEX IAMX<=.78
  icsf = giDsfCs
  isnf = giSine
  kamp           oscili    iamp,1/iDur,iampf                    ; AMP ENV
  k1             oscili    iamx,1/iDur,iampf                    ; INDEX ENV
  ksq            =         k1*k1
  kmp            =         -2*k1
  k2             =         1+ksq
  a2             oscili    kmp,icps,icsf
  a3             =         a2+k2
  k3             =         sqrt((1-ksq)/(1+ksq))              ; AMP NORM. FUNC.
  a1             oscili    k3,icps,isnf
  a3             =         a1/a3
  asig           =         kamp*a3
  alt            =         asig*sqrt(ipan)
  art            =         asig*sqrt(1-ipan)


  kGate linsegr 1, 0.002, 1, max(iDur - 0.04, 0.02), 0.45, 0.08, 0
  aL = tanh(alt * kGate * giMaster * 1.5)
  aR = tanh(art * kGate * giMaster * 1.5)
  chnmix aL, "revL"
  chnmix aR, "revR"
  outs aL, aR
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
