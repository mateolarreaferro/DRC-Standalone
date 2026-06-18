<CsoundSynthesizer>
<CsOptions>
-odac -d
</CsOptions>
<CsInstruments>

sr     = 48000
ksmps  = 100
nchnls = 2
0dbfs  = 1

instr Kick
    iOctave init p5
    iAmplitude init p4
    iDuration init p3
    iStartTime init p2
    aOscAmpEnv = expsegr:a(0.000100, 0.010000, 1.000000, 0.500000, 0.000100, 0.900000, 0.000100)
    aRandAmpEnv = expsegr:a(0.000100, 0.001000, 0.500000, 0.002000, 0.040000, 0.500000, 0.000100, 0.010000, 0.000100)
    aOscOctEnv = linsegr:a(9.200000, 0.050000, iOctave, 0.500000, iOctave, 0.050000, iOctave)
    aFreqFromOct0 = cpsoct:a(aOscOctEnv)
    aFiltCutoffEnv = expsegr:a(20000.000000, 0.300000, 200.000000, 0.900000, 20.000000, 0.500000, 20.000000)
    aOsc0 = oscili:a(aOscAmpEnv, aFreqFromOct0)
    aRand0 = rand:a(aRandAmpEnv, 2.000000)
    aSigMix = aOsc0 * 0.350000 + aRand0
    aFilt0 = mvclpf3:a(aSigMix, aFiltCutoffEnv, 0.000000)
    aMaths9 = aFilt0 * iAmplitude
    outs aMaths9, aMaths9
endin

</CsInstruments>
<CsScore>

t 0 60

i"Kick" 0.000000 0.125000 0.500000 6.273083
i"Kick" 0.250000 0.125000 0.169541 6.025758
i"Kick" 0.375000 0.125000 0.265359 6.299560
i"Kick" 0.500000 0.125000 0.338136 6.156609
i"Kick" 0.750000 0.125000 0.107444 6.010960
i"Kick" 0.875000 0.125000 0.189788 6.502128
i"Kick" 1.250000 0.125000 0.359605 6.290485
i"Kick" 1.375000 0.125000 0.253425 6.694606
i"Kick" 1.750000 0.125000 0.281007 6.072183
i"Kick" 2.250000 0.125000 0.437406 6.517318
i"Kick" 2.500000 0.125000 0.301804 6.185603
i"Kick" 2.625000 0.125000 0.303654 6.217183
i"Kick" 3.000000 0.125000 0.500000 6.328006
i"Kick" 3.125000 0.125000 0.120511 6.111028
i"Kick" 3.250000 0.125000 0.354486 6.277189
i"Kick" 3.500000 0.125000 0.250104 6.001258

</CsScore>
</CsoundSynthesizer>
