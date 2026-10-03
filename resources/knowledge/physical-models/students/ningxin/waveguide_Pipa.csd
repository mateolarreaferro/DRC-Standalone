<CsoundSynthesizer>
<CsOptions>
;-odac
--limiter=.9
;-dm0 -F pipa_A2-E6.mid
;-W -o waveguide_result.wav
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 16
nchnls = 2
0dbfs = 1

; excitation recording
giPipa ftgen 0, 0, 262144, 1, "pipa-G4-recorded.wav", 0, 0, 0
; body IR
giIr   ftgen 1, 0, 16384, 1, "pipa-Body-IR.wav", 0, 0, 0

; M zeros and N poles
; string-damping filter (Hd(z))
opcode Damping,a,ai
	asig,ifreq xin
	; damping variation/gain compensation of damping filter
	iwgdec = 3 ; attenuation in dB
	ig = cos($M_PI*ifreq/sr)
	igf pow 10, -iwgdec/(20*ifreq)
	
	; coefficients are different for different frequency ranges 
	; if ifreq > 220, b0 = 0.9015, b1 = 0.1275, a1 = 0.0331
	; if ifreq <= 220, b0 = 0.6502, a1 = -0.3412
	if (ifreq > 440) then
		igc = ig/igf
		adamp filter2 asig, 2, 1, 0.9015*igc, 0.1275*igc, 0.0331
	elseif (ifreq <= 440) then
		igc = igf/ig
		adamp filter2 asig, 1, 1, 0.6502*igc, -0.3412
	endif
		xout adamp
endop

; string-tuning allpass filter (Hρ(z))
opcode Tuning,a,aii
	asig,ifreq,idlts xin
	; fractional delay
	idltf = sr/ifreq-(idlts+.5)
	; allpass tuning filter coefficient
	icoe1 = (1-idltf)/(1+idltf)
	atuning filter2 asig, 2, 1, icoe1, 1, icoe1
		xout atuning
endop

; string-stiffnesss allpass filter (Hs(z))
opcode Stiffness,a,ai
	asig,ifreq xin
	; just noticeable coefficient of inharmonicity of stringed instrument
	; iB = exp(2.54*log(ifreq)-24.6)
	; inharmonicity coefficient equation: π^3 * Q * d^4 / 64 * l^2 * Ts
	; approximate Young's modulus for different materials: steel A36 200 Gpa/29 Mpsi, Nylon 66 2.93 Gpa/0.425 Mpsi
	; diameters of string: steel string (79.5μm), nylon string (94.67μm, 101.0μm, 120.67μm)
	; length of string: 72.5 cm, 28.5 inch
	il = 28.5
	
	if (ifreq > 220) then ; higher than D3
		; polynomial coefficients
		ik1 = -0.0026580
		ik2 = -0.014811
		ik3 = -2.9018
		; straight line coefficients
		iC1 = 0.071089
		iC2 = 2.1074
		if (ifreq >= 440) then ; A3
			iQ = 29
			id = 0.00313
			igauge = 0.00001085
		elseif (ifreq < 440) && (ifreq > 220) then ; E3, D3
			iQ = 0.425
			id = 0.00373
			igauge = 0.0002826
		endif
	elseif (ifreq <= 220) then ; A2
		; polynomial coefficients
		ik1 = -0.00050469
		ik2 = -0.0064264
		ik3 = -2.8743
		; straight line coefficients
		iC1 = 0.069618
		iC2 = 2.0427
		
		iQ = 0.425
		id = 0.00475
		igauge = 0.0002826
	endif
	
	; string tension: T = (f * 2 * L) ² * μ / g
	ig = 386.08858
	iT = ((ifreq*2*il)^2*igauge)/ig
	; inharmonicity coefficient B
	iB = ($M_PI^3*iQ*id^4)/(64*il^2*iT)

	; logarithmic representation of the desired fundamental frequency
	; 12√2 ≈ 1.059, log(1.059)27.5 ≈ 57.813, log(1.059)1.059 = 1
	; ikey ≈ log(1.059)ifreq - 57.813
	; log(a)b = log(c)b/log(c)a
	ikey = log(ifreq)/log(1.059)-57.813

	ikdB = $M_E^(ik1*(log10(iB)^2)+ik2*(log10(iB))+ik3)
	icdB = $M_E^(iC1*(log10(iB))+iC2)
	iD   = $M_E^(icdB-ikey*ikdB)
	icoe2 = (1-iD)/(1+iD)
	
	if (ifreq <= 220) then
		astiff filter2 asig, 2, 1, icoe2, 1, icoe2 ; using 4 cascaded filters for low frequencies
		astiff filter2 astiff, 2, 1, icoe2, 1, icoe2
		astiff filter2 astiff, 2, 1, icoe2, 1, icoe2
		astiff filter2 astiff, 2, 1, icoe2, 1, icoe2
	elseif (ifreq > 220) then
		astiff filter2 asig, 2, 1, icoe2, 1, icoe2 ; using a single filter for high frequencies
	endif
		xout astiff
endop

; body filter (Hb(z))
opcode Body,a,a
	asig xin
	; 4 cascaded body filters
	; low-shelf
	afilt1 biquad asig, 0.2485, -0.4937, 0.2453, 1, -1.9747, 0.9755
	; peak-notch
	afilt2 biquad afilt1, 0.5888, -0.4687, -0.1190, 1, -1.8746, 0.8794
	; peak-notch
	afilt3 biquad afilt2, 0.7701, -0.1817, -0.4351, 1, -0.7269, 0.3400
	; high-shelf
	afilt4 biquad afilt3, 0.1753, -0.1708, 0.0743, 1, -1.1763, 0.4913
		xout afilt4
endop

; waveguide pipa
opcode WaveguidePipa,a,iiiiii
	setksmps 1
	ifreq,ipluck,iamp,idlt,idlts,iatt xin
	
	kcount init idlts
	awgout init 0

	if kcount < 0 goto continue
	
	; excitation signal
	initialise:
	knoise1 oscil1i 0, 1, ftlen(giPipa)/sr, giPipa
	anoise1 upsamp knoise1
	knoise2 oscil1i 0, 1, ftlen(giIr)/sr, giIr
	anoise2 upsamp knoise2

	; pick direction lowpass filter (Hp(z))
	anoise1 butterlp anoise1, iamp*iamp*sr/2
	anoise2 butterlp anoise2, iamp*iamp*sr/2

	; pick position comb filter (Hβ(z))
	acomb1 delay anoise1, ipluck*ifreq
	acomb2 delay anoise2, ipluck*ifreq
	anoize1 = anoise1-acomb1
	anoize2 = anoise2-acomb2
	anoize = anoize1+anoize2*.45

	; delay line
	continue:
	adel delayr idlt
	ainput = anoize+adel

	; string model, 3 filters
	adamp Damping ainput, ifreq
	astiff Stiffness adamp, ifreq
	atuning Tuning astiff, ifreq, idlts
	
	awgout = iatt*atuning
	
		delayw awgout
	
	anoize = 0
	kcount -= 1

	xout awgout
endop

gaRvbL, gaRvbR init 0

turnon 99

	instr 1
; Start clock #1.
clockon 1
; fundamental frequency                                                                                                  
ifreq cpsmidi
iamp ampmidi 1

ifreq += 7

; attenuation gain
iatt  = 0.996

; pluck point (0-1)
ipluck = .5*(1.65-iamp)

; add some release
krel linsegr 1, 10, 1, .04 ,0
kgain = .9
kverb = .6

; delay time in samps
idlts = int(sr/ifreq-.5)
; delay time in sec
idlt = idlts/sr

awgout WaveguidePipa ifreq,ipluck,iamp,idlt,idlts,iatt
awgout dcblock2 awgout
; extra body filter
abody Body awgout
; resonant filter to add color
aout reson abody, 3000, 900

aout *= iamp*kgain*krel

vincr gaRvbL, aout*kverb
vincr gaRvbR, aout*kverb

	outs aout, aout
	
; Stop clock #1.
clockoff 1
; Print the time accumulated in clock #1.
i1 readclock 1
print i1
  
endin

; Reverb
instr 99
denorm gaRvbL, gaRvbR
kfblvl = 0.7
kfco = 20000
kdepth = 0.6
aL, aR reverbsc gaRvbL, gaRvbR, kfblvl, kfco, sr, i(kdepth), 1
	outs aL, aR
clear gaRvbL,gaRvbR
endin

</CsInstruments>
<CsScore>
; pipa range (A2-E6), freq 110-1318.51, midi 25-68(half is 46)
f0 z
</CsScore>
</CsoundSynthesizer>
