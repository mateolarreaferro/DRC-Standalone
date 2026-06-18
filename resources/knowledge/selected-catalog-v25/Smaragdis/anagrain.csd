<CsoundSynthesizer>
<CsOptions>
</CsOptions>
<CsInstruments>
sr		=		44100
kr		=		4410
ksmps	=		10
nchnls	=		1		
		
		instr 1
		
idur		=		1 / 1.45
a1		grain	30000, idur, 15, 0, idur/2,1, 1, 2, 1
		out		a1
		
		endin

</CsInstruments>
<CsScore>
f1  0  32768   1  16  .01  1  1

f2  0   1024  20   2

i1  0  4
</CsScore>
</CsoundSynthesizer>
