<CsoundSynthesizer>
<CsOptions>
</CsOptions>
; ==============================================
<CsInstruments>

sr	=	48000
ksmps	=	1
nchnls	=	2
0dbfs	=	1

; --- inlined: ../k35.udo ---
;; 12db/oct low-pass filter based on Korg 35 module
;; (found in MS-10 and MS-20).
;; 
;; Based on code by Will Pirkle, presented in:
;; 
;; http://www.willpirkle.com/Downloads/AN-5Korg35_V3.pdf
;; 
;; [ARGS]
;; 
;; ain - audio input
;; acutoff - frequency of cutoff
;; kQ - filter Q [1, 10.0] (k35-lpf will clamp to boundaries)
;; knonlinear - use non-linear processing
;; ksaturation - saturation for tanh distortion

opcode k35_lpf, a, akkkk

  ain, kcutoff, kQ, knonlinear, ksaturation xin

  kz1 init 0
  kz2 init 0
  kz3 init 0
  kv1 init 0
  kv2 init 0
  kv3 init 0
  aout init 0

  kg init 0
  kG init 0
  kK init 0
  klastcut init -1
  klastQ init -1
  kS35 init 0 
  kalpha init -1 
  klpf2_beta init -1 
  khpf1_beta init -1 

  kindx = 0
  kQ = limit(kQ, 1.0, 10.0)
  kcf = kcutoff 

  if (klastcut != kcf) then
    ; pre-warp the cutoff- these are bilinear-transform filters
    kwd = 2 * $M_PI * kcf
    iT  = 1/sr 
    kwa = (2/iT) * tan(kwd * iT/2) 
    kg  = kwa * iT/2 
    kG  = kg / (1 + kg)

  endif

  if (klastQ != kQ) then
    kK  = 0.01 + ((2.0 -  0.01) * (kQ / 10.0))
  endif

  if ((klastcut != kcf) || (klastQ != kQ)) then
    klpf2_beta = (kK - (kK * kG)) / (1.0 + kg)
    khpf1_beta = -1.0 / (1.0 + kg)
    kalpha = 1.0 / (1.0 - (kK * kG) + (kK * kG * kG))
  endif

  klastcut = kcf
  klastQ = kQ
  
  while (kindx < ksmps) do
    ksig = ain[kindx]

    ;; lpf1
    kv1 = (ksig - kz1) * kG
    klp1 = kv1 + kz1 
    kz1 = klp1 + kv1
   
    ku = kalpha * (klp1 + kS35)

    if (knonlinear == 1) then
      ku = tanh(ku * ksaturation)
    endif

    ;; lpf2
    kv2 = (ku - kz2) * kG
    klp2 = kv2 + kz2 
    kz2 = klp2 + kv2
    ky = kK * klp2

    ;; hpf1
    kv3 = (ky - kz3) * kG
    klp3 = kv3 + kz3 
    kz3 = klp3 + kv3
    khp1 = ky - klp3

    kS35 = (klpf2_beta * kz2) + (khpf1_beta * kz3)

    kout = (kK > 0) ? (ky / kK) : ky 

    aout[kindx] = kout

    kindx += 1
  od

  xout aout

endop



opcode k35_lpf, a, aakkk

  ain, acutoff, kQ, knonlinear, ksaturation xin

  kz1 init 0
  kz2 init 0
  kz3 init 0
  kv1 init 0
  kv2 init 0
  kv3 init 0
  aout init 0

  kg init 0
  kG init 0
  kK init 0
  klastcut init -1
  klastQ init -1
  kS35 init 0 
  kalpha init -1 
  klpf2_beta init -1 
  khpf1_beta init -1 

  kindx = 0
  kQ = limit(kQ, 1.0, 10.0)

  if (klastQ != kQ) then
    kK  = 0.01 + ((2.0 -  0.01) * (kQ / 10.0))
  endif

  klastQ = kQ
  
  while (kindx < ksmps) do
    kcf = acutoff[kindx]
    ksig = ain[kindx]

    if (klastcut != kcf) then
      ; pre-warp the cutoff- these are bilinear-transform filters
      kwd = 2 * $M_PI * kcf
      iT  = 1/sr 
      kwa = (2/iT) * tan(kwd * iT/2) 
      kg  = kwa * iT/2 
      kG  = kg / (1 + kg)

    endif

    if ((klastcut != kcf) || (klastQ != kQ)) then
      klpf2_beta = (kK - (kK * kG)) / (1.0 + kg)
      khpf1_beta = -1.0 / (1.0 + kg)
      kalpha = 1.0 / (1.0 - (kK * kG) + (kK * kG * kG))
    endif

    ;; lpf1
    kv1 = (ksig - kz1) * kG
    klp1 = kv1 + kz1 
    kz1 = klp1 + kv1
   
    ku = kalpha * (klp1 + kS35)

    if (knonlinear == 1) then
      ku = tanh(ku * ksaturation)
    endif

    ;; lpf2
    kv2 = (ku - kz2) * kG
    klp2 = kv2 + kz2 
    kz2 = klp2 + kv2
    ky = kK * klp2

    ;; hpf1
    kv3 = (ky - kz3) * kG
    klp3 = kv3 + kz3 
    kz3 = klp3 + kv3
    khp1 = ky - klp3

    kS35 = (klpf2_beta * kz2) + (khpf1_beta * kz3)

    kout = (kK > 0) ? (ky / kK) : ky 

    aout[kindx] = kout

    klastcut = kcf
    kindx += 1
  od

  xout aout

endop

;; 6db/oct high-pass filter based on Korg 35 module
;; (found in MS-10 and MS-20).
;; 
;; Based on code by Will Pirkle, presented in:
;; 
;; http://www.willpirkle.com/Downloads/AN-7Korg35HPF_V2.pdf 
;; 
;; [ARGS]
;; 
;; ain - audio input
;; acutoff - frequency of cutoff
;; kQ - filter Q [1, 10.0] (k35_hpf will clamp to boundaries)
;; knonlinear - use non-linear processing
;; ksaturation - saturation for tanh distortion

opcode k35_hpf, a, akkkk

  ain, kcutoff, kQ, knonlinear, ksaturation xin

  kz1 init 0
  kz2 init 0
  kz3 init 0
  kv1 init 0
  kv2 init 0
  kv3 init 0
  aout init 0

  kg init 0
  kG init 0
  kK init 0
  klastcut init -1
  klastQ init -1
  kS35 init 0 
  kalpha init -1 
  khpf2_beta init -1 
  klpf1_beta init -1 

  kindx = 0
  kQ = limit(kQ, 1.0, 10.0)
  kcf = kcutoff 

  if (klastcut != kcf) then
    ; pre-warp the cutoff- these are bilinear-transform filters
    kwd = 2 * $M_PI * kcf
    iT  = 1/sr 
    kwa = (2/iT) * tan(kwd * iT/2) 
    kg  = kwa * iT/2 
    kG  = kg / (1 + kg)

  endif

  if (klastQ != kQ) then
    kK  = 0.01 + ((2.0 -  0.01) * (kQ / 10.0))
  endif

  if ((klastcut != kcf) || (klastQ != kQ)) then
    khpf2_beta = -kG / (1.0 + kg)
    klpf1_beta = 1.0 / (1.0 + kg)
    kalpha = 1.0 / (1.0 - (kK * kG) + (kK * kG * kG))
  endif

  klastcut = kcf
  klastQ = kQ
  
  while (kindx < ksmps) do
    ksig = ain[kindx]

    ;; hpf1
    kv1 = (ksig - kz1) * kG
    klp1 = kv1 + kz1 
    kz1 = klp1 + kv1
    ky1 = ksig - klp1
   
    ku = kalpha * (ky1 + kS35)
    ky = kK * ku

    if (knonlinear == 1) then
      ky = tanh(ky * ksaturation)
    endif

    ;; hpf2
    kv2 = (ky - kz2) * kG
    klp2 = kv2 + kz2 
    kz2 = klp2 + kv2
    khp2 = ky - klp2 

    ;; lpf1
    kv3 = (khp2 - kz3) * kG
    klp3 = kv3 + kz3 
    kz3 = klp3 + kv3

    kS35 = (khpf2_beta * kz2) + (klpf1_beta * kz3)

    kout = (kK > 0) ? (ky / kK) : ky 

    aout[kindx] = kout

    kindx += 1
  od

  xout aout

endop


opcode k35_hpf, a, aakkk

  ain, acutoff, kQ, knonlinear, ksaturation xin

  kz1 init 0
  kz2 init 0
  kz3 init 0
  kv1 init 0
  kv2 init 0
  kv3 init 0
  aout init 0

  kg init 0
  kG init 0
  kK init 0
  klastcut init -1
  klastQ init -1
  kS35 init 0 
  kalpha init -1 
  khpf2_beta init -1 
  klpf1_beta init -1 

  kindx = 0
  kQ = limit(kQ, 1.0, 10.0)

  if (klastQ != kQ) then
    kK  = 0.01 + ((2.0 -  0.01) * (kQ / 10.0))
  endif

  klastQ = kQ
  
  while (kindx < ksmps) do
    kcf = acutoff[kindx]
    ksig = ain[kindx]

    if (klastcut != kcf) then
      ; pre-warp the cutoff- these are bilinear-transform filters
      kwd = 2 * $M_PI * kcf
      iT  = 1/sr 
      kwa = (2/iT) * tan(kwd * iT/2) 
      kg  = kwa * iT/2 
      kG  = kg / (1 + kg)

    endif

    if ((klastcut != kcf) || (klastQ != kQ)) then
      khpf2_beta = -kG / (1.0 + kg)
      klpf1_beta = 1.0 / (1.0 + kg)
      kalpha = 1.0 / (1.0 - (kK * kG) + (kK * kG * kG))
    endif

    ;; hpf1
    kv1 = (ksig - kz1) * kG
    klp1 = kv1 + kz1 
    kz1 = klp1 + kv1
    ky1 = ksig - klp1
   
    ku = kalpha * (ky1 + kS35)
    ky = kK * ku

    if (knonlinear == 1) then
      ky = tanh(ky * ksaturation)
    endif

    ;; hpf2
    kv2 = (ky - kz2) * kG
    klp2 = kv2 + kz2 
    kz2 = klp2 + kv2
    khp2 = ky - klp2 

    ;; lpf1
    kv3 = (khp2 - kz3) * kG
    klp3 = kv3 + kz3 
    kz3 = klp3 + kv3

    kS35 = (khpf2_beta * kz2) + (klpf1_beta * kz3)

    kout = (kK > 0) ? (ky / kK) : ky 

    aout[kindx] = kout

    klastcut = kcf
    kindx += 1
  od

  xout aout

endop


; --- end ../k35.udo ---


;; test instruments to demo filter cutoff sweep with high resonance

instr 1	

asig = vco2(0.5, cps2pch(6.00, 12))
asig = k35_lpf(asig, expseg:a(10000, p3, 30), 9.9, 0, 1)
asig *= 0.25
asig  = limit(asig, -1.0, 1.0)

outc(asig, asig)

endin


instr 2	

asig = vco2(0.5, cps2pch(6.00, 12))
asig = k35_lpf(asig, expseg:k(10000, p3, 30), 9.9, 0, 1)
asig *= 0.25
asig  = limit(asig, -1.0, 1.0)

outc(asig, asig)

endin

instr 3	

asig = vco2(0.5, cps2pch(6.00, 12))
asig = k35_hpf(asig, expseg:a(10000, p3, 30), 9.9, 0, 1)
asig *= 0.25
asig  = limit(asig, -1.0, 1.0)

outc(asig, asig)

endin


instr 4	

asig = vco2(0.5, cps2pch(6.00, 12))
asig = k35_hpf(asig, expseg:k(10000, p3, 30), 9.9, 0, 1)
asig *= 0.25
asig  = limit(asig, -1.0, 1.0)

outc(asig, asig)

endin

;; beat instruments

instr ms20_drum

  ipch = cps2pch(p4, 12)
  iamp = ampdbfs(p5)
  aenv = expseg(20000, 0.05, ipch, p3 - .05, ipch)

  asig = rand(1.0)
  asig = k35_hpf(asig, 100, 7, 0, 1)
  asig = k35_lpf(asig, aenv, 9.8, 0, 1)

  asig = tanh(asig * 16)

  asig *= expon(iamp, p3, 0.0001)

  outc(asig, asig)

endin

instr ms20_bass 
  ipch = cps2pch(p4, 12)
  iamp = ampdbfs(p5)
  aenv = expseg(1000, 0.1, ipch * 2, p3 - .05, ipch * 2)

  asig = vco2(1.0, ipch)
  asig = k35_hpf(asig, ipch, 5, 0, 1)
  asig = k35_lpf(asig, aenv, 8, 0, 1)

  asig *= expon(iamp, p3, 0.0001) * 0.8

  outc(asig, asig)
endin

;; perf code

gktempo init 122

opcode beat_dur,i,0
  xout 60 / i(gktempo) 
endop

instr bass_player
  idur = beat_dur() / int(random(1,3)) 
  ipch = 6.00 + int(random(1,3)) + int(random(1,3)) / 100

  schedule("ms20_bass", 0, idur, ipch, -11) 

  schedule("bass_player", idur, 0.1)
endin

instr beat_player 
  istep_total = p4 
  istep = istep_total % 16

  if(istep % 4 == 0) then
    ipch = ((istep_total % 128) < 112) ? 4.00 : 8.00
    iamp = (istep == 0)  ? -9 : -12
    schedule("ms20_drum", 0, 0.5, ipch, iamp)
  endif

  schedule("ms20_drum", 0, 0.125, 14.00, 
           (istep % 4 == 0) ? -12 : -18)

  if(istep == 4 || istep == 14) then
    schedule("ms20_drum", 0, 0.35, 10.00, -12)
  elseif (istep == 6 || istep == 12) then
    schedule("ms20_drum", 0, 0.35, 10.06, -12)
  endif

  schedule("beat_player", beat_dur() / 4, 0.1, istep_total + 1)
endin

;; start play of beats

instr start_beats
  schedule("beat_player", 0, 0.1, 0)
  schedule("bass_player", 0, 0.1)
endin


</CsInstruments>
; ==============================================
<CsScore>
i1 0 5.0
i2 5 5.0
i3 10 5.0
i4 15 5.0

i "start_beats" 22 0.5 0
f0 3600

</CsScore>
</CsoundSynthesizer>
