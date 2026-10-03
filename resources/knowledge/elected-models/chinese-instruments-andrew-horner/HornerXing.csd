<CsoundSynthesizer>
<CsInstruments>
; Xing	
; small Chinese bell struck with a metal rod
; coded by Andrew Horner
; Journal Audio Engineering Society, Vol.45, No.3, 1997 March
;---------------------------------------------------------------------
sr	=	44100
kr	=	44100
ksmps	=	1

;---------------------------------------------------------------------

instr 1

; p4 pitch in octave.pch
; original pitch	= A6
; range		= C6 - C7
; extended range	= F4 - C7

idur	=	p3
ifreq	=	cpspch(p4)
iamp	=	p5
inorm	=	32310

aamp1 	linseg	0,.001,5200,.001,800,.001,3000,.0025,1100,.002,2800,.0015,1500,.001,2100,.011,1600,.03,1400,.95,700,1,320,1,180,1,90,1,40,1,20,1,12,1,6,1,3,1,0,1,0
kdevamp1	linseg	0,.05,.3,idur-.05,0
kdev1 	oscil 	kdevamp1, 6.7,1,.8
amp1 	=	aamp1*(1+kdev1)

aamp2 	linseg	0,.0009,22000,.0005,7300,.0009,11000,.0004,5500,.0006,15000,.0004,5500,.0008,2200,.055,7300,.02,8500,.38,5000,.5,300,.5,73,.5,5.,5,0,1,1
kdevamp2	linseg	0,.12,.5,idur-.12,0
kdev2 	oscil 	kdevamp2,10.5,1,0
amp2	=	aamp2*(1+kdev2)

aamp3 	linseg	0,.001,3000,.001,1000,.0017,12000,.0013,3700,.001,12500,.0018,3000,.0012,1200,.001,1400,.0017,6000,.0023,200,.001,3000,.001,1200,.0015,8000,.001,1800,.0015,6000,.08,1200,.2,200,.2,40,.2,10,.4,0,1,0
kdevamp3	linseg	0,.02,.8,idur-.02,0
kdev3 	oscil  	kdevamp3,70,1,0
amp3	=	aamp3*(1+kdev3)

awt1  	oscili	amp1,ifreq,1
awt2   	oscili	amp2,2.7*ifreq, 1
awt3  	oscili	amp3,4.95*ifreq, 1
asig	=	awt1+awt2+awt3
krel  	linen  	1,0,idur,.06
asig	=	asig*krel*(iamp/inorm)

	out	asig

endin
</CsInstruments>
; ==============================================
<CsScore>

f1	0	8192	-10	1

i1	0	10	10.09	30000
i1	5	10	9.10	
e
</CsScore>
</CsoundSynthesizer>
