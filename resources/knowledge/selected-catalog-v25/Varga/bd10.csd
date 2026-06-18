<CsoundSynthesizer>
<CsOptions>
</CsOptions>
<CsInstruments>
sr	=  44100
kr	=  22050
ksmps	=  2
nchnls	=  1

	seed 0

#define MIDI2CPS(xmidi) # (440.0*exp(log(2.0)*(($xmidi)-69.0)/12.0)) #
#define CPS2MIDI(xcps)  # ((log(($xcps)/440.0)/log(2.0))*12.0+69.0) #

gax0	init 0

	instr 1

/* ------------------------------------------------------------------------- */

ivol	table 0,64	/* volume					*/
ibpm	table 1,64	/* tempo					*/

irel	table 2,64	/* release time					*/

istrtf1	table 3,64	/* start frequency 1				*/
ifdec1	table 4,64	/* freq. decay speed 1				*/
istrtf2	table 5,64	/* start frequency 2				*/
ifdec2	table 6,64	/* freq. decay speed 2				*/

insmix	table 7,64	/* noise mix					*/

iHP1f	table 8,64	/* HP filter 1 frequency / osc. freq.		*/
iBP1f	table 9,64	/* BP filter 1 frequency / osc. freq.		*/
iBP1b	table 10,64	/* BP filter 1 bandwidth / osc. freq.		*/

iHP2f	table 11,64	/* HP filter 2 frequency / osc. freq.		*/
iHP2m	table 12,64	/* HP filter 2 mix				*/
iHP3f	table 13,64	/* HP filter 3 frequency / osc. freq.		*/
iHP3m	table 14,64	/* HP filter 3 mix				*/

iHPxf	table 15,64	/* output HP filter frequency / note frequency	*/
iHPxr	table 16,64	/* output HP filter resonance			*/

iLPf1	table 17,64	/* output LP filter frequency 1 / osc. freq.	*/
iLPd1	table 18,64	/* output LP filter frequency 1 decay speed	*/
iLPf2	table 19,64	/* output LP filter frequency 2 / osc. freq.	*/
iLPd2	table 20,64	/* output LP filter frequency 2 decay speed	*/

iAM1s	table 21,64	/* amp. envelope 1 start value			*/
iAM1d	table 22,64	/* amp. envelope 1 decay speed			*/
iAM2s	table 23,64	/* amp. envelope 2 start value			*/
iAM2d	table 24,64	/* amp. envelope 2 decay speed			*/

/* ------------------------------------------------------------------------- */

ibtime	=  60/ibpm

p3	=  p3+irel+0.05

imkey	=  p4
imvel	=  p5

icps	=  $MIDI2CPS(imkey)
iamp	=  (0.0039+imvel*imvel/16192)*ivol
kamp	linseg 1,p3-(irel+0.05),1,irel,0,0.05,0

k_	port 1,ibtime/ifdec1,istrtf1		/* calculate base frequency */
k__	port 1,ibtime/ifdec2,istrtf2
kcps	=  icps*k_*k__

knumh	=  sr/(2*kcps)			/* oscillator */
a1	buzz sr/(10*3.14159265), kcps, knumh, 256, 0
a2	buzz sr/(10*3.14159265), kcps, knumh, 256, 0.5
a1	tone a1-a2, 10
a0	=  a1					/* a0 = osc. signal */

a_	unirand 2				/* noise generator */
a_	tone a_-1,kcps
a0	=  a0+a_*insmix

a1	=  a0	/* save osc. output */

a0	butterhp a0,iHP1f*kcps			/* HP filter 1 */

a0	butterbp a0,iBP1f*kcps,iBP1b*kcps	/* BP filter 1 */

a_	butterhp a1,iHP2f*kcps			/* HP filter 2 and 3 */
a__	butterhp a1,iHP3f*kcps
a0	=  a0+a_*iHP2m+a__*iHP3m

a0	butterhp a0,iHPxf*icps				/* output HP filter */
a0	pareq a0,iHPxf*icps,iHPxr*1.4142,iHPxr,0

k_	port 0,ibtime/iLPd1,iLPf1			/* output LP filter */
k__	port 0,ibtime/iLPd2,iLPf2
a0	butterlp a0,kcps*(k_+k__)

k_	expseg 1,ibtime/iAM1d,0.5			/* amp. envelopes */
k__	expseg 1,ibtime/iAM2d,0.5
k_	=  (1-k_)*(1-iAM1s)+iAM1s
k__	=  (1-k__)*(1-iAM2s)+iAM2s
a0	=  a0*k_*k__

gax0	=  gax0+(a0*iamp*kamp)

	endin

	instr 90

/* ----------------------- compressor parameters --------------------------- */

iamp	table 25,64	/* output volume				*/
iclpl	table 26,64	/* ouput clip level				*/
imxlvl	table 27,64	/* threshold level				*/
icomp1	table 28,64	/* compression ratio below thr. level		*/
icomp2	table 29,64	/* compression ratio above thr. level		*/
idel1	table 30,64	/* delay time in sec.				*/
iatt	table 31,64	/* envelope attack speed			*/
idec	table 32,64	/* envelope decay speed				*/
ifrq1	table 33,64	/* lowpass filter freq.				*/

/* ------------------------------------------------------------------------- */

icomp1	=  icomp1-1
icomp2	=  icomp2-1
klvl	init 0

a1	=  gax0
ad1	delay a1,idel1
gax0	=  0

atmp	=  abs(a1)				/* klvl = signal level */
ktmp	downsamp atmp
atmp	tone atmp,(ktmp>klvl ? iatt:idec)
atmp	butterlp atmp,ifrq1
klvl	downsamp atmp

ktmp	=  klvl/imxlvl
ktmp	=  (ktmp<1 ? exp(log(ktmp)*icomp1):exp(log(ktmp)*icomp2))

a0	=  (ad1*ktmp*iamp)
a0	limit a0,-iclpl,iclpl
a0	butterlp a0,(sr*0.48)

	out a0

	endin



</CsInstruments>
<CsScore>

t 0 140.00	/* tempo */

i 90	0.0000	34.000		/* output instrument */

#define Rhytm1(xstrt) #

i 1	[$xstrt+0.0000]		0.4500	31	120
i 1	[$xstrt+0.9900]		0.4500	31	116
i 1	[$xstrt+1.9900]		0.4500	31	127
i 1	[$xstrt+3.0000]		0.4500	31	116
i 1	[$xstrt+4.0000]		0.4500	31	120
i 1	[$xstrt+4.9900]		0.4500	31	116
i 1	[$xstrt+5.9900]		0.4500	31	118
i 1	[$xstrt+7.0000]		0.4500	31	116

#

$Rhytm1(0)
$Rhytm1(8)
$Rhytm1(16)
$Rhytm1(24)

/* ------------------------------------------------------------------------- */

f 64 0 64 -2	0.7		/* volume				*/
		140		/* tempo				*/

		0.05		/* release time				*/

		5.3333		/* start frequency 1			*/
		16		/* freq. decay speed 1			*/
		0.5		/* start frequency 2			*/
		128		/* freq. decay speed 2			*/

		4.0		/* noise mix				*/

		0.25		/* HP filter 1 frequency / osc. freq.	*/
		1.0		/* BP filter 1 frequency / osc. freq.	*/
		1.0		/* BP filter 1 bandwidth / osc. freq.	*/

		2.0		/* HP filter 2 frequency / osc. freq.	*/
		0.7		/* HP filter 2 mix			*/
		8.0		/* HP filter 3 frequency / osc. freq.	*/
		-2.0		/* HP filter 3 mix			*/

		1.333		/* output HP filter freq. / note freq.	*/
		2.0		/* output HP filter resonance		*/

		12.0		/* output LP filter frq. 1 / osc. freq.	*/
		8		/* output LP filter frq. 1 decay speed	*/
		4.0		/* output LP filter frq. 2 / osc. freq.	*/
		8		/* output LP filter frq. 2 decay speed	*/

		16.0		/* amp. envelope 1 start value		*/
		256		/* amp. envelope 1 decay speed		*/
		0.25		/* amp. envelope 2 start value		*/
		4		/* amp. envelope 2 decay speed		*/

/* ---- compressor parameters ---- */

		30000		/* output volume			*/
		30000		/* output clip level			*/
		1.0		/* threshold level			*/
		1.0		/* compression ratio below thr. level	*/
		0.0		/* compression ratio above thr. level	*/
		0.0002		/* delay time				*/
		5000		/* envelope LP filter 1 freq. (attack)	*/
		500		/* envelope LP filter 1 freq. (decay)	*/
		2000		/* envelope LP filter 2 frequency (Hz)	*/

/* ------------------------------------------------------------------------- */

f 256 0 262144 10 1

e	/* end of score */


</CsScore>
</CsoundSynthesizer>
