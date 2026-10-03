<CsoundSynthesizer>
<CsOptions>
--limiter=0.9
</CsOptions>
<CsInstruments>
sr			=		44100
kr			=		441
ksmps		=		100
nchnls		=		1

	instr 1
inote		=		cpspch( p4)
ifc			=		p5
ifm			=		p6
id			=		p7*ifm
iamp		=		p8
km			oscil	id,1/p3,p9
kc			oscil	iamp,1/p3,p10
am			oscil	km,ifm,1
ac			oscil	kc,(ifc+am),1
			out		ac
endin
</CsInstruments>
<CsScore>
f1	0	1024	10	1
f2	0	1024	5	1	1000	.01
f3	0	1024	8	.8	50	1	100	.7	824	0
f4	0	512	7	1	100	0
f5	0	1024	7	0	100	1	124	.7	600	.7	100	0
f6	0	1024	7	0	100	1	824	1	100	0
; BELL:     8.00  200 280 10 10000 2 2
; WOOD:     8.00   80  55 25     3 4
; BRASS:    8.00  440 440  5     5 5
; CLARINET: 8.00  900 800  2-4   6 6
e
</CsScore>
</CsoundSynthesizer>
