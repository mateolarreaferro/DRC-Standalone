<CsoundSynthesizer>
<CsOptions>
</CsOptions>
<CsInstruments>

;***************** Dan Gutwein - WOOD FLUTE ****************
; Based on Hans Mikelson's 1/22/97 physical modeling code  *
; which was based on Perry Cook's Slide Flute              *
;***********************************************************

ksmps =  10
nchnls = 2


instr 2
; iamp is overall volume of the note-event
; krelamp is relative volume needed to produce equal volumes for each overblow segment of the overall note-event
; kgenamp is the expressive control over krelamp within the note-event

  aflute1 init 0
  idur = p3
  iamp = p4*64 ;(127*64 = 8128)
  ifreq    = cpspch(p5+2)
  ibthatk = p7
  ipan = .5
  ifeedbk1= .4
  ifeedbk2= .4
  ;ifreq and ibreath are adjusted by linsegs below
  
  ; Copy Overblow values for each pt. in linseg into variables
  ; from tables 10-13
  iOB1 table 	p40, 10  
  iOB2 table	p41, 10
  iOB3 table    p42, 10
  iOB4 table    p43, 10
  iOB5 table    p44, 10
  iOB6 table    p45, 10
  iOB7 table    p46, 10
  iOB8 table    p44, 10
  iOB9 table    p48, 10
  iOB10 table    p49, 10
  
  iVol1 table    p40, 11
  iVol2 table    p41, 11
  iVol3 table    p42, 11
  iVol4 table    p43, 11
  iVol5 table    p44, 11
  iVol6 table    p45, 11
  iVol7 table    p46, 11
  iVol8 table    p47, 11
  iVol9 table    p48, 11
  iVol10 table    p49, 11

  iBth1  table    p40, 12
  iBth2  table    p41, 12
  iBth3  table    p42, 12
  iBth4  table    p43, 12
  iBth5  table    p44, 12
  iBth6  table    p45, 12
  iBth7  table    p46, 12
  iBth8  table    p47, 12
  iBth9  table    p48, 12
  iBth10 table    p49, 12
  
  iAir1  table    p40, 13
  iAir2  table    p41, 13
  iAir3  table    p42, 13
  iAir4  table    p43, 13
  iAir5  table    p44, 13
  iAir6  table    p45, 13
  iAir7  table    p46, 13
  iAir8  table    p47, 13
  iAir9  table    p48, 13
  iAir10 table    p49, 13    	
 
;Convert Additive Notation of durations to % of idur 
;to be used in linseg below
	idur1 = p80 ; LITERAL SECONDS
	isubdiv = (idur-idur1)/(p81+p82+p83+p84+p85+p86+p87+p88) ; The rest are proportional
	idur2 = isubdiv*p81 
	idur3 = isubdiv*p81
	idur4 = isubdiv*p83
	idur5 = isubdiv*p84
	idur6 = isubdiv*p85
	idur7 = isubdiv*p86
	idur8 = isubdiv*p87
	idur9 = isubdiv*p88 
	
; EXPRESSION CONTROL - All linseg time-varying parameters  
  kvibamp    linseg p10 , idur1, p11, idur2, p12, idur3, p13, idur4, p14, idur5, p15, idur6, p16, idur7, p17, idur8, p18, idur9, p19 
  kvibspd    linseg p20 , idur1, p21, idur2, p22, idur3, p23, idur4, p24, idur5, p25, idur6, p26, idur7, p27, idur8, p28, idur9, p29     
  kpan       linseg p30 , idur1, p31, idur2, p32, idur3, p33, idur4, p34, idur5, p35, idur6, p36, idur7, p37, idur8, p38, idur9, p39     
  koverblow  linseg iOB1 , idur1, iOB2, idur2, iOB3, idur3, iOB4, idur4, iOB5, idur5, iOB6, idur6, iOB7, idur7, iOB8, idur8, iOB9, idur9, iOB10 
  kpressure  linseg iAir1, idur1, iAir2, idur2, iAir3, idur3, iAir4, idur4, iAir5, idur5, iAir6, idur6, iAir7, idur7, iAir8, idur8, iAir9, idur9, iAir10 
  krelbth    linseg iBth1*ibthatk , idur1, iBth2, idur2, iBth3, idur3, iBth4, idur4, iBth5, idur5, iBth6, idur6, iBth7, idur7, iBth8, idur8, iBth9, idur9, iBth10 
  krelamp    linseg 0,idur1, iVol2, idur2, iVol3, idur3, iVol4, idur4, iVol5, idur5, iVol6, idur6, iVol7, idur7, iVol8, idur8, iVol9, idur9, 0
  kgenamp    linseg p50,idur1, p51, idur2, p52, idur3, p53, idur4, p54, idur5, p55, idur6, p56, idur7, p57, idur8, p58, idur9, p59
  kpchoffset linseg p60, idur1, p61, idur2, p62, idur3, p63, idur4, p64, idur5, p65, idur6, p66, idur7, p67, idur8, p68, idur9, p69
  kbthpct    linseg p70, idur1, p71, idur2, p72, idur3, p73, idur4, p74, idur5, p75, idur6, p76, idur7, p77, idur8, p78, idur9, p79
  
; Control the i-values
  ibreath = (p6*.01)
  
; The values must be approximately -1 to 1 or the cubic will blow up.
  aflow1 rand kpressure
  kpchvibr oscil kvibamp*.1, kvibspd, 3
  kbthvibr oscil kvibamp*.01, kvibspd, 3
  kbreath = ((ibreath*krelbth)*kbthpct)+kbthvibr; ibreath = overall ref. volume,  krelbth = bthvol. from table adjusted for overblows
                                                   ; kbthpct = the expressive changes to ibreath via linseg
 
 ; Compute the audio sample 
  asum1 = kbreath*aflow1 + kpressure + kpchvibr
  asum2 = asum1 + aflute1*ifeedbk1
  afqc  = 1/(ifreq+kpchoffset) - asum1/20000 -9/sr + (ifreq+kpchoffset)/12000000 ; Get the Pitch
  atemp1 delayr 1/ifreq/2  ; Embouchure delay should be 1/2 the bore delay
  ax     deltapi afqc/koverblow ; - asum1/ifreq/10 + 1/1000
         delayw asum2
  apoly = ax - ax*ax*ax
  asum3 = apoly+aflute1*ifeedbk2
  
  ; Filter audio source sums
  aout01 tone asum3, 2000
  aout02 tone asum3, 2000

; Bore, the bore length determines pitch.  Shorter is higher pitch.
   atemp2   delayr 1/ifreq
   aflute1 deltapi afqc
           delayw aout01
  
  outs (aout01*(iamp*(kgenamp*krelamp)))*kpan, (aout02*(iamp*(kgenamp*krelamp)))*(1-kpan)

endin
</CsInstruments>
<CsScore>


;********************  WOOD FLUTE DEMO - PHYSICAL MODEL ****************
;        Dan Gutwein (2000) via Hans Mikelson via Perry Cook's slide flute



; Tables holding normalizing values for Overblow, Amp, Bth-vol, & Air-Pressure
; These produce "flat" responses from each "overblow" setting.  Expressive values that
; further modify these results are listed in the score p-fields 40 and higher. Air Pressure
; values should produce equal volumes for each overblow setting when genamp p40-49 are set at 1.
;
; OVERBLOW VARIABLE EFFECTS: assuming air-pressure = 1:  	
; 2           = pure-tone (fundamental)
; 2.5  - 2.76 = upper m2nd lip-roll
; 2.77 - 2.89 =       m2nd lip-roll & slight harmonic at m7th above lip-roll (Db -  B nat.)
; 2.9  - 3.9 =   "   M7th above fundamental (B nat.) - full and clear
; 4.0  - 7.00 =   "   oct.
; 4.97 - 5.00 =   "   #11th (with soft flat-9th below #11)	
; 7.01 - 7.5  =   "   12th (.486 is more complex - realistic)
; 7.50 - 8.0   =  "   oct + M7th 
; 9.0          =  "   2 oct.
; 9.5 - 10.00  =  "   2 oct. & M3rd  
;
f3 0 1024 10 1  
f10 0 16 -2     2    2.76  2.76   2.89   3.6       4     4.7    5    7.486  8      9    10;  Overblow values
f11 0 16 -2     1    .7     2      3      1.3     .8     2     2     5.5    4.5    13   15;  Relative Amp Values per overblow value
f12 0 16 -2     1    .4    .4     .15    .5       .6    .20   .2     .075   .1    .03  .03;  Breath vol. per  overblow value
f13 0 16 -2    .89   1     .91    .903   .85      .89   .89    .899  .933   .942   .970   1   ;  Air Pressure per overblow value

t 0 60 


;LONG SUSTAIN TONE
i2     0    5    700  5.09     5     15    0    0	; 4=amp, 5=pch 6=bth.vol., 7=bth.atk, 8-9 dummys
.0   .0     0    0     .1   .2   .3   .5   .3   .0	; 10-19 vibrato amp
0     0     0    0     1     2    3    4    2    1	; 20-29 vibrato speed
.5   .5    .5   .5    .5    .5   .5   .5   .5   .5	; 30-39 pan 
0     1     2    3     3    3     3    3    4    4  	; 40-49 = Table indexes: 0-11
0     .6   .3    .5   .6    .8   .7    .5  .3  0	; 50-59 = Gen Amp - mult. of rel. table values, all 1st produce equal volumes
0     0     0    0     0     0    0     0    0      0   ; 60-69 = Pitch offset in Hz
1    1     1    1      1     1    1     1     1     1   ; 70-79 = % of p6 (breath vol.)
   .4    1    1    1     8      1   1    4     8    	; 80-88 = seg. durs (1st p-field is literal time)
   
;SEVEN-TONE ASCENT:  (2+5) TWO SHORT FALSE STARTS
i2     6.5    .75    500  5.09     5     20    0    0	; 4=amp, 5=pch 6=bth.vol., 7=bth.atk, 8-9 dummys
.0   .0    .0   .0    .0    .0   .0   .0   .0   .0	; 10-19 vibrato amp
1     1     2    3     3     3    3    2    2    1	; 20-29 vibrato speed
.5   .5    .5   .5    .5    .5   .5   .5   .5   .5	; 30-39 pan 
2   2   2   2 2   3  3  3  3  3  	                ; 40-49 = Table indexes: 0-11
0     1      1     1    1     1    1    1   1    0      ; 50-59 = Gen Amp - mult. of rel. table values, all 1st produce equal volumes
0     0     0    0     0     0    0     0    0      0  ; 60-69 = Pitch offset in Hz
1    1     1    1      1     1    1     1     1     1  ; 70-79 = % of p6 (breath vol.)
   .2    1    1    1     1      1   1    1     4    	; 80-88 = seg. durs (1st p-field is literal time)
   

i2    7.3     .6    200  6.00     5     20    0    0		; 4=amp, 5=pch 6=bth.vol., 7=bth.atk, 8-9 dummys
.0   .0    .0   .0    .0    .0   .0   .0   .0   .0		; 10-19 vibrato amp
1     1     2    3     3     3    3    2    2    1		; 20-29 vibrato speed
.5   .5    .5   .5    .5    .5   .5   .5   .5   .5		; 30-39 pan 
0   0  0   0  0  0   0  0  0  0  				; 40-49 = Table indexes: 0-11
0     1     1     1    1     1    1    1   1    0		; 50-59 = Gen Amp - mult. of rel. table values, all 1st produce equal volumes
0     0     0    0     0     0    0     0    0      0  ; 60-69 = Pitch offset in Hz
1    1     1    1      1     1    1     1     1     1  ; 70-79 = % of p6 (breath vol.)
   .15   1    1    1     1      1   1    1     6    	; 80-88 = seg. durs (1st p-field is literal time)

;FIVE NOTE RISE
i2    7.9     .5    700  6.02     5     18    0    0		; 4=amp, 5=pch 6=bth.vol., 7=bth.atk, 8-9 dummys
.0   .0    .0   .0    .0    .0   .0   .0   .0   .0		; 10-19 vibrato amp
1     1     2    3     3     3    3    2    2    1		; 20-29 vibrato speed
.5   .5    .5   .5    .5    .5   .5   .5   .5   .5		; 30-39 pan 
1    1  1   1  1  1  1   1  1  1  			; 40-49 = Table indexes: 0-11
0     1.2   .8    .7   .6    .5   .4   .3  .2   0	; 50-59 = Gen Amp - mult. of rel. table values, all 1st produce equal volumes
0     0     0    0     0     0    0     0    0      0  	; 60-69 = Pitch offset in Hz
1    1     1    1      1     1    1     1     1     1  	; 70-79 = % of p6 (breath vol.)
   .1    1    1    1     1      1   1    1     2    	; 80-88 = seg. durs 

i2    8.4     .5    400  6.04     5     10    0    0	; 4=amp, 5=pch 6=bth.vol., 7=bth.atk, 8-9 dummys
.0   .0    .0   .0    .0    .0   .0   .0   .0   .0	; 10-19 vibrato amp
1     1     2    3     3     3    3    2    2    1	; 20-29 vibrato speed
.5   .5    .5   .5    .5    .5   .5   .5   .5   .5	; 30-39 pan 
2    2  2   2  2  2  2  2   2  2  			; 40-49 = Table indexes: 0-11
0     1     1     1    1     1    1    1   1    0	; 50-59 = Gen Amp - mult. of rel. table values, all 1st produce equal volumes
0     0     0    0     0     0    0     0    0      0   ; 60-69 = Pitch offset in Hz
1    1     1    1      1     1    1     1     1     1   ; 70-79 = % of p6 (breath vol.)
   .2    1    1    1     1      1   1    1     6    	; 80-88 = seg. durs 

i2    8.9     .333  600  6.05     5     18    0    0	; 4=amp, 5=pch 6=bth.vol., 7=bth.atk, 8-9 dummys
.0   .0    .0   .0    .0    .0   .0   .0   .0   .0	; 10-19 vibrato amp
1     1     2    3     3     3    3    2    2    1	; 20-29 vibrato speed
.5   .5    .5   .5    .5    .5   .5   .5   .5   .5	; 30-39 pan 
3    3  3   3  3  3  3  3  3   3  			; 40-49 = Table indexes: 0-11
0     1     1.5   1    1     1    1    1   1    0	; 50-59 = Gen Amp - mult. of rel. table values, all 1st produce equal volumes
0     0     0    0     0     0    0     0    0      0   ; 60-69 = Pitch offset in Hz
1    1     1    1      1     1    1     1     1     1   ; 70-79 = % of p6 (breath vol.)
   .10   1    1    1     1      1   1    1     6    	; 80-88 = seg. durs 


i2    9.13    .333  400  6.09     5     10    0    0	; 4=amp, 5=pch 6=bth.vol., 7=bth.atk, 8-9 dummys
.0   .0    .0   .0    .0    .0   .0   .0   .0   .0	; 10-19 vibrato amp
1     1     2    3     3     3    3    2    2    1	; 20-29 vibrato speed
.5   .5    .5   .5    .5    .5   .5   .5   .5   .5	; 30-39 pan 
4    4  4   4  4  4  4  4  4  4   			; 40-49 = Table indexes: 0-11
0     2     1.5   1    1     1    1    1   1    0	; 50-59 = Gen Amp - mult. of rel. table values, all 1st produce equal volumes
0     0     0    0     0     0    0     0    0      0  	; 60-69 = Pitch offset in Hz
1    1     1    1      1     1    1     1     1     1  	; 70-79 = % of p6 (breath vol.)
   .10   1    1    1     1      1   1    1     6    	; 80-88 = seg. durs 

i2    9.47    .40   600  6.11     5     18    0    0	; 4=amp, 5=pch 6=bth.vol., 7=bth.atk, 8-9 dummys
.0   .0    .0   .0    .0    .0   .0   .0   .0   .0	; 10-19 vibrato amp
1     1     2    3     3     3    3    2    2    1	; 20-29 vibrato speed
.5   .5    .5   .5    .5    .5   .5   .5   .5   .5	; 30-39 pan 
5    5  5   5  5  5  5  5  5   5  			; 40-49 = Table indexes: 0-11
0     2     1     1    1     1    1    1   1    0	; 50-59 = Gen Amp - mult. of rel. table values, all 1st produce equal volumes
0     0     0    0     0     0    0     0    0      0   ; 60-69 = Pitch offset in Hz
1    1     1    1      1     1    1     1     1     1   ; 70-79 = % of p6 (breath vol.)
   .10   1    1    1     1      1   1    1     6    	; 80-88 = seg. durs 

i2    9.88  5   750  6.11     2     40    0    0	; 4=amp, 5=pch 6=bth.vol., 7=bth.atk, 8-9 dummys
.0   .0    .1   .3    .4    .5   .5   .4   .4    0	; 10-19 vibrato amp
0     1     2    3     5     5    4    3    2    1	; 20-29 vibrato speed
.5   .5    .5   .5    .5    .5   .5   .5   .5   .5	; 30-39 pan 
6     6     6    6     6     6    6    6    6    6  	; 40-49 = Table indexes: 0-11
0     1.4   1     1    .5    .5   1    1    1    0	; 50-59 = Gen Amp - mult. of rel. table values, all 1st produce equal volumes
0     0     0    0     0     0    0     0    0      0   ; 60-69 = Pitch offset in Hz
1    1     1    1      1     1    1     1     1     1   ; 70-79 = % of p6 (breath vol.)
   .40   1    1    1     1      1   1    1     20   	; 80-88 = seg. durs 
   
;---- END OF SEGMENT:  insert 1 sec of silence
i2     +       1      0  6.00     5     30    0    0	; 4=amp, 5=pch 6=bth.vol., 7=bth.atk, 8-9 dummys
.0   .0    .0   .0    .0    .0   .0   .0   .0   .0	; 10-19 vibrato amp
1     1     2    3     3     3    3    2    2    1	; 20-29 vibrato speed
.5   .5    .5   .5    .5    .5   .5   .5   .5   .5	; 30-39 pan 
0   0  0   0  0  0   0  0  0  0  			; 40-49 = Table indexes: 0-11
0     1     1     1    1     1    1    1   1    0	; 50-59 = Gen Amp - mult. of rel. table values, all 1st produce equal volumes
0     0     0    0     0     0    0     0    0      0   ; 60-69 = Pitch offset in Hz
1    1     1    1      1     1    1     1     1     1   ; 70-79 = % of p6 (breath vol.)
   .1    1    1    1     1      1   1    1     4    	; 80-88 = seg. durs (1st p-field is literal time)
</CsScore>
</CsoundSynthesizer>
