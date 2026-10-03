<CsoundSynthesizer>
<CsOptions>
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 1
nchnls = 2
0dbfs = 1

		seed	127

giSine	ftgen	0, 0, 8192, 10, 1
gaRevL	init 0
gaRevR	init 0

gkMetro init 0
gkCtr	init 0
gkLineA	init 0
gkLineB	init 0
gkLineC	init 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

instr gControl

gkMetro		metro		7
if (gkMetro == 1) then
	gkCtr = gkCtr + 1
endif

ih = p3 * 0.5
iq = p3 * 0.25
ie = p3 * 0.125

gkLineA		linseg		1, ie, 0, iq, 1, ie, 0, ih, 1
gkLineB		linseg		1, iq, 0, iq, 1, iq, 0, iq, 1
gkLineC		linseg		0, ie, 1, ie, 0, ie, 1, ie, 0, ie, 1, ie, 0, ie, 1, ie, 0

endin

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

instr SourceA

kdiv		oscil		2, 0.2, giSine, 0.2
kdiv		=			int(kdiv + 5) - int(gkLineC * 3)
ktrig		init		0

if ((gkCtr % kdiv == 0) && (gkMetro == 1)) then
	ktrig = 1
else
	ktrig = 0
endif

schedkwhen	ktrig, 0, 12, 11, 0, 0.2 + (0.2 * gkLineB), 100, 0.5, 0.7

endin

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

instr SourceB

kdiv		oscil		2, 0.17, giSine, 0.7
kdiv		=			int(kdiv + 4) + int(gkLineC * 3)
ktrig		init		0

if ((gkCtr % kdiv == 0) && (gkMetro == 1)) then
	ktrig = 1
else
	ktrig = 0
endif

schedkwhen	ktrig, 0, 12, 12, 0, 0.2, 200, 0.3, 0.4, 1, 1, 1.2

endin

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

instr SourceC

kdiv		oscil		1.5, 0.143, giSine
kdiv		=			int(kdiv + 3) + int(gkLineC * 3)
ktrig		init		0

if ((gkCtr % kdiv == 0) && (gkMetro == 1)) then
	ktrig = 1
else
	ktrig = 0
endif

schedkwhen	ktrig, 0, 12, 12, 0, 0.2, 300, 0.05, 0.1, 1, 3, 0.7

endin

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

instr SourceD

kdiv		oscil		2.5, 0.23, giSine
kdiv		=			int(kdiv + 4) + int(gkLineC * 3)
ktrig		init		0

if ((gkCtr % kdiv == 0) && (gkMetro == 1)) then
	ktrig = 1
else
	ktrig = 0
endif

schedkwhen	ktrig, 0, 12, 12, 0, 0.2, 400, 0.7, 0.4, 2, 1, 0.4

endin

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

instr SourceE

kdiv		oscil		2, 0.09, giSine
kdiv		=			int(kdiv + 5) - int(gkLineC * 3)
ktrig		init		0

if ((gkCtr % kdiv == 0) && (gkMetro == 1)) then
	ktrig = 1
else
	ktrig = 0
endif

schedkwhen	ktrig, 0, 12, 11, 0, 0.2, 500, 0.95, 0.1

endin

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

instr 11		; a sine tone generator

iLineB = i(gkLineB)
ibp1 = 0.3 + (iLineB * 0.4)
ibp2 = 0.2 + (iLineB * 0.1)
ibp3 = 0.1 + (iLineB * 0.04)

irand		random	0, 1
if (irand > ibp1) then
	ifreq_offset = 0
elseif (irand > ibp2) then
	ifreq_offset = 150
elseif (irand > ibp3) then
	ifreq_offset = 225
else
	ifreq_offset = 300
endif

iamprand	random	0.11, 0.23

iLineA = i(gkLineA)
iatk = 0.002 + (0.1 - (0.1 * iLineA))

kline		linsegr	0, iatk, iamprand, p3, iamprand * 0.25, p6, 0
asig		oscil		kline, p4 + ifreq_offset, giSine
aL, aR	pan2		asig, p5

gaRevL = gaRevL + aL
gaRevR = gaRevR + aR
		outs		aL, aR

endin

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

instr 12		; a more crisp tone generator

irand		random	0, 1
if (irand > 0.5) then
	ifreq_offset = 0
elseif (irand > 0.3) then
	ifreq_offset = 150
elseif (irand > 0.1) then
	ifreq_offset = 225
else
	ifreq_offset = 300
endif

iamprand	random	0.07, 0.17
iamp = iamprand * p9 * 1.1
indexrand	random	0.2, 0.3

iLineA = i(gkLineA)
iatk = 0.002 + (0.02 - (0.02 * iLineA))

indexstart	=		indexrand + (iLineA * 0.5)
indexend	=		indexstart * 0.3
kindex		line	indexrand, p3, indexend

kline		linsegr	0, iatk, iamp, p3, iamp * 0.25, p6, 0
asig		foscil		kline, p4 + ifreq_offset, p7, p8, kindex, giSine
aL, aR	pan2		asig, p5

gaRevL = gaRevL + (aL * (gkLineB + 1))
gaRevR = gaRevR + (aR * (gkLineB + 1))
		outs		aL, aR

endin

instr Reverb

iamp = 0.6
inlevel = 0.4
isize = 0.75
icutoff = 2000
aoutL, aoutR	reverbsc	gaRevL * inlevel, gaRevR * inlevel, isize, icutoff

gaRevL = 0
gaRevR = 0

			outs	aoutL * iamp, aoutR * iamp

endin

</CsInstruments>
<CsScore>

i "gControl"	0 121
i "SourceA"		0 120
i "SourceB"		0 120
i "SourceC"		0 120
i "SourceD"		0 120
i "SourceE"		0 120
i "Reverb"		0 123

</CsScore>
</CsoundSynthesizer>
