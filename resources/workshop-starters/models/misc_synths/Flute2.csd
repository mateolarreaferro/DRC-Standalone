<CsoundSynthesizer>
<CsOptions>
--limiter=0.9
</CsOptions>
<CsInstruments>
;FLUTE
;Lee Zakian
;9/12/02 1:28:06 PM
 
;++++++++++

sr 		= 44100
kr 		= 441
ksmps 		= 100
nchnls 		= 2
zakinit   	30, 30

;++++++++++

	instr 2	;FLUTE      
idur    	=       	abs(p3)             	;Absolute value of Duration
ipch1   =       	cpspch(p6)  
ipch2   =       	cpspch(p5)  
kpch    	=       	ipch2
iport   	=       	0.03                	;Portamento 0-1 for slurred notes: 0.01 = clean slur, 0.9 = slow gliss
iatt    	=       	0.03                	;Attack (short) for single notes or 1st note of slur
idec    	=       	p10                 	;Decay 0-1 for diminuendo: 0.05 = slight decay, 0.9 = long decay
ivibd	=	p11		;Vibrato Depth 0-1
ivibs	=	p12		;Vibrato Speed 2-8 Hz
iout	=	p13		;To Processing or Mixer
irise   	=       	idur*p9             	;Peak Swell 0-1: 0.01 = sharp accent, 0.9 = crescendo
idovib 	=       	1           		;Vibrato except on short notes 
icut    	=       	(p5 > 9.11 ? 3500 : 2000)   	;Cut high partials
iamp    	=       	p4                  	;Tied note starts at amp ramp
i1      	=       	-1                  	;Tied note phase
i2      	=       	-1                  	;Vibrato phase
kdclk	linseg  	0, .001, 2, p3-.5, 2, .01, 1, .001, 0	;declick envelope
;================================================
ir      	tival               		;Tied note conditional Init block
        	tigoto  	tie 
i1      	=       	0                   	;Reset phase for 1st note
i2      	=       	0.25                	;Vibrato phase offset
iamp    	=       	0                   	;Set start amp
iatt    	=       	0.07                	;Longer Attack for 1st note of slur
;================================================
;TIE
;================================================
tie:            
iadjust 	=       	iatt+idec
if      	idur >= iadjust igoto doamp	;Adjust ramp duration on short notes, 10ms limit
iatt    	=       	(idur/2)-0.005
idec    	=       	iatt                	;Timespan can not be 0
iadjust 	=       	idur-0.01           	;Ensure ilen != 0 for linseg)
idovib 	=       	0           		;No vibrato on short notes
iport   	=       	0.007               	;Smooth Portamento on tied notes
;================================================
;AMPLITUDE RAMP (chiff, low pass filters)
;================================================
doamp:          
ilen    		=       	idur-iadjust	;Create amplitude amp
amp     		linseg  	iamp, iatt, p4, ilen, p4, idec, p7
if      	ir == 1 goto pitch  		;No chiff on tied notes
ichiff  		=       	p4/25               	;Chiff set to % of volume
ifac1   		=       	(p5 >9.01 ? 3.0 : 1.)  	;Balance chiff with register
ifac2   		=       	(p5 >9.01 ? 0.1 : 0.2)
aramp   	linseg  	0, 0.005, ichiff, 0.02, ichiff*0.5, 0.05, 0, 0, 0
anoise  	randi    aramp, amp
achiff1		reson	anoise, 2000, 400, 1, 1	;Fixed hifreq filters, wide bandwidths
achiff2		reson	anoise, 4000, 800, 1, 1
achiff3 	reson   	anoise, ipch2*2, 40, 0, 1 ;Pitched chiff filter, narrow bandwidth
achiff  		=       	(achiff1+achiff2)*ifac1+(achiff3*ifac2)
;================================================
;PITCH
;================================================
pitch:
if      	ir == 0 || 	p6 == p5 kgoto expr  	;Skip pitchramp on 1st note or tie
kpramp	linseg  	ipch1, iport, ipch2, idur-iport, ipch2
kpch  	=       	kpramp  
;================================================
;EXPRESSION (rise, fall, vibrato)
;================================================
expr:
irise   	=       	(p9>0.?irise:iatt) 	;Maximum accent shape
ifall   	=       	idur-irise  
p8	=       	((p8+p4)>0.?p8:-p4) 	;p4-p8 > or = 0
aslur   	linseg  	0, irise, p8, ifall, 0	;Make vibrato
if     	idovib == 0 goto play   	;No vibrato on short notes
avib    	oscili  	p11, p12, 2, 0.25	;Vibrato (f2) with phase offset
avib    	=       	avib+0.5    
aslur   	=       	aslur*avib  
;================================================
;PLAY
;================================================
play:
aamp    =       		amp+aslur
aflute	oscil3  		aamp, kpch, 1, i1
asig   	butterlp 	aflute, icut, 1	;Trim high note partials
   	zawm		asig+(achiff*0.15)*kdclk, iout
	endin       

	instr 93		;Reverb
iin		=	p4
iout		=	p5	;to mixer or write to disk
irvbtime	=	p6	;reverb in seconds
iwet		=	p7	;amount of  signal processed with reverb
idry		=	1-p7	;amount of signal not processed with reverb
ihfroll		=	p8	;low pass filter: high frequency rolloff
ihfdiff		=	p9	;high frequency diffusion
kdclk		linseg  	0, .2, 1, p3-.4, 1, .2, 0	;declick envelope
asig		zar	iin
aoutrev	nreverb	asig*iwet, p6, p9
aout		tone	aoutrev, p8
		zawm 	(aout+(asig*idry))*kdclk, iout	;to MIXER
	endin		

	instr 98		;2 in 2 out MIXER

;++CHANNEL 1
a1		zar	p4		;IN
igL1		init	p5*p6		;GAIN
igR1		init	p5*(1-p6)	;PAN
;=====
;++CHANNEL 2
a2		zar	p7		;IN
igL2		init	p8*p9		;GAIN
igR2		init	p8*(1-p9)	;PAN
;=====
aoutL		=	(igL1*a1)+(igL2*a2)
aoutR		=	(igR1*a1)+(igR2*a2)
		outs	aoutL, aoutR
		zacl	0, 30
	endin




</CsInstruments>
<CsScore>
;FLUTE
;Lee Zakian
;9/12/02 1:28:06 PM
 
;++++++++++

;Flute table
;GEN 10, fundamenal/partials
f1 	0 	4096 	10 	2  0.5  0.03  0.004  0.002  0.001  0.001

;Vibrato
f2  0   1024    10  1

;Tempo   	
t	0	45	8	30

;p1	p2	p3	p4	p5	p6	p7	p8	p9	p10	p11	p12	p13
;Instr   	Sta	Dur	Amp	Pitch	Pitch	Amp	Amp	Peak	Dim	Vibrato	Vibrato	OUT
;					From	To                                  		Depth	Speed
i2	0  	-0.48	10000	9.06	9.06	np4	14000	.3	.1	.5	4	1		
i2	+	-0.48	8000	9.03	pp5	np4	11000	.5	.	.	4	.		
i2	+	1.44	12000	9.10	9.10	0	16000	.03	.3	.65	5.5	.
i2	+	-0.48	11000	9.06	pp5	np4	15000	.3	.	.	4	.		
i2	+	-0.48	10000	9.03	pp5	np4	13000	.	.	.	4	.		
i2	+	0.48	10000	9.06	9.06	0	13000	.	.	.	4	.		
i2	+	-0.96	8000	10.02	pp5	np4	16000	.1	.	.	5.5	.		
i2	+	-1.92	11000	10.01	pp5	0	15000	.7	.5	.3	3	.

;REVERB
;instr	sta	dur	IN	OUT	rvbtime	wet	rolloff	diff
;p1	p2	p3	p4	p5	p6	p7	p8	p9
i93	0	8	1	2	2.5	.3	2500	.3

;MIXER	  	|CH 1			|CH 2         
;In/Gain/Pan        	i	g	p	i	g	p       
;p1	p2	p3	p4  	p5  	p6	p7  	p8  	p9  
;instr	sta 	dur    
i98	0    	8     	2    	.5    	.5   	2    	.5   	.5

</CsScore>

</CsoundSynthesizer>
<MacOptions>
Version: 3
Render: Real
Ask: Yes
Functions: Window
WindowBounds: 29 50 951 782
Options: -b64 -A -s -m7 -R 
</MacOptions>
<MacGUI>
ioView nobackground {65535, 65535, 65535}
ioListing {10, 10} {400, 500}
</MacGUI>
<bsbPanel>
 <label>Widgets</label>
 <objectName/>
 <x>100</x>
 <y>100</y>
 <width>320</width>
 <height>240</height>
 <visible>true</visible>
 <uuid/>
 <bgcolor mode="background">
  <r>240</r>
  <g>240</g>
  <b>240</b>
 </bgcolor>
</bsbPanel>
<bsbPresets>
</bsbPresets>
