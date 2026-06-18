<CsoundSynthesizer>

<CsOptions>

-odac -iadc -b1024 -B2048 -m0 -M0
;-iadc1

</CsOptions>

<CsInstruments>

	sr = 48000 
	ksmps = 128
	nchnls = 2	
	0dbfs = 32768


	maxalloc	1, 1
	prealloc	1, 1
	maxalloc	10, 4
	prealloc	10, 4

	maxalloc	302, 1
	prealloc	302, 1
	maxalloc	303, 1
	prealloc	303, 1
	maxalloc	304, 1
	prealloc	304, 1
	maxalloc	305, 1
	prealloc	305, 1
	maxalloc	311, 20
	prealloc	311, 20
	maxalloc	314, 20
	prealloc	314, 20
	maxalloc	331, 50
	prealloc	331, 50
	maxalloc	335, 16
	prealloc	335, 16
	maxalloc	336, 16
	prealloc	336, 16
	maxalloc	337, 16
	prealloc	337, 16

	maxalloc	350, 2
	prealloc	350, 2

	massign		1, 361		; pad/dualtheme control
	massign		2, 10		; midi control of Grain1
	massign		3, 9		; single trig, sample playback
	massign		4, 15		; drumloop presets
	massign		5, 16		; drumloop inc/dec
	massign		6, 4
	massign		7, 4
	massign		8, 4
	massign		9, 4
	massign		10, 4
	massign		11, 13		; KIK line generation, note on midi buttons, efx send routing notes
	massign		12, 4
	massign		13, 4
	massign		14, 4
	massign		15, 4
	massign		16, 4

	zakinit	24,10

	gkLastRec	init 1
	gactrlvol1	init 1
	gactrlvol2	init 1
	gidenorm	= 0.0000000000000001
	gkt5		init 0
	gkout_tim1	init 1
	gktrig		init 0
	gktrig2		init 0
	gktrig3		init 0
	gkbtpo_cps	init 1
	gitime_old	init	0
	gktemp		init 60
	gkbeatcps	init 1
	gkbeatcps2	init 1
	gkbeatcps3	init 1
	gktrig_phr	init 1
	gktrig_phr2	init 1
	gktrig_phr3	init 1
	gk_endflag	init 1
	gk_endflag2	init 1
	gk_endflag3	init 1
	gkbeats		init 4
	gktimesign1	init 201
	gknumevents	init 7
	gknumevents2	init 7
	gknumevents3	init 7	
	gkdrmoff	init 0
	gkptrnoff	init 0
	gkbend2midi	init 1
	gkctrl2midi	init 0
	gkveloc		init 1		; amp for Grain 1
	gk10active	init 0		; amp for Grain 1
	gk10voiceN	init 0		; voice (polyphony) counter for Grain1
	gkout_amp2	init 1		; velocity for R.Play module 1
	gkout_amp22	init 1		; velocity for R.Play module 2

	gkminpause1	init 0
	gkminpause2	init 0
	gkminpause3	init 0
	gkmaxpause1	init 4
	gkmaxpause2	init 4
	gkmaxpause3	init 4

	gks1bypas 	init 0		; bypass random selection of sounds, instr 312
	gks1fno		init 1		
	gks2bypas 	init 0		; bypass random selection of sounds, instr 314
	gks2fno		init 1		
;	gk_maxRMS1	init 0		; maximum rms value for each sound stored

	gktime304	init	0	; length of last stored sound, updated while writing audio
	gk304active	init	0	; for testing if instr 304 is active
	gkcount304	init 	0	; index number of last stored sound
	gk304off	init 	0	; turnoff trigger indicator, for release time envelope on recording

	gktime305	init	0	; length of last stored sound, updated while writing audio
	gk305active	init	0	; for testing if instr 304 is active
	gkcount305	init 	0	; index number of last stored sound
	gk305off	init 	0	; turnoff trigger indicator, for release time envelope on recording

	gkGrn1form_mc	init 1
	gk61oct_mc	init 0
	gk10cps		init 20
	gkRAGphs	init 0.1
	gkRAGdur	init 0.1
	gkPtrkTrig	init 0
	gk_efxroute	init 0		; routing of midi controls for efx sends, init to off
	gkDel1ManualTime init 1		; knob for manual sweep of delay time
	gkDel2ManualTime init 1		; knob for manual sweep of delay time

	gi_snc_delay	init 0.05	; sync delay, delays metro/drumloop to sync with live-recorded ftables (fade in time)
	giampdiv	init 1/32768	; 1/32768 calculated once for frequent lookup (instr 335, 336, 337)

	gactrlvol1	init 1
	gactrlvol2	init 1

;DualTheme
	giDTcpsindx1	init 0
	giDTcpsindx2	init 0
	giDTtablen  	init 32
	giDTwindx	init 0
	gkDTtime1	init 0
	gkDTtime2	init 0

; metro for updating VU meters etcetera
	gkupdate1	init 0


;****************************************************************
; ftables
;****************************************************************

iSigmRis	ftgen	130, 0, 8192, 19, 0.5, 1, 270, 1

	

;****************************************************************
; GUI widgets 
;****************************************************************

igfxknobsize	= 40

#define EfxSend(A'B'C'D'E'F'G'H'I'J'K'L) #
; arguments: Name, upper left X pos, upper left Y pos, init params (args D-L)
ihfxbox$A.		FLbox		"Effect Sends", 5, 1 , 11, 424, 17, $B., $C.
			FLlabel  	10, 1, 2, 0, 0, 0

i$A.fxknoby1	= $C. + 25
i$A.fxvaly1	= i$A.fxknoby1 + 55
i$A.fxknobx1	= $B.
i$A.fxknobx2	= i$A.fxknobx1 + 48
i$A.fxknobx3	= i$A.fxknobx2 + 48
i$A.fxknobx4	= i$A.fxknobx3 + 48
i$A.fxknobx5	= i$A.fxknobx4 + 48
i$A.fxknobx6	= i$A.fxknobx5 + 48
i$A.fxknobx7	= i$A.fxknobx6 + 48
i$A.fxknobx8	= i$A.fxknobx7 + 48
i$A.fxknobx9	= i$A.fxknobx8 + 48

ih$A._cleanV		FLvalue		" ", 40, 17, i$A.fxknobx1, i$A.fxvaly1
ih$A._rmV		FLvalue		" ", 40, 17, i$A.fxknobx2, i$A.fxvaly1
ih$A._fmV		FLvalue		" ", 40, 17, i$A.fxknobx3, i$A.fxvaly1
ih$A._filt1V		FLvalue		" ", 40, 17, i$A.fxknobx4, i$A.fxvaly1
ih$A._distV		FLvalue		" ", 40, 17, i$A.fxknobx5, i$A.fxvaly1
ih$A._filt2V		FLvalue		" ", 40, 17, i$A.fxknobx6, i$A.fxvaly1
ih$A._del1V		FLvalue		" ", 40, 17, i$A.fxknobx7, i$A.fxvaly1
ih$A._del2V		FLvalue		" ", 40, 17, i$A.fxknobx8, i$A.fxvaly1
ih$A._revbV		FLvalue		" ", 40, 17, i$A.fxknobx9, i$A.fxvaly1

gk$A._clean,ih$A._clean 	FLknob		"Dry ", 	    0, 1, 0, 1, ih$A._cleanV, igfxknobsize, i$A.fxknobx1, i$A.fxknoby1
gk$A._rm,ih$A._rm 	FLknob		"RingMod ", 	    0, 1, 0, 1, ih$A._rmV,    igfxknobsize, i$A.fxknobx2, i$A.fxknoby1
gk$A._fm,ih$A._fm 	FLknob		"FreqMod ", 	    0, 1, 0, 1, ih$A._fmV,    igfxknobsize, i$A.fxknobx3, i$A.fxknoby1
gk$A._filt1,ih$A._filt1	FLknob		"Filter1", 	    0, 1, 0, 1, ih$A._filt1V, igfxknobsize, i$A.fxknobx4, i$A.fxknoby1
gk$A._dist,ih$A._dist	FLknob		"Distortion", 	    0, 1, 0, 1, ih$A._distV,   igfxknobsize, i$A.fxknobx5, i$A.fxknoby1
gk$A._filt2,ih$A._filt2	FLknob		"Filter2", 	    0, 1, 0, 1, ih$A._filt2V, igfxknobsize, i$A.fxknobx6, i$A.fxknoby1
gk$A._del1,ih$A._del1	FLknob		"Delay1", 	    0, 1, 0, 1, ih$A._del1V,  igfxknobsize, i$A.fxknobx7, i$A.fxknoby1
gk$A._del2,ih$A._del2	FLknob		"Delay2", 	    0, 1, 0, 1, ih$A._del2V,  igfxknobsize, i$A.fxknobx8, i$A.fxknoby1
gk$A._revb,ih$A._revb 	FLknob		"Reverb1", 	    0, 1, 0, 1, ih$A._revbV,  igfxknobsize, i$A.fxknobx9, i$A.fxknoby1

			FLsetVal_i 	$D., 	ih$A._clean
			FLsetVal_i 	$E., 	ih$A._rm
			FLsetVal_i 	$F., 	ih$A._fm
			FLsetVal_i 	$G., 	ih$A._filt1
			FLsetVal_i 	$H., 	ih$A._dist
			FLsetVal_i 	$I., 	ih$A._filt2
			FLsetVal_i 	$J., 	ih$A._del1
			FLsetVal_i 	$K., 	ih$A._del2
			FLsetVal_i 	$L., 	ih$A._revb
#

;******************************************************************
		FLpanel         "DualTheme",480,300,50,100

iDTbtx1		= 20
iDTbty1		= 20

iDTvx1		= 150
iDTvy1		= 160
iDTvx2		= iDTvx1 + 50
iDTvx3		= iDTvx2 + 50
iDTvx4		= iDTvx3 + 50

iDTfx1		= 160
iDTfy1		= 20
iDTfx2		= iDTfx1 + 50
iDTfx3		= iDTfx2 + 50
iDTfx4		= iDTfx3 + 50

iDThv1		FLvalue		" ", 					40,  20, iDTvx1, iDTvy1
gkDTf1, iDThf1	FLslider	"slider_1", 0,    1, 0, 6, iDThv1, 	20, 120, iDTfx1, iDTfy1
iDThv2		FLvalue		" ", 					40,  20, iDTvx2, iDTvy1
gkDTf2, iDThf2	FLslider	"slider_2", 0,    1, 0, 6, iDThv2, 	20, 120, iDTfx2, iDTfy1
iDThv3		FLvalue		" ", 					40,  20, iDTvx3, iDTvy1
gkDTf3, iDThf3	FLslider	"slider_3", 0,    1, 0, 6, iDThv3, 	20, 120, iDTfx3, iDTfy1

		FLsetVal_i 	0.5, iDThf1
		FLsetVal_i 	0.5, iDThf2
		FLsetVal_i 	0.5, iDThf3

;****
;Volume, "On", and VU

ihbxDTmix		FLbox		"DT",	5, 1, 10,		 	 74, 130,  iDTbtx1,    iDTbty1
			FLsetAlign	2, ihbxDTmix
gkDTon, ihDTon		FLbutton	"On", 1, 0, 2, 				 42, 20,   iDTbtx1+9,  iDTbty1+4, -105, 0 
			FLsetAlign	1, ihDTon
ihvalDTamp		FLvalue		" ", 					 38,  15,  iDTbtx1+11, iDTbty1+110
gksDTamp,ihsDTamp	FLknob          " ", 	0, 2, 0, 1, ihvalDTamp,		 42, 	   iDTbtx1+9,  iDTbty1+63
gksDTampD,gihsDTampD	FLslider        " ", 	0, 30000, 0, 2 , -1,	 	 10, 121,  iDTbtx1+55, iDTbty1+4
			FLsetColor 	 80, 150, 50,  gihsDTampD
			FLsetColor2 	230, 50,  30,  gihsDTampD
			
			FLsetVal_i	1,	ihsDTamp

	$EfxSend.(DT'20'200'0.8'0'0'0'0'0'0'0.15'0.3)
;****

        	FLpanelEnd     
;******************************************************************

		FLpanel         "Noises", 480,300,10,10 	;***** start of container
gktWLN2,ihWLN2	FLbutton	"2", 1, 0, 2, 100, 30,  30,  50, -105 , 2, 0, -1
gktWLN3,ihWLN3	FLbutton	"3", 1, 0, 2, 100, 30,  30, 100, -105 , 2, 0, -1
gktWLN4,ihWLN4	FLbutton	"4", 1, 0, 2, 100, 30, 130,  50, -105 , 2, 0, -1
gktWLN5,ihWLN5	FLbutton	"5", 1, 0, 2, 100, 30, 130, 100, -105 , 2, 0, -1

;****
;Volume and VU
iWLNbtx1	= 300
iWLNbty1	=  50
ihbxWLNmix		FLbox		"WLN",	5, 1, 10,		 	74, 130,  iWLNbtx1,    iWLNbty1
			FLsetAlign	2, ihbxWLNmix
gkWLN_pan,ihWLN_pan	FLknob		"Pan", 	0, 1, 0, 3, -1,			 20,       iWLNbtx1+20, iWLNbty1+30
			FLsetVal_i	0.5,	ihWLN_pan
ihvalWLNamp		FLvalue		" ", 					38,  15,  iWLNbtx1+11, iWLNbty1+110
gksWLNamp,ihsWLNamp	FLknob          " ", 	0, 2, 0, 1, ihvalWLNamp,	42,	  iWLNbtx1+9,  iWLNbty1+63
gksWLNampD,gihsWLNampD	FLslider        " ", 	0, 30000, 0, 2 , -1,	 	10, 121,  iWLNbtx1+55, iWLNbty1+4
			FLsetColor 	 80, 150, 50,  gihsWLNampD
			FLsetColor2 	230, 50,  30,  gihsWLNampD
			
			FLsetVal_i	1,	ihsWLNamp

;****
	$EfxSend.(WLN'20'200'0.8'0'0'0'0'0'0'0.15'0.3)
;****

		FLpanelEnd     ;***** end of container
;******************************************************************

	FLpanel         "Pitch Tracker",680,430,100,100 ;***** start of container

			FLlabel  	-1
			FLlabel  	10, 1, 3, 0, 0, 0

ihPbox1			FLbox		"Recording synced to audio sampling", 5, 1, 11, 			650, 55,  15,  20
;gkPSmpl,ihP01		FLbutton	"Sample Pitch",  1, 0, 2, 		120, 20,  30,  40, -105 , 2, 0, -1
;gkPTrackIn,ihkPTrackIn	FLcount		"input select", 1, 2, 1, 1, 1, 	 90, 20, 260,  40, -1, -1
;gkPn1,ihPn1		FLcount		"Pitch mel. no", 1, 4, 1, 2, 1, 	 90, 20, 460,  40, -1, -1

ihPbox2		FLbox		"Playback", 5, 1, 11, 			650,175,  15, 100

gkPGrFrq,ihP02	FLbutton	"Grain4Freq",     1, 0, 2, 		 80, 20,  30, 120, -105 , 2, 0, -1
ihPbox3		FLbox		"Freq Multi", 1, 1, 10, 		100, 15, 120, 110
gkPmul1,ihPmul1	FLbutBank			2, 4, 1, 		100, 15, 120, 125, -105, -1
gktPAmp1,ihP03	FLbutton	"Amp enable",    1, 0, 2, 		 80, 20, 240, 120, -105 , 2, 0, -1
gkPa1,ihPa1	FLtext		"Amp amount", 	 0, 4, 0.1, 1, 		 50, 20, 340, 120
gkPa2,ihPa2	FLtext		"Amp thresh", 	 0, 2, 0.1, 1,		 50, 20, 400, 120
gkPn2,ihPn2	FLcount		"Pitch mel. no", 1, 14, 1, 2, 1, 	 90, 20, 460, 120, -1, -1
gkPtrg1,ihPtrg1	FLcount		"retrig measure", 0, 8, 1, 2, 1, 	 90, 20, 550, 120, -1, -1

gkPGrTsp,ihP04	FLbutton	"Grain4Transp",   1, 0, 2, 		 80, 20,  30, 160, -105 , 2, 0, -1
ihPbox4		FLbox		"Freq Multi", 1, 1, 10, 		100, 15, 120, 150
gkPmul2,ihPmul2	FLbutBank			2, 4, 1, 		100, 15, 120, 165, -105, -1
gktPAmp2,ihP05	FLbutton	"Amp enable",    1, 0, 2,		 80, 20, 240, 160, -105 , 2, 0, -1
gkPa3,ihPa3	FLtext		"Amp amount", 	 0, 4, 0.1, 1, 		 50, 20, 340, 160
gkPa4,ihPa4	FLtext		"Amp thresh", 	 0, 2, 0.1, 1,		 50, 20, 400, 160
gkPn3,ihPn3	FLcount		"Pitch mel. no", 1, 14, 1, 2, 1, 	 90, 20, 460, 160, -1, -1
gkPtrg2,ihPtrg2	FLcount		"retrig measure", 0, 8, 1, 2, 1, 	 90, 20, 550, 160, -1, -1

gkPFMFrq,ihP06	FLbutton	"FM Freq",       1, 0, 2,		 80, 20,  30, 200, -105 , 2, 0, -1
ihPbox4		FLbox		"Freq Multi", 1, 1, 10, 		100, 15, 120, 190
gkPmul3,ihPmul3	FLbutBank			2, 4, 1, 		100, 15, 120, 205, -105, -1
gkPn4,ihPn4	FLcount		"Pitch mel. no", 1, 14, 1, 2, 1, 	 90, 20, 460, 200, -1, -1
gkPtrg3,ihPtrg3	FLcount		"retrig measure", 0, 8, 1, 2, 1, 	 90, 20, 550, 200, -1, -1

gkPRMFrq,ihP07	FLbutton	"RM Freq",       1, 0, 2,		 80, 20,  30, 240, -105 , 2, 0, -1
ihPbox5		FLbox		"Freq Multi", 1, 1, 10, 		100, 15, 120, 230
gkPmul4,ihPmul4	FLbutBank			2, 4, 1, 		100, 15, 120, 245, -105, -1
gkPn5,ihPn5	FLcount		"Pitch mel. no", 1, 14, 1, 2, 1, 	 90, 20, 460, 240, -1, -1
gkPtrg4,ihPtrg4	FLcount		"retrig measure", 0, 8, 1, 2, 1, 	 90, 20, 550, 240, -1, -1

gkPBasSyn,ihP08	FLbutton	"BasSynth",     1, 0, 2, 		 80, 20,  30, 285, -105 , 2, 0, -1
ihPbox6		FLbox		"Freq Multi", 1, 1, 10, 		100, 15, 120, 275
gkPmul5,ihPmul5	FLbutBank			2, 4, 1, 		100, 15, 120, 290, -105, -1
gkBasSynAmp, ihBasSynAmp FLtext	"Out Amp", 	 0, 2, 0.05, 1, 	 60, 20, 240, 285
gkPa5,ihPa5	FLtext		"Amp follow", 	 0, 4, 0.1, 1, 		 50, 20, 340, 285
gkPn6,ihPn6	FLcount		"Pitch mel. no", 1, 14, 1, 2, 1, 	 90, 20, 460, 285, -1, -1
gkPtrg5,ihPtrg5	FLcount		"retrig measure", 0, 8, 1, 2, 1, 	 90, 20, 550, 285, -1, -1

	$EfxSend.(BasSyn'20'320'0.5'0'0'0'0'0.15'0'0'0.03)

		FLsetAlign	2, ihPbox1
		FLsetAlign	2, ihPbox2
		FLsetAlign	2, ihPa1
		FLsetAlign	2, ihPa2
		FLsetAlign	2, ihPa3
		FLsetAlign	2, ihPa4
;		FLsetAlign	2, ihPn1
		FLsetAlign	2, ihPn2
		FLsetAlign	2, ihPn3
		FLsetAlign	2, ihPn4
		FLsetAlign	2, ihPn5
;		FLsetVal_i	1, ihkPTrackIn
;		FLsetVal_i	1, ihPn1
		FLsetVal_i	1, ihPn2
		FLsetVal_i	1, ihPn3
		FLsetVal_i	1, ihPn4
		FLsetVal_i	1, ihPn5
		FLsetVal_i	1, ihPn6
		FLsetVal_i	2, ihPa1
		FLsetVal_i	0, ihPa2
		FLsetVal_i	2, ihPa3
		FLsetVal_i	0, ihPa4
		FLsetVal_i	1, ihPa5
		FLsetVal_i	1, ihBasSynAmp

       	FLpanelEnd     ;***** end of container

			FLpanel         "Pattern Sequencer",700,535,120,40 ;***** start of container
			FLlabel  	-1
			FLlabel  	10, 1, 3, 0, 0, 0

# define Pattern(A'B) #
iptrn$A.X1		= iptrn$A.X + 100
iptrn$A.X2		= iptrn$A.X + 200
iptrn$A.X3		= iptrn$A.X2  + 30
iptrn$A.X4		= iptrn$A.X3  + 30
iptrn$A.X5		= iptrn$A.X4  + 30
iptrn$A.X6		= iptrn$A.X5  + 30
iptrn$A.X7		= iptrn$A.X6  + 30
iptrn$A.X8		= iptrn$A.X7  + 30
iptrn$A.X9		= iptrn$A.X8  + 30
iptrn$A.X10		= iptrn$A.X9  + 30
iptrn$A.X11		= iptrn$A.X10 + 30
iptrn$A.X12		= iptrn$A.X11 + 30
iptrn$A.X13		= iptrn$A.X12 + 30
iptrn$A.X14		= iptrn$A.X13 + 30
iptrn$A.X15		= iptrn$A.X14 + 30
iptrn$A.X16		= iptrn$A.X15 + 30
iptrn$A.X17		= iptrn$A.X16 + 30

iptrn$A.Y1		= iptrn$A.Y + 35
iptrn$A.Y2		= iptrn$A.Y1 + 25
iptrn$A.Y3		= iptrn$A.Y2 + 25
iptrn$A.Y4		= iptrn$A.Y3 + 35

iptrn$A.height		= (iptrn$A.Y4 + 40) - iptrn$A.Y
iptrn$A.width		= (iptrn$A.X17 + 50) - iptrn$A.X

		FLlabel  	-1
		FLlabel  	10, 1, 3, 0, 0, 0

ihptrn$A.box		FLbox		"pattern$A.", 5, 1, 11, iptrn$A.width, iptrn$A.height, iptrn$A.X-10, iptrn$A.Y-10
			FLsetAlign	2, ihptrn$A.box
	
gkpt$A.fno1,ihptrn$A.fno	FLcount		"sample no.", 	1, 14, 1, 2, 1,  90, 20, iptrn$A.X,  iptrn$A.Y, -1, -1
			FLsetVal_i	$A., ihptrn$A.fno
gkptrn$A.sht,ihptrn$A.sht	FLbutton	"shortest",   	1, 0, 2,      	 70, 20, iptrn$A.X1, iptrn$A.Y, -105 , 2, 0, -1

gkp$A.fmfrq, ihp$A.fmfrq	FLtext		"fm freq", 	0, 4000, 10, 1,  50, 20, iptrn$A.X,  iptrn$A.Y1
gkp$A.fmindx,ihp$A.fmindx	FLtext		"fm index", 	0, 5,    0.1, 1, 50, 20, iptrn$A.X1, iptrn$A.Y1
gkp$A.fltQ, ihp$A.fltQ	FLtext		"filter Q", 	1, 40,    1, 1, 50, 20, iptrn$A.X,  iptrn$A.Y2
gkp$A.fltfrq,ihp$A.fltfrq	FLtext		"cutoff", 	0, 7000, 10, 1,  50, 20, iptrn$A.X1, iptrn$A.Y2
gkp$A.fdin, ihp$A.fdin	FLtext		"fade in", 	0, 1, 0.05, 1, 	 50, 20, iptrn$A.X,  iptrn$A.Y3
gkp$A.fdout, ihp$A.fdout	FLtext		"fade out", 	0.1, 1, 0.05, 1, 50, 20, iptrn$A.X1, iptrn$A.Y3

			FLsetVal_i	400, ihp$A.fmfrq
			FLsetVal_i	0.7, ihp$A.fmindx		
			FLsetVal_i	5000, ihp$A.fltfrq
			FLsetVal_i	2, ihp$A.fltQ
			FLsetVal_i	0.1, ihp$A.fdout		
			FLsetAlign	5, ihp$A.fmfrq
			FLsetAlign	5, ihp$A.fmindx
			FLsetAlign	5, ihp$A.fltQ
			FLsetAlign	5, ihp$A.fltfrq
			FLsetAlign	5, ihp$A.fdin
			FLsetAlign	5, ihp$A.fdout

gkptrn$A._1, ihptrn$A._01	FLslider	"1", 		0, 1, 0, 1, -1,	 30, 20, iptrn$A.X2,  iptrn$A.Y
gkptrn$A._2, ihptrn$A._02	FLslider	"2", 		0, 1, 0, 1, -1,	 30, 20, iptrn$A.X3,  iptrn$A.Y
gkptrn$A._3, ihptrn$A._03	FLslider	"3", 		0, 1, 0, 1, -1,	 30, 20, iptrn$A.X4,  iptrn$A.Y
gkptrn$A._4, ihptrn$A._04	FLslider	"4", 		0, 1, 0, 1, -1,	 30, 20, iptrn$A.X5,  iptrn$A.Y
gkptrn$A._5, ihptrn$A._05	FLslider	"5", 		0, 1, 0, 1, -1,	 30, 20, iptrn$A.X6,  iptrn$A.Y
gkptrn$A._6, ihptrn$A._06	FLslider	"6", 		0, 1, 0, 1, -1,	 30, 20, iptrn$A.X7,  iptrn$A.Y
gkptrn$A._7, ihptrn$A._07	FLslider	"7", 		0, 1, 0, 1, -1,	 30, 20, iptrn$A.X8,  iptrn$A.Y
gkptrn$A._8, ihptrn$A._08	FLslider	"8", 		0, 1, 0, 1, -1,	 30, 20, iptrn$A.X9,  iptrn$A.Y
gkptrn$A._9, ihptrn$A._09	FLslider	"9", 		0, 1, 0, 1, -1,	 30, 20, iptrn$A.X10, iptrn$A.Y
gkptrn$A._10,ihptrn$A._10	FLslider	"10", 		0, 1, 0, 1, -1,	 30, 20, iptrn$A.X11, iptrn$A.Y
gkptrn$A._11,ihptrn$A._11	FLslider	"11", 		0, 1, 0, 1, -1,	 30, 20, iptrn$A.X12, iptrn$A.Y
gkptrn$A._12,ihptrn$A._12	FLslider	"12", 		0, 1, 0, 1, -1,	 30, 20, iptrn$A.X13, iptrn$A.Y
gkptrn$A._13,ihptrn$A._13	FLslider	"13", 		0, 1, 0, 1, -1,	 30, 20, iptrn$A.X14, iptrn$A.Y
gkptrn$A._14,ihptrn$A._14	FLslider	"14", 		0, 1, 0, 1, -1,	 30, 20, iptrn$A.X15, iptrn$A.Y
gkptrn$A._15,ihptrn$A._15	FLslider	"15", 		0, 1, 0, 1, -1,	 30, 20, iptrn$A.X16, iptrn$A.Y
gkptrn$A._16,ihptrn$A._16	FLslider	"16", 		0, 1, 0, 1, -1,	 30, 20, iptrn$A.X17, iptrn$A.Y

			FLsetColor2 	200, 60,  30,  ihptrn$A._01
			FLsetColor2 	200, 60,  30,  ihptrn$A._02
			FLsetColor2 	200, 60,  30,  ihptrn$A._03
			FLsetColor2 	200, 60,  30,  ihptrn$A._04
			FLsetColor2 	200, 60,  30,  ihptrn$A._05
			FLsetColor2 	200, 60,  30,  ihptrn$A._06
			FLsetColor2 	200, 60,  30,  ihptrn$A._07
			FLsetColor2 	200, 60,  30,  ihptrn$A._08
			FLsetColor2 	200, 60,  30,  ihptrn$A._09
			FLsetColor2 	200, 60,  30,  ihptrn$A._10
			FLsetColor2 	200, 60,  30,  ihptrn$A._11
			FLsetColor2 	200, 60,  30,  ihptrn$A._12
			FLsetColor2 	200, 60,  30,  ihptrn$A._13
			FLsetColor2 	200, 60,  30,  ihptrn$A._14
			FLsetColor2 	200, 60,  30,  ihptrn$A._15
			FLsetColor2 	200, 60,  30,  ihptrn$A._16

gkp$A._1fm, ihp$A._01fm	FLtext		" ", 		0, 2, 0.1, 1, 	 30, 20, iptrn$A.X2,  iptrn$A.Y1
gkp$A._2fm, ihp$A._02fm	FLtext		" ", 		0, 2, 0.1, 1,	 30, 20, iptrn$A.X3,  iptrn$A.Y1
gkp$A._3fm, ihp$A._03fm	FLtext		" ", 		0, 2, 0.1, 1,	 30, 20, iptrn$A.X4,  iptrn$A.Y1
gkp$A._4fm, ihp$A._04fm	FLtext		" ", 		0, 2, 0.1, 1,	 30, 20, iptrn$A.X5,  iptrn$A.Y1
gkp$A._5fm, ihp$A._05fm	FLtext		" ", 		0, 2, 0.1, 1,	 30, 20, iptrn$A.X6,  iptrn$A.Y1
gkp$A._6fm, ihp$A._06fm	FLtext		" ", 		0, 2, 0.1, 1, 	 30, 20, iptrn$A.X7,  iptrn$A.Y1
gkp$A._7fm, ihp$A._07fm	FLtext		" ", 		0, 2, 0.1, 1,	 30, 20, iptrn$A.X8,  iptrn$A.Y1
gkp$A._8fm, ihp$A._08fm	FLtext		" ", 		0, 2, 0.1, 1,	 30, 20, iptrn$A.X9,  iptrn$A.Y1
gkp$A._9fm, ihp$A._09fm	FLtext		" ", 		0, 2, 0.1, 1,	 30, 20, iptrn$A.X10, iptrn$A.Y1
gkp$A._10fm, ihp$A._10fm	FLtext		" ", 		0, 2, 0.1, 1,	 30, 20, iptrn$A.X11, iptrn$A.Y1
gkp$A._11fm, ihp$A._11fm	FLtext		" ", 		0, 2, 0.1, 1, 	 30, 20, iptrn$A.X12, iptrn$A.Y1
gkp$A._12fm, ihp$A._12fm	FLtext		" ", 		0, 2, 0.1, 1,	 30, 20, iptrn$A.X13, iptrn$A.Y1
gkp$A._13fm, ihp$A._13fm	FLtext		" ", 		0, 2, 0.1, 1,	 30, 20, iptrn$A.X14, iptrn$A.Y1
gkp$A._14fm, ihp$A._14fm	FLtext		" ", 		0, 2, 0.1, 1,	 30, 20, iptrn$A.X15, iptrn$A.Y1
gkp$A._15fm, ihp$A._15fm	FLtext		" ", 		0, 2, 0.1, 1,	 30, 20, iptrn$A.X16, iptrn$A.Y1
gkp$A._16fm, ihp$A._16fm	FLtext		" ", 		0, 2, 0.1, 1,	 30, 20, iptrn$A.X17, iptrn$A.Y1

gkp$A._1flt, ihp$A._01flt	FLtext		" ", 		0.1, 2, 0.1, 1, 30, 20, iptrn$A.X2,  iptrn$A.Y2
gkp$A._2flt, ihp$A._02flt	FLtext		" ", 		0.1, 2, 0.1, 1, 30, 20, iptrn$A.X3,  iptrn$A.Y2
gkp$A._3flt, ihp$A._03flt	FLtext		" ", 		0.1, 2, 0.1, 1, 30, 20, iptrn$A.X4,  iptrn$A.Y2
gkp$A._4flt, ihp$A._04flt	FLtext		" ", 		0.1, 2, 0.1, 1, 30, 20, iptrn$A.X5,  iptrn$A.Y2
gkp$A._5flt, ihp$A._05flt	FLtext		" ", 		0.1, 2, 0.1, 1, 30, 20, iptrn$A.X6,  iptrn$A.Y2
gkp$A._6flt, ihp$A._06flt	FLtext		" ", 		0.1, 2, 0.1, 1, 30, 20, iptrn$A.X7,  iptrn$A.Y2
gkp$A._7flt, ihp$A._07flt	FLtext		" ", 		0.1, 2, 0.1, 1, 30, 20, iptrn$A.X8,  iptrn$A.Y2
gkp$A._8flt, ihp$A._08flt	FLtext		" ", 		0.1, 2, 0.1, 1, 30, 20, iptrn$A.X9,  iptrn$A.Y2
gkp$A._9flt, ihp$A._09flt	FLtext		" ", 		0.1, 2, 0.1, 1, 30, 20, iptrn$A.X10, iptrn$A.Y2
gkp$A._10flt,ihp$A._10flt	FLtext		" ", 		0.1, 2, 0.1, 1, 30, 20, iptrn$A.X11, iptrn$A.Y2
gkp$A._11flt,ihp$A._11flt	FLtext		" ", 		0.1, 2, 0.1, 1, 30, 20, iptrn$A.X12, iptrn$A.Y2
gkp$A._12flt,ihp$A._12flt	FLtext		" ", 		0.1, 2, 0.1, 1, 30, 20, iptrn$A.X13, iptrn$A.Y2
gkp$A._13flt,ihp$A._13flt	FLtext		" ", 		0.1, 2, 0.1, 1, 30, 20, iptrn$A.X14, iptrn$A.Y2
gkp$A._14flt,ihp$A._14flt	FLtext		" ", 		0.1, 2, 0.1, 1, 30, 20, iptrn$A.X15, iptrn$A.Y2
gkp$A._15flt,ihp$A._15flt	FLtext		" ", 		0.1, 2, 0.1, 1, 30, 20, iptrn$A.X16, iptrn$A.Y2
gkp$A._16flt,ihp$A._16flt	FLtext		" ", 		0.1, 2, 0.1, 1, 30, 20, iptrn$A.X17, iptrn$A.Y2

			FLsetVal_i	1, ihp$A._01flt
			FLsetVal_i	1, ihp$A._02flt
			FLsetVal_i	1, ihp$A._03flt
			FLsetVal_i	1, ihp$A._04flt
			FLsetVal_i	1, ihp$A._05flt
			FLsetVal_i	1, ihp$A._06flt
			FLsetVal_i	1, ihp$A._07flt
			FLsetVal_i	1, ihp$A._08flt
			FLsetVal_i	1, ihp$A._09flt
			FLsetVal_i	1, ihp$A._10flt
			FLsetVal_i	1, ihp$A._11flt
			FLsetVal_i	1, ihp$A._12flt
			FLsetVal_i	1, ihp$A._13flt
			FLsetVal_i	1, ihp$A._14flt
			FLsetVal_i	1, ihp$A._15flt
			FLsetVal_i	1, ihp$A._16flt

gkp$A._1dur, ikp$A._01dur	FLtext		" ", 		0.3, 1, 0.1, 1,	 30, 20, iptrn$A.X2,  iptrn$A.Y3
gkp$A._2dur, ikp$A._02dur	FLtext		" ", 		0.3, 1, 0.1, 1,	 30, 20, iptrn$A.X3,  iptrn$A.Y3
gkp$A._3dur, ikp$A._03dur	FLtext		" ", 		0.3, 1, 0.1, 1,	 30, 20, iptrn$A.X4,  iptrn$A.Y3
gkp$A._4dur, ikp$A._04dur	FLtext		" ", 		0.3, 1, 0.1, 1,	 30, 20, iptrn$A.X5,  iptrn$A.Y3
gkp$A._5dur, ikp$A._05dur	FLtext		" ", 		0.3, 1, 0.1, 1,	 30, 20, iptrn$A.X6,  iptrn$A.Y3
gkp$A._6dur, ikp$A._06dur	FLtext		" ", 		0.3, 1, 0.1, 1,	 30, 20, iptrn$A.X7,  iptrn$A.Y3
gkp$A._7dur, ikp$A._07dur	FLtext		" ", 		0.3, 1, 0.1, 1,	 30, 20, iptrn$A.X8,  iptrn$A.Y3
gkp$A._8dur, ikp$A._08dur	FLtext		" ", 		0.3, 1, 0.1, 1,	 30, 20, iptrn$A.X9,  iptrn$A.Y3
gkp$A._9dur, ikp$A._09dur	FLtext		" ", 		0.3, 1, 0.1, 1,	 30, 20, iptrn$A.X10, iptrn$A.Y3
gkp$A._10dur,ikp$A._10dur	FLtext		" ", 		0.3, 1, 0.1, 1,	 30, 20, iptrn$A.X11, iptrn$A.Y3
gkp$A._11dur,ikp$A._11dur	FLtext		" ", 		0.3, 1, 0.1, 1,	 30, 20, iptrn$A.X12, iptrn$A.Y3
gkp$A._12dur,ikp$A._12dur	FLtext		" ", 		0.3, 1, 0.1, 1,	 30, 20, iptrn$A.X13, iptrn$A.Y3
gkp$A._13dur,ikp$A._13dur	FLtext		" ", 		0.3, 1, 0.1, 1,	 30, 20, iptrn$A.X14, iptrn$A.Y3
gkp$A._14dur,ikp$A._14dur	FLtext		" ", 		0.3, 1, 0.1, 1,	 30, 20, iptrn$A.X15, iptrn$A.Y3
gkp$A._15dur,ikp$A._15dur	FLtext		" ", 		0.3, 1, 0.1, 1,	 30, 20, iptrn$A.X16, iptrn$A.Y3
gkp$A._16dur,ikp$A._16dur	FLtext		" ", 		0.3, 1, 0.1, 1,	 30, 20, iptrn$A.X17, iptrn$A.Y3

			FLsetVal_i	1, ikp$A._01dur
			FLsetVal_i	1, ikp$A._02dur
			FLsetVal_i	1, ikp$A._03dur
			FLsetVal_i	1, ikp$A._04dur
			FLsetVal_i	1, ikp$A._05dur
			FLsetVal_i	1, ikp$A._06dur
			FLsetVal_i	1, ikp$A._07dur
			FLsetVal_i	1, ikp$A._08dur
			FLsetVal_i	1, ikp$A._09dur
			FLsetVal_i	1, ikp$A._10dur
			FLsetVal_i	1, ikp$A._11dur
			FLsetVal_i	1, ikp$A._12dur
			FLsetVal_i	1, ikp$A._13dur
			FLsetVal_i	1, ikp$A._14dur
			FLsetVal_i	1, ikp$A._15dur
			FLsetVal_i	1, ikp$A._16dur

ihP7$A.51		FLbox		"Effect Sends", 5, 1 , 11, 190, 20, 10, iptrn$A.Y4
		FLlabel  	-1
		FLlabel  	10, 1, 2, 0, 0, 0

gkPtn$A._clean,ihFP$A.11 	FLtext		"Dry ", 	    0, 1, 0.05, 1,	 44, 20, iptrn$A.X2,     iptrn$A.Y4
gkPtn$A._pan,ihFP$A.11p 	FLtext		"Pan ", 	    0, 1, 0.05, 1,	 44, 20, iptrn$A.X2+49,  iptrn$A.Y4
gkPtn$A._rm,ihFP$A.12 	FLtext		"RingMod ", 	    0, 1, 0.05, 1,	 44, 20, iptrn$A.X2+98,	iptrn$A.Y4
gkPtn$A._fm,ihFP$A.13 	FLtext		"FreqMod ", 	    0, 1, 0.05, 1,	 44, 20, iptrn$A.X2+147, iptrn$A.Y4
gkPtn$A._filt1,ihFP$A.14 	FLtext		"Filter1", 	    0, 1, 0.05, 1,	 44, 20, iptrn$A.X2+196,	iptrn$A.Y4
gkPtn$A._dist,ihFP$A.15 	FLtext		"Distortion", 	    0, 1, 0.05, 1,	 44, 20, iptrn$A.X2+245, iptrn$A.Y4
gkPtn$A._filt2,ihFP$A.16 	FLtext		"Filter2", 	    0, 1, 0.05, 1,	 44, 20, iptrn$A.X2+294,	iptrn$A.Y4
gkPtn$A._del1,ihFP$A.17 	FLtext		"Delay1", 	    0, 1, 0.05, 1,	 44, 20, iptrn$A.X2+343, iptrn$A.Y4
gkPtn$A._del2,ihFP$A.18 	FLtext		"Delay2", 	    0, 1, 0.05, 1,	 44, 20, iptrn$A.X2+392,	iptrn$A.Y4
gkPtn$A._revb,ihFP$A.19 	FLtext		"Reverb1", 	    0, 1, 0.05, 1,	 44, 20, iptrn$A.X2+441, iptrn$A.Y4

			FLsetVal_i 	1, 	ihFP$A.11
			FLsetVal_i 	$B., 	ihFP$A.11p
			FLsetVal_i 	0, 	ihFP$A.12
			FLsetVal_i 	0, 	ihFP$A.13
			FLsetVal_i 	0, 	ihFP$A.14
			FLsetVal_i 	0, 	ihFP$A.15
			FLsetVal_i 	0, 	ihFP$A.16
			FLsetVal_i 	0, 	ihFP$A.17
			FLsetVal_i 	0, 	ihFP$A.18
			FLsetVal_i 	0, 	ihFP$A.19
#

iptrn1X			= 10				; upper left corner of pattern 1 section
iptrn1Y			= 25				; adjusting these two nmumbers moves the whole GUI block
$Pattern.(1'0.3)
iptrn2X			= 10				; upper left corner of pattern 2 section
iptrn2Y			= 205				; adjusting these two nmumbers moves the whole GUI block
$Pattern.(2'0.7)
iptrn3X			= 10				; upper left corner of pattern 3 section
iptrn3Y			= 385				; adjusting these two nmumbers moves the whole GUI block
$Pattern.(3'0.5)

			FLpanelEnd
;******************************************************************
;******************************************************************
			FLpanel		"ImproSculpt",1010,710,5,20

;***************************************
ihbxInputs		FLbox		"Inputs",	5, 1, 12, 	310, 345,   5,  20
			FLsetAlign	2, ihbxInputs
			FLlabel  	10, 1, 3, 0, 0, 0

inpwidth		= 147
inpt1X1			= 15
inpt1X1a		= inpt1X1 + 20
inpt1X2			= inpt1X1a + 45
inpt1X3			= inpt1X1a + 60

inpt2X1			= inpt1X1 + inpwidth + 5
inpt2X1a		= inpt2X1 + 15
inpt2X2			= inpt2X1a + 45
inpt2X3			= inpt2X1a + 60

inpt1Y0			= 45
inpt1Y1			= inpt1Y0 + 35
inpt1Y2			= inpt1Y1 + 35
inpt1Y3			= inpt1Y2 + 35
inpt1Y4			= inpt1Y3 + 35
inpt1Y5			= inpt1Y4 + 35
inpt1Y6			= inpt1Y5 + 35
inpt1Y7			= inpt1Y6 + 35
inpt1Y8			= inpt1Y7 + 35
inpt1Y9			= inpt1Y8 + 15

ih199			FLbox		"Input 1", 5, 1 , 11, inpwidth, 325, 10, 40
			FLsetAlign	2, ih199
;level display
gkInAmp1,gihInAmp1	FLslider        " ", 	0, 30000, 0, 2 , -1,	      10, 280, inpt1X1, inpt1Y0
			FLsetColor 	 80, 150, 50,  gihInAmp1
			FLsetColor2 	230, 50,  30,  gihInAmp1

;midi control input volume  display
gkInAmp1midi,gihInAmp1midi	FLslider  "midi input vol", 	0, 1, 0, 1 , -1,  inpwidth-13, 10, inpt1X1, inpt1Y9
			FLsetColor 	 80, 150, 50,  gihInAmp1midi
			FLsetColor2 	230, 50,  30,  gihInAmp1midi

gkinputmix,ihinputmix	FLbutton	"Mix inputs to 1",      1, 0, 2,     115, 20, inpt1X1a, inpt1Y0, -105 , 2, 0, -1
			FLsetAlign	1, ihinputmix

gkt2,ih101		FLbutton	"Auto Sampling",     1, 0, 2,        115, 25, inpt1X1a, inpt1Y1, -105 , 2, 0, -1
gk_manual1,ih101m	FLbutton	"Manual",   	     1, 0, 2,         60, 20, inpt1X1a, inpt1Y2, -105 , 2, 0, -1
gk_mantrig1,ih101t	FLbutton	"Trig",   	     1, 0, 2,         55, 20, inpt1X3, inpt1Y2, -105 , 2, 0, -1
gk_next1,ih101n		FLbutton	"Auto Cycle Slot" ,  1, 0, 2,        115, 20, inpt1X1a, inpt1Y3, -105 , 2, 0, -1
gih102			FLvalue		"Current Slot", 		      40, 20, inpt1X1a, inpt1Y4
gk_v1_minfno,ih103	FLcount		"First slot",        1, 14, 1, 2, 1, 115, 20, inpt1X1a, inpt1Y5, -1, -1
gk_v1_maxfno,ih104	FLcount		"Last slot",         1, 14, 1, 2, 1, 115, 20, inpt1X1a, inpt1Y6, -1, -1
ih110			FLvalue		"auto threshold",  		      70, 20, inpt1X2, inpt1Y7+10
gk_sampthresh1,ih109 	FLknob		" ",		    1, 10000, -1, 1, ih110, 40, inpt1X1a, inpt1Y7

			FLsetBox	2, ih101
			FLsetBox	2, ih101m
			FLsetBox	2, ih101t
			FLsetBox	2, ih101n

			FLsetAlign	1, ih101
			FLsetAlign	1, ih101m
			FLsetAlign	1, ih101t
			FLsetAlign	1, ih101n
			FLsetAlign	5, gih102
			FLsetVal_i 	1, ih103
			FLsetAlign	3, ih103
			FLsetVal_i 	7, ih104
			FLsetAlign	3, ih104
			FLsetVal_i 	500, ih109

ih198			FLbox		"Input 2", 5, 1 , 11, inpwidth, 325, inpwidth+15, 40
			FLsetAlign	2, ih198
;level display
gkInAmp2,gihInAmp2	FLslider        " ", 	0, 30000, 0, 2 , -1,	      10, 280, inpt2X1, inpt1Y0
			FLsetColor 	 80, 150, 50,  gihInAmp2
			FLsetColor2 	230, 50,  30,  gihInAmp2

;midi control input volume  display
gkInAmp2midi,gihInAmp2midi	FLslider  "midi input vol", 	0, 1, 0, 1 , -1,  inpwidth-13, 10, inpt2X1, inpt1Y9
			FLsetColor 	 80, 150, 50,  gihInAmp2midi
			FLsetColor2 	230, 50,  30,  gihInAmp2midi

gkt22,ih105		FLbutton	"Auto Sampling",     1, 0, 2,        115, 25,  inpt2X1a, inpt1Y1, -105 , 2, 0, -1
gk_manual2,ih105m	FLbutton	"Manual",            1, 0, 2,         60, 20,  inpt2X1a, inpt1Y2, -105 , 2, 0, -1
gk_mantrig2,ih105t	FLbutton	"Trig",              1, 0, 2,         55, 20,  inpt2X3, inpt1Y2, -105 , 2, 0, -1
gk_next2,ih105n		FLbutton	"Auto Cycle Slot",   1, 0, 2,        115, 20,  inpt2X1a, inpt1Y3, -105 , 2, 0, -1
gih106			FLvalue		"Current Slot", 		      40, 20,  inpt2X1a, inpt1Y4
gk_v2_minfno,ih107	FLcount		"First slot",        1, 14, 1, 2, 1, 115, 20,  inpt2X1a, inpt1Y5, -1, -1
gk_v2_maxfno,ih108	FLcount		"Last slot",         1, 14, 1, 2, 1, 115, 20,  inpt2X1a, inpt1Y6, -1, -1
ih112			FLvalue		"auto threshold",  		      70, 20,  inpt2X2, inpt1Y7+10
gk_sampthresh2,ih111 	FLknob		" ",		    1, 10000, -1, 1, ih112, 40, inpt2X1a, inpt1Y7

			FLsetBox	2, ih105
			FLsetBox	2, ih105m
			FLsetBox	2, ih105t
			FLsetBox	2, ih105n

			FLsetAlign	1, ih105
			FLsetAlign	1, ih105m
			FLsetAlign	1, ih105t
			FLsetAlign	1, ih105n
			FLsetAlign	5, gih106
			FLsetVal_i 	8, ih107
			FLsetAlign	3, ih107
			FLsetVal_i 	14,ih108
			FLsetAlign	3, ih108
			FLsetVal_i 	500, ih111


;***************************************
ihbxRythm		FLbox		"Rhythm",	5, 1, 12,	210, 355, 320,  20
			FLsetAlign	2, ihbxRythm

iRy1X1			= 352
iRy1X2			= iRy1X1 + 45
iRy1X3			= iRy1X2 + 40

iRy1Y1			= 30
iRy1Y2			= iRy1Y1 + 87
iRy1Y3			= iRy1Y2 + 117


gihtRythmv		FLvalue		" ", 30, 22, iRy1X1+126, iRy1Y1
gktR,ihtRythm		FLbutton	"Rythm On" ,    1, 0, 12, 126, 22,  iRy1X1-10, iRy1Y1, -105 , 4, 0, -1
			FLsetAlign	1,	ihtRythm


			FLtabs		206, 313, 322, 60
			FLgroup		"Master",	206, 298, 322, 75
			FLlabel  	-1
			FLlabel  	10, 1, 1, 0, 0, 0

ihBoxTm1		FLbox		"Tempo", 5, 1, 10, 145, 17, iRy1X1, iRy1Y2-25
gihCurTpo		FLvalue		"result", 60, 20, iRy1X3, iRy1Y2-5
			FLsetAlign	3,	gihCurTpo
gktmpo1,ihtmpo1		FLbutBank	2, 1, 5,	40, 80, iRy1X1, iRy1Y2, -105, -1
gktaptemp, ihtaptemp	FLbutton	"taptempo" ,    1, 0, 11, 60, 20, iRy1X3, iRy1Y2+29, 105 , 19, 0, 0.1
gkbtpoT, ihbtpoT	FLtext		"Adjust", 30, 240, 1, 1, 60, 20, iRy1X3, iRy1Y2+54
			FLsetVal_i	60, 	ihbtpoT
			FLsetAlign	3,	ihbtpoT

			FLlabel  	-1
			FLlabel  	10, 1, 4, 0, 0, 0
ihRytextTm1		FLbox		"0.25",	1, 1, 10, 	 30, 20, iRy1X2, iRy1Y2
ihRytextTm2		FLbox		"0.5",  1, 1, 10, 	 30, 20, iRy1X2, iRy1Y2 + 16
ihRytextTm3		FLbox		"1",  	1, 1, 10, 	 30, 20, iRy1X2, iRy1Y2 + 32
ihRytextTm4		FLbox		"2",  	1, 1, 10, 	 30, 20, iRy1X2, iRy1Y2 + 48
ihRytextTm5		FLbox		"4",  	1, 1, 10, 	 30, 20, iRy1X2, iRy1Y2 + 64

			FLlabel  	-1
			FLlabel  	10, 1, 1, 0, 0, 0
ihBoxTs1		FLbox	"Time Signature", 5, 1, 10, 145, 17, iRy1X1, iRy1Y3-25
gkTimSig,ihTimSig	FLbutBank	2, 1, 8, 	40, 128, iRy1X1, iRy1Y3, -105, -1

			FLlabel  	-1
			FLlabel  	10, 1, 4, 0, 0, 0
ihRytextTs1		FLbox		"4/4",  	1, 1, 10, 	 30, 20, iRy1X2, iRy1Y3
ihRytextTs2		FLbox		"5/4",  	1, 1, 10, 	 30, 20, iRy1X2, iRy1Y3 + 16
ihRytextTs3		FLbox		"3/4 ",  	1, 1, 10, 	 30, 20, iRy1X2, iRy1Y3 + 32
ihRytextTs4		FLbox		"3/8",  	1, 1, 10, 	 30, 20, iRy1X2, iRy1Y3 + 48
ihRytextTs5		FLbox		"5/8",  	1, 1, 10, 	 30, 20, iRy1X2, iRy1Y3 + 64
ihRytextTs6		FLbox		"7/8",  	1, 1, 10, 	 30, 20, iRy1X2, iRy1Y3 + 80
ihRytextTs7		FLbox		"3/16",  	1, 1, 10, 	 30, 20, iRy1X2, iRy1Y3 + 96
ihRytextTs8		FLbox		"5/16",  	1, 1, 10, 	 30, 20, iRy1X2, iRy1Y3 + 112

			FLlabel  	-1
			FLlabel  	10, 1, 3, 0, 0, 0

gkmetro_on,ihmtro_on	FLbutton	"Metro" ,     	1, 0, 2,        60, 22,  iRy1X3, iRy1Y3+17, -105 , 4, 0, -1
gkmetro_onM,ihmtro_onM	FLbutton	"MetroMidi" ,  	1, 0, 2,        60, 22,  iRy1X3, iRy1Y3+68, -105 , 4, 0, -1

			FLgroupEnd


			FLgroup		"Phrases",	206, 298, 322, 75
			FLlabel  	-1
			FLlabel  	10, 1, 1, 0, 0, 0

iRy2X1			= iRy1X1 - 3
iRy2X2			= iRy2X1 + 60
iRy2X3			= iRy2X2 + 60

iRy2Y1			= iRy1Y1
iRy2Y2			= iRy2Y1 + 62
iRy2Y3			= iRy2Y2 + 140

ihphrasetxt1		FLbox		"Rplay1", 	1, 1, 10,  	 50, 15, iRy2X1, iRy2Y2
gk_forcetrig1,ihphr1f	FLbutton	"force", 	1, 0, 1,  	 50, 17, iRy2X1, iRy2Y2+15,     -105 , 4, 0, -1
gkloop_phr1,ihphr1l	FLbutton	"loop",  	1, 0, 2,  	 50, 17, iRy2X1, iRy2Y2+32,  -105 , 4, 0, -1
gkphrasetick,ihphr1t	FLbutton	"Tick" ,    	1, 0, 2,         50, 17, iRy2X1, iRy2Y2+49, -105 , 4, 0, -1
ihpausetxt1		FLbox		"Phrase Pause", 1, 1, 10,  	165, 15, iRy2X1, iRy2Y2+72
gkminpause1,ihphr1min	FLtext		"min",		0, 16, 1, 1, 	 50, 20, iRy2X1, iRy2Y2+87
gkmaxpause1,ihphr1max	FLtext		"max",		0, 16, 1, 1, 	 50, 20, iRy2X1, iRy2Y2+107

			FLsetAlign	1, 	ihphr1f
			FLsetAlign	1, 	ihphr1l
			FLsetAlign	1, 	ihphr1t
			FLsetAlign	4, 	ihphr1min
			FLsetAlign	4, 	ihphr1max
			FLsetVal_i 	0,	ihphr1min
			FLsetVal_i 	2,	ihphr1max

ihphrasetxt2		FLbox		"Rplay2", 	1, 1, 10,  	 50, 15, iRy2X2, iRy2Y2
gk_forcetrig2,ihphr2f	FLbutton	"force", 	1, 0, 1,  	 50, 17, iRy2X2, iRy2Y2+15,     -105 , 4, 0, -1
gkloop_phr2,ihphr2l	FLbutton	"loop",  	1, 0, 2,  	 50, 17, iRy2X2, iRy2Y2+32,  -105 , 4, 0, -1
gkphrasetick2,ihphr2t	FLbutton	"Tick" ,    	1, 0, 2,         50, 17, iRy2X2, iRy2Y2+49, -105 , 4, 0, -1
gkminpause2,ihphr2min	FLtext		" ",		0, 16, 1, 1, 	 50, 20, iRy2X2, iRy2Y2+87
gkmaxpause2,ihphr2max	FLtext		" ",		0, 16, 1, 1, 	 50, 20, iRy2X2, iRy2Y2+107
			FLsetAlign	1, 	ihphr2f
			FLsetAlign	1, 	ihphr2l
			FLsetAlign	1, 	ihphr2t
			FLsetAlign	4, 	ihphr2min
			FLsetAlign	4, 	ihphr2max
			FLsetVal_i 	0,	ihphr2min
			FLsetVal_i 	2,	ihphr2max

ihphrasetxt3		FLbox		"RAG",  	1, 1, 10,  	 50, 15, iRy2X3, iRy2Y2
gk_forcetrig3,ihphr3f	FLbutton	"force", 	1, 0, 1,  	 50, 17, iRy2X3, iRy2Y2+15,     -105 , 4, 0, -1
gkloop_phr3,ihphr3l	FLbutton	"loop",  	1, 0, 2,  	 50, 17, iRy2X3, iRy2Y2+32,  -105 , 4, 0, -1
gkphrasetick3,ihphr3t	FLbutton	"Tick" ,    	1, 0, 2,         50, 17, iRy2X3, iRy2Y2+49, -105 , 4, 0, -1
gkminpause3,ihphr3min	FLtext		" ",		0, 16, 1, 1, 	 50, 20, iRy2X3, iRy2Y2+87
gkmaxpause3,ihphr3max	FLtext		" ",		0, 16, 1, 1, 	 50, 20, iRy2X3, iRy2Y2+107
			FLsetAlign	1, 	ihphr3f
			FLsetAlign	1, 	ihphr3l
			FLsetAlign	1, 	ihphr3t
			FLsetAlign	4, 	ihphr3min
			FLsetAlign	4, 	ihphr3max
			FLsetVal_i 	0,	ihphr3min
			FLsetVal_i 	0,	ihphr3max

ihphrselBx		FLbox	"Phrase Selector", 1, 1, 10,  	165,  15, iRy2X1, iRy2Y3
gkphr1N,ihphr1N		FLtext		" ",	0, 7, 1, 1, 	 50,  20, iRy2X1, iRy2Y3+15
gkphr2N,ihphr2N		FLtext		" ",	0, 7, 1, 1, 	 50,  20, iRy2X2, iRy2Y3+15
gkphr3N,ihphr3N		FLtext		" ",	0, 7, 1, 1, 	 50,  20, iRy2X3, iRy2Y3+15
			FLsetVal_i	5,	ihphr1N
			FLsetVal_i	4,	ihphr2N
			FLsetVal_i	6,	ihphr3N

ihphr1Tpo		FLbox	"Phrase Tempo", 1, 1, 10, 	165,  15, iRy2X1, iRy2Y3+45
gkphr1Tpo,ihphr1Tpo	FLbutBank	2, 1, 4, 		 50,  64, iRy2X1, iRy2Y3+60, -105, -1
gkphr2Tpo,ihphr2Tpo	FLbutBank	2, 1, 4, 		 50,  64, iRy2X2, iRy2Y3+60, -105, -1
gkphr3Tpo,ihphr3Tpo	FLbutBank	2, 1, 4, 		 50,  64, iRy2X3, iRy2Y3+60, -105, -1

ihphrasetpotxt1		FLbox		"x0.5", 1, 1, 10,  	 26, 15, iRy2X1-26, iRy2Y3+60
ihphrasetpotxt2		FLbox		"x1", 1, 1, 10,  	 26, 15, iRy2X1-26, iRy2Y3+76
ihphrasetpotxt3		FLbox		"x2", 1, 1, 10,  	 26, 15, iRy2X1-26, iRy2Y3+92
ihphrasetpotxt4		FLbox		"x4", 1, 1, 10,  	 26, 15, iRy2X1-26, iRy2Y3+108

			FLgroupEnd

			FLtabsEnd

;***************************************
ihbModules		FLbox		"Modules",	5, 1, 12,		470, 460, 535,  20
			FLsetAlign	2, ihbModules

			FLlabel  	-1
			FLlabel  	10, 1, 3, 0, 0, 0

			FLtabs		466, 456, 537,  22

iGr1_knobsize	= 40
iGr1_knoby1	=  60
iGr1_valy1	= iGr1_knoby1 + 55
iGr1_banky1	= iGr1_valy1 + 40
iGr1_knoby2	= iGr1_banky1 + 40
iGr1_valy2	= iGr1_knoby2 + 55
iGr1_slidy1	= iGr1_valy2 + 40
iGr1_slidy2	= iGr1_slidy1 + 40
iGr1_knoby3	= iGr1_knoby2 + 140

;iGr1_fxy	= iGr1_valy2 + 90

iGr1_knobx1	=  540 + 17
iGr1_knobx2	=  iGr1_knobx1 + 48
iGr1_knobx3	=  iGr1_knobx2 + 48
iGr1_knobx4	=  iGr1_knobx3 + 48
iGr1_knobx5	=  iGr1_knobx4 + 48
iGr1_knobx6	=  iGr1_knobx5 + 48
iGr1_knobx7	=  iGr1_knobx6 + 48
iGr1_knobx8	=  iGr1_knobx7 + 48
iGr1_knobx9	=  iGr1_knobx8 + 48

#define RplayModule(A'B'C'D'E'F'G'H'I'J'K'L'M) #
;argument : module number, firstsound, lastsound, FM indx, FM freq, fm params (args F - M )

ihRpl$A.trspV		FLvalue		" ", 40, 15, iGr1_knobx1, iGr1_valy1
gkRpl$A.trsp,ihRpl$A.trsp	FLknob	 	"Transp",  0, 2,     0, 1, ihRpl$A.trspV,  iGr1_knobsize, iGr1_knobx1,    iGr1_knoby1
			FLsetVal_i 	1, 	ihRpl$A.trsp
gkRpl$A.inv,ihRpl$A.inv	FLbutton	"inv",  		1, 0,  2,	   30, 15,       iGr1_knobx1+37, iGr1_knoby1, -1, -1 
			FLsetAlign	3, ihRpl$A.inv


gkRpl$A.fno1,ihRpl$A.fno1	FLcount		"First Sound", 		1, 14, 	  1, 2, 1,         90, 20, iGr1_knobx1+96, iGr1_knoby1+20, -1, -1
gkRpl$A.fno2,ihRpl$A.fno2	FLcount		"Last Sound", 		1, 14, 	  1, 2, 1,         90, 20, iGr1_knobx1+215, iGr1_knoby1+20, -1, -1
gkRpl$A.poly,ihRpl$A.poly	FLcount		"Polyphony", 		1, 20, 	  1, 2, 1,         90, 20, iGr1_knobx1+334, iGr1_knoby1+20, -1, -1
			FLsetAlign	2, ihRpl$A.fno1
			FLsetAlign	2, ihRpl$A.fno2
			FLsetAlign	2, ihRpl$A.poly

ihRpl$A.text1		FLbox		"selection of the", 	1, 1, 10,	  120, 20, iGr1_knobx1+96,  iGr1_valy1
gkRpl$A.shrt,ihRpl$A.shrt	FLbutton	"shortest",  		1, 0,  2,	   70, 20, iGr1_knobx1+215, iGr1_valy1, -1, -1 
ihRpl$A.text2		FLbox		"sounds", 		1, 1, 10,	   50, 20, iGr1_knobx1+290, iGr1_valy1
			FLsetAlign	1, ihRpl$A.shrt
			FLsetBox	2, ihRpl$A.shrt

			FLsetVal_i 	$B., 	ihRpl$A.fno1
			FLsetVal_i 	$C., 	ihRpl$A.fno2
			FLsetVal_i 	4, 	ihRpl$A.poly

			FLlabel  	-1
			FLlabel  	10, 1, 3, 0, 0, 0

ihRpl$A.textTr		FLbox		"semitone transpose", 	1, 1, 10, 100, 15, iGr1_knobx1, iGr1_banky1-15
gkRpl$A.btsp,ihRpl$A.btsp	FLbutBank				2, 15, 1, 424, 10, iGr1_knobx1, iGr1_banky1, -105, -1

			FLlabel  	-1
			FLlabel  	10, 1, 1, 0, 0, 0
iRpFMknoby		= iGr1_knoby2-11
gkRpl$A.mwave,ihRpl$A.mwav	FLbutBank			2, 1, 4,  	 40, 76, iGr1_knobx1, iRpFMknoby+23, -105, -1

			FLlabel  	-1
			FLlabel  	10, 1, 4, 0, 0, 0
ihRpl$A.text3		FLbox		"Mod Wave",  	1, 1, 10, 	 60, 20, iGr1_knobx1,    iRpFMknoby
ihRpl$A.text4		FLbox		"saw",  	1, 1, 10, 	 30, 20, iGr1_knobx1+40, iRpFMknoby+23
ihRpl$A.text5		FLbox		"tri ",  	1, 1, 10, 	 30, 20, iGr1_knobx1+40, iRpFMknoby+42
ihRpl$A.text6		FLbox		"sin",  	1, 1, 10, 	 30, 20, iGr1_knobx1+40, iRpFMknoby+61
ihRpl$A.text7		FLbox		"sqr",  	1, 1, 10, 	 30, 20, iGr1_knobx1+40, iRpFMknoby+80
	
			FLlabel  	-1
			FLlabel  	10, 1, 3, 0, 0, 0
gkRpl$A.fm,ihRpl$A.fm	FLbutton	"FM on/off",     1, 0, 2, 	170, 20, iGr1_knobx1, iRpFMknoby+110, -105 
			FLsetAlign	1, 	ihRpl$A.fm
			FLsetBox	2, 	ihRpl$A.fm

ihRpl$A.mdxV		FLvalue		" ", 	40, 15, iGr1_knobx1+130,    iRpFMknoby+30
ihRpl$A.mfqV		FLvalue		" ", 	40, 15, iGr1_knobx1+130,    iRpFMknoby+82
gkRpl$A.mndx,ihRpl$A.mdx	FLknob		"FM index",	0.01, 2,    -1, 1, ihRpl$A.mdxV,  40, iGr1_knobx1+90, iRpFMknoby+15
gkRpl$A.mfq,ihRpl$A.mfq	FLknob		"Mod Freq",	0.01, 6000, -1, 1, ihRpl$A.mfqV,  40, iGr1_knobx1+90, iRpFMknoby+67
			FLsetVal_i 	$D.,	ihRpl$A.mdx
			FLsetVal_i 	$E.,	ihRpl$A.mfq
			FLsetAlign	6, 	ihRpl$A.mdx
			FLsetAlign	6, 	ihRpl$A.mfq

gkRpl$A.mdxS,ihRpl$A.mdxS	FLtext		"Indx_start_x", 0, 5, 0.1, 1,       50, 20, iGr1_knobx1+200,    iRpFMknoby+15
gkRpl$A.mdxT,ihRpl$A.mdxT	FLtext		"Indx_thru_x", 	0, 5, 0.1, 1,       50, 20, iGr1_knobx1+287,    iRpFMknoby+15
gkRpl$A.mdxE,ihRpl$A.mdxE	FLtext		"Indx_end_x", 	0, 5, 0.1, 1,       50, 20, iGr1_knobx1+374,    iRpFMknoby+15
gkRpl$A.mdxP,ihRpl$A.mdxP	FLslider        "Thru point", 	0, 1, 0, 1, -1,    224, 15, iGr1_knobx1+200,    iRpFMknoby+50

gkRpl$A.mfqS,ihRpl$A.mfqS	FLtext		"Freq_start_x", 0, 5, 0.1, 1,       50, 20, iGr1_knobx1+200,    iRpFMknoby+82
gkRpl$A.mfqT,ihRpl$A.mfqT	FLtext		"Freq_thru_x",  0, 5, 0.1, 1,       50, 20, iGr1_knobx1+287,    iRpFMknoby+82
gkRpl$A.mfqE,ihRpl$A.mfqE	FLtext		"Freq_end_x", 	0, 5, 0.1, 1,       50, 20, iGr1_knobx1+374,    iRpFMknoby+82
gkRpl$A.mfqP,ihRpl$A.mfqP	FLslider        "Thru point", 	0, 1, 0, 1, -1,    224, 15, iGr1_knobx1+200,    iRpFMknoby+117

			FLsetVal_i 	$F.,	ihRpl$A.mdxS
			FLsetVal_i 	$G.,	ihRpl$A.mdxT
			FLsetVal_i 	$H.,	ihRpl$A.mdxE
			FLsetVal_i 	$I.,	ihRpl$A.mdxP
			FLsetVal_i 	$J.,	ihRpl$A.mfqS
			FLsetVal_i 	$K.,	ihRpl$A.mfqT
			FLsetVal_i 	$L.,	ihRpl$A.mfqE
			FLsetVal_i 	$M,	ihRpl$A.mfqP
			FLsetAlign	2, 	ihRpl$A.mdxS
			FLsetAlign	2, 	ihRpl$A.mdxT
			FLsetAlign	2, 	ihRpl$A.mdxE
			FLsetAlign	2, 	ihRpl$A.mdxP
			FLsetAlign	2, 	ihRpl$A.mfqS
			FLsetAlign	2, 	ihRpl$A.mfqT
			FLsetAlign	2, 	ihRpl$A.mfqE
			FLsetAlign	2, 	ihRpl$A.mfqP

; SV filter
ihRpl$A.SvTxt		FLbox		"SV Filter", 	1, 1, 10, 	  70, 20, iGr1_knobx1, iGr1_knoby3
gkRpl$A.SvMd,ihRpl$A.SvMd	FLbutBank				2, 4, 1, 160, 18, iGr1_knobx1+90, iGr1_knoby3, -105, -1
ihRpl$A.SvTxt2		FLbox		"bypass", 	1, 1, 10, 	  40, 15, iGr1_knobx1+90, iGr1_knoby3+18
ihRpl$A.SvTxt2		FLbox		"lo", 		1, 1, 10, 	  40, 15, iGr1_knobx1+130, iGr1_knoby3+18
ihRpl$A.SvTxt2		FLbox		"band", 	1, 1, 10, 	  40, 15, iGr1_knobx1+170, iGr1_knoby3+18
ihRpl$A.SvTxt2		FLbox		"hi", 		1, 1, 10, 	  40, 15, iGr1_knobx1+210, iGr1_knoby3+18
gkRpl$A.SvCf,ihRpl$A.SvCf	FLtext		"Cutoff", 	20, 6000, 20, 1,  50, 20, iGr1_knobx1+290, iGr1_knoby3
gkRpl$A.SvQ,ihRpl$A.SvQ	FLtext		"Q", 		4, 100, 1, 1,     50, 20, iGr1_knobx1+374, iGr1_knoby3

			FLsetVal_i	1000, 	ihRpl$A.SvCf
			FLsetVal_i	5, 	ihRpl$A.SvQ
			FLsetAlign	2, 	ihRpl$A.SvMd
			FLsetAlign	4, 	ihRpl$A.SvCf
			FLsetAlign	4, 	ihRpl$A.SvQ

#

#define GrainModule(A) #
;argument : module number
ihGrn$A.grfqV		FLvalue		" ", 40, 17, iGr1_knobx3-3, iGr1_valy1
ihGrn$A.octV		FLvalue		" ", 40, 17, iGr1_knobx5-20, iGr1_valy1
ihGrn$A.trspV		FLvalue		" ", 40, 17, iGr1_knobx7-20, iGr1_valy1
ihGrn$A.gliV		FLvalue		" ", 40, 17, iGr1_knobx9-20, iGr1_valy1

gkGrn$A.sel,ihGrn$A.sel	FLcount		"input sound no.", 0, 14, 1, 2,   1, 	 80, 20, iGr1_knobx1, iGr1_valy1-35, -1, -1
gkGrn$A.grfq,ihGrn$A.grfq	FLknob		"GrainFreq",  	    1, 1500, -1, 1, ihGrn$A.grfqV,  iGr1_knobsize, iGr1_knobx3-3, iGr1_knoby1
gkGrn$A.fsnc,ihGrn$A.fsnc	FLbutton	"sync", 	    1, 0,  2,	   	  30, 15,        	  iGr1_knobx3+38, iGr1_knoby1, -1, -1 
gkGrn$A.oct,ihGrn$A.oct	FLknob		"Octaviation", 	    0,    5, 0, 1, ihGrn$A.octV,   iGr1_knobsize, iGr1_knobx5-20, iGr1_knoby1

gkGrn$A.trnsp,ihGrn$A.trsp	FLknob		"Transp", 	    0,   2, 0, 1, ihGrn$A.trspV,  iGr1_knobsize, iGr1_knobx7-22, iGr1_knoby1
gkGrn$A.inv,ihGrn$A.inv	FLbutton	"inv",  		1, 0,  2,	   	  30, 15,        iGr1_knobx7+19, iGr1_knoby1, -1, -1 

gkGrn$A.glis,ihGrn$A.gli 	FLknob		"Gliss", 	    0,   2, 0, 1, ihGrn$A.gliV,   iGr1_knobsize, iGr1_knobx9-22, iGr1_knoby1
gkGrn$A.ginv,ihGrn$A.ginv	FLbutton	"inv",  		1, 0,  2,	   	  30, 15,       iGr1_knobx9+19, iGr1_knoby1, -1, -1 

			FLsetVal_i 	$A., 	ihGrn$A.sel
			FLsetVal_i 	33, 	ihGrn$A.grfq
			FLsetVal_i 	0, 	ihGrn$A.oct
			FLsetVal_i 	1, 	ihGrn$A.trsp
			FLsetVal_i 	0, 	ihGrn$A.gli
			FLsetAlign	3, 	ihGrn$A.fsnc
			FLsetAlign	3, 	ihGrn$A.inv
			FLsetAlign	3, 	ihGrn$A.ginv

			FLlabel  	-1
			FLlabel  	10, 1, 3, 0, 0, 0
ihGrn$A.textTr		FLbox		"semitone transpose", 	1, 1, 10, 100, 15, iGr1_knobx1, iGr1_banky1-15
gkGrn$A.btsp,ihGrn$A.btsp	FLbutBank				2, 15, 1,  424, 10, iGr1_knobx1, iGr1_banky1, -105, -1

ihGrn$A.bwV		FLvalue		" ", 40, 17, iGr1_knobx1, iGr1_valy2-6
ihGrn$A.risV		FLvalue		" ", 40, 17, iGr1_knobx2, iGr1_valy2-6
ihGrn$A.durV		FLvalue		" ", 40, 17, iGr1_knobx3, iGr1_valy2-6
ihGrn$A.decV		FLvalue		" ", 40, 17, iGr1_knobx4, iGr1_valy2-6

gkGrn$A.bw,ihGrn$A.bw 	FLknob		"Bandwidth",  	    0.001, 1, -1, 1, ihGrn$A.bwV,   iGr1_knobsize, iGr1_knobx1, iGr1_knoby2-6
gkGrn$A.ris,ihGrn$A.ris 	FLknob		"Rise", 	    0.001, 1, -1, 1, ihGrn$A.risV,  iGr1_knobsize, iGr1_knobx2, iGr1_knoby2-6
gkGrn$A.dur,ihGrn$A.dur 	FLknob		"Duration", 	    0.001, 8, -1, 1, ihGrn$A.durV,  iGr1_knobsize, iGr1_knobx3, iGr1_knoby2-6
gkGrn$A.dec,ihGrn$A.dec 	FLknob		"Dec",	 	    0.001, 1, -1, 1, ihGrn$A.decV,  iGr1_knobsize, iGr1_knobx4, iGr1_knoby2-6

			FLsetVal_i 	0.01, 	ihGrn$A.bw
			FLsetVal_i 	0.2, 	ihGrn$A.ris
			FLsetVal_i 	6.5, 	ihGrn$A.dur
			FLsetVal_i 	0.2, 	ihGrn$A.dec

gkGrn$A.mTim,ihGrn$A.mTim	FLbutton	"Man. TimPoint", 	1, 0, 2, 		   90, 20, iGr1_knobx1, iGr1_slidy1-12, -105 , 4, 0, -1
ihGrn$A.mPhsV		FLvalue		" ", 					 	   40, 15, iGr1_knobx1 + 384, iGr1_slidy1-12
gkGrn$A.mPhs,ihGrn$A.mPhs	FLslider        "Man. Time pointer",   	0, 1, 0, 1, ihGrn$A.mPhsV, 280, 15, iGr1_knobx1 + 100, iGr1_slidy1-12

ihGrn$A.lfqV		FLvalue		" ", 40, 17, iGr1_knobx6, iGr1_valy2-6
ihGrn$A.lfaV		FLvalue		" ", 40, 17, iGr1_knobx7, iGr1_valy2-6
ihGrn$A.rndaV		FLvalue		" ", 40, 17, iGr1_knobx8, iGr1_valy2-6
ihGrn$A.tratV		FLvalue		" ", 40, 17, iGr1_knobx9, iGr1_valy2-6

gkGrn$A.lfq,ihGrn$A.lfq	FLknob		"Lfo Frq",  	    0.001, 10, -1, 1, ihGrn$A.lfqV,  iGr1_knobsize, iGr1_knobx6, iGr1_knoby2-6
gkGrn$A.lfoA,ihGrn$A.lfa 	FLknob		"Lfo Amt", 	    0.001, 3,  -1, 1, ihGrn$A.lfaV,  iGr1_knobsize, iGr1_knobx7, iGr1_knoby2-6
gkGrn$A.randA,ihGrn$A.rnda	FLknob		"RndAmt", 	    0.001, 3,  -1, 1, ihGrn$A.rndaV,  iGr1_knobsize, iGr1_knobx8, iGr1_knoby2-6
gkGrn$A.trat,ihGrn$A.trat	FLknob		"TimRatio", 	    -3, 3, 0, 1, ihGrn$A.tratV,  iGr1_knobsize, iGr1_knobx9, iGr1_knoby2-6

			FLsetVal_i 	0.15, 	ihGrn$A.lfq
			FLsetVal_i 	0.01, 	ihGrn$A.lfa
			FLsetVal_i 	0.001, 	ihGrn$A.rnda
			FLsetVal_i 	1, 	ihGrn$A.trat

gkGrn$A.numv,ihGrn$A.numv	FLcount		"numvoice", 	1, 4, 1, 2,   1,	   	80, 20, iGr1_knobx1, iGr1_slidy2-7, -1, -1
gkGrn$A.Tr1,ihGrn$A.Tr1	FLtext		"Trsp1", 	0, 12, 1, 1, 	  		30, 20, iGr1_knobx1 +  91, iGr1_slidy2-7
gkGrn$A.Tr2,ihGrn$A.Tr2	FLtext		"Trsp2", 	0, 12, 1, 1, 	  		30, 20, iGr1_knobx1 + 126, iGr1_slidy2-7
gkGrn$A.Tr3,ihGrn$A.Tr3	FLtext		"Trsp3", 	0, 12, 1, 1, 	  		30, 20, iGr1_knobx1 + 161, iGr1_slidy2-7
gkGrn$A.Tr4,ihGrn$A.Tr4	FLtext		"Trsp4", 	0, 12, 1, 1, 	  		30, 20, iGr1_knobx1 + 196, iGr1_slidy2-7
ihGrn$A.SprdV		FLvalue		" ", 				 	   	40, 15, iGr1_knobx1 + 334, iGr1_slidy2-7
gkGrn$A.Sprd,ihGrn$A.Sprd	FLslider        "rndPitch Spread", 0, 12, 0, 1, ihGrn$A.SprdV, 	95, 15, iGr1_knobx1 + 236, iGr1_slidy2-7
gkGrn$A.SprF,ihGrn$A.SprF	FLtext		"SpreadFreq", 	1, 1500, 1, 1, 	  		40, 20, iGr1_knobx1 + 384, iGr1_slidy2-7
; hack
iQptchX			= iGr1_knobx1 + 334
iQptchY			= iGr1_slidy2+15
gkGrn$A.QPch,ihGrn$A.QPch	FLbutton	"qpch", 	1, 0, 2, 		   	40, 15, iQptchX, iQptchY, -105 , 4, 0, -1
			FLsetAlign	1, ihGrn$A.QPch

			FLsetVal_i 	1, 	ihGrn$A.numv
			FLsetVal_i 	0, 	ihGrn$A.Sprd
			FLsetVal_i 	20, 	ihGrn$A.SprF

#


			FLgroup		"Rplay1   ",  455, 440, 540,  45
	$RplayModule.(1'1'4'0.15'250'1'0.1'0.3'0.2'1'1'0.5'0.5)
	$EfxSend.(Rplay1'557'370'1'0'0'0'0'0'0.15'0'0)
			FLgroupEnd
			FLgroup		"Rplay2   ",  455, 440, 540,  45
	$RplayModule.(2'5'7'0.30'850'0'1'0.3'0.6'1'1'0.5'0.5)
	$EfxSend.(Rplay2'557'370'1'0'0'0.15'0'0'0'0'0.3)
			FLgroupEnd
			FLgroup		"Grain1   ",  455, 440, 540,  45
	$GrainModule.(1)
	$EfxSend.(Grain1'557'370'1'0'0'0'0'0'0'0.3'0)
			FLgroupEnd
			FLgroup		"Grain2   ",  455, 440, 540,  45
	$GrainModule.(2)
	$EfxSend.(Grain2'557'370'1'0'0'0'0'0'0'0.2'0.25)
			FLgroupEnd
			FLgroup		"Grain3   ",  455, 440, 540,  45
	$GrainModule.(3)
	$EfxSend.(Grain3'557'370'1'0'0'0'0.1'0'0'0'0.20)
			FLgroupEnd
			FLgroup		"Grain4   ",  455, 440, 540,  45
	$GrainModule.(4)
	$EfxSend.(Grain4'557'370'1'0'0'0'0'0'0'0'0.15)
			FLgroupEnd

			FLgroup		"RAGrain",  455, 440, 540,  45
ihRAGtrspV		FLvalue		" ", 40, 17, iGr1_knobx5, iGr1_valy1
ihRAGrpchV		FLvalue		" ", 40, 17, iGr1_knobx7, iGr1_valy1

gkRAGsel,ihRAGsel	FLcount		"input sound no.",  0, 14, 1, 2,   1, 	 80, 20, iGr1_knobx1, iGr1_valy1-35, -1, -1
gkRAGtrnsp,ihRAGtrsp	FLknob		"Transp", 	    0,   2, 0, 1, ihRAGtrspV,  iGr1_knobsize, iGr1_knobx5-2, iGr1_knoby1
gkRAGinv,ihRAGinv	FLbutton	"inv",  		1, 0,  2,	   	  30, 15,     iGr1_knobx5+39, iGr1_knoby1, -1, -1 

gkRAGrptch,ihRAGrpch 	FLknob		"R.pitch", 	    0,   1, 0, 1, ihRAGrpchV,  iGr1_knobsize, iGr1_knobx7-2, iGr1_knoby1
gkRAGrpinv,ihRAGrpinv	FLbutton	"inv",  		1, 0,  2,	   	  30, 15,     iGr1_knobx7+39, iGr1_knoby1, -1, -1 

			FLsetVal_i 	1, 	ihRAGsel
			FLsetVal_i 	1, 	ihRAGtrsp
			FLsetVal_i 	0, 	ihRAGrpch
			FLsetAlign	3, 	ihRAGinv
			FLsetAlign	3, ihRAGrpinv

			FLlabel  	-1
			FLlabel  	10, 1, 3, 0, 0, 0
ihRAGtextTr		FLbox		"semitone transpose", 	1, 1, 10, 100, 15, iGr1_knobx1, iGr1_banky1-15
gkRAGbtsp,ihRAGbtsp	FLbutBank				2, 15, 1, 424, 10, iGr1_knobx1, iGr1_banky1, -105, -1

ihRAGrisV		FLvalue		" ", 40, 17, iGr1_knobx1, iGr1_valy2+15
ihRAGdurV		FLvalue		" ", 40, 17, iGr1_knobx2, iGr1_valy2+15
ihRAGdecV		FLvalue		" ", 40, 17, iGr1_knobx3, iGr1_valy2+15
ihRAGrdurV		FLvalue		" ", 40, 17, iGr1_knobx4, iGr1_valy2+15

ihRAGtextEnv		FLbox		"Duration / Envelope", 	5, 1, 10, 190, 15, iGr1_knobx1, iGr1_knoby2
gkRAGris,ihRAGris 	FLknob		"Rise", 	    0.01, 1, -1, 1, ihRAGrisV,  iGr1_knobsize, iGr1_knobx1, iGr1_knoby2+15
gkRAGdur,ihRAGdur 	FLknob		"Duration", 	    0.1, 5, -1, 1, ihRAGdurV,  iGr1_knobsize, iGr1_knobx2, iGr1_knoby2+15
gkRAGdec,ihRAGdec 	FLknob		"Dec",	 	    0.01, 1, -1, 1, ihRAGdecV,  iGr1_knobsize, iGr1_knobx3, iGr1_knoby2+15
gkRAGrdur,ihRAGrdur 	FLknob		"R.dur", 	    0.001, 1, -1, 1, ihRAGrdurV, iGr1_knobsize, iGr1_knobx4, iGr1_knoby2+15

			FLsetVal_i 	0.2, 	ihRAGris
			FLsetVal_i 	0.2, 	ihRAGdur
			FLsetVal_i 	0.35, 	ihRAGdec
			FLsetVal_i 	0.001, 	ihRAGrdur

gkRAGmTim,ihRAGmTim	FLbutton	"Man. TimPoint", 	1, 0, 2, 		 90, 20, iGr1_knobx1, iGr1_slidy1+15, -105 , 4, 0, -1
ihRAGmPhsV		FLvalue		" ", 					 	 40, 15, iGr1_knobx1 + 384, iGr1_slidy1+15
gkRAGmPhs,ihRAGmPhs	FLslider        "Man. Time pointer",   	0, 1, 0, 1, ihRAGmPhsV, 280, 15, iGr1_knobx1 + 100, iGr1_slidy1+15

ihRAGlfqV		FLvalue		" ", 40, 17, iGr1_knobx6, iGr1_valy2+15
ihRAGlfaV		FLvalue		" ", 40, 17, iGr1_knobx7, iGr1_valy2+15
ihRAGrphsV		FLvalue		" ", 40, 17, iGr1_knobx8, iGr1_valy2+15
ihRAGtratV		FLvalue		" ", 40, 17, iGr1_knobx9, iGr1_valy2+15

ihRAGtextEnv		FLbox		"StartPoint / Phase", 	5, 1, 10, 190, 15, iGr1_knobx6, iGr1_knoby2
gkRAGlfq,ihRAGlfq	FLknob		"Lfo Frq",  	    0.001, 10, -1, 1, ihRAGlfqV,  iGr1_knobsize, iGr1_knobx6, iGr1_knoby2+15
gkRAGlfA,ihRAGlfa 	FLknob		"Lfo Amt", 	    0.001, 3,  -1, 1, ihRAGlfaV,  iGr1_knobsize, iGr1_knobx7, iGr1_knoby2+15
gkRAGrphs,ihRAGrphs	FLknob		"RndAmt", 	    0.001, 3,  -1, 1, ihRAGrphsV, iGr1_knobsize, iGr1_knobx8, iGr1_knoby2+15
gkRAGtrat,ihRAGtrat	FLknob		"TimRatio", 	    -3, 3, 0, 1, ihRAGtratV, iGr1_knobsize, iGr1_knobx9, iGr1_knoby2+15

			FLsetVal_i 	0.2, 	ihRAGlfq
			FLsetVal_i 	0.1, 	ihRAGlfa
			FLsetVal_i 	0.001, 	ihRAGrphs
			FLsetVal_i 	1, 	ihRAGtrat

	$EfxSend.(RAG'557'370'1'0'0'0'0'0'0'0'0.15)
			FLgroupEnd


			FLgroup		"Pad ",  455, 440, 540,  45
			FLlabel  	-1
			FLlabel  	10, 1, 1, 0, 0, 0

gkt701,ih701		FLbutton	"E'", 	     1, 0, 2,        50, 20, iGr1_knobx1,     iGr1_knoby2, -105 , 2, 0, -1
gkt702,ih702		FLbutton	"E", 	     1, 0, 2,        50, 20, iGr1_knobx1+50,  iGr1_knoby2, -105 , 2, 0, -1
gkt703,ih703		FLbutton	"e", 	     1, 0, 2,        50, 20, iGr1_knobx1+100, iGr1_knoby2, -105 , 2, 0, -1
gkt704,ih704		FLbutton	"f#", 	     1, 0, 2,        50, 20, iGr1_knobx1+150, iGr1_knoby2, -105 , 2, 0, -1
gkt705,ih705		FLbutton	"g#", 	     1, 0, 2,        50, 20, iGr1_knobx1+200, iGr1_knoby2, -105 , 2, 0, -1
gkt706,ih706		FLbutton	"a#", 	     1, 0, 2,        50, 20, iGr1_knobx1+250, iGr1_knoby2, -105 , 2, 0, -1
gkt707,ih707		FLbutton	"h", 	     1, 0, 2,        50, 20, iGr1_knobx1+300, iGr1_knoby2, -105 , 2, 0, -1

	$EfxSend.(Pad'557'370'1'0'0'0.2'0'0'0.2'0'0.2)
			FLgroupEnd
			FLgroup		"DrumLoop",  455, 440, 540,  45
			FLlabel  	-1
			FLlabel  	10, 1, 1, 0, 0, 0

gihDrmLopNd		FLvalue		" ", 					40,  20,   iGr1_knobx1+168, iGr1_knoby1
gkDrmLopN,ihDrmLopN	FLcount		"Loop no",		1, 28, 1, 4, 1, 120, 20,     iGr1_knobx1, iGr1_knoby1, -1, -1
			FLsetVal_i 	1, 	ihDrmLopN
			FLsetAlign 	5, 	ihDrmLopN

gihDrmLopNd2		FLvalue		" ", 					40,  20,   iGr1_knobx1+168, iGr1_knoby1+120
gkDrmLopN2,ihDrmLopN2	FLcount		"Loop 2",		0, 16, 1, 4, 1, 120, 20,     iGr1_knobx1, iGr1_knoby1+120, -1, -1
			FLsetVal_i 	0, 	ihDrmLopN2
			FLsetAlign 	5, 	ihDrmLopN2

gihDrmLopNd3		FLvalue		" ", 					40,  20,   iGr1_knobx1+168, iGr1_knoby1+152
gkDrmLopN3,ihDrmLopN3	FLcount		"Loop 3",		0, 16, 1, 4, 1, 120, 20,     iGr1_knobx1, iGr1_knoby1+152, -1, -1
			FLsetVal_i 	0, 	ihDrmLopN3
			FLsetAlign 	5, 	ihDrmLopN3

; starts instr that sets gkButnRetrig1 = 1, retrig beat counter
gkButnRetrig,ihButnRetr	FLbutton	"Retrig",  	        1, 0, 2,        60, 20,     iGr1_knobx1, iGr1_knoby1+80, -105 , 17, 0, 0.01
			FLsetAlign 	1, 	ihButnRetr
ihDrmLopTpoBx		FLbox	"pitch/tempo", 		1, 1, 10, 		60, 15,     iGr1_knobx1, iGr1_valy1-25
gkDrmLopTpo,ihDrmLopTpo	FLbutBank				2, 5, 1, 	200, 20,     iGr1_knobx1, iGr1_valy1-10, -105, -1

ihDLbbcutbox		FLbox		"BBCut parameters", 	1, 1, 10, 	120, 20,    iGr1_knobx7+10, iGr1_knoby1
gkDLsubdiv,ihDLsubdiv	FLcount		"subdiv",		1, 16,  1, 4,  1, 120, 20,  iGr1_knobx7+10, iGr1_knoby1+20, -1, -1
gkDLbarlen,ihDLbarlen	FLcount		"barlength",		1, 8,  1, 4,  1, 120, 20,  iGr1_knobx7+10, iGr1_knoby1+40, -1, -1
gkDLphrbar,ihDLphrbar	FLcount		"phrasebar",		1, 16,  1, 4,  1, 120, 20,  iGr1_knobx7+10, iGr1_knoby1+60, -1, -1
gkDLnumrep,ihDLnumrep	FLcount		"num rep",		1, 16,  1, 4,  1, 120, 20,  iGr1_knobx7+10, iGr1_knoby1+80, -1, -1
gkDLstuspd,ihDLstuspd	FLcount		"stutr speed",		1, 16,  1, 4,  1, 120, 20,  iGr1_knobx7+10, iGr1_knoby1+100, -1, -1
gkDLsturnd,ihDLsturnd	FLcount		"stutr chance",		0, 100, 1, 10, 1, 120, 20,  iGr1_knobx7+10, iGr1_knoby1+120, -1, -1
gkDLenv,ihenv 	 	FLcount		"envelope",		0, 1,   1, 1,  1, 120, 20,  iGr1_knobx7+10, iGr1_knoby1+140, -1, -1

			FLsetVal_i 	8, 	ihDLsubdiv
			FLsetVal_i 	4, 	ihDLbarlen
			FLsetVal_i 	2, 	ihDLphrbar
			FLsetVal_i 	2, 	ihDLnumrep
			FLsetVal_i 	6, 	ihDLstuspd
			FLsetVal_i 	80, 	ihDLsturnd
			FLsetVal_i 	1, 	ihenv

			FLsetAlign 	4, 	ihDLsubdiv
			FLsetAlign 	4, 	ihDLbarlen
			FLsetAlign 	4, 	ihDLphrbar
			FLsetAlign 	4, 	ihDLnumrep
			FLsetAlign 	4, 	ihDLstuspd
			FLsetAlign 	4, 	ihDLsturnd
			FLsetAlign 	4, 	ihenv


ihDLbbmixV		FLvalue		" ", 	40, 15, iGr1_knobx1+300, iGr1_slidy1-40
gkDLbbmix,ihDLbbmix	FLslider        "Clean/BBCut balance", 0, 1, 0, 1, ihDLbbmixV, 290, 15, iGr1_knobx1, iGr1_slidy1-40
			FLsetVal_i 	0, 	ihDLbbmix
			FLsetAlign	3, 	ihDLbbmix


ihDrmLopAmV		FLvalue		" ", 	40, 15, iGr1_knobx1+300, iGr1_slidy1
gkDrmLopAm,ihDrmLopAm	FLslider        "DrumLoop Amplitude", 0, 4, 0, 1, ihDrmLopAmV, 290, 15, iGr1_knobx1, iGr1_slidy1
			FLsetVal_i 	1, 	ihDrmLopAm
			FLsetAlign	3, 	ihDrmLopAm

ih1DrmLopAmV		FLvalue		" ",  	40, 15, iGr1_knobx1+300,  iGr1_slidy2
gk1DrmLopAm,ih1DrmLopAm	FLslider        "Layer1 Amplitude",	0,  4, 0, 1, ih1DrmLopAmV, 290, 15, iGr1_knobx1, iGr1_slidy2
			FLsetVal_i 	1, 	ih1DrmLopAm
			FLsetAlign	3, 	ih1DrmLopAm

	$EfxSend.(Loop'557'370'1'0'0'0'0'0'0'0'0)
			FLgroupEnd
			FLtabsEnd

;***************************************
ihbxSoundList		FLbox		"Sound List",	5, 1, 12,		500, 205, 503, 500
			FLsetAlign	2, ihbxSoundList
			FLlabel  	-1
			FLlabel  	10, 1, 1, 0, 0, 0

isndlstX1		= 517
isndlstX2		= isndlstX1 + 34
isndlstX3		= isndlstX2 + 34
isndlstX4		= isndlstX3 + 34
isndlstX5		= isndlstX4 + 34
isndlstX6		= isndlstX5 + 34
isndlstX7		= isndlstX6 + 34
isndlstX8		= isndlstX7 + 34
isndlstX9		= isndlstX8 + 34
isndlstX10		= isndlstX9 + 34
isndlstX11		= isndlstX10 + 34
isndlstX12		= isndlstX11 + 34
isndlstX13		= isndlstX12 + 34
isndlstX14		= isndlstX13 + 34

isndlstY1		= 520
isndlstY2		= isndlstY1 + 42
isndlstY3		= isndlstY2 + 40
isndlstY4		= isndlstY3 + 42
isndlstY5		= isndlstY4 + 42


ihsndlstxt1		FLbox		"Sound Length",	1, 1, 10, 476, 20, isndlstX1, isndlstY1-19
gihsnd1			FLvalue		" ", 32, 20, isndlstX1, isndlstY1
gihsnd2			FLvalue		" ", 32, 20, isndlstX2, isndlstY1
gihsnd3			FLvalue		" ", 32, 20, isndlstX3, isndlstY1
gihsnd4			FLvalue		" ", 32, 20, isndlstX4, isndlstY1
gihsnd5			FLvalue		" ", 32, 20, isndlstX5, isndlstY1
gihsnd6			FLvalue		" ", 32, 20, isndlstX6, isndlstY1
gihsnd7			FLvalue		" ", 32, 20, isndlstX7, isndlstY1
gihsnd8			FLvalue		" ", 32, 20, isndlstX8, isndlstY1
gihsnd9			FLvalue		" ", 32, 20, isndlstX9, isndlstY1
gihsnd10		FLvalue		" ", 32, 20, isndlstX10, isndlstY1
gihsnd11		FLvalue		" ", 32, 20, isndlstX11, isndlstY1
gihsnd12		FLvalue		" ", 32, 20, isndlstX12, isndlstY1
gihsnd13		FLvalue		" ", 32, 20, isndlstX13, isndlstY1
gihsnd14		FLvalue		" ", 32, 20, isndlstX14, isndlstY1

ihsndlstxt2		FLbox		"Test Play Sounds", 1, 1, 10, 476, 20, isndlstX1, isndlstY2-19
gkply1,ihply1		FLbutton	"1",     1, 0, 11,        32, 17,  isndlstX1, isndlstY2, 105 , 311, 0, 5.944, 1
gkply2,ihply2		FLbutton	"2",     1, 0, 11,        32, 17,  isndlstX2, isndlstY2, 105 , 311, 0, 5.944, 2
gkply3,ihply3		FLbutton	"3",     1, 0, 11,        32, 17,  isndlstX3, isndlstY2, 105 , 311, 0, 5.944, 3
gkply4,ihply4		FLbutton	"4",     1, 0, 11,        32, 17,  isndlstX4, isndlstY2, 105 , 311, 0, 5.944, 4
gkply5,ihply5		FLbutton	"5",     1, 0, 11,        32, 17,  isndlstX5, isndlstY2, 105 , 311, 0, 5.944, 5
gkply6,ihply6		FLbutton	"6",     1, 0, 11,        32, 17,  isndlstX6, isndlstY2, 105 , 311, 0, 5.944, 6
gkply7,ihply7		FLbutton	"7",     1, 0, 11,        32, 17,  isndlstX7, isndlstY2, 105 , 311, 0, 5.944, 7
gkply8,ihply8		FLbutton	"8",     1, 0, 11,        32, 17,  isndlstX8, isndlstY2, 105 , 311, 0, 5.944, 8
gkply9,ihply9		FLbutton	"9",     1, 0, 11,        32, 17,  isndlstX9, isndlstY2, 105 , 311, 0, 5.944, 9
gkply10,ihply10		FLbutton	"10",    1, 0, 11,        32, 17,  isndlstX10, isndlstY2, 105 , 311, 0, 5.944, 10
gkply11,ihply11		FLbutton	"11",    1, 0, 11,        32, 17,  isndlstX11, isndlstY2, 105 , 311, 0, 5.944, 11
gkply12,ihply12		FLbutton	"12",    1, 0, 11,        32, 17,  isndlstX12, isndlstY2, 105 , 311, 0, 5.944, 12
gkply13,ihply13		FLbutton	"13",    1, 0, 11,        32, 17,  isndlstX13, isndlstY2, 105 , 311, 0, 5.944, 13
gkply14,ihply14		FLbutton	"14",    1, 0, 11,        32, 17,  isndlstX14, isndlstY2, 105 , 311, 0, 5.944, 14

ihsndlstxt3		FLbox		"Save Sounds (record protect)", 1, 1, 10, 476, 20, isndlstX1, isndlstY3-19
gksav1,ihsav1		FLbutton	"1",      1, 0, 2,       32, 20, isndlstX1, isndlstY3, -105 , 2, 0, -1
gksav2,ihsav2		FLbutton	"2",      2, 0, 2,       32, 20, isndlstX2, isndlstY3, -105 , 2, 0, -1
gksav3,ihsav3		FLbutton	"3",      3, 0, 2,       32, 20, isndlstX3, isndlstY3, -105 , 2, 0, -1
gksav4,ihsav4		FLbutton	"4",      4, 0, 2,       32, 20, isndlstX4, isndlstY3, -105 , 2, 0, -1
gksav5,ihsav5		FLbutton	"5",      5, 0, 2,       32, 20, isndlstX5, isndlstY3, -105 , 2, 0, -1
gksav6,ihsav6		FLbutton	"6",      6, 0, 2,       32, 20, isndlstX6, isndlstY3, -105 , 2, 0, -1
gksav7,ihsav7		FLbutton	"7",      7, 0, 2,       32, 20, isndlstX7, isndlstY3, -105 , 2, 0, -1
gksav8,ihsav8		FLbutton	"8",      8, 0, 2,       32, 20, isndlstX8, isndlstY3, -105 , 2, 0, -1
gksav9,ihsav9		FLbutton	"9",      9, 0, 2,       32, 20, isndlstX9, isndlstY3, -105 , 2, 0, -1
gksav10,ihsav10		FLbutton	"10",    10, 0, 2,       32, 20, isndlstX10, isndlstY3, -105 , 2, 0, -1
gksav11,ihsav11		FLbutton	"11",    11, 0, 2,       32, 20, isndlstX11, isndlstY3, -105 , 2, 0, -1
gksav12,ihsav12		FLbutton	"12",    12, 0, 2,       32, 20, isndlstX12, isndlstY3, -105 , 2, 0, -1
gksav13,ihsav13		FLbutton	"13",    13, 0, 2,       32, 20, isndlstX13, isndlstY3, -105 , 2, 0, -1
gksav14,ihsav14		FLbutton	"14",    14, 0, 2,       32, 20, isndlstX14, isndlstY3, -105 , 2, 0, -1

ihsndlstxt4		FLbox		"Hide Sounds (don't use)", 1, 1, 10, 476, 20, isndlstX1, isndlstY4-19
gkhide1,ihhide1		FLbutton	"1",    1, 0, 2,       32, 20, isndlstX1, isndlstY4, -105 , 2, 0, -1
gkhide2,ihhide2		FLbutton	"2",    2, 0, 2,       32, 20, isndlstX2, isndlstY4, -105 , 2, 0, -1
gkhide3,ihhide3		FLbutton	"3",    3, 0, 2,       32, 20, isndlstX3, isndlstY4, -105 , 2, 0, -1
gkhide4,ihhide4		FLbutton	"4",    4, 0, 2,       32, 20, isndlstX4, isndlstY4, -105 , 2, 0, -1
gkhide5,ihhide5		FLbutton	"5",    5, 0, 2,       32, 20, isndlstX5, isndlstY4, -105 , 2, 0, -1
gkhide6,ihhide6		FLbutton	"6",    6, 0, 2,       32, 20, isndlstX6, isndlstY4, -105 , 2, 0, -1
gkhide7,ihhide7		FLbutton	"7",    7, 0, 2,       32, 20, isndlstX7, isndlstY4, -105 , 2, 0, -1
gkhide8,ihhide8		FLbutton	"8",    8, 0, 2,       32, 20, isndlstX8, isndlstY4, -105 , 2, 0, -1
gkhide9,ihhide9		FLbutton	"9",    9, 0, 2,       32, 20, isndlstX9, isndlstY4, -105 , 2, 0, -1
gkhide10,ihhide10	FLbutton	"10",  10, 0, 2,       32, 20, isndlstX10, isndlstY4, -105 , 2, 0, -1
gkhide11,ihhide11	FLbutton	"11",  11, 0, 2,       32, 20, isndlstX11, isndlstY4, -105 , 2, 0, -1
gkhide12,ihhide12	FLbutton	"12",  12, 0, 2,       32, 20, isndlstX12, isndlstY4, -105 , 2, 0, -1
gkhide13,ihhide13	FLbutton	"13",  13, 0, 2,       32, 20, isndlstX13, isndlstY4, -105 , 2, 0, -1
gkhide14,ihhide14	FLbutton	"14",  14, 0, 2,       32, 20, isndlstX14, isndlstY4, -105 , 2, 0, -1

ihsndlstxt5		FLbox		"Clear Sounds", 1, 1, 10, 476, 20, isndlstX1, isndlstY5-19
gkclear1,ihclear1	FLbutton	"1",     1, 0, 11,        32, 17,  isndlstX1, isndlstY5, 105 , 201, 0, 0.1, 1
gkclear2,ihclear2	FLbutton	"2",     1, 0, 11,        32, 17,  isndlstX2, isndlstY5, 105 , 201, 0, 0.1, 2
gkclear3,ihclear3	FLbutton	"3",     1, 0, 11,        32, 17,  isndlstX3, isndlstY5, 105 , 201, 0, 0.1, 3
gkclear4,ihclear4	FLbutton	"4",     1, 0, 11,        32, 17,  isndlstX4, isndlstY5, 105 , 201, 0, 0.1, 4
gkclear5,ihclear5	FLbutton	"5",     1, 0, 11,        32, 17,  isndlstX5, isndlstY5, 105 , 201, 0, 0.1, 5
gkclear6,ihclear6	FLbutton	"6",     1, 0, 11,        32, 17,  isndlstX6, isndlstY5, 105 , 201, 0, 0.1, 6
gkclear7,ihclear7	FLbutton	"7",     1, 0, 11,        32, 17,  isndlstX7, isndlstY5, 105 , 201, 0, 0.1, 7
gkclear8,ihclear8	FLbutton	"8",     1, 0, 11,        32, 17,  isndlstX8, isndlstY5, 105 , 201, 0, 0.1, 8
gkclear9,ihclear9	FLbutton	"9",     1, 0, 11,        32, 17,  isndlstX9, isndlstY5, 105 , 201, 0, 0.1, 9
gkclear10,ihclear10	FLbutton	"10",    1, 0, 11,        32, 17,  isndlstX10, isndlstY5, 105 , 201, 0, 0.1, 10
gkclear11,ihclear11	FLbutton	"11",    1, 0, 11,        32, 17,  isndlstX11, isndlstY5, 105 , 201, 0, 0.1, 11
gkclear12,ihclear12	FLbutton	"12",    1, 0, 11,        32, 17,  isndlstX12, isndlstY5, 105 , 201, 0, 0.1, 12
gkclear13,ihclear13	FLbutton	"13",    1, 0, 11,        32, 17,  isndlstX13, isndlstY5, 105 , 201, 0, 0.1, 13
gkclear14,ihclear14	FLbutton	"14",    1, 0, 11,        32, 17,  isndlstX14, isndlstY5, 105 , 201, 0, 0.1, 14


;***************************************
			FLlabel		-1
			FLlabel  	10, 1, 6, 0, 0, 0
ihbxMixer		FLbox		"Mixer",	5, 1, 12,		490, 325,   5, 380
			FLsetAlign	2, ihbxMixer

			FLtabs		486, 321,   7, 382

#define MixFader(A'B'C'D) #
imX$A.offset		= ($A. > 5 ? 80*($A.-6) : 80*($A.-1) )			; two rows of mixer modules, 5 in each row
imX$A.			=  12 + imX$A.offset
imY$A.			= 420 + $B.
ihbx$C.mix		FLbox		"$C.",	5, 1, 10,		 	 74, 130,  imX$A.,    imY$A.
			FLsetAlign	2, ihbx$C.mix
gkbt$C.On,ihbt$C.On 	FLbutton	"On",		1, 0, 2,		 42,  20,  imX$A.+9,  imY$A.+4, -1, -1 
			FLsetAlign	1, ihbt$C.On
gk$C._pan,ih$C._pan	FLknob		"Pan", 	0, 1, 0, 3, -1,			 20,       imX$A.+20, imY$A.+30
ihval$C.amp		FLvalue		" ", 					 38,  15,  imX$A.+11,  imY$A.+110
gks$C.amp,ihs$C.amp	FLknob          " ", 	0, 2, 0, 1, ihval$C.amp,		 42, 	   imX$A.+9,  imY$A.+63
gks$C.ampD,gihs$C.ampD	FLslider        " ", 	0, 30000, 0, 2 , -1,	 	 10, 121,  imX$A.+55, imY$A.+4
			FLsetColor 	 80, 150, 50,  gihs$C.ampD
			FLsetColor2 	230, 50,  30,  gihs$C.ampD
			
			FLsetVal_i	$D.,	ih$C._pan
			FLsetVal_i	1,	ihs$C.amp
#

			FLgroup		"Levels ",  475, 305, 10,  400

$MixFader.(1'0'Rplay1'0.35)
$MixFader.(2'0'Rplay2'0.75)
$MixFader.(3'0'Grain1'0.20)
$MixFader.(4'0'Grain2'0.80)
$MixFader.(5'0'Grain3'0.15)
$MixFader.(6'150'Grain4'0.85)
$MixFader.(7'150'RAG'0.3)
$MixFader.(8'150'Pad'0.6)
$MixFader.(9'150'PtSeq'0.5)
$MixFader.(10'150'Loop'0.5)

;Master Volume and VU:
iMstX 			= 412
iMstY 			= 570
ihbxMastermix		FLbox		"Master", 5, 1, 10,		 	 74,  15,  iMstX,    iMstY-15
ihvalMasteramp		FLvalue		" ", 					 35,  15,  iMstX+3,  iMstY+110
gksMastamp,gihsMastamp	FLknob	        " ", 	0, 2, 0, 2, ihvalMasteramp, 	 35,	   iMstX+3,  iMstY+65
gksMLampD,gihsMLampD	FLslider        " ", 	0, 30000, 0, 2 , -1,	 	 10, 121,  iMstX+42, iMstY+4
gksMRampD,gihsMRampD	FLslider        " ", 	0, 30000, 0, 2 , -1,	 	 10, 121,  iMstX+55, iMstY+4
			FLsetColor 	 80, 150, 50,  	gihsMLampD
			FLsetColor 	 80, 150, 50,  	gihsMRampD
			FLsetColor2 	230, 50,  30,  	gihsMLampD
			FLsetColor2 	230, 50,  30,  	gihsMRampD
			FLsetColor2 	 80, 20,  20,  	gihsMastamp
			FLsetVal_i	1,		gihsMastamp

			FLlabel		-1
			FLlabel  	10, 1, 1, 0, 0, 0

iPreX			= 417
iPreY			= 420
gkPresN,ihPresN		FLcount		"Preset",	 0, 50, 1, 2, 1,  70, 20, iPreX, iPreY,     -1, -1
			FLsetAlign	2,	ihPresN
gkPreStor,ihPreStor	FLbutton	"Store",	11, 0, 11,        70, 20, iPreX, iPreY+30,  0 , 270, 0, 0
gkPreRead,ihPreRead	FLbutton	"Recall", 	11, 0, 11,        70, 20, iPreX, iPreY+50,  0 , 271, 0, 0
gkPreSav,ihPreSav	FLbutton	"SaveSet", 	11, 0, 11,        70, 20, iPreX, iPreY+80,  0 , 272, 0, 0
gkPreOpn,ihPreOpn	FLbutton	"OpenSet", 	11, 0, 11,        70, 20, iPreX, iPreY+100, 0 , 273, 0, 0

			FLgroupEnd

; *************************
#define EfxFader(A'B) #
imX1			= 12
imY1			= 600
ihbx$A.mix		FLbox		"$A.",	5, 1, 10,		 	 74, 100,  imX1,    imY1
			FLsetAlign	2, ihbx$A.mix
gkpan$A.,ihpan$A.		FLknob		"Pan", 	0, 1, 0, 3, -1,			 20,       imX1+20, imY1+4
ihval$A.mix		FLvalue		" ", 					 38,  15,  imX1+11, imY1+80
gks$A.amp,ihs$A.amp	FLknob          " ", 	0, 2, 0, 1, ihval$A.mix,		 42,  	   imX1+9,  imY1+35
gks$A.ampD,gihs$A.ampD	FLslider        " ", 	0, 30000, 0, 2, -1,	 	 10, 91,  imX1+55, imY1+4
			FLsetColor 	 80, 150, 50,  gihs$A.ampD
			FLsetColor2 	230, 50,  30,  gihs$A.ampD
			FLsetVal_i	$B.,	ihpan$A.
			FLsetVal_i	1,	ihs$A.amp
#

;four buttons side by side
iefxX1			= 92
iefxX2_4		= iefxX1 + 98
iefxX3_4		= iefxX2_4 + 98
iefxX4_4		= iefxX3_4 + 98

;five buttons side by side
iefxX2_5		= iefxX1 + 79
iefxX3_5		= iefxX2_5 + 79
iefxX4_5		= iefxX3_5 + 79
iefxX5_5		= iefxX4_5 + 79

;six buttons side by side
iefxX2_6		= iefxX1 + 66
iefxX3_6		= iefxX2_6 + 66
iefxX4_6		= iefxX3_6 + 66
iefxX5_6		= iefxX4_6 + 66
iefxX6_6		= iefxX5_6 + 66

;eight buttons side by side
iefxX2_8		= iefxX1 + 50
iefxX3_8		= iefxX2_8 + 50
iefxX4_8		= iefxX3_8 + 50
iefxX5_8		= iefxX4_8 + 50
iefxX6_8		= iefxX5_8 + 50
iefxX7_8		= iefxX6_8 + 50
iefxX8_8		= iefxX7_8 + 50

; Y - rows of buttons
iefxY1			= 420
iefxY1V			= iefxY1 + 45
iefxY2			= iefxY1 + 90
iefxY2V			= iefxY2 + 45

;efx send buttons
ifxknobsize	= 40
ifxvaly1	= 680
ifxknoby1	= 625

			FLgroup		"RingMod",  475, 305, 10, 400
			FLlabel  	10, 1, 2, 0, 0, 0

$EfxFader.(RngMod'0.35)
ih1101			FLvalue		" ", 40, 15, iefxX1,   iefxY1V
ih1102			FLvalue		" ", 40, 15, iefxX2_5, iefxY1V
ih1103			FLvalue		" ", 40, 15, iefxX3_5, iefxY1V
ih1104			FLvalue		" ", 40, 15, iefxX4_5, iefxY1V
ih1105			FLvalue		" ", 40, 15, iefxX5_5, iefxY1V

gkfx_rm_mfrq,ih1151 	FLknob		"Mod Freq", 	    1, 5000, -1, 1, ih1101, 40, iefxX1,   iefxY1
gkfx_rm_mndx,ih1152 	FLknob		"Mod indx", 	    0, 1,     0, 1, ih1102, 40, iefxX2_5, iefxY1
gkfx_rm_lfrq,ih1153 	FLknob		"LFO Freq", 	    0.01, 20,-1, 1, ih1103, 40, iefxX3_5, iefxY1
gkfx_rm_lamt,ih1154 	FLknob		"LFO amt", 	    0, 2,     0, 1, ih1104, 40, iefxX4_5, iefxY1
gkfx_rm_afrq,ih1155 	FLknob		"Amp -> Freq", 	   -1, 3,     0, 1, ih1105, 40, iefxX5_5, iefxY1

			FLsetAlign	 2, ih1151
			FLsetAlign	 2, ih1152
			FLsetAlign	 2, ih1153
			FLsetAlign	 2, ih1154
			FLsetAlign	 2, ih1155
			FLsetVal_i 	20, ih1151
			FLsetVal_i 	 1, ih1152
			FLsetVal_i 	 1, ih1153
			FLsetVal_i 	 0, ih1154
			FLsetVal_i 	 0, ih1155


ihF1141			FLbox		"Effect Sends", 5, 1 , 11, 392, 17, iefxX1, ifxknoby1-25

ihF1101			FLvalue		" ", 40, 17, iefxX1,   ifxvaly1
ihF1103			FLvalue		" ", 40, 17, iefxX2_8, ifxvaly1
ihF1104			FLvalue		" ", 40, 17, iefxX3_8, ifxvaly1
ihF1105			FLvalue		" ", 40, 17, iefxX4_8, ifxvaly1
ihF1106			FLvalue		" ", 40, 17, iefxX5_8, ifxvaly1
ihF1107			FLvalue		" ", 40, 17, iefxX6_8, ifxvaly1
ihF1108			FLvalue		" ", 40, 17, iefxX7_8, ifxvaly1
ihF1109			FLvalue		" ", 40, 17, iefxX8_8, ifxvaly1

gkfx_rm_dry,ihF1111	FLknob		"Dry",  	    0, 1, 0, 1, ihF1101, ifxknobsize, iefxX1,   ifxknoby1
gkfx_rm_fm,ihF1113	FLknob		"FreqMod", 	    0, 1, 0, 1, ihF1103, ifxknobsize, iefxX2_8, ifxknoby1
gkfx_rm_flt1,ihF1114	FLknob		"Filter1", 	    0, 1, 0, 1, ihF1104, ifxknobsize, iefxX3_8, ifxknoby1
gkfx_rm_dist,ihF1115	FLknob		"Distortion", 	    0, 1, 0, 1, ihF1105, ifxknobsize, iefxX4_8, ifxknoby1
gkfx_rm_flt2,ihF1116	FLknob		"Filter2", 	    0, 1, 0, 1, ihF1106, ifxknobsize, iefxX5_8, ifxknoby1
gkfx_rm_dly1,ihF1117	FLknob		"Delay1", 	    0, 1, 0, 1, ihF1107, ifxknobsize, iefxX6_8, ifxknoby1
gkfx_rm_dly2,ihF1118	FLknob		"Delay2", 	    0, 1, 0, 1, ihF1108, ifxknobsize, iefxX7_8, ifxknoby1
gkfx_rm_rvb,ihF1119	FLknob		"Reverb", 	    0, 1, 0, 1, ihF1109, ifxknobsize, iefxX8_8, ifxknoby1

			FLsetVal_i 	1, 	ihF1111
			FLsetVal_i 	0, 	ihF1113
			FLsetVal_i 	0, 	ihF1114
			FLsetVal_i 	0.1, 	ihF1115
			FLsetVal_i 	0, 	ihF1116
			FLsetVal_i 	0, 	ihF1117
			FLsetVal_i 	0, 	ihF1118

		FLgroupEnd
; *************************
			FLgroup		"FreqMod",  475, 305, 10, 400

$EfxFader.(FrqMod'0.70)
ih1201			FLvalue		" ", 40, 15, iefxX1,   iefxY1V
ih1202			FLvalue		" ", 40, 15, iefxX2_5, iefxY1V
ih1203			FLvalue		" ", 40, 15, iefxX3_5, iefxY1V
ih1204			FLvalue		" ", 40, 15, iefxX4_5, iefxY1V
ih1205			FLvalue		" ", 40, 15, iefxX5_5, iefxY1V

gkfx_fm_mfrq,ih1251 	FLknob		"Mod Freq", 	    1, 5000, -1, 1, ih1201, 40, iefxX1,   iefxY1
gkfx_fm_mndx,ih1252 	FLknob		"Mod indx", 	 0.01, 0.4,  -1, 1, ih1202, 40, iefxX2_5, iefxY1
gkfx_fm_lfrq,ih1253 	FLknob		"LFO Freq", 	    0.01, 20,-1, 1, ih1203, 40, iefxX3_5, iefxY1
gkfx_fm_lamt,ih1254 	FLknob		"LFO amt", 	    0, 2,     0, 1, ih1204, 40, iefxX4_5, iefxY1
gkfx_fm_afrq,ih1255 	FLknob		"Amp -> Freq", 	   -1, 3,     0, 1, ih1205, 40, iefxX5_5, iefxY1

			FLsetAlign	   2, ih1251
			FLsetAlign	   2, ih1252
			FLsetAlign	   2, ih1253
			FLsetAlign	   2, ih1254
			FLsetAlign	   2, ih1255
			FLsetVal_i 	 400, ih1251
			FLsetVal_i 	0.03, ih1252
			FLsetVal_i 	   1, ih1253
			FLsetVal_i 	   0, ih1254
			FLsetVal_i 	   3, ih1255

ihF1241			FLbox		"Effect Sends", 5, 1 , 11, 392, 17, iefxX1, ifxknoby1-25

ihF1201			FLvalue		" ", 40, 17, iefxX1,   ifxvaly1
ihF1203			FLvalue		" ", 40, 17, iefxX3_8, ifxvaly1
ihF1204			FLvalue		" ", 40, 17, iefxX4_8, ifxvaly1
ihF1205			FLvalue		" ", 40, 17, iefxX5_8, ifxvaly1
ihF1206			FLvalue		" ", 40, 17, iefxX6_8, ifxvaly1
ihF1207			FLvalue		" ", 40, 17, iefxX7_8, ifxvaly1
ihF1208			FLvalue		" ", 40, 17, iefxX8_8, ifxvaly1


gkfx_fm_dry,ihF1211	FLknob		"Dry",  	    0, 1, 0, 1, ihF1201, ifxknobsize, iefxX1,   ifxknoby1
gkfx_fm_flt1,ihF1213	FLknob		"Filter1", 	    0, 1, 0, 1, ihF1203, ifxknobsize, iefxX3_8, ifxknoby1
gkfx_fm_dist,ihF1214	FLknob		"Distortion", 	    0, 1, 0, 1, ihF1204, ifxknobsize, iefxX4_8, ifxknoby1
gkfx_fm_flt2,ihF1215	FLknob		"Filter2", 	    0, 1, 0, 1, ihF1205, ifxknobsize, iefxX5_8, ifxknoby1
gkfx_fm_dly1,ihF1216	FLknob		"Delay1", 	    0, 1, 0, 1, ihF1206, ifxknobsize, iefxX6_8, ifxknoby1
gkfx_fm_dly2,ihF1217	FLknob		"Delay2", 	    0, 1, 0, 1, ihF1207, ifxknobsize, iefxX7_8, ifxknoby1
gkfx_fm_rvb,ihF1218	FLknob		"Reverb", 	    0, 1, 0, 1, ihF1208, ifxknobsize, iefxX8_8, ifxknoby1

			FLsetVal_i 	0.3, 	ihF1211
			FLsetVal_i 	0, 	ihF1213
			FLsetVal_i 	0, 	ihF1214
			FLsetVal_i 	0, 	ihF1215
			FLsetVal_i 	0, 	ihF1216
			FLsetVal_i 	0, 	ihF1217
			FLsetVal_i 	0.25, 	ihF1218

		FLgroupEnd
; *************************
			FLgroup		"Filter 1", 475, 305, 10, 400

$EfxFader.(Filt1'0.40)
ih1301			FLvalue		" ", 40, 15, iefxX1,   iefxY1V
ih1302			FLvalue		" ", 40, 15, iefxX2_5, iefxY1V
ih1303			FLvalue		" ", 40, 15, iefxX3_5, iefxY1V
ih1304			FLvalue		" ", 40, 15, iefxX4_5, iefxY1V
ih1305			FLvalue		" ", 40, 15, iefxX5_5, iefxY1V

gkfx_f1_cfrq,ih1351 	FLknob		"Cutoff Freq", 	    10, 8000,-1, 1, ih1301, 40, iefxX1,   iefxY1
gkfx_f1_q,ih1352 	FLknob		"Filter Q", 	  0.01, 1,   -1, 1, ih1302, 40, iefxX2_5, iefxY1
gkfx_f1_lp,ih1353 	FLknob		"Amp LP", 	  0.01, 1,    0, 1, ih1303, 40, iefxX3_5, iefxY1
gkfx_f1_bp,ih1354 	FLknob		"Amp BP", 	  0.01, 1,    0, 1, ih1304, 40, iefxX4_5, iefxY1
gkfx_f1_hp,ih1355 	FLknob		"Amp HP", 	  0.01, 1,    0, 1, ih1305, 40, iefxX5_5, iefxY1

			FLsetAlign	2, 	ih1351
			FLsetAlign	2, 	ih1352
			FLsetAlign	2, 	ih1353
			FLsetAlign	2, 	ih1354
			FLsetAlign	2, 	ih1355
			FLsetVal_i 	500, 	ih1351
			FLsetVal_i 	0.03, 	ih1352
			FLsetVal_i 	0, 	ih1353
			FLsetVal_i 	1, 	ih1354
			FLsetVal_i 	0.7, 	ih1355

ih1306			FLvalue		" ", 40, 15, iefxX1,   iefxY2V
ih1307			FLvalue		" ", 40, 15, iefxX2_5, iefxY2V
ih1308			FLvalue		" ", 40, 15, iefxX3_5, iefxY2V

gkfx_f1_lfrq,ih1356 	FLknob		"LFO Freq", 	    0.01, 20,-1, 1, ih1306, 40, iefxX1,   iefxY2
gkfx_f1_lamt,ih1357 	FLknob		"LFO amt", 	    0, 2,     0, 1, ih1307, 40, iefxX2_5, iefxY2
gkfx_f1_afrq,ih1358 	FLknob		"Amp -> Freq", 	   -1, 3,     0, 1, ih1308, 40, iefxX3_5, iefxY2

			FLsetAlign	2, 	ih1356
			FLsetAlign	2, 	ih1357
			FLsetAlign	2, 	ih1358
			FLsetVal_i 	0.2, 	ih1356
			FLsetVal_i 	0.3, 	ih1357
			FLsetVal_i 	3, 	ih1358

ihF1341			FLbox		"Effect Sends", 5, 1 , 11, 392, 17, iefxX1, ifxknoby1-25

ihF1301			FLvalue		" ", 40, 17, iefxX1,   ifxvaly1
ihF1304			FLvalue		" ", 40, 17, iefxX4_8, ifxvaly1
ihF1305			FLvalue		" ", 40, 17, iefxX5_8, ifxvaly1
ihF1306			FLvalue		" ", 40, 17, iefxX6_8, ifxvaly1
ihF1307			FLvalue		" ", 40, 17, iefxX7_8, ifxvaly1
ihF1308			FLvalue		" ", 40, 17, iefxX8_8, ifxvaly1

gkfx_f1_dry,ihF1311	FLknob		"Dry",  	    0, 1, 0, 1, ihF1301, ifxknobsize, iefxX1,   ifxknoby1
gkfx_f1_dist,ihF1314	FLknob		"Distortion", 	    0, 1, 0, 1, ihF1304, ifxknobsize, iefxX4_8, ifxknoby1
gkfx_f1_flt2,ihF1315	FLknob		"Filter2", 	    0, 1, 0, 1, ihF1305, ifxknobsize, iefxX5_8, ifxknoby1
gkfx_f1_dly1,ihF1316	FLknob		"Delay1", 	    0, 1, 0, 1, ihF1306, ifxknobsize, iefxX6_8, ifxknoby1
gkfx_f1_dly2,ihF1317	FLknob		"Delay2", 	    0, 1, 0, 1, ihF1307, ifxknobsize, iefxX7_8, ifxknoby1
gkfx_f1_rvb,ihF1318	FLknob		"Reverb", 	    0, 1, 0, 1, ihF1308, ifxknobsize, iefxX8_8, ifxknoby1

			FLsetVal_i 	1, 	ihF1311
			FLsetVal_i 	0, 	ihF1314
			FLsetVal_i 	0, 	ihF1315
			FLsetVal_i 	0, 	ihF1316
			FLsetVal_i 	0.6, 	ihF1317
			FLsetVal_i 	0, 	ihF1318

		FLgroupEnd
; *************************

			FLgroup		"Distortion", 475, 305, 10, 400

$EfxFader.(Dist'0.40)
ih1401			FLvalue		" ", 40, 15, iefxX1,   iefxY1V
ih1402			FLvalue		" ", 40, 15, iefxX2_5, iefxY1V
ih1403			FLvalue		" ", 40, 15, iefxX3_5, iefxY1V
ih1404			FLvalue		" ", 40, 15, iefxX4_5, iefxY1V

gkfx_ds_drv,ih1451 	FLknob		"Dist Drive", 	    1, 50,   -1, 1, ih1401, 40, iefxX1,   iefxY1
gkfx_ds_shp,ih1452 	FLknob		"Dist Shape", 	    0, 2,     0, 1, ih1402, 40, iefxX2_5, iefxY1
gkfx_ds_pflt,ih1453 	FLknob		"Post Filter", 	   20, 16000, 0, 1, ih1403, 40, iefxX3_5, iefxY1
gkfx_ds_adrv,ih1454 	FLknob		"Amp -> Drive",    -20, 20,   0, 1, ih1404, 40, iefxX4_5, iefxY1

			FLsetAlign	2, 	ih1451
			FLsetAlign	2, 	ih1452
			FLsetAlign	2, 	ih1453
			FLsetAlign	2, 	ih1454
			FLsetVal_i 	5, 	ih1451
			FLsetVal_i 	0.14, 	ih1452
			FLsetVal_i 	9000,	ih1453
			FLsetVal_i 	10, 	ih1454

ihF1441			FLbox		"Effect Sends", 5, 1 , 11, 392, 17, iefxX1, ifxknoby1-25

ihF1401			FLvalue		" ", 40, 17, iefxX1,   ifxvaly1
ihF1405			FLvalue		" ", 40, 17, iefxX5_8, ifxvaly1
ihF1406			FLvalue		" ", 40, 17, iefxX6_8, ifxvaly1
ihF1407			FLvalue		" ", 40, 17, iefxX7_8, ifxvaly1
ihF1408			FLvalue		" ", 40, 17, iefxX8_8, ifxvaly1

gkfx_ds_dry,ihF1411	FLknob		"Dry",  	    0, 1, 0, 1, ihF1401, ifxknobsize, iefxX1,   ifxknoby1
gkfx_ds_flt2,ihF1415	FLknob		"Filter2", 	    0, 1, 0, 1, ihF1405, ifxknobsize, iefxX5_8, ifxknoby1
gkfx_ds_dly1,ihF1416	FLknob		"Delay1", 	    0, 1, 0, 1, ihF1406, ifxknobsize, iefxX6_8, ifxknoby1
gkfx_ds_dly2,ihF1417	FLknob		"Delay2", 	    0, 1, 0, 1, ihF1407, ifxknobsize, iefxX7_8, ifxknoby1
gkfx_ds_rvb,ihF1418	FLknob		"Reverb", 	    0, 1, 0, 1, ihF1408, ifxknobsize, iefxX8_8, ifxknoby1

			FLsetVal_i 	1, 	ihF1411
			FLsetVal_i 	0, 	ihF1415
			FLsetVal_i 	0, 	ihF1416
			FLsetVal_i 	0.3, 	ihF1417
			FLsetVal_i 	0, 	ihF1418

		FLgroupEnd
; *************************
			FLgroup		"Filter 2",  475, 305, 10, 400

$EfxFader.(Filt2'0.40)
ih1501			FLvalue		" ", 40, 15, iefxX1,   iefxY1V
ih1502			FLvalue		" ", 40, 15, iefxX2_6, iefxY1V
ih1503			FLvalue		" ", 40, 15, iefxX3_6, iefxY1V
ih1504			FLvalue		" ", 40, 15, iefxX4_6, iefxY1V
ih1505			FLvalue		" ", 40, 15, iefxX5_6, iefxY1V
ih1506			FLvalue		" ", 40, 15, iefxX6_6, iefxY1V

gkfx_f2_cfrq,ih1551 	FLknob		"Cutoff Freq", 	    20, 8000,-1, 1, ih1501, 40, iefxX1,   iefxY1
gkfx_f2_res,ih1552 	FLknob		"Resonance", 	    0.1,   1, 0, 1, ih1502, 40, iefxX2_6, iefxY1
gkfx_f2_dst,ih1553 	FLknob		"Distortion", 	    0,    20, 0, 1, ih1503, 40, iefxX3_6, iefxY1
gkfx_f2_lfrq,ih1554 	FLknob		"LFO Freq", 	    0.01,20, -1, 1, ih1504, 40, iefxX4_6, iefxY1
gkfx_f2_lamt,ih1555 	FLknob		"LFO amt", 	    0,   2,   0, 1, ih1505, 40, iefxX5_6, iefxY1
gkfx_f2_afrq,ih1556 	FLknob		"Amp -> Freq", 	   -1,   3,   0, 1, ih1506, 40, iefxX6_6, iefxY1

			FLsetAlign	2, 	ih1551
			FLsetAlign	2, 	ih1552
			FLsetAlign	2, 	ih1553
			FLsetAlign	2, 	ih1554
			FLsetAlign	2, 	ih1555
			FLsetAlign	2, 	ih1556
			FLsetVal_i 	1000, 	ih1551
			FLsetVal_i 	0.7, 	ih1552
			FLsetVal_i 	3.7, 	ih1553
			FLsetVal_i 	0.15, 	ih1554
			FLsetVal_i 	0.2, 	ih1555
			FLsetVal_i 	3, 	ih1556


ihF1541			FLbox		"Effect Sends", 5, 1 , 11, 392, 17, iefxX1, ifxknoby1-25

ihF1501			FLvalue		" ", 40, 17, iefxX1,   ifxvaly1
ihF1506			FLvalue		" ", 40, 17, iefxX6_8, ifxvaly1
ihF1507			FLvalue		" ", 40, 17, iefxX7_8, ifxvaly1
ihF1508			FLvalue		" ", 40, 17, iefxX8_8, ifxvaly1

gkfx_f2_dry,ihF1511	FLknob		"Dry",  	    0, 1, 0, 1, ihF1501, ifxknobsize, iefxX1,   ifxknoby1
gkfx_f2_dly1,ihF1516	FLknob		"Delay1", 	    0, 1, 0, 1, ihF1506, ifxknobsize, iefxX6_8, ifxknoby1
gkfx_f2_dly2,ihF1517	FLknob		"Delay2", 	    0, 1, 0, 1, ihF1507, ifxknobsize, iefxX7_8, ifxknoby1
gkfx_f2_rvb,ihF1518	FLknob		"Reverb", 	    0, 1, 0, 1, ihF1508, ifxknobsize, iefxX8_8, ifxknoby1

			FLsetVal_i 	1, 	ihF1511
			FLsetVal_i 	0.25, 	ihF1516
			FLsetVal_i 	0, 	ihF1517
			FLsetVal_i 	0, 	ihF1518

		FLgroupEnd
; *************************

; *************************

#define DelayEfx(A'G'H'I'J'K'L'M) #
;ARGS: delaymodule number, subdivL, straightdotL, subdivR, strdtR, fineL, fineR,
; LfoFq, LfoAmtL, LfoAmtR, Feedback, FeedbackFiltFreq

			FLlabel  	-1
			FLlabel  	10, 1, 1, 0, 0, 0

ihDel$A.2b		FLbox		"Tempofactor",  1, 1, 10, 	   74, 15,  imX1, iefxY1-15
gkfx_d$A.2b,ihDel$A.2	FLbutBank	2,  1,  8, 			   74, 130,  imX1, iefxY1, -105, -1

gkfx_d$A._unl,ihDel$A.10 	FLbutton	"Unlink",	    1, 0, 2,	   74, 20, imX1, iefxY1+135, -1, -1 

ihDel$A.0a		FLbox		"deltime subdiv (2, 4, 8, 16)", 1, 1, 10,  180, 15, iefxX1+20,  iefxY1-15
ihDel$A.0b		FLbox		"straight/dotted/triplet", 1, 1, 10, 	   140, 15, iefxX1+210, iefxY1-15
ihDel$A.0c		FLbox		"delaytime", 		   1, 1, 10, 	    45, 15, iefxX1+345, iefxY1-15
ihDel$A.0d		FLbox		"L", 			   1, 1, 10, 	    20, 18, iefxX1,     iefxY1
ihDel$A.0e		FLbox		"R", 			   1, 1, 10, 	    20, 18, iefxX1,     iefxY1+25

gkfx_d$A.1a,ihDel$A.1a	FLbutBank	2,  4,  1,			   180, 18, iefxX1+20,  iefxY1, -105, -1

gkfx_d$A.1b,ihDel$A.1b	FLbutBank	2,  3,  1, 			   130, 18, iefxX1+210, iefxY1, -105, -1

gkfx_d$A.1c,ihDel$A.1c	FLbutBank	2,  4,  1, 			   180, 18, iefxX1+20,  iefxY1+25, -105, -1

gkfx_d$A.1d,ihDel$A.1d	FLbutBank	2,  3,  1, 			   130, 18, iefxX1+210, iefxY1+25, -105, -1


gihDel$A.timL		FLvalue		" ", 				    45, 18, iefxX1+345, iefxY1
gihDel$A.timR		FLvalue		" ", 				    45, 18, iefxX1+345, iefxY1+25

			FLlabel  	-1
			FLlabel  	10, 1, 2, 0, 0, 0

ihDel$A.3v		FLvalue		" ", 40, 17, iefxX1+20,   iefxY2V		; deltime fine L
ihDel$A.4v		FLvalue		" ", 40, 17, iefxX2_5+20, iefxY2V		; deltime fine R
ihDel$A.5v		FLvalue		" ", 40, 17, iefxX3_5+20, iefxY2V
ihDel$A.6v		FLvalue		" ", 40, 17, iefxX4_5+20, iefxY2V
ihDel$A.7v		FLvalue		" ", 40, 17, iefxX5_5+20, iefxY2V

ihDel$A.8v		FLvalue		" ", 40, 17,  iefxX1+20,   ifxvaly1
ihDel$A.9v		FLvalue		" ", 40, 17,  iefxX2_5+20, ifxvaly1

gkfx_d$A._timfL,ihDel$A.3	FLknob		"time fine L",     -0.2, 0.2,   0, 1, ihDel$A.3v, 40, iefxX1+20,   iefxY2
gkfx_d$A._timfR,ihDel$A.4	FLknob		"time fine R",     -0.2, 0.2,   0, 1, ihDel$A.4v, 40, iefxX2_5+20, iefxY2
gkfx_d$A._lfrq,ihDel$A.5 	FLknob		"LFO Freq", 	    0.01, 5,   -1, 1, ihDel$A.5v, 40, iefxX3_5+20, iefxY2
gkfx_d$A._lamtL,ihDel$A.6	FLknob		"LFO amtL", 	   -0.2, 0.2,   0, 1, ihDel$A.6v, 40, iefxX4_5+20, iefxY2
gkfx_d$A._lamtR,ihDel$A.7	FLknob		"LFO amtR", 	   -0.2, 0.2,   0, 1, ihDel$A.7v, 40, iefxX5_5+20, iefxY2

gkfx_d$A._fb,ihDel$A.8 	FLknob		"Feedback", 	    0, 1,       0, 1, ihDel$A.8v, 40, iefxX1+20,   ifxknoby1
gkfx_d$A._flt,ihDel$A.9 	FLknob		"Fb Filter",      0, 10000,     0, 1, ihDel$A.9v, 40, iefxX2_5+20, ifxknoby1

			FLsetAlign	2, 	ihDel$A.3
			FLsetAlign	2, 	ihDel$A.4
			FLsetAlign	2, 	ihDel$A.5
			FLsetAlign	2, 	ihDel$A.6
			FLsetAlign	2, 	ihDel$A.7
			FLsetAlign	2, 	ihDel$A.8
			FLsetAlign	2, 	ihDel$A.9
			FLsetAlign	1, 	ihDel$A.10
			FLsetVal_i 	$G.,	ihDel$A.3
			FLsetVal_i 	$H.,	ihDel$A.4
			FLsetVal_i 	$I., 	ihDel$A.5
			FLsetVal_i 	$J., 	ihDel$A.6
			FLsetVal_i 	$K., 	ihDel$A.7
			FLsetVal_i 	$L., 	ihDel$A.8
			FLsetVal_i 	$M, 	ihDel$A.9


ihFDel$A.1bx		FLbox		"Effect Sends", 5, 1 , 11, 140, 17, iefxX6_8, ifxknoby1-25

ihFDel$A.1v		FLvalue		" ", 40, 17, iefxX6_8, ifxvaly1
ihFDel$A.7v		FLvalue		" ", 40, 17, iefxX7_8, ifxvaly1
ihFDel$A.8v		FLvalue		" ", 40, 17, iefxX8_8, ifxvaly1

gkfx_d$A._dry,ihFDel$A.1	FLknob		"Dry",  	    0, 1, 0, 1, ihFDel$A.1v, ifxknobsize, iefxX6_8, ifxknoby1
gkfx_d$A._dly2,ihFDel$A.7	FLknob		"Delay2", 	    0, 1, 0, 1, ihFDel$A.7v, ifxknobsize, iefxX7_8, ifxknoby1
gkfx_d$A._rvb,ihFDel$A.8	FLknob		"Reverb", 	    0, 1, 0, 1, ihFDel$A.8v, ifxknobsize, iefxX8_8, ifxknoby1

			FLsetVal_i 	1, 	ihFDel$A.1
			FLsetVal_i 	0, 	ihFDel$A.7
			FLsetVal_i 	0, 	ihFDel$A.8


#	
			FLgroup		"Delay 1",  475, 305, 10, 400
$EfxFader.(Del1'0.35)	
$DelayEfx.(1'0.005'0.006'0.12'0.003'0.001'0.4'6100)
;ARGS: delaymodule number, fineL, fineR, LfoFq, LfoAmtL, LfoAmtR, Feedback, FeedbackFiltFreq
			FLgroupEnd

			FLgroup		"Delay 2",  475, 305, 10, 400
$EfxFader.(Del2'0.65)	
$DelayEfx.(2'0.0'0.0'0.7'0'0'0.35'6000)
			FLgroupEnd

; *************************
			FLgroup		"Reverb",  475, 305, 10, 400

$EfxFader.(Revb'0.52)	

ih1801			FLvalue		" ", 40, 15, iefxX1,   iefxY1V
ih1802			FLvalue		" ", 40, 15, iefxX2_5, iefxY1V
ih1803			FLvalue		" ", 40, 15, iefxX3_5, iefxY1V
ih1804			FLvalue		" ", 40, 15, iefxX4_5, iefxY1V
ih1805			FLvalue		" ", 40, 15, iefxX5_5, iefxY1V

gkfx_rv_tim,ih1851 	FLknob		"Reverb Feedb",	  0.4, 1,   130, 1, ih1801, 40, iefxX1,   iefxY1
gkfx_rv_pdly,ih1852 	FLknob		"Pre Delay", 	0.001, 0.1,   0, 1, ih1802, 40, iefxX2_5, iefxY1
gkfx_rv_hf,ih1853 	FLknob		"HP Damp", 	    1, 15000, 0, 1, ih1803, 40, iefxX3_5, iefxY1
gkfx_rv_lf,ih1854 	FLknob		"LF Rolloff", 	    1, 1000,  0, 1, ih1804, 40, iefxX4_5, iefxY1
gkfx_rv_pmod,ih1855 	FLknob		"Pitchmod", 	    0, 4,     0, 1, ih1805, 40, iefxX5_5, iefxY1

			FLsetAlign	2, 	ih1851
			FLsetAlign	2, 	ih1852
			FLsetAlign	2, 	ih1853
			FLsetAlign	2, 	ih1854
			FLsetAlign	2, 	ih1855
			FLsetVal_i 	0.77, 	ih1851
			FLsetVal_i 	0.1, 	ih1852
			FLsetVal_i 	10000, 	ih1853
			FLsetVal_i 	140, 	ih1854
			FLsetVal_i 	0.98, 	ih1855

			FLgroupEnd
; *************************
			FLtabsEnd
			FLpanelEnd


;*******************************
	FLrun
;*******************************

;****************************************************************
; some control stuff, related to GUI
;******************************************************************
	instr 1

; Dual Theme controls

; midi control
kctrl11	ctrl7	2, 11, 0, 1	; ch, ctl, min, max 
kctrl12	ctrl7	2, 12, 0, 1	; ch, ctl, min, max
kctrl13	ctrl7	2, 13, 0, 1 	; ch, ctl, min, max

gkDTclear	init 0
gkDTclear	= (kctrl11 > 0.95 && kctrl13 < 0.05 ? 1 : 0 )	; if speed1 == max AND volume/dynamics == zero
								; then clear stored pitches
kDTclrTrig	trigger	gkDTclear, 0.5, 0
schedkwhen	kDTclrTrig, 0, 1, 381, 0, .1


gkctrl11	init 0
gkctrl12	init 0
gkctrl13	init 0
; if value has changed during last k-cycle, then write midi controller to parameter value
gkDTf1		= (gkctrl11 == kctrl11 ? gkDTf1 : kctrl11 ) 			; update only if midi controller activity is sensed
gkDTf2		= (gkctrl12 == kctrl12 ? gkDTf2 : kctrl12 ) 			; update only if midi controller activity is sensed
gkDTf3		= (gkctrl13 == kctrl13 ? gkDTf3 : kctrl13 ) 			; update only if midi controller activity is sensed
gkctrl11	= kctrl11							; update global, so as to check if value changes next k-cycle
gkctrl12	= kctrl12							; update global, so as to check if value changes next k-cycle
gkctrl13	= kctrl13							; update global, so as to check if value changes next k-cycle

k_Dtoff			= (gkDTon = 0 ? 1 : 0)
			FLsetVal	gkupdate1*k_Dtoff, 0, gihsDTampD	; reset VU when unit is turned off

kDTtrigOn	trigger		gkDTon, 0.5, 0
schedkwhen	kDTtrigOn, 0, 0, 382, 0, -1
kDTtrigOff	trigger		gkDTon, 0.5, 1
schedkwhen	kDTtrigOff, 0, 0, -382, 0, .1

;*************************************************

; WL noises instruments

; *** trigger instr events
kWLN2trigOn	trigger	gktWLN2, 0.5, 0
schedkwhen	kWLN2trigOn, 0.1, 1, 387, 0, -1		;note on
kWLN2trigOff	trigger	gktWLN2, 0.5, 1
schedkwhen	kWLN2trigOff, 0.1, 1, -387, 0, 1		;note off

kWLN3trigOn	trigger	gktWLN3, 0.5, 0
schedkwhen	kWLN3trigOn, 0.1, 1, 388, 0, -1		;note on
kWLN3trigOff	trigger	gktWLN3, 0.5, 1
schedkwhen	kWLN3trigOff, 0.1, 1, -388, 0, 1		;note off

kWLN4trigOn	trigger	gktWLN4, 0.5, 0
schedkwhen	kWLN4trigOn, 0.1, 1, 389, 0, -1		;note on
kWLN4trigOff	trigger	gktWLN4, 0.5, 1
schedkwhen	kWLN4trigOff, 0.1, 1, -389, 0, 1		;note off

kWLN5trigOn	trigger	gktWLN5, 0.5, 0
schedkwhen	kWLN5trigOn, 0.1, 1, 390, 0, -1		;note on
kWLN5trigOff	trigger	gktWLN5, 0.5, 1
schedkwhen	kWLN5trigOff, 0.1, 1, -390, 0, 1		;note off
;*************************************************

; Pitch Tracker

gkPmul1		init	2
gkPmulti1	table 	gkPmul1, 185; freq multiply factor

gkPmul2		init	2
gkPmulti2	table 	gkPmul2, 185; freq multiply factor

gkPmul3		init	2
gkPmulti3	table 	gkPmul3, 185; freq multiply factor

gkPmul4		init	2
gkPmulti4	table 	gkPmul4, 185; freq multiply factor

gkPmul5		init	2
gkPmulti5	table 	gkPmul5, 185; freq multiply factor		

;*************************************************
; Pattern Sequencer

k1short			table gkpt1fno1, 111					; point to shortest sounds table,
gkpt1fno		= (gkptrn1sht == 1 ? k1short : gkpt1fno1)		; select amongst the sortest sounds

k2short			table gkpt2fno1, 111					; point to shortest sounds table,
gkpt2fno		= (gkptrn2sht == 1 ? k2short : gkpt2fno1)		; select amongst the sortest sounds

k3short			table gkpt3fno1, 111					; point to shortest sounds table,
gkpt3fno		= (gkptrn3sht == 1 ? k3short : gkpt3fno1)		; select amongst the sortest sounds

;*************************************************
; Main Improsculpt window 
;*************************************************

; Rhythm, master
gk100trig		init 0
gk100togl		init 0
gk100togl		= gk100togl + gk100trig			; add one for each trig
gk100togl		= (gk100togl > 1 ? 0 : gk100togl)	; create toggle switch 0,1,0,1,0,1...
gk100togl_old		init 0

; update toggle, to follow if button pushed
ktrig_onR		trigger	gktR, 0.5, 0	; zero to 1 transition
ktrig_offR		trigger	gktR, 0.5, 1	; 1 to zero transition
gk100togl		= (ktrig_onR == 1 ? 1 : gk100togl)
gk100togl		= (ktrig_offR == 1 ? 0 : gk100togl)

; if value has changed during last k-cycle, then write midi controller to parameter value
gktR		= (gk100togl == gk100togl_old ? gktR : gk100togl ) 		; update only if midi controller activity is sensed
gk100togl_old	= gk100togl							; update global, so as to check if value changes next k-cycle

;*************************************************
; Tempo

gktmpo1			init 2
gktmpo1a		table		gktmpo1, 185

gkbtpoTemp		= gkbtpoT * gktmpo1a
; update tempo parameter only if GUI has been used this k-cycle, otherwise let old value pass thru
; this is useful when using other processes as e.g. taptempo to change parameters,
; without it, the GUI would always overrule the midi ctrl, 
; because of the table lookup in the transpose parameter

gkbtpoC1		init 0
gkbtpo			init 60
gkbtpo			= (gkbtpoC1 == gkbtpoTemp ? gkbtpo : gkbtpoTemp )	
gkbtpo			= (gkbtpo < 10 ? 10 : gkbtpo)				; filter out very low values
gkbtpoC1 		= gkbtpoTemp

;			FLsetVal	gkupdate1, gkbtpo, gihCurTpo

;*************************************************
; Rhythmic phrases

gktimesign		= gkTimSig+201	; time signature, points to ftable no

gk_ryt_phrase		= gkphr1N+301	; rythmic phrase select/init, points to ftable no
gk_ryt_phrase2		= gkphr2N+301	; rythmic phrase select/init, points to ftable no
gk_ryt_phrase3		= gkphr3N+301	; rythmic phrase select/init, points to ftable no

gkphr1Tpo		init 1
gkphr2Tpo		init 1
gkphr3Tpo		init 2
gk_ryt_fact1		table gkphr1Tpo, 181			; phrase tempo factor
gk_ryt_fact2		table gkphr2Tpo, 181			; phrase tempo factor
gk_ryt_fact3		table gkphr3Tpo, 181			; phrase tempo factor

;*************************************************
; R.Play

#define RPlayParameters(A) #
gkRpl$A.inv		init 2
kRpl$A.trsp		= gkRpl$A.trsp * (abs((gkRpl$A.inv*2)-2)-1)	; invert transposition factor, play sound backwards

gks$A.bypas 		= 0						; bypass off random selection of sounds, instr 312 pp.

gkRpl$A.btsp		init 7						; init to transposition factor 1
kRpl$A.pitch		table gkRpl$A.btsp + 5, 150
gkRpl$A.trspo		= kRpl$A.trsp*kRpl$A.pitch			; playback ratio, transposition factor

kRpl$A.mwav		= gkRpl$A.mwave+91				; wave select for FM
gkRpl$A.mwav		= (kRpl$A.mwav == 0 ? 93 : kRpl$A.mwav)		; set to 93 (sine) if not set otherwise

gkRpl$A.mdx		= (gkRpl$A.mndx-0.01)				; FM index, the -0.01 is to allow for the knob to have an exponential behaviour, and still have a minimum value of 0
#

$RPlayParameters(1)
$RPlayParameters(2)

;*************************************************
; Grain

#define GrainParameters(A) #
gkGrn$A.inv		init 2
gkGrn$A.trsp		= gkGrn$A.trnsp * (abs((gkGrn$A.inv*2)-2)-1)	; invert transposition factor, play sound backwards

gkGrn$A.ginv		init 2
gkGrn$A.gli		= gkGrn$A.glis * (abs((gkGrn$A.ginv*2)-2)-1)	; invert transposition factor, play sound backwards

gkGrn$A.btsp		init 7						; init to transposition factor 1
kGrn$A.btsp		table gkGrn$A.btsp + 5, 150
gkGrn$A.formT		= gkGrn$A.trsp*kGrn$A.btsp			; playback ratio, transposition factor

; update transpose parameter only if GUI has been used this k-cycle, otherwise let old value pass thru
; this is useful when using an external midi faderbox to change parameters,
; without it, the GUI would always overrule the midi ctrl, 
; because of the table lookup in the transpose parameter
gkGrn$A.form		init 1
gkGrn$A.formC1		init 0.1
gkGrn$A.form		= (gkGrn$A.formC1 == gkGrn$A.formT ? gkGrn$A.form : gkGrn$A.formT )	
gkGrn$A.formC1 		= gkGrn$A.formT

gkGrn$A.lfA		= gkGrn$A.lfoA * 0.1
gkGrn$A.rndA		= (gkGrn$A.randA-0.001) * 0.1
#

$GrainParameters(1)
$GrainParameters(2)
$GrainParameters(3)
$GrainParameters(4)

;*************************************************
; RAG

gkRAGinv		init 2
gkRAGtrsp		= gkRAGtrnsp * (abs((gkRAGinv*2)-2)-1)	; invert transposition factor, play sound backwards

gkRAGrpinv		init 2
gkRAGrpch		= gkRAGrptch * (abs((gkRAGrpinv*2)-2)-1); invert transposition factor, play sound backwards

gkRAGbtsp		init 7					; init to transposition factor 1
kRAGbtsp		table gkRAGbtsp + 5, 150
gkRAGtrspo		= gkRAGtrsp*kRAGbtsp			; playback ratio, transposition factor

;*************************************************
; Drumloops

gkButnRetrig1		= 0 					; reinit every k cycle

; instr 17 is used to set the retrig variable, 
; if instr 17 is active it will be = 1, otherwise it is = 0
kButnRetrig_on	trigger gkButnRetrig, 0.5, 0
kButnRetrig_off	trigger gkButnRetrig, 0.5, 1
schedkwhen	kButnRetrig_on,  0, 0, 17, 0, -1	; on
schedkwhen	kButnRetrig_off, 0, 0, -17, 0, .1	; off


gkDrmLopTpo		init 2		 	; drumloop speed factor initialize
gkdrumlop_ptch		table gkDrmLopTpo, 180	; drumloop speed/transposition factor

;*************************************************
; Mixer

#define MixParameters(A'C) #
k_$A.off			= (gkbt$C.On = 0 ? 1 : 0)
			FLsetVal	gkupdate1*k_$A.off, 0, gihs$C.ampD		; reset VU when unit is turned off
#

$MixParameters(1'Rplay1)
$MixParameters(2'Rplay2)
$MixParameters(3'Grain1)
$MixParameters(4'Grain2)
$MixParameters(5'Grain3)
$MixParameters(6'Grain4)
$MixParameters(7'RAG)
$MixParameters(8'Pad)
$MixParameters(9'PtSeq)
$MixParameters(10'Loop)


;*************************************************
; Delay effect

#define DelayEffParameters(A'B'C'D'E'F) #
;ARGS: delaymodule number, tempofact, subdivL, straightdotL, subdivR, strdtR

gkfx_d$A.2b		init	$B.
gkfx_d$A._timul		table gkfx_d$A.2b,  184 	; Deltime, Tempofactor

gkfx_d$A.1a		init	$C.
gkfx_d$A._subL		table gkfx_d$A.1a, 182 ; Left  deltime subdiv (2, 4, 8, 16)

gkfx_d$A.1b		init 	$D.
gkfx_d$A._noteL		table gkfx_d$A.1b, 183 ; Left  straight/dotted/triplet

gkfx_d$A.1c		init 	$E.
gkfx_d$A._subR		table gkfx_d$A.1c, 182 ; Right deltime subdiv (2, 4, 8, 16)

gkfx_d$A.1d		init 	$F.
gkfx_d$A._noteR		table gkfx_d$A.1d, 183 ; Right straight/dotted/triplet

#
$DelayEffParameters.(1'1'1'1'2'1)
$DelayEffParameters.(2'1'1'1'1'0)

;*************************************************
; global triggers
;*************************************************

;Pad 1
kpad1on		trigger gkt701, 0.5, 0
schedkwhen	kpad1on,  0, 0, 360.1, 0, -1, 7.04		; E'
kpad1off	trigger gkt701, 0.5, 1
schedkwhen	kpad1off,  0, 0, -360.1, 0, 1, 7.04		; E'
kpad2on		trigger gkt702, 0.5, 0
schedkwhen	kpad2on,  0, 0, 360.2, 0, -1, 8.04		; E
kpad2off	trigger gkt702, 0.5, 1
schedkwhen	kpad2off,  0, 0, -360.2, 0, 1, 8.04		; E
kpad3on		trigger gkt703, 0.5, 0
schedkwhen	kpad3on,  0, 0, 360.3, 0, -1, 9.04		; e
kpad3off	trigger gkt703, 0.5, 1
schedkwhen	kpad3off,  0, 0, -360.3, 0, 1, 9.04		; e
kpad4on		trigger gkt704, 0.5, 0
schedkwhen	kpad4on,  0, 0, 360.4, 0, -1, 9.06		; f#
kpad4off	trigger gkt704, 0.5, 1
schedkwhen	kpad4off,  0, 0, -360.4, 0, 1, 9.06		; f#
kpad5on		trigger gkt705, 0.5, 0
schedkwhen	kpad5on,  0, 0, 360.5, 0, -1, 9.08		; g#
kpad5off	trigger gkt705, 0.5, 1
schedkwhen	kpad5off,  0, 0, -360.5, 0, 1, 9.08		; g#
kpad6on		trigger gkt706, 0.5, 0
schedkwhen	kpad6on,  0, 0, 360.6, 0, -1, 9.10		; a#
kpad6off	trigger gkt706, 0.5, 1
schedkwhen	kpad6off,  0, 0, -360.6, 0, 1, 9.10		; a#
kpad7on		trigger gkt707, 0.5, 0
schedkwhen	kpad7on,  0, 0, 360.7, 0, -1, 9.11		; h
kpad7off	trigger gkt707, 0.5, 1
schedkwhen	kpad7off,  0, 0, -360.7, 0, 1, 9.11		; h
kpad8on		trigger gkbtPadOn, 0.5, 0
schedkwhen	kpad8on,  0, 0, 360.7, 0, -1, 10.03		; d#
kpad8off	trigger gkbtPadOn, 0.5, 1
schedkwhen	kpad8off,  0, 0, -360.7, 0, 1, 10.03		; d#

; *** trigger instr events
;;auto sampler voice 1 (instr 302)
kt2on	trigger	gkt2, 0.5, 0
schedkwhen	kt2on, 0.1, 1, 302, 0, -1		;note on
kt2off	trigger	gkt2, 0.5, 1
schedkwhen	kt2off,  0.1, 1, -302, 0, 1		;note off

;auto sampler voice 2 (instr 303)
kt22on	trigger	gkt22, 0.5, 0
schedkwhen	kt22on, 0.1, 1, 303, 0, -1		 ;note on
kt22off	trigger	gkt22, 0.5, 1
schedkwhen	kt22off,  0.1, 1, -303, 0, 1		;note off

;*******************************************************************
;pitch track instr scheduling
; pitch track sampling synchronized to audio sampling input 1
;kPTstore		trigger gkPSmpl,  0.5, 0
;kPTst_off		trigger gkPSmpl,  0.5, 1
kPTGrFrq		trigger gkPGrFrq, 0.5, 0
kPTGrFrq_off		trigger gkPGrFrq, 0.5, 1
kPTGrTsp		trigger gkPGrTsp, 0.5, 0
kPTGrTsp_off		trigger gkPGrTsp, 0.5, 1
kPTFmFrq		trigger gkPFMFrq, 0.5, 0
kPTFmFrq_off		trigger gkPFMFrq, 0.5, 1
kPTRmFrq		trigger gkPRMFrq, 0.5, 0
kPTRmFrq_off		trigger gkPRMFrq, 0.5, 1
kPTBasSyn		trigger gkPBasSyn, 0.5, 0
kPTBasSyn_off		trigger gkPBasSyn, 0.5, 1


;schedkwhen		kPTstore,  	0, 1, 181, 0, -1	; on store pitch
;schedkwhen		kPTst_off,  	0, 1, -181, 0, 1	; off store pitch
schedkwhen		kPTGrFrq, 	0, 1, 182, 0, -1	; on pitch to GrainFreq
schedkwhen		kPTGrFrq_off, 	0, 1, -182, 0, 1	; off pitch to GrainFreq
schedkwhen		kPTGrTsp, 	0, 1, 183, 0, -1	; on pitch to GrainTransp
schedkwhen		kPTGrTsp_off, 	0, 1, -183, 0, 1	; off pitch to GrainTransp
schedkwhen		kPTFmFrq, 	0, 1, 184, 0, -1	; on pitch to FM Freq
schedkwhen		kPTFmFrq_off, 	0, 1, -184, 0, 1	; off pitch to FM Freq
schedkwhen		kPTRmFrq, 	0, 1, 185, 0, -1	; on pitch to RM Freq
schedkwhen		kPTRmFrq_off, 	0, 1, -185, 0, 1	; off pitch to RM Freq
schedkwhen		kPTBasSyn, 	0, 1, 186, 0, -1	; on pitch to BasSynth
schedkwhen		kPTBasSyn_off, 	0, 1, -186, 0, 1	; off pitch to BasSynth
;*******************************************************************

;;rythm engine (instr 255) (+ instr 256,257,258)
ktRon		trigger	gktR,  0.5, 0
schedkwhen	ktRon,  0.1, 1, 255, 0, -1		;note on
gktRoff		trigger	gktR,  0.5, 1
schedkwhen	gktRoff, 0.1, 1, -255, 0, 1		;note off(5)
schedkwhen	gktRoff, 0.1, 1, -256, 0, 1		;note off(6)
schedkwhen	gktRoff, 0.1, 1, -257, 0, 1		;note off(7)
schedkwhen	gktRoff, 0.1, 1, -258, 0, 1		;note off(8)

;loop enable trig/mute
gkdrmoff	= (gktR + gkbtLoopOn > 1 ? 0 : 1 )	;if both buttons ON, let drumloop play

; pattern sequencer clock enable/disable
gkptrnoff	= (gktR + gkbtPtSeqOn > 1 ? 0 : 1 )	;if both buttons ON, let pattern play

;;grain playback voice 1 (instr 321)
ktGr1on		trigger	gkbtGrain1On, 0.5, 0
schedkwhen	ktGr1on, 0.1, 1, 321, 0, -1		;note on
ktGr1off	trigger	gkbtGrain1On, 0.5, 1
schedkwhen	ktGr1off,  0.1, 1, -321, 0, 1		;note off

;;grain playback voice 2 (instr 322)
ktGr2on		trigger	gkbtGrain2On, 0.5, 0
schedkwhen	ktGr2on, 0.1, 1, 322, 0, -1		;note on
ktGr2off	trigger	gkbtGrain2On, 0.5, 1
schedkwhen	ktGr2off,  0.1, 1, -322, 0, 1		;note off

;;grain playback voice 3 (instr 323)
ktGr3on		trigger	gkbtGrain3On, 0.5, 0
schedkwhen	ktGr3on, 0.1, 1, 323, 0, -1		;note on
ktGr3off	trigger	gkbtGrain3On, 0.5, 1
schedkwhen	ktGr3off,  0.1, 1, -323, 0, 1		;note off

;;grain playback voice 4 (instr 324)
ktGr4on		trigger	gkbtGrain4On, 0.5, 0
schedkwhen	ktGr4on, 0.1, 1, 324, 0, -1		;note on
ktGr4off	trigger	gkbtGrain4On, 0.5, 1
schedkwhen	ktGr4off,  0.1, 1, -324, 0, 1		;note off

;;random access grain module, voice 1 (control, instr 330)
ktRAGon		trigger	gkbtRAGOn, 0.5, 0
schedkwhen	ktRAGon, 0.1, 1, 330, 0, -1		;note on
k_rag_off	trigger	gkbtRAGOn, 0.5, 1
schedkwhen	k_rag_off, 0.1, 1, -330, 0, 1		;note off

; DRUMLOOP FILL REINIT
gkfill1	= 0
gkfill2	= 0
gkfill3	= 0
gkfill4	= 0
	endin
;****************************************************************
;****************************************************************

;****************************************************************
; empty, assigning inactive midi channels to this instr
;****************************************************************
	instr	4

	endin
;****************************************************************
;****************************************************************

;****************************************************************
; metro for updating VU meters via FLsetVal
;****************************************************************
	instr	5
gkupdate1		metro	6		; GUI update frequency, higher values -> smoother update, but its CPU hungry !
	endin
;****************************************************************
;****************************************************************
;****************************************************************
; single trig midi instr
;****************************************************************
	instr	9

inum	notnum
icps	cpsmidi
iamp	ampmidi	1

ifno	= inum - 59
ktrig	init 1
schedkwhen	ktrig, 0, 0, 311, 0, 1, ifno
ktrig	= 0


	endin
;****************************************************************
;****************************************************************

;****************************************************************
; midi instr for Grain 1
;****************************************************************
	instr	10
icps	cpsmidi
;iamp	ampmidi	1
gk10cps	= icps
;gk10amp	= iamp
;gk10active	= iamp
	endin
;****************************************************************
;****************************************************************

;****************************************************************
; midi faderbox ctrl instr, always on
;****************************************************************
	instr	12

gkG2pitchdir	init 1					; init to transpose up
gkG3pitchdir	init 1					; init to transpose up
gkG4pitchdir	init 1					; init to transpose up

kstatus, kchan, kdata1, kdata2	midiin			; generic midi input
if kchan == 2 goto channel2				; for midi channel 2
if kchan == 11 goto channel11				; for midi channel 11 
if kchan != 11 goto not11					; process midi input from channel 11 only

channel2:
if kstatus == 128 goto ch2noteoff			; read note-off messages only
if kstatus == 144 goto ch2noteon			; read note-on messages only
goto endCh2

ch2noteoff:
gk10voiceN	= gk10voiceN - 1			; voice (polyphony) counter
gk10active	= (gk10voiceN == 0 ? 0 : gk10active) 	; turn off if no notes active
goto endCh2

ch2noteon:
gk10voiceN	= gk10voiceN + 1			; voice (polyphony) counter
;gk10cps	= 440*exp((kdata1 -69)*log(1.0594631)) 	; midi note to cps conversion
;gk10cps		= cpsoct((kdata1/12)+3)			; midi note to cps conversion
gk10active	= 1

endCh2:

if kchan != 11 goto not11					; process midi input from channel 11 only


channel11:
if kstatus != 144 goto nonote				; read note-on messages only

;process note on ctrls here


; *** Grain Voice 2

if kdata1 != 84 goto notnote84				; note 84 activates Grain Voice 2 instr
kG2on		init 0
kG2on		= (kG2on > 0 ? -1 : 1 )			; toggle counter 0, 1, -1, 1, -1, 1, -1, 1,....
schedkwhen	kG2on, 0, 1, 322, 0, -1			; turn on module/instr
kG2off		= kG2on * -1				; opposite of kG2on 0, -1, 1, -1, 1, -1, ...
schedkwhen	kG2off, 0, 1, -322, 0, 1		; turn off module/instr
goto nonote
notnote84:


; note 85 handled in instr 13

if kdata1 != 86 goto notnote86				; note 86 toggles pitch transpose up/down
gkG2pitchdir 	= (gkG2pitchdir < 1 ? 1 : -1 )		; toggles between -1 and 1 (down/up)
goto nonote
notnote86:

; note 87 handled in instr 13
; note 88 handled in instr 13

; *** Grain Voice 3

if kdata1 != 89 goto notnote89				; note 89 activates Grain Voice 3 instr
kG3on		init 0
kG3on		= (kG3on > 0 ? -1 : 1 )			; toggle counter 0, 1, -1, 1, -1, 1, -1, 1,....
schedkwhen	kG3on, 0, 1, 323, 0, -1			; turn on module/instr
kG3off		= kG3on * -1				; opposite of kG3on 0, -1, 1, -1, 1, -1, ...
schedkwhen	kG3off, 0, 1, -323, 0, 1		; turn off module/instr
goto nonote
notnote89:

; note 90 handled in instr 13

if kdata1 != 91 goto notnote91				; note 91 toggles pitch transpose up/down
gkG3pitchdir 	= (gkG3pitchdir < 1 ? 1 : -1 )		; toggles between -1 and 1 (down/up)
goto nonote
notnote91:

; note 92 handled in instr 13
; note 93 handled in instr 13

; *** Grain Voice 4

if kdata1 != 94 goto notnote94				; note 94 activates Grain Voice 4 instr
kG4on		init 0
kG4on		= (kG4on > 0 ? -1 : 1 )			; toggle counter 0, 1, -1, 1, -1, 1, -1, 1,....
schedkwhen	kG4on, 0, 1, 324, 0, -1			; turn on module/instr
kG4off		= kG4on * -1				; opposite of kG4on 0, -1, 1, -1, 1, -1, ...
schedkwhen	kG4off, 0, 1, -324, 0, 1		; turn off module/instr
goto nonote
notnote94:

; note 95 handled in instr 13

if kdata1 != 96 goto notnote96				; note 96 toggles pitch transpose up/down
gkG4pitchdir 	= (gkG4pitchdir < 1 ? 1 : -1 )		; toggles between -1 and 1 (down/up)
goto nonote
notnote96:

; note 97 handled in instr 13
; note 98 handled in instr 13
; note 99 handled in instr 13

kdata1	= 0
nonote:


;if kstatus != 176 goto noctrl				; don't process this section if no incoming midi controllers are present

kctrl1, kctrl2, kctrl3, kctrl4, kctrl5, kctrl6, \	; midi faders, input params
kctrl7, kctrl8,	kctrl9, kctrl10, kctrl11, 	\	;
kctrl12, kctrl13, kctrl14, kctrl15, kctrl16,	\	;
kctrl17, kctrl18, kctrl19, kctrl20, kctrl21,	\	;
kctrl22, kctrl23, kctrl24, kctrl25, kctrl26,	\	;
kctrl27, kctrl28, kctrl29, kctrl30, kctrl31, 	\	;
kctrl32						\	;
slider32	11,				\	; read midi controller inputs
1, 0, 1, 0, 0,		\	; 			; ctl.no., min, max, ival, ifno, lp_freq
2, 0, 12, 0, 0,	\	; Rplay transp
3, -2, 2, 0, 0,		\	; 
4, 0, 5, 0, 0,		\	; 
5, 0, 1, 0, 0,		\	; 
6, 0, 1, 0, 0,	\
7, 0, 12, 0, 0,	\		; Rplay transp
8, 0, 1, 0, 0,	\
9, 0, 1, 1, 0,	\		; input 1 volume
10, -0.63, 1, 1, 0,	\		; input 2 volume
11, 0, 1, 0, 0,	\		; 
12, 0, 1, 0, 0,	\		; 
13, 0, 1, 0, 0,	\		; 
14, 0, 1, 0, 0,	\
15, 0, 1, 0, 0,	\
16, 0, 1, 0, 0,	\
17, 0, 2, 0, 0,		\	; amp
18, 1, 127, 20, 123,	\	; gr.freq ; 18, 0, 1024, 256, 122,
19, 0, 12, 0, 0,	\	; transp  ; 19, 0, 1, 0, 0,
20, 0, 5, 0, 0,		\	; oct
21, 0, 1, 0.2, 0,	\	; time
22, 0, 2, 0, 0,		\	; amp
23, 1, 127, 20, 123,	\	; gr.freq ; 18, 0, 1024, 256, 122,
24, 0, 12, 0, 0,	\	; transp  ; 19, 0, 1, 0, 0,
25, 0, 5, 0, 0,		\	; oct
26, 0, 1, 0.2, 0,	\	; time
27, 0, 2, 0, 0,		\	; amp
28, 1, 127, 20, 123,	\	; gr.freq ; 18, 0, 1024, 256, 122,
29, 0, 12, 0, 0,	\	; transp  ; 19, 0, 1, 0, 0,
30, 0, 5, 0, 0,		\	; oct
31, 0, 1, 0.2, 0,	\	; time
32, 0, 2, 1, 0		\ 	; loop volume


; the following acts as a gate for the midi controller messages,
; the parameters to be controlled are updated with the midi controller values 
; only when there is activity on the incoming midi controller data
; when there is no incoming midi controller data, 
; the parameters are controllable from the Windows GUI sliders

; **** for Grain Voice 2 ***

gkctrl17	init 0
gkctrl18	init 0
gkctrl19	init 0
gkctrl20	init 0
gkctrl21	init 0

gkctrl36	init 0
kctrl36		ctrl7	11, 36, 0, 12	; ch, ctrl, min, max
; additional processing and mapping of the midi controller values
kctrl18		= (kctrl18 > 36 ? (cpsoct(int(kctrl18+24)/12)+3) : kctrl18 )	; grain freq quantized to closest semitone if freq > 36
kctrl19		table 12+(kctrl19*gkG2pitchdir), 150				; transpose in semitones, up or down selectable by gkpitchdir
kctrl19		tonek	kctrl19+gidenorm, 20						; portamento for transpose 
kctrl21		tonek	kctrl21+gidenorm, 10						; portamento for manual timepoint

; actual gate mechanism, if value has changed during last k-cycle, then write midi controller to parameter value
gksGrain2amp	= (gkctrl17 == kctrl17 ? gksGrain2amp   : kctrl17 ) 			; update only if midi controller activity is sensed
gkGrn2grfq	= (gkctrl18 == kctrl18 ? gkGrn2grfq  : kctrl18 ) 			; update only if midi controller activity is sensed
gkGrn2form	= (gkctrl19 == kctrl19 ? gkGrn2form  : kctrl19 ) 			; update only if midi controller activity is sensed
gkGrn2oct	= (gkctrl20 == kctrl20 ? gkGrn2oct   : kctrl20 ) 			; update only if midi controller activity is sensed
gkGrn2mPhs	= (gkctrl21 == kctrl21 ? gkGrn2mPhs : kctrl21 ) 			; update only if midi controller activity is sensed
gkGrn2Sprd	= (gkctrl36 == kctrl36 ? gkGrn2Sprd : kctrl36 ) 			; update only if midi controller activity is sensed

gkctrl17	= kctrl17							; update global, so as to check if value changes next k-cycle
gkctrl18	= kctrl18
gkctrl19	= kctrl19
gkctrl20	= kctrl20
gkctrl21	= kctrl21
gkctrl36	= kctrl36

; **** for Grain Voice 3 ***

gkctrl22	init 0
gkctrl23	init 0
gkctrl24	init 0
gkctrl25	init 0
gkctrl26	init 0

gkctrl37	init 0
kctrl37		ctrl7	11, 37, 0, 12	; ch, ctrl, min, max

; additional processing and mapping of the midi controller values
kctrl23		= (kctrl23 > 36 ? (cpsoct(int(kctrl23+24)/12)+3) : kctrl23 )	; grain freq quantized to closest semitone if freq > 36
kctrl24		table 12+(kctrl24*gkG3pitchdir), 150				; transpose in semitones, up or down selectable by gkpitchdir
kctrl24		tonek	kctrl24+gidenorm, 20						; portamento for transpose 
kctrl26		tonek	kctrl26+gidenorm, 10						; portamento for manual timepoint

; actual gate mechanism, if value has changed during last k-cycle, then write midi controller to parameter value
gksGrain3amp	= (gkctrl22 == kctrl22 ? gksGrain3amp   : kctrl22 ) 			; update only if midi controller activity is sensed
gkGrn3grfq	= (gkctrl23 == kctrl23 ? gkGrn3grfq  : kctrl23 ) 			; update only if midi controller activity is sensed
gkGrn3form	= (gkctrl24 == kctrl24 ? gkGrn3form  : kctrl24 ) 			; update only if midi controller activity is sensed
gkGrn3oct	= (gkctrl25 == kctrl25 ? gkGrn3oct   : kctrl25 ) 			; update only if midi controller activity is sensed
gkGrn3mPhs	= (gkctrl26 == kctrl26 ? gkGrn3mPhs : kctrl26 ) 			; update only if midi controller activity is sensed
gkGrn3Sprd	= (gkctrl37 == kctrl37 ? gkGrn3Sprd : kctrl37 ) 			; update only if midi controller activity is sensed

gkctrl22	= kctrl22							; update global, so as to check if value changes next k-cycle
gkctrl23	= kctrl23
gkctrl24	= kctrl24
gkctrl25	= kctrl25
gkctrl26	= kctrl26
gkctrl37	= kctrl37

; **** for Grain Voice 4 ***

gkctrl27	init 0
gkctrl28	init 0
gkctrl29	init 0
gkctrl30	init 0
gkctrl31	init 0

gkctrl38	init 0
kctrl38		ctrl7	11, 38, 0, 12	; ch, ctrl, min, max

; additional processing and mapping of the midi controller values
kctrl28		= (kctrl28 > 36 ? (cpsoct(int(kctrl28+24)/12)+3) : kctrl28 )	; grain freq quantized to closest semitone if freq > 36
kctrl29		table 12+(kctrl29*gkG4pitchdir), 150				; transpose in semitones, up or down selectable by gkpitchdir
kctrl29		tonek	kctrl29+gidenorm, 20						; portamento for transpose 
kctrl31		tonek	kctrl31+gidenorm, 10						; portamento for manual timepoint

; actual gate mechanism, if value has changed during last k-cycle, then write midi controller to parameter value
gksGrain4amp	= (gkctrl27 == kctrl27 ? gksGrain4amp   : kctrl27 ) 		; update only if midi controller activity is sensed
gkGrn4grfq	= (gkctrl28 == kctrl28 ? gkGrn4grfq  : kctrl28 ) 		; update only if midi controller activity is sensed
gkGrn4form	= (gkctrl29 == kctrl29 ? gkGrn4form  : kctrl29 ) 		; update only if midi controller activity is sensed
gkGrn4oct	= (gkctrl30 == kctrl30 ? gkGrn4oct   : kctrl30 ) 		; update only if midi controller activity is sensed
gkGrn4mPhs	= (gkctrl31 == kctrl31 ? gkGrn4mPhs : kctrl31 ) 		; update only if midi controller activity is sensed
gkGrn4Sprd	= (gkctrl38 == kctrl38 ? gkGrn4Sprd : kctrl38 ) 		; update only if midi controller activity is sensed

gkctrl27	= kctrl27							; update global, so as to check if value changes next k-cycle
gkctrl28	= kctrl28
gkctrl29	= kctrl29
gkctrl30	= kctrl30
gkctrl31	= kctrl31
gkctrl38	= kctrl38

; balance of dry/filter2 send
gkctrl33	init 0
kctrl33		ctrl7	11, 33, 0, 1	; ch, ctrl, min, max
kctrl33		tonek	kctrl33+gidenorm, 160					; portamento for dry/filter mix
gkLoop_filt2	init 0
gkLoop_filt2	= (gkctrl33 == kctrl33 ? gkLoop_filt2   : kctrl33 ) 		; update only if midi controller activity is sensed
gkLoop_clean	= (gkctrl33 == kctrl33 ? gkLoop_clean   : 1-kctrl33 ) 		; update only if midi controller activity is sensed
gkctrl33	= kctrl33

; loop hipass filter ctrl
gkctrl35	init 0
kctrl35		ctrl7	11, 35, 0, 1, 126	; ch, ctrl, min, max, ifno
kctrl35		tonek	kctrl35+gidenorm, 160					; portamento 
gkLoop_HP	init 0
gkLoop_HP	= (gkctrl35 == kctrl35 ? gkLoop_HP : kctrl35 )	 		; update only if midi controller activity is sensed
gkctrl35	= kctrl35

; Drumloop BBcut mix
gkctrl34	init 0
kctrl34		ctrl7	11, 34, 0, 1	; ch, ctrl, min, max
kctrl34		tonek	kctrl34+gidenorm, 160						; portamento for bbcut mix
gkDLbbmix	init 0
gkDLbbmix	= (gkctrl34 == kctrl34 ? gkDLbbmix : kctrl34 ) 			; update only if midi controller activity is sensed
gkctrl34	= kctrl34


; **** for Loop Volume ***

gkctrl32	init 0
kctrl32		tonek	kctrl32+gidenorm, 160						; portamento for loop volume
gkDrmLopAm	= (gkctrl32 == kctrl32 ? gkDrmLopAm : kctrl32 ) 		; update only if midi controller activity is sensed
gkctrl32	= kctrl32


kctrl41, kctrl42, kctrl43, kctrl44, kctrl45, kctrl46, \	; midi faders, input params
kctrl47, kctrl48				\
slider8	11,					\	; read midi controller inputs
41, 0, 1, 0, 0,		\	; hipass		; ctl.no., min, max, ival, ifno
42, 0, 1, 0, 0,		\	; lopass
43, 0, 1, 0, 0,		\	; bbcut
44, 0, 2, 1, 0,		\	; volume 2
45, 0, 1, 0, 0,		\	; hipass
46, 0, 1, 0, 0,		\	; lopass
47, 0, 1, 0, 0,		\	; bbcut
48, 0, 2, 1, 0			; volume 3

kctrl41		tonek	kctrl41+gidenorm, 160		; portamento 
kctrl42		tonek	kctrl42+gidenorm, 160		; portamento 
kctrl43		tonek	kctrl43+gidenorm, 160		; portamento 
kctrl44		tonek	kctrl44+gidenorm, 160		; portamento 
kctrl45		tonek	kctrl45+gidenorm, 160		; portamento 
kctrl46		tonek	kctrl46+gidenorm, 160		; portamento 
kctrl47		tonek	kctrl47+gidenorm, 160		; portamento 
kctrl48		tonek	kctrl48+gidenorm, 160		; portamento 

gk2Loop_HP	= kctrl41
gk2Loop_LP	= kctrl42
gk2Loop_Clean	= 1 - kctrl42		; clean / lopass mix
gk2DLbbmix	= kctrl43
gk2DrmLopAm	= kctrl44		; layer 2 amplitude

gk3Loop_HP	= kctrl45
gk3Loop_LP	= kctrl46
gk3Loop_Clean	= 1 - kctrl46		; clean /lopass mix
gk3DLbbmix	= kctrl47
gk3DrmLopAm	= kctrl48		; layer 3 amplitude


kstatus	= 0
noctrl:
not11:


;Master Rhythm Start/Stop
kctrl100	ctrl7	1, 100, 0, 1 	; ch, ctl, min, max 
gk100trig	trigger	kctrl100, 0.5, 0

; Input volume via midi, 
kctrl9		init 1
gactrlvol1	interp	kctrl9
gactrlvol2	interp	kctrl10
gactrlvol1	init 1

; display input volume
;kVu	max_k	gactrlvol1, gkupdate1, 0
aVu	init 0
	maxabsaccum  aVu, gactrlvol1
kVu	downsamp aVu
aVu	= 0
	FLsetVal	gkupdate1, kVu, gihInAmp1midi

;kVu	max_k	gactrlvol2, gkupdate1, 0
aVu2	init 0
	maxabsaccum  aVu, gactrlvol2
kVu2	downsamp aVu2
aVu2	= 0
	FLsetVal	gkupdate1, kVu2, gihInAmp2midi

;Master Section controls

kctrl101, kctrl102, kctrl103, kctrl104, 	\	;
kctrl105, kctrl106, kctrl107, kctrl108,	 	\	;
kctrl111, kctrl112, kctrl113, kctrl114,	 	\	;
kctrl115, kctrl116, kctrl117, kctrl118	 	\	;
slider16	11,					\	; read midi controller inputs
101, 0,   2,    1,    0,		\	; master	; ctl.no., min, max, ival, ifno, lp_freq
102, 0,   1,    1,    0,		\	; revb level
103, 0.4, 1,    0.77, 130,		\	; revb time
104, 0,   1,    1,    0,		\	; delay1 level
105, 1,   3,    1,    0,		\	; delay1 time
106, 0,   1,    1,    0,		\	; delay2 level
107, 1,   3,    1,    0,		\	; delay2 time
108, 20,  3000, 1000, 130,	 	\	; filter2 CF
111, 0,   1,    0,    0,		\	; (routed) dry send
112, 0,   1,    0,    0,		\	; (routed) RM send
113, 0,   1,    0,    0,		\	; (routed) FM send
114, 0,   1,    0,    0,		\	; (routed) Filt1 send
115, 0,   1,    0,    0,		\	; (routed) Dist send
116, 0,   1,    0,    0,		\	; (routed) Filt2 send
117, 0,   1,    0,    0,		\	; (routed) Dly1 send
118, 0,   1,    0,    0 		\	; (routed) Dly2 send

; Master Volume
; Reverb out level
; Reverb time
; Delay 1 out level
; Delay 1 time
; Delay 2 out level
; Delay 2 time
; Filter 2 cutoff freq

gkctrl101	init 0
gkctrl102	init 0
gkctrl103	init 0
gkctrl104	init 0
gkctrl105	init 0
gkctrl106	init 0
gkctrl107	init 0
gkctrl108	init 0

kctrl101	tonek	kctrl101+gidenorm, 10						; avoid clicks
kctrl102	tonek	kctrl102+gidenorm, 10						; avoid clicks
kctrl104	tonek	kctrl104+gidenorm, 10						; avoid clicks
kctrl105	tonek	kctrl105+gidenorm, 1						; avoid clicks
kctrl106	tonek	kctrl106+gidenorm, 10						; avoid clicks
kctrl107	tonek	kctrl107+gidenorm, 1						; avoid clicks

gksMastamp	= (gkctrl101 == kctrl101 ? gksMastamp : kctrl101 ) 		; update only if midi controller activity is sensed
gksRevbamp	= (gkctrl102 == kctrl102 ? gksRevbamp : kctrl102 ) 		; update only if midi controller activity is sensed
gkfx_rv_tim	= (gkctrl103 == kctrl103 ? gkfx_rv_tim : kctrl103 ) 		; update only if midi controller activity is sensed
gkfx_d1_dry	= (gkctrl104 == kctrl104 ? gkfx_d1_dry : kctrl104 ) 		; update only if midi controller activity is sensed
gkDel1ManualTime= (gkctrl105 == kctrl105 ? gkDel1ManualTime : kctrl105 ) 	; update only if midi controller activity is sensed
gkfx_d2_dry	= (gkctrl106 == kctrl106 ? gkfx_d2_dry : kctrl106 ) 		; update only if midi controller activity is sensed
gkDel2ManualTime= (gkctrl107 == kctrl107 ? gkDel2ManualTime : kctrl107 ) 	; update only if midi controller activity is sensed
gkfx_f2_cfrq	= (gkctrl108 == kctrl108 ? gkfx_f2_cfrq : kctrl108 ) 		; update only if midi controller activity is sensed

gkctrl101	= kctrl101
gkctrl102	= kctrl102
gkctrl103	= kctrl103
gkctrl104	= kctrl104
gkctrl105	= kctrl105
gkctrl106	= kctrl106
gkctrl107	= kctrl107
gkctrl108	= kctrl108

; ** Routed efx send controls
gkctrl111	init 0
gkctrl112	init 0
gkctrl113	init 0
gkctrl114	init 0
gkctrl115	init 0
gkctrl116	init 0
gkctrl117	init 0
gkctrl118	init 0

kctrl101	tonek	kctrl101+gidenorm, 10						; avoid clicks
kctrl102	tonek	kctrl102+gidenorm, 10						; avoid clicks
kctrl103	tonek	kctrl103+gidenorm, 10						; avoid clicks
kctrl104	tonek	kctrl104+gidenorm, 10						; avoid clicks
kctrl105	tonek	kctrl105+gidenorm, 10						; avoid clicks
kctrl106	tonek	kctrl106+gidenorm, 10						; avoid clicks
kctrl107	tonek	kctrl107+gidenorm, 10						; avoid clicks
kctrl108	tonek	kctrl108+gidenorm, 10						; avoid clicks

#define EfxSendROUTING(A) #
gk$A._clean	= (gkctrl111 == kctrl111 ? gk$A._clean : kctrl111 ) 		; update only if midi controller activity is sensed
gk$A._rm		= (gkctrl112 == kctrl112 ? gk$A._rm : kctrl112 ) 		; update only if midi controller activity is sensed
gk$A._fm		= (gkctrl113 == kctrl113 ? gk$A._fm : kctrl113 ) 		; update only if midi controller activity is sensed
gk$A._filt1	= (gkctrl114 == kctrl114 ? gk$A._filt1 : kctrl114 ) 		; update only if midi controller activity is sensed
gk$A._dist	= (gkctrl115 == kctrl115 ? gk$A._dist : kctrl115 ) 		; update only if midi controller activity is sensed
gk$A._filt2	= (gkctrl116 == kctrl116 ? gk$A._filt2 : kctrl116 ) 		; update only if midi controller activity is sensed
gk$A._del1	= (gkctrl117 == kctrl117 ? gk$A._del1 : kctrl117 ) 		; update only if midi controller activity is sensed
gk$A._del2	= (gkctrl118 == kctrl118 ? gk$A._del2 : kctrl118 ) 		; update only if midi controller activity is sensed
#

if gk_efxroute == 1 goto rplay1
if gk_efxroute == 2 goto rplay2
if gk_efxroute == 3 goto grain1
if gk_efxroute == 4 goto grain2
if gk_efxroute == 5 goto grain3
if gk_efxroute == 6 goto grain4
if gk_efxroute == 7 goto rag
if gk_efxroute == 8 goto loop
goto skiproute

rplay1:
$EfxSendROUTING.(Rplay1)
goto skiproute
rplay2:
$EfxSendROUTING.(Rplay2)
goto skiproute
grain1:
$EfxSendROUTING.(Grain1)
goto skiproute
grain2:
$EfxSendROUTING.(Grain2)
goto skiproute
grain3:
$EfxSendROUTING.(Grain3)
goto skiproute
grain4:
$EfxSendROUTING.(Grain4)
goto skiproute
rag:
$EfxSendROUTING.(RAG)
goto skiproute
loop:
$EfxSendROUTING.(Loop)
goto skiproute

skiproute:
gkctrl111	= kctrl111
gkctrl112	= kctrl112
gkctrl113	= kctrl113
gkctrl114	= kctrl114
gkctrl115	= kctrl115
gkctrl116	= kctrl116
gkctrl117	= kctrl117
gkctrl118	= kctrl118


	endin
;****************************************************************
;****************************************************************
;****************************************************************
; line generation instr, control, midi activated
;****************************************************************
	instr 13

inum	notnum



; note numbers not listed here are handled in instr 12
if inum < 10 goto efxrouting
if inum == 85 goto note85
if inum == 87 goto note87
if inum == 88 goto note88
if inum == 90 goto note90
if inum == 92 goto note92
if inum == 93 goto note93
if inum == 95 goto note95
if inum == 97 goto note97
if inum == 98 goto note98
if inum == 99 goto note99

goto end

efxrouting:
gk_efxroute	= inum
goto end 

note85:
istart		= i(gkGrain2_filt1)*0.5			; get start(current) value
iend		= 0.75					; end value for line is 1 (max Send)
irel		= 0.1					; release time to old value when button is released (note off
k1		linsegr istart, 1, iend, 1, iend, irel, istart	; ramp to new value during 1 second, 
k1		limit k1, 0, 1				; limit to 0 to 1 range
gkGrain2_filt1	= k1					; assign modified value
goto end

note87:
istart		= i(gkGrain2_del1)*0.5			; get start(current) value
iend		= 1					; end value for line is 1 (max Send)
irel		= 0.1					; release time to old value when button is released (note off
k1		linsegr istart, 1, iend, 1, iend, irel, istart	; ramp to new value during 1 second, 
k1		limit k1, 0, 1				; limit to 0 to 1 range
gkGrain2_del1	= k1					; assign modified value
goto end

note88:
istart		= i(gkGrain2_revb)*0.5			; get start(current) value
iend		= 1					; end value for line is 1 (max Send)
irel		= 0.1					; release time to old value when button is released (note off
k1		linsegr istart, 1, iend, 1, iend, irel, istart	; ramp to new value during 1 second, 
k1		limit k1, 0, 1				; limit to 0 to 1 range
gkGrain2_revb	= k1					; assign modified value
goto end

note90:
istart		= i(gkGrain3_filt1)*0.5			; get start(current) value
iend		= 0.75					; end value for line is 1 (max Send)
irel		= 0.1					; release time to old value when button is released (note off
k1		linsegr istart, 1, iend, 1, iend, irel, istart	; ramp to new value during 1 second, 
k1		limit k1, 0, 1				; limit to 0 to 1 range
gkGrain3_filt1	= k1					; assign modified value
goto end

note92:
istart		= i(gkGrain3_del1)*0.5			; get start(current) value
iend		= 1					; end value for line is 1 (max Send)
irel		= 0.1					; release time to old value when button is released (note off
k1		linsegr istart, 1, iend, 1, iend, irel, istart	; ramp to new value during 1 second, 
k1		limit k1, 0, 1				; limit to 0 to 1 range
gkGrain3_del1	= k1					; assign modified value
goto end

note93:
istart		= i(gkGrain3_revb)*0.5			; get start(current) value
iend		= 1					; end value for line is 1 (max Send)
irel		= 0.1					; release time to old value when button is released (note off
k1		linsegr istart, 1, iend, 1, iend, irel, istart	; ramp to new value during 1 second, 
k1		limit k1, 0, 1				; limit to 0 to 1 range
gkGrain3_revb	= k1					; assign modified value
goto end

note95:
istart		= i(gkGrain4_filt1)*0.5			; get start(current) value
iend		= 0.75					; end value for line is 1 (max Send)
irel		= 0.1					; release time to old value when button is released (note off
k1		linsegr istart, 1, iend, 1, iend, irel, istart	; ramp to new value during 1 second, 
k1		limit k1, 0, 1				; limit to 0 to 1 range
gkGrain4_filt1	= k1					; assign modified value
goto end

note97:
istart		= i(gkGrain4_del1)*0.5			; get start(current) value
iend		= 1					; end value for line is 1 (max Send)
irel		= 0.1					; release time to old value when button is released (note off
k1		linsegr istart, 1, iend, 1, iend, irel, istart	; ramp to new value during 1 second, 
k1		limit k1, 0, 1				; limit to 0 to 1 range
gkGrain4_del1	= k1					; assign modified value
goto end

note98:
istart		= i(gkGrain4_revb)*0.5			; get start(current) value
iend		= 1					; end value for line is 1 (max Send)
irel		= 0.1					; release time to old value when button is released (note off
k1		linsegr istart, 1, iend, 1, iend, irel, istart	; ramp to new value during 1 second, 
k1		limit k1, 0, 1				; limit to 0 to 1 range
gkGrain4_revb	= k1					; assign modified value
goto end

note99:
istart		= i(gkLoop_del1)*0.5			; get start(current) value
iend		= 1					; end value for line is 1 (max Send)
irel		= 0.1					; release time to old value when button is released (note off
k1		linsegr istart, 1, iend, 1, iend, irel, istart	; ramp to new value during 1 second, 
k1		limit k1, 0, 1				; limit to 0 to 1 range
gkLoop_del1	= k1					; assign modified value
goto end

end:
	endin
;****************************************************************
;****************************************************************

;****************************************************************
; midi controls instr, for Grain1
;****************************************************************
	instr	14

; *** Grain Voice 1 reinit ifnoselect
kreinit		ctrl7 	2, 99, 0, 127			;midi ctrl, min, max
gkGrain1Reinit	= (kreinit > 20 ? 1 : 0)

kcps	= gk10cps
;kamp	= gk10amp

;kvel	tonek gk10active, 10	; filter for smooth in and out fades
gkveloc	= gk10active
;gk10active = 0	; reset for next test

; midi keyboard can take over control of Grain Frequency
kcps		= kcps*0.5
;gkGrn1grfq	= (kcps > 0 ? kcps : gkGrn1grfq)
gkGrn1grfq	= kcps


; midi pitch bend is factor to Grain transposition
; 0.5 to 2.0 range
;kbend	pchbend	0, 0.5				; pb, min, max
;kbend	= kbend + 0.5				; 0 to 1 range
kbend	ctrl7 	2, 2, 0, 1			;midi ctrl, min, max
kbend	init 0.5
kbend	table	kbend, 149, 1			; 0.5 to 2 range
;gkGrn1form_mc	= gkGrn1form * kbend		; moved to grain instr
gkbend2midi	= kbend

; midi controller 1 adds to Octaviation
; 0 to 4 range
kctrl1	ctrl7 	2, 1, 0, 4			;midi ctrl, min, max
;gkGrn1oct_mc		= gkGrn1oct + kctrl1	; moved to grain instr
gkctrl2midi		= kctrl1

; pitch spread
kctrl3	ctrl7 	2, 3, 0, 12			;midi ctrl, min, max
gkctrl2_3	init 0
gkGrn1Sprd	= (gkctrl2_3 == kctrl3 ? gkGrn1Sprd : kctrl3 ) 			; update only if midi controller activity is sensed
gkctrl2_3	= kctrl3

; timepoint
kctrl4	ctrl7 	2, 4, 0, 1			;midi ctrl, min, max
kctrl4		tonek	kctrl4+gidenorm, 2					; portamento 
gkctrl2_4	init 0
gkGrn1mPhs	= (gkctrl2_4 == kctrl4 ? gkGrn1mPhs : kctrl4 ) 			; update only if midi controller activity is sensed
gkctrl2_4	= kctrl4

; delay 2 send
kctrl7	ctrl7 	2, 7, 0, 1			;midi ctrl, min, max
kctrl7		tonek	kctrl7+gidenorm, 10						; portamento for dry/filter mix
gkctrl2_7	init 0
gkGrain1_del2	= (gkctrl2_7 == kctrl7 ? gkGrain1_del2   : kctrl7 ) 		; update only if midi controller activity is sensed
gkctrl2_7	= kctrl7

; balance of filter2/dry 
kctrl8	ctrl7	2, 8, 0, 1			;midi ctrl, min, max
kctrl8		tonek	kctrl8 +gidenorm, 10						; portamento for dry/filter mix
gkctrl2_8	init 0
gkGrain1_filt2	= (gkctrl2_8 == kctrl8 ? gkGrain1_filt2   : kctrl8 ) 		; update only if midi controller activity is sensed
gkGrain1_clean	= (gkctrl2_8 == kctrl8 ? gkGrain1_clean   : 1-kctrl8 ) 		; update only if midi controller activity is sensed
gkctrl2_8	= kctrl8


	endin
;****************************************************************
;****************************************************************

;****************************************************************
; drumloop presets
;****************************************************************
	instr 15

inum	notnum

; *** drumloop preset control
if inum != 100 goto notnote100			; note 100 activates drumloop preset
gkDrmLopN	= 1
gkDrmLopN2	= 0
gkDrmLopN3	= 0
goto nonote
notnote100:

if inum != 101 goto notnote101			; note 101 activates drumloop preset
gkDrmLopN	= 4
gkDrmLopN2	= 0
gkDrmLopN3	= 0
goto nonote
notnote101:

if inum != 102 goto notnote102			; note 102 activates drumloop preset
gkDrmLopN	= 6
gkDrmLopN2	= 7
gkDrmLopN3	= 1
goto nonote
notnote102:

if inum != 103 goto notnote103			; note 103 retrig measure, insert 2/4 measure
gkButnRetrig1	= 1
;schedkwhen	1, 0, 1, 17, 0, 0.01
goto nonote
notnote103:

if inum != 104 goto notnote104			; note 104 activates snaredrumBreak sample
gkDrmLopN	= 14
gkDrmLopN2	= 0
gkDrmLopN3	= 0
goto nonote
notnote104:

nonote:
; printing of midi-updated drumloop "presets"
FLprintk2	gkDrmLopN, gihDrmLopNd
FLprintk2	gkDrmLopN2, gihDrmLopNd2
FLprintk2	gkDrmLopN3, gihDrmLopNd3

	endin
;****************************************************************
;****************************************************************

;****************************************************************
; drumloop INCREASE/DECREASE
;****************************************************************
	instr 16

inum	notnum
; for loop select inc/dec
knum = inum
gktriginc	trigger knum, 0.5, 0			; single trigger

if inum == 118 goto note118
if inum == 119 goto note119
if inum == 120 goto note120
if inum == 121 goto note121
if inum == 122 goto note122
if inum == 123 goto note123
if inum == 124 goto note124
if inum == 125 goto note125

if inum == 126 goto note126
if inum == 127 goto note127

goto end

note118:
gkfill1	= 1
goto end

note119:
gkfill2	= 1
goto end

note120:
gkDrmLopN2	= gkDrmLopN2 - gktriginc			; increase by 1
gkDrmLopN2	= (gkDrmLopN2 < 0 ? 0 : gkDrmLopN2)		; safety, not below zero
; printing of midi-updated drumloop "presets"
FLprintk2	gkDrmLopN2, gihDrmLopNd2
goto end

note121:
gkDrmLopN2	= gkDrmLopN2 + gktriginc			; increase by 1
; printing of midi-updated drumloop "presets"
FLprintk2	gkDrmLopN2, gihDrmLopNd2
goto end

note122:
gkfill3	= 1
goto end

note123:
gkfill4	= 1
goto end

note124:
gkDrmLopN3	= gkDrmLopN3 - gktriginc			; increase by 1
gkDrmLopN3	= (gkDrmLopN3 < 0 ? 0 : gkDrmLopN3)		; safety, not below zero
; printing of midi-updated drumloop "presets"
FLprintk2	gkDrmLopN3, gihDrmLopNd3
goto end

note125:
gkDrmLopN3	= gkDrmLopN3 + gktriginc			; increase by 1
; printing of midi-updated drumloop "presets"
FLprintk2	gkDrmLopN3, gihDrmLopNd3
goto end

note126:
gkDrmLopN	= gkDrmLopN - gktriginc			; increase by 1
gkDrmLopN	= (gkDrmLopN < 0 ? 0 : gkDrmLopN)		; safety, not below zero
; printing of midi-updated drumloop "presets"
FLprintk2	gkDrmLopN, gihDrmLopNd
goto end

note127:
gkDrmLopN	= gkDrmLopN + gktriginc			; increase by 1
; printing of midi-updated drumloop "presets"
FLprintk2	gkDrmLopN, gihDrmLopNd
goto end

end:
	endin
;****************************************************************
;****************************************************************

;****************************************************************
; retrig beat counter instr, for inserting 2/4 measures
;****************************************************************
	instr 17
gkButnRetrig1	= 1
	endin
;****************************************************************
;****************************************************************


;****************************************************************
; Tap tempo instr1, calculate tempo
;****************************************************************
	instr 19
;gktaptempo1	line 1, p3, 0.2

gitime_new	times				; seconds since performance start
iperiod		= gitime_new - gitime_old 	; number of seconds since last tap
gitime_old	= gitime_new			; update for next tap
itempo		= 60/iperiod			; convert to bpm
gkbtpo		= ( itempo > 30 ? itempo : gkbtpo )	; filter extremely low values

FLprintk2	gkbtpo, gihCurTpo

	endin
;****************************************************************
;****************************************************************


;****************************************************************
; Pitch Tracker
;****************************************************************
instr 181
	a1,a2		ins

; midi controlled input volume
	a1	= a1 * gactrlvol1
	a2	= a2 * gactrlvol2
; denormalize
	abogus	rand	gidenorm
	kbogus	rand	gidenorm
	a1	= a1 + abogus

	imincps		= 60
	imaxcps		= 1000
	a1		lowpass2 a1, imaxcps, 2

	initfreq	= imincps
	imedian		= 1
	idowns		= 4
	iexcps		= imincps
	irmsmedi	= 0
	kcps,krms	pitchamdf	a1, imincps, imaxcps ,initfreq ,imedian ,idowns ,iexcps ,irmsmedi
	kcps		= (kcps > imaxcps * 0.95 ? imincps : kcps)	; when detection error: default to min, not to max
	kcps		= kcps + kbogus					; denorm
	kcps		tonek	kcps, 10
	krms		= (kcps > imaxcps * 0.95 ? krms*0.5 : krms )	; lower amp when pitchdetection is incorrect
	krms		= krms + kbogus					; denorm
	krms		tonek	krms, 20

       	gkcps		= kcps
	gkrms		= krms

	ifn		table	p4, 186		; table lookup for pitch track/slot selection

	tableicopy	ifn, 15				; clear pitch table
	tableicopy	ifn+1, 15			; clear amp table

;	kpeak		init 0
;	kpeak		peak	krms			  	; peak level so far
;	if		kpeak < gk_sampthresh1 kgoto end  	; don't start writing before the first sound comes in
;	krms		= (krms < gk_sampthresh1 ? 0 : krms )	; if low amplitude, set to zero
;	krms		tonek	krms, 50			; filter out abrupt changes in amp

	kndx		line	0, 1, kr			; goes on forever
	itablen		tableng	ifn
	kndx		= (kndx > itablen ? itablen : kndx)
;	kndx		= (kndx > 262144 ? kndx-262144 : kndx)	; wrap around
 	tablew		kcps, kndx, ifn				; write pitch
 	tablew		krms, kndx, ifn+1			; write amp
;end:

endin
;****************************************************************
;****************************************************************
;playback of recorded pitches, to Grain Frequency, Grain Module 2
instr 182

	kretrig		init 0						; reinit, start over from start of pitch table
	kretrig		= (gkPtrkTrig == 1 ? kretrig+1 : kretrig)	; if at count 1 of measure, step up
	kretrig1	= (kretrig > (gkPtrg1-1) ? 1 : 0 )		; if over threshold, retrig
	kretrig1	= (gkPtrg1 == 0 ? 0 : kretrig1 )		; if set to retrig every 0 measures, do not retrig
	kretrig 	= (kretrig > (gkPtrg1-1) ? 0 : kretrig )	; if over threshold, start over from zero

if kretrig1 == 0 goto skipretrig
reinit	skipretrig
skipretrig:
	iold		= i(gkGrn2grfq)
	gk182active	= 1
	ifn		table	i(gkPn2), 186		; table lookup for playback track selection
	kndx		line	0, 1, kr		; goes on forever
	itablen		tableng	i(gkPn2)
	kndx		= (kndx > itablen ? itablen : kndx)
	kcps		table	kndx, ifn		; read pitch
	krms		table	kndx, ifn+1		; read amp
rireturn
	kcps		= kcps * gkPmulti1
	gkGrn4grfq	= (kcps > 30 ? kcps : gkGrn4grfq)			; pitchmel to grain freq

	if gktPAmp1 == 0 kgoto skipamp

	gksGrain4amp	= (krms > gkPa2 ? krms*0.0001*gkPa1 : gkPa2)	; amp thresh and amount
	skipamp:

endin
;****************************************************************
;****************************************************************
;playback of recorded pitches, to Grain Transpose, Grain Module 4
instr 183

	kretrig		init 0						; reinit, start over from start of pitch table
	kretrig		= (gkPtrkTrig == 1 ? kretrig+1 : kretrig)	; if at count 1 of measure, step up
	kretrig1	= (kretrig > (gkPtrg2-1) ? 1 : 0 )		; if over threshold, retrig
	kretrig1	= (gkPtrg2 == 0 ? 0 : kretrig1 )		; if set to retrig every 0 measures, do not retrig
	kretrig 	= (kretrig > (gkPtrg2-1) ? 0 : kretrig )	; if over threshold, start over from zero

if kretrig1 == 0 goto skipretrig
reinit	skipretrig
skipretrig:
	ifn		table	i(gkPn3), 186		; table lookup for playback track selection
	kndx		line	0, 1, kr		; goes on forever
	itablen		tableng	i(gkPn2)
	kndx		= (kndx > itablen ? itablen : kndx)
	kcps		table	kndx, ifn		; read pitch
	krms		table	kndx, ifn+1		; read amp
rireturn
	kcps		= kcps * gkPmulti2
	gkGrn4form	= (kcps > 30 ? kcps/220 : gkGrn4form)			; pitchmel to grain transp

	if gktPAmp2 == 0 kgoto skipamp
	gksGrain4amp	= (krms > gkPa4 ? krms*0.0001*gkPa3 : gkPa4)	; amp thresh and amount
	skipamp:

endin
;****************************************************************
;****************************************************************
;playback of recorded pitches, to FM Freq (FM aux effect)
instr 184

	kretrig		init 0						; reinit, start over from start of pitch table
	kretrig		= (gkPtrkTrig == 1 ? kretrig+1 : kretrig)	; if at count 1 of measure, step up
	kretrig1	= (kretrig > (gkPtrg3-1) ? 1 : 0 )		; if over threshold, retrig
	kretrig1	= (gkPtrg3 == 0 ? 0 : kretrig1 )		; if set to retrig every 0 measures, do not retrig
	kretrig 	= (kretrig > (gkPtrg3-1) ? 0 : kretrig )	; if over threshold, start over from zero

if kretrig1 == 0 goto skipretrig
reinit	skipretrig
skipretrig:
	ifn		table	i(gkPn4), 186		; table lookup for playback track selection
	kndx		line	0, 1, kr		; goes on forever
	itablen		tableng	i(gkPn2)
	kndx		= (kndx > itablen ? itablen : kndx)
	kcps		table	kndx, ifn		; read pitch
	krms		table	kndx, ifn+1		; read amp
rireturn
	kcps		= kcps * gkPmulti3
	gkfx_fm_mfrq	= (kcps > 30 ? kcps*2 : gkfx_fm_mfrq)	; pitchmel to FM Freq

endin
;****************************************************************
;****************************************************************
;playback of recorded pitches, to AmpMod Freq (AM aux effect)
instr 185

	kretrig		init 0						; reinit, start over from start of pitch table
	kretrig		= (gkPtrkTrig == 1 ? kretrig+1 : kretrig)	; if at count 1 of measure, step up
	kretrig1	= (kretrig > (gkPtrg4-1) ? 1 : 0 )		; if over threshold, retrig
	kretrig1	= (gkPtrg4 == 0 ? 0 : kretrig1 )		; if set to retrig every 0 measures, do not retrig
	kretrig 	= (kretrig > (gkPtrg4-1) ? 0 : kretrig )	; if over threshold, start over from zero

if kretrig1 == 0 goto skipretrig
reinit	skipretrig
skipretrig:
	ifn		table	i(gkPn5), 186		; table lookup for playback track selection
	kndx		line	0, 1, kr		; goes on forever
	itablen		tableng	i(gkPn2)
	kndx		= (kndx > itablen ? itablen : kndx)
	kcps		table	kndx, ifn		; read pitch
	krms		table	kndx, ifn+1		; read amp
rireturn
	kcps		= kcps * gkPmulti4
	gkfx_rm_mfrq	= (kcps > 30 ? kcps*2 : gkfx_rm_mfrq)	; pitchmel to AM Freq

endin
;****************************************************************


;****************************************************************
;playback of recorded pitches, BassSynth
instr 186

	kretrig		init 0						; reinit, start over from start of pitch table
	kretrig		= (gkPtrkTrig == 1 ? kretrig+1 : kretrig)	; if at count 1 of measure, step up
	kretrig1	= (kretrig > (gkPtrg5-1) ? 1 : 0 )		; if over threshold, retrig
	kretrig1	= (gkPtrg5 == 0 ? 0 : kretrig1 )		; if set to retrig every 0 measures, do not retrig
	kretrig 	= (kretrig > (gkPtrg5-1) ? 0 : kretrig )	; if over threshold, start over from zero

if kretrig1 == 0 goto skipretrig
reinit	skipretrig
skipretrig:
	ifn		table	i(gkPn6), 186		; table lookup for playback track selection
	kndx		line	0, 1, kr		; goes on forever
	itablen		tableng	i(gkPn2)
	kndx		= (kndx > itablen ? itablen : kndx)
	kcps		table	kndx, ifn		; read pitch
	krms		table	kndx, ifn+1		; read amp
rireturn
	krms		limit	krms, 0, 5000		; limit amp fluctuation of bass synth
	kcps		= kcps * gkPmulti5 * 0.5	; octave down

	iamp		= 1500
	kamp		= iamp 
	kthresh		= 0						
	kampmod		= gkPa5
	kamp		= (krms > kthresh ? krms*kampmod : kamp)	; amp thresh and amount
	amp		= kamp * gkBasSynAmp
	amp		tone	amp, 50

	abogus	rand	1				; bogus low amp noise signal
	a1	oscil	amp, kcps, 95
	a1	= a1 + abogus				; prevent filter underflow
	asine	oscil	amp, kcps, 93
	kfilt	tonek	kamp,	0.45
	alo	lpf18	a1/32768, 20+(kfilt*0.3), 0.4, 0.4
	alo	= (alo *32768) + (asine * 3)
	alo	dcblock	alo				; experimental, declick at note off

; VU meter
;kVu	maxk	alo, gkupdate1, 0
;	FLsetVal	gkupdate1, kVu, gihsBasSynampD

;EFX and dry out amplitudes
	zawm	alo * gkBasSyn_clean ,	4	; send to clean out Left
	zawm	alo * gkBasSyn_clean , 	5	; send to clean out Right
	zawm	alo * gkBasSyn_rm ,	6	; send to ring mod
	zawm	alo * gkBasSyn_fm ,	7	; send to freq mod
	zawm	alo * gkBasSyn_filt1,	8	; send to filter 1
	zawm	alo * gkBasSyn_dist ,	9	; send to distrortion
	zawm	alo * gkBasSyn_filt2,	10	; send to filter 2
	zawm	alo * gkBasSyn_del1,	11	; send to delay 1
	zawm	alo * gkBasSyn_del2,	12	; send to delay 2
	zawm	alo * gkBasSyn_revb,	13	; send to reverb
;	zawm	alo,			14	; to output file

endin
;****************************************************************


;****************************************************************
;****************************************************************

instr 200 ; 

; writing of "last recorded sound"
gkLastRec	= p5


; sorting of stored sounds related to sound length, in ascending order
; shortest sound has indx=1 in ftable 111.
; the indexes in ftable111 points to ftable numbers 1 to 14 where audio is stored

; ekspandere listen med "current rekkef�lge" lage mellomrom i den,
; skrive inn ny lyd i hullet mellom to eksisterende.
; kollapse listen ved � fjerne nuller og dobbeltoppf�ringer

is1	table	1, 111
is2	table	2, 111
is3	table	3, 111
is4	table	4, 111
is5	table	5, 111
is6	table	6, 111
is7	table	7, 111
is8	table	8, 111
is9	table	9, 111
is10	table	10, 111
is11	table	11, 111
is12	table	12, 111
is13	table	13, 111
is14	table	14, 111
is15	table	15, 111
is16	table	16, 111

i1	table is1, 110
i2	table is2, 110
i3	table is3, 110
i4	table is4, 110
i5	table is5, 110
i6	table is6, 110
i7	table is7, 110
i8	table is8, 110
i9 	table is9, 110
i10	table is10, 110
i11	table is11, 110
i12	table is12, 110
i13	table is13, 110
i14	table is14, 110
i15	table is15, 110
i16	table is16, 110

; finding the index for the new sound, in the sorted list
; comparing the length of the new sound to the stored sounds, in ascending order
; e.g. if its longer than the one at index 2, assume it as number 3 in the list
; then compare if it's longer than number 3 in the list etcetera
; skip test if comparing with an empty storage location (length = 0)
; inew is length of new sound
; i1 is length of stored sound 1
; is1 is index number of shortest stored sound
; iindx is index number of new sound 

inew	= p4				; inew is length of new sound
iindx	= p5				; audio storage index

if inew == 0 goto newzero		; if sound has been cleared (length recorded = zero)
goto newcompare

newzero:
indxnew = 16				; to be sorted as the longest sound
goto skiptest

newcompare:
; FIXX this section ??
indxnew	= 1
if i1	== 0 goto skiptest
indxnew	= (inew > i1 ? 2 : indxnew )
if i2	== 0 goto skiptest
indxnew	= (inew > i2 ? 3 : indxnew )
if i3	== 0 goto skiptest
indxnew	= (inew > i3 ? 4 : indxnew )
if i4	== 0 goto skiptest
indxnew	= (inew > i4 ? 5 : indxnew )
if i5	== 0 goto skiptest
indxnew	= (inew > i5 ? 6 : indxnew )
if i6	== 0 goto skiptest
indxnew	= (inew > i6 ? 7 : indxnew )
if i7	== 0 goto skiptest
indxnew	= (inew > i7 ? 8 : indxnew )
if i8	== 0 goto skiptest
indxnew	= (inew > i8 ? 9 : indxnew )
if i9	== 0 goto skiptest
indxnew	= (inew > i9 ? 10 : indxnew )
if i10	== 0 goto skiptest
indxnew	= (inew > i10 ? 11 : indxnew )
if i11	== 0 goto skiptest
indxnew	= (inew > i11 ? 12 : indxnew )
if i12	== 0 goto skiptest
indxnew	= (inew > i12 ? 13 : indxnew )
if i13	== 0 goto skiptest
indxnew	= (inew > i13 ? 14 : indxnew )
if i14	== 0 goto skiptest
indxnew	= (inew > i14 ? 15 : indxnew )
if i15	== 0 goto skiptest
indxnew	= (inew > i15 ? 16 : indxnew )
skiptest:

; delete values to be stored in table 112 that equals iindx,
; to avoid duplicates, avoid the table exploding

is1	= (is1 == iindx ? 0 : is1)
is2	= (is2 == iindx ? 0 : is2)
is3	= (is3 == iindx ? 0 : is3)
is4	= (is4 == iindx ? 0 : is4)
is5	= (is5 == iindx ? 0 : is5)
is6	= (is6 == iindx ? 0 : is6)
is7	= (is7 == iindx ? 0 : is7)
is8	= (is8 == iindx ? 0 : is8)
is9	= (is9 == iindx ? 0 : is9)
is10	= (is10 == iindx ? 0 : is10)
is11	= (is11 == iindx ? 0 : is11)
is12	= (is12 == iindx ? 0 : is12)
is13	= (is13 == iindx ? 0 : is13)
is14	= (is14 == iindx ? 0 : is14)
is15	= (is15 == iindx ? 0 : is15)
is16	= (is16 == iindx ? 0 : is16)

; temporal storage of index numbers,
; stored with a space in between each one in f112, (expanded list)
; to make room for writing the new index in between
; spaces are later collapsed, and the list written back to f111
tablecopy	112, 113		; clear f112
	tableiw	is16, 32, 112		; expand list
	tableiw	is15, 30, 112
	tableiw	is14, 28, 112
	tableiw	is13, 26, 112
	tableiw	is12, 24, 112
	tableiw	is11, 22, 112
	tableiw	is10, 20, 112
	tableiw	is9, 18, 112
	tableiw	is8, 16, 112
	tableiw	is7, 14, 112
	tableiw	is6, 12, 112
	tableiw	is5, 10, 112
	tableiw	is4, 8, 112
	tableiw	is3, 6, 112
	tableiw	is2, 4, 112
	tableiw	is1, 2, 112

	indxnew2 = (2*indxnew)-1	; write new indx in expanded list
	tableiw	iindx, indxnew2, 112

; check for duplicates in f112 ******************* FIX !!

; read expanded list from f112
; compress the list and write to f111
in2 init 0
in1 init 0
ie2 init 0
loopstart:

in2	= in2 + 1
if in2 > 32 goto done
ie	table in2, 112

if ie2 = ie goto skipduplicate
ie2	= ie
goto insert

skipduplicate:
ie2	= ie
goto loopstart

insert:
if ie == 0 goto loop
in1	= in1 + 1
	tableiw	ie, in1, 111

loop:
goto loopstart
done:


end:

;read sound lengths from ftable 110
; print to GUI FLvalue
isnd1	table 1, 110
isnd2	table 2, 110
isnd3	table 3, 110
isnd4	table 4, 110
isnd5	table 5, 110
isnd6	table 6, 110
isnd7	table 7, 110
isnd8	table 8, 110
isnd9	table 9, 110
isnd10	table 10, 110
isnd11	table 11, 110
isnd12	table 12, 110
isnd13	table 13, 110
isnd14	table 14, 110

isnd1	= (isnd1 < 0.2 ? 0 : isnd1)
isnd2	= (isnd2 < 0.2 ? 0 : isnd2)
isnd3	= (isnd3 < 0.2 ? 0 : isnd3)
isnd4	= (isnd4 < 0.2 ? 0 : isnd4)
isnd5	= (isnd5 < 0.2 ? 0 : isnd5)
isnd6	= (isnd6 < 0.2 ? 0 : isnd6)
isnd7	= (isnd7 < 0.2 ? 0 : isnd7)
isnd8	= (isnd8 < 0.2 ? 0 : isnd8)
isnd9	= (isnd9 < 0.2 ? 0 : isnd9)
isnd10	= (isnd10 < 0.2 ? 0 : isnd10)
isnd11	= (isnd11 < 0.2 ? 0 : isnd11)
isnd12	= (isnd12 < 0.2 ? 0 : isnd12)
isnd13	= (isnd13 < 0.2 ? 0 : isnd13)
isnd14	= (isnd14 < 0.2 ? 0 : isnd14)

FLprintk2	isnd1, gihsnd1
FLprintk2	isnd2, gihsnd2
FLprintk2	isnd3, gihsnd3
FLprintk2	isnd4, gihsnd4
FLprintk2	isnd5, gihsnd5
FLprintk2	isnd6, gihsnd6
FLprintk2	isnd7, gihsnd7
FLprintk2	isnd8, gihsnd8
FLprintk2	isnd9, gihsnd9
FLprintk2	isnd10, gihsnd10
FLprintk2	isnd11, gihsnd11
FLprintk2	isnd12, gihsnd12
FLprintk2	isnd13, gihsnd13
FLprintk2	isnd14, gihsnd14


; write updated list of soundlength to ftable 114,
; f113 will be an exact copy of f110, but is updated *after" recordin is finished
; this is used in e.g. Grain modules, to update sound length
	tableiw	isnd1, 1, 114
	tableiw	isnd2, 2, 114
	tableiw	isnd3, 3, 114
	tableiw	isnd4, 4, 114
	tableiw	isnd5, 5, 114
	tableiw	isnd6, 6, 114
	tableiw	isnd7, 7, 114
	tableiw	isnd8, 8, 114
	tableiw	isnd9, 9, 114
	tableiw	isnd10, 10, 114
	tableiw	isnd11, 11, 114
	tableiw	isnd12, 12, 114
	tableiw	isnd13, 13, 114
	tableiw	isnd14, 14, 114

endin
;****************************************************************

;****************************************************************
; Clear single sounds, and update sound length info
;****************************************************************
	instr	201

; *** clear table
i_count		= p4
tableicopy	i_count, 15 	; clear table (copy from empty table)

; *** write zero as sound length to table
ktime	init 0
tablew	ktime, i_count, 110

;sort sound lengths, re-sort after clearing table
schedkwhen	1, 0, 1, 200, 0, 0.1, ktime, i_count	; initiate sorting of soundlength 

endin
;****************************************************************

;***********************************************************************
; rythm synthesizer, separated into 2 rythmic levels:  grid, phrase
;***********************************************************************

;****************************************************************
; rythm synthesizer level 1 : grid
;****************************************************************
	instr	255

FLprintk2	gktR, gihtRythmv	; display playing status (start/stop)

kbtpo		= 60 / gkbtpo 		; base tempo in seconds (1 = 60 bpm)
gkbtpo_cps	= 1 / kbtpo		; base tempo in cps


; *** ktrig1 is rythmic level 1, counting/trigging the subdivisions of the grid
ktimeunit	= gkbtpo_cps / gkout_tim1
ktrig1		metro	ktimeunit
ktrig1tim4	metro	ktimeunit * 4


; *** trigseq supply duration and accent info for each subdivision of the grid

kloop		= gkbeats 			; kloop point is "group index" no 
kfn_time1	init 201			; init time signature
kfn_time1	= gktimesign1			; set time signature
kout_ndx	init 0
kbeats		init 4
kout_tim1	init 1
kout_amp1	init 1
trigseq	ktrig1, 0, kloop, 0, kfn_time1, kout_ndx, kbeats, kout_tim1, kout_amp1	; get values from table
gkout_tim1	= kout_tim1

klastbeat	= (kout_ndx == kbeats ? 1 : 0) ; set to 1 if current beat is last in a measure
gktimesign1	= (klastbeat == 1 ? gktimesign : gktimesign1) ;update current time signature at end of each measure

gkbeats		= kbeats

; Drumloop trigging
klooptrig	= (kout_ndx == 1 ? 1 : 0)
klooptrig1a	trigger klooptrig, 0.5, 0		; down-up gate
gkBeatOne	trigger klooptrig1a, 0.5, 0		; master clock beat of One
klooptrig1b	init 0
klooptrig1b	= klooptrig1b + klooptrig1a		; create step-up sequence
klooptrig1b	= (klooptrig1b > 1 ? 0 : klooptrig1b)	; cyclic behaviour: 0,1,0,1...

; Trigger to reinit pitch track playback modules, jump to start of pitch track table at count 1 of a measure
aPtrkTrig	upsamp	klooptrig1a			; neccessary because there is no k-rate delay opcode
aPtrkTrig	delay	aPtrkTrig, gi_snc_delay		; sync delay trigger signal
gkPtrkTrig	downsamp aPtrkTrig			; trigger to Pitch Track playback every 1 of a measure

;Force retrig drumloop when GUI actions for loop on, loop pitch and loop number select has occured
gkbtLoopOn_old	init i(gkbtLoopOn)
gkdrumlop_pt_o	init i(gkdrumlop_ptch)
gkDrmLopN_old	init i(gkDrmLopN)
klopGUItest	= gkbtLoopOn + gkdrumlop_ptch + gkDrmLopN
klopGUItest_old	= gkbtLoopOn_old + gkdrumlop_pt_o + gkDrmLopN_old
klooptrig1b	= (klopGUItest_old = klopGUItest ? klooptrig1b : 0) ; force trig loop if loopparams was changed via GUI
gkbtLoopOn_old	= gkbtLoopOn
gkdrumlop_pt_o	= gkdrumlop_ptch
gkDrmLopN_old	= gkDrmLopN

klooptrig1	trigger klooptrig1b, 0.5, 0		; down-up gate, trigs drumloop start every 2nd measure
klooptrig1	= klooptrig1 * gkbtLoopOn		; trig loop only when Loop On button is active
; separate retrig button, temporary out of 2-bar phrase, but keep 2 bar period
klooptrig1Rtrig	= (gkButnRetrig1 = 1 ? ktrig1 : 0 ) ; force trig loop if Button pressed
printk2 gkButnRetrig1
gkButnRetrig1	= 0	;reset for next test
klooptrig1	= (klooptrig1Rtrig == 1 ? klooptrig1Rtrig : klooptrig1)

gkdrmoff	= (klooptrig1 = 1 ? 0 : gkdrmoff )		; reinit note-off trigger
schedkwhen	klooptrig1, 0, 0,  350, gi_snc_delay, -1	; trig drumloop, sync-delayed

gkptrnoff	= (klooptrig1 = 1 ? 0 : gkptrnoff )		; reinit note-off trigger
schedkwhen	klooptrig1a, 0, 0,  261, 0, -1			; trig patternclock

; metronome sound
kmetrotrig	= ktrig1 * gkmetro_on
schedkwhen	kmetrotrig, 0, 0, 340, gi_snc_delay, 1, kout_amp1	; trig metronome sound, sync-delayed

; midi metronome
;kmetrotrigM	= ktrig1 * gkmetro_onM
;schedkwhen	kmetrotrigM, 0, 0, 345, gi_snc_delay, 1, kout_amp1	; trig metronome sound, sync-delayed


; the (gi_snc_delay) delay to schedkwhen opcodes when trigging "straight" sounds make them sync
; with the live-recorded ones, as the live recorded ones have an inherent delay at the start
; of the sound, due to fade in curve when recording

; the following sets "phrase end" flag when the user changes tablenumber for the rythm via GUI
; this faciliates user cross-combination of rythm phrases

krytm1phrase	init 0
krytm1change	init 1
krytm1change	= (krytm1phrase == gk_ryt_phrase ? 0 : 1)	; if rythm table changed since last k-pass, set flag to 1
;gk_endflag	= (krytm1change == 1 ? 1 : gk_endflag)		; and set "phrase end" flag
;gk_forcetrig1	= (krytm1change == 1 ? 1 : gk_forcetrig1)	; and set "force trig" flag
gktrig_phr	= (krytm1change == 1 ? 1 : gktrig_phr)		; and set "trig enable" flag
krytm1phrase	= gk_ryt_phrase					; then update local var from global, for comparision next k-pass

krytm2phrase	init 0
krytm2change	init 1
krytm2change	= (krytm2phrase == gk_ryt_phrase2 ? 0 : 1)	; if rythm table changed since last k-pass, set flag to 1
;gk_endflag2	= (krytm2change == 1 ? 1 : gk_endflag2)		; and set "phrase end" flag
;gk_forcetrig2	= (krytm2change == 1 ? 1 : gk_forcetrig2)	; and set "force trig" flag
gktrig_phr2	= (krytm2change == 1 ? 1 : gktrig_phr2)		; and set "trig enable" flag
krytm2phrase	= gk_ryt_phrase2				; then update local var from global, for comparision next k-pass

krytm3phrase	init 0
krytm3change	init 1
krytm3change	= (krytm3phrase == gk_ryt_phrase3 ? 0 : 1)	; if rythm table changed since last k-pass, set flag to 1
;gk_endflag3	= (krytm3change == 1 ? 1 : gk_endflag3)		; and set "phrase end" flag
gktrig_phr3	= (krytm3change == 1 ? 1 : gktrig_phr3)		; and set "trig enable" flag
krytm3phrase	= gk_ryt_phrase3				; then update local var from global, for comparision next k-pass

; the following generates phrase pauses, 
; 1. watch for "end of phrase" indication
; 2. set minimum and maximum "metro ticks" pause before enabling next phrase trig
; 2. count the allowed number of metro ticks before trigging next phrase

kpause1		init 0
kpause2		init 0
kpause3		init 0

; trigger signal when a rythmic phrase has ended
k_end1		trigger	gk_endflag, 0.5, 0
k_end2		trigger	gk_endflag2, 0.5, 0
k_end3		trigger	gk_endflag3, 0.5, 0
; reset counter after phrase end
kpause1		= (k_end1 == 1 ? 0 : kpause1)
kpause2		= (k_end2 == 1 ? 0 : kpause2)
kpause3		= (k_end3 == 1 ? 0 : kpause3)
; reset trig_phrase to zero flag after phrase end
gktrig_phr	= (k_end1 == 1 ? 0 : gktrig_phr)
gktrig_phr2	= (k_end2 == 1 ? 0 : gktrig_phr2)
gktrig_phr3	= (k_end3 == 1 ? 0 : gktrig_phr3)
; count the metroticks during pause
kpause1		= kpause1 + (ktrig1 * gk_endflag)
kpause2		= kpause2 + (ktrig1 * gk_endflag2)
kpause3		= kpause3 + (ktrig1 * gk_endflag3)
; generate random number for pause duration (number of metroticks in pause)
kpauseN1	rspline	gkminpause1, gkmaxpause1, 0.2, 0.8
kpauseN2	rspline	gkminpause2, gkmaxpause2, 0.2, 0.8
kpauseN3	rspline	gkminpause3, gkmaxpause3, 0.2, 0.8
; when counted metroticks exceeds the wanted pause length, set flag to enable trig phrase
gktrig_phr	= (kpause1 > kpauseN1 ? 1 : gktrig_phr)
gktrig_phr2	= (kpause2 > kpauseN2 ? 1 : gktrig_phr2)
gktrig_phr3	= (kpause3 > kpauseN3 ? 1 : gktrig_phr3)

; re-init, if rythm module is turned off and then on again during the same session
gk_endflag	init 1
gk_endflag2	init 1
gk_endflag3	init 1


; the following section turns on instr 6, for phrase generation, PHRASE 1
; and contains code for handling "force trig" and "loop current phrase" commands

k6off		trigger gk_endflag, 0.5, 0

if gk_forcetrig1 == 1 kgoto forcetrig1				; allow for force trigging at any time
if gkloop_phr1	== 1 kgoto skipoff1 				; allow for phrase to loop itself without turnoff/retrig from ktrig1
if gk_endflag 	== 0 kgoto end1					; if no endflag is set, goto end
kgoto contin1

forcetrig1:
schedkwhen	ktrig1, 0, 0, -256, 0, 1				; turn off instr 6
schedkwhen	ktrig1, 0, 1, 256, 0, -1				; trig phrase (instr 6)
goto end1

contin1:
schedkwhen	k6off, 0, 0, -256, 0, 1				; turn off instr 6

skipoff1:
ktrig1t		= ktrig1 * gktrig_phr 				; phrase trigging only if both values nonzero
schedkwhen	ktrig1t, 0, 1, 256, 0, -1				; trig phrase (instr 6)

end1:

; the following section turns on instr 7, for phrase generation, PHRASE 2
; and contains code for handling "force trig" and "loop current phrase" commands

k7off		trigger gk_endflag2, 0.5, 0

if gk_forcetrig2 == 1 kgoto forcetrig2				; allow for force trigging at any time
if gkloop_phr2	== 1 kgoto skipoff2 				; allow for phrase to loop itself without turnoff/retrig from ktrig1
if gk_endflag2 	== 0 kgoto end2					; if no endflag is set, goto end
kgoto contin2

forcetrig2:
schedkwhen	ktrig1, 0, 0, -257, 0, 1				; turn off instr 7
schedkwhen	ktrig1, 0, 1, 257, 0, -1				; trig phrase (instr 7)
goto end2

contin2:
schedkwhen	k7off, 0, 0, -257, 0, 1				; turn off instr 7

skipoff2:
ktrig2		= ktrig1 * gktrig_phr2 				; phrase trigging only if both values nonzero
schedkwhen	ktrig2, 0, 1, 257, 0, -1				; trig phrase (instr 7)

end2:

; the following section turns on instr 8, for phrase generation, PHRASE 3
; and contains code for handling "force trig" and "loop current phrase" commands

k8off		trigger gk_endflag3, 0.5, 0

if gk_forcetrig3 == 1 kgoto forcetrig3				; allow for force trigging at any time
if gkloop_phr3	== 1 kgoto skipoff3 				; allow for phrase to loop itself without turnoff/retrig from ktrig1
if gk_endflag3 	== 0 kgoto end3					; if no endflag is set, goto end
kgoto contin3

forcetrig3:
schedkwhen	ktrig1, 0, 0, -258, 0, 1				; turn off instr 8
schedkwhen	ktrig1, 0, 1, 258, 0, -1				; trig phrase (instr 8)
goto end3

contin3:
schedkwhen	k8off, 0, 0, -258, 0, 1				; turn off instr 8

skipoff3:
ktrig3		= ktrig1 * gktrig_phr3 				; phrase trigging only if both values nonzero
schedkwhen	ktrig3, 0, 1, 258, 0, -1				; trig phrase (instr 8)

end3:

endin
;****************************************************************
;****************************************************************

;****************************************************************
; rythm synthesizer level 2 : phrase1
;****************************************************************
	instr	256

; *** ktrig2is rythmic level 2 counting/trigging the subdivisions of the grid
ktrig2		metro	gkbeatcps		; gkbeatcps is retreived from rythm phrase table (trigseq opcode below)

; *** trigseq supply duration and accent info for each event in the phrase
knumevents	= gknumevents			; number of events in the phrase
kloop		= knumevents 			; kloop point is "group index" no 
kfn_time2	init 301			; table number for rythm, phrase
kfn_time2	= i(gk_ryt_phrase)		; from GUI selector, changeable only at start of each new phrase
imaxphrase	= 7 - 0.01
irand_time	= int(rnd(imaxphrase))+301
kfn_time2	= (kfn_time2 == 300 ? irand_time : kfn_time2)	; GUI select phrase zero, -> random selection

kout_ndx	init 0
kout_num	init 1
kout_tim2	init 1
kout_amp2	init 1
k_endflag	init 0
trigseq	ktrig2, 0, kloop, 0, kfn_time2, kout_ndx, kout_num, kout_tim2, kout_amp2, k_endflag  ; get values from table
gkbeatcps	= abs(gkbtpo_cps * kout_tim2 * i(gk_ryt_fact1))
ktrig2		= (kout_tim2 < 0 ? 0 : ktrig2)			; if negative dur, rest
gk_endflag	= k_endflag
gknumevents	= kout_num

; this scheduling is for metro/phrase-tick only,
; the random player and other processes get their trig directly from gktrig
kphrasetick	= ktrig2 * gkphrasetick
schedkwhen	kphrasetick, 0, 0, 341, gi_snc_delay, 1, kout_amp2		; trig metronome sound 2

gktrig		= ktrig2 			; gktrig follows phrase metro
gkout_amp2	= kout_amp2

endin
;****************************************************************
;****************************************************************

;****************************************************************
; rythm synthesizer level 2 : phrase2
;****************************************************************
	instr	257

; *** ktrig2is rythmic level 2 counting/trigging the subdivisions of the grid
ktrig2		metro	gkbeatcps2		; gkbeatcps is retreived from rythm phrase table (trigseq opcode below)

; *** trigseq supply duration and accent info for each event in the phrase
knumevents	= gknumevents2			; number of events in the phrase
kloop		= knumevents 			; kloop point is "group index" no 
kfn_time2	init 301			; table number for rythm, phrase
kfn_time2	= i(gk_ryt_phrase2)		; from GUI selector, changeable only at start of each new phrase
imaxphrase	= 7 - 0.01
irand_time	= int(rnd(imaxphrase))+301
kfn_time2	= (kfn_time2 == 300 ? irand_time : kfn_time2)	; GUI select phrase zero, -> random selection

kout_ndx	init 0
kout_num	init 1
kout_tim2	init 1
kout_amp2	init 1
k_endflag	init 0
trigseq	ktrig2, 0, kloop, 0, kfn_time2, kout_ndx, kout_num, kout_tim2, kout_amp2, k_endflag  ; get values from table
gkbeatcps2	= abs(gkbtpo_cps * kout_tim2 * i(gk_ryt_fact2))
ktrig2		= (kout_tim2 < 0 ? 0 : ktrig2)			; if negative dur, rest
gk_endflag2	= k_endflag
gknumevents2	= kout_num

; this scheduling is for metro/phrase-tick only,
; the random player and other processes get their trig directly from gktrig
kphrasetick	= ktrig2 * gkphrasetick2
schedkwhen	kphrasetick, 0, 0, 342, gi_snc_delay, 1, kout_amp2		; trig metronome sound 2

gktrig2		= ktrig2 			; gktrig follows phrase metro
gkout_amp22	= kout_amp2

endin
;****************************************************************
;****************************************************************

;****************************************************************
; rythm synthesizer level 2 : phrase3
;****************************************************************
	instr	258

; *** ktrig2is rythmic level 2 counting/trigging the subdivisions of the grid
ktrig2		metro	gkbeatcps3		; gkbeatcps is retreived from rythm phrase table (trigseq opcode below)

; *** trigseq supply duration and accent info for each event in the phrase
knumevents	= gknumevents3			; number of events in the phrase
kloop		= knumevents 			; kloop point is "group index" no 
kfn_time2	init 301			; table number for rythm, phrase
kfn_time2	= i(gk_ryt_phrase3)		; from GUI selector, changeable only at start of each new phrase
imaxphrase	= 7 - 0.01
irand_time	= int(rnd(imaxphrase))+301
kfn_time2	= (kfn_time2 == 300 ? irand_time : kfn_time2)	; GUI select phrase zero, -> random selection

kout_ndx	init 0
kout_num	init 1
kout_tim2	init 1
kout_amp2	init 1
k_endflag	init 0
trigseq	ktrig2, 0, kloop, 0, kfn_time2, kout_ndx, kout_num, kout_tim2, kout_amp2, k_endflag  ; get values from table
gkbeatcps3	= abs(gkbtpo_cps * kout_tim2 * i(gk_ryt_fact3))* 2	; twice the speed of "normal" rythms
ktrig2		= (kout_tim2 < 0 ? 0 : ktrig2)			; if negative dur, rest
gk_endflag3	= k_endflag
gknumevents3	= kout_num

; this scheduling is for metro/phrase-tick only,
; the random player and other processes get their trig directly from gktrig
imaxinst	= 0 ; 50
imintime	= 0 ; 0.0001 ; (1/kr)*4

kphrasetick	= ktrig2 * gkphrasetick3
schedkwhen	kphrasetick, imintime, imaxinst, 343, gi_snc_delay, 1, kout_amp2	; trig metronome sound 3
	
gktrig3		= ktrig2 					; gktrig follows phrase metro
								; gktrig3 is for RAG
gkout_amp32	= kout_amp2
endin
;****************************************************************
;****************************************************************


;****************************************************************
; rythm synthesizer level 3 : phrase control
;****************************************************************
	instr	260




endin
;****************************************************************
;****************************************************************

;****************************************************************
; rythm synthesizer level 4 : PatternSequencer clock & trig
;****************************************************************
	instr	261

if gkptrnoff = 0 kgoto contin
schedkwhen	1, 0, 1, -339, 0, 0.1		; stop efx and output instr for PatternSeq
turnoff
contin:

schedkwhen	1, 0, 1, 339, 0, -1		; start efx and output instr for PatternSeq

;gkbtpo_cps		; base tempo in cps
ksubdiv		= 4
ktpo		= (gkbtpo_cps)*ksubdiv
ktick		metro	ktpo
kcount 		init 0
kcount		= (kcount > 16 ? 1 : kcount + ktick)

if gkbtPtSeqOn == 0 goto mute		; dont't trig any events unless module is activated
imaxlength	= 2.0			; limit max length of playback, cut off very long sounds

#define PatternTrig(A'B) #

kfno$A.		= gkpt$A.fno
ksoundlen$A.	table kfno$A., 110					; get length of actual audio segment stored
ksoundlen$A.	= (ksoundlen$A. > imaxlength ? imaxlength : ksoundlen$A.) ; limit max length of playback, cut off very long sounds

ktick$A._1	trigger	kcount, 0, 0
ktick$A._2	trigger	kcount, 1, 0
ktick$A._3	trigger	kcount, 2, 0
ktick$A._4	trigger	kcount, 3, 0
ktick$A._5	trigger	kcount, 4, 0
ktick$A._6	trigger	kcount, 5, 0
ktick$A._7	trigger	kcount, 6, 0
ktick$A._8	trigger	kcount, 7, 0
ktick$A._9	trigger	kcount, 8, 0
ktick$A._10	trigger	kcount, 9, 0
ktick$A._11	trigger	kcount, 10, 0
ktick$A._12	trigger	kcount, 11, 0
ktick$A._13	trigger	kcount, 12, 0
ktick$A._14	trigger	kcount, 13, 0
ktick$A._15	trigger	kcount, 14, 0
ktick$A._16	trigger	kcount, 15, 0

ktrig_ptrn$A._1	= gkptrn$A._1 * ktick$A._1
ktrig_ptrn$A._2	= gkptrn$A._2 * ktick$A._2
ktrig_ptrn$A._3	= gkptrn$A._3 * ktick$A._3
ktrig_ptrn$A._4	= gkptrn$A._4 * ktick$A._4
ktrig_ptrn$A._5	= gkptrn$A._5 * ktick$A._5
ktrig_ptrn$A._6	= gkptrn$A._6 * ktick$A._6
ktrig_ptrn$A._7	= gkptrn$A._7 * ktick$A._7
ktrig_ptrn$A._8	= gkptrn$A._8 * ktick$A._8
ktrig_ptrn$A._9	= gkptrn$A._9 * ktick$A._9
ktrig_ptrn$A._10	= gkptrn$A._10 * ktick$A._10
ktrig_ptrn$A._11	= gkptrn$A._11 * ktick$A._11
ktrig_ptrn$A._12	= gkptrn$A._12 * ktick$A._12
ktrig_ptrn$A._13	= gkptrn$A._13 * ktick$A._13
ktrig_ptrn$A._14	= gkptrn$A._14 * ktick$A._14
ktrig_ptrn$A._15	= gkptrn$A._15 * ktick$A._15
ktrig_ptrn$A._16	= gkptrn$A._16 * ktick$A._16

schedkwhen	ktrig_ptrn$A._1,  0, 0, $B., 0, ksoundlen$A.*gkp$A._1dur, gkpt$A.fno, gkp$A._1fm, gkp$A._1flt, gkptrn$A._1
schedkwhen	ktrig_ptrn$A._2,  0, 0, $B., 0, ksoundlen$A.*gkp$A._2dur, gkpt$A.fno, gkp$A._2fm, gkp$A._2flt, gkptrn$A._2
schedkwhen	ktrig_ptrn$A._3,  0, 0, $B., 0, ksoundlen$A.*gkp$A._3dur, gkpt$A.fno, gkp$A._3fm, gkp$A._3flt, gkptrn$A._3
schedkwhen	ktrig_ptrn$A._4,  0, 0, $B., 0, ksoundlen$A.*gkp$A._4dur, gkpt$A.fno, gkp$A._4fm, gkp$A._4flt, gkptrn$A._4
schedkwhen	ktrig_ptrn$A._5,  0, 0, $B., 0, ksoundlen$A.*gkp$A._5dur, gkpt$A.fno, gkp$A._5fm, gkp$A._5flt, gkptrn$A._5
schedkwhen	ktrig_ptrn$A._6,  0, 0, $B., 0, ksoundlen$A.*gkp$A._6dur, gkpt$A.fno, gkp$A._6fm, gkp$A._6flt, gkptrn$A._6
schedkwhen	ktrig_ptrn$A._7,  0, 0, $B., 0, ksoundlen$A.*gkp$A._7dur, gkpt$A.fno, gkp$A._7fm, gkp$A._7flt, gkptrn$A._7
schedkwhen	ktrig_ptrn$A._8,  0, 0, $B., 0, ksoundlen$A.*gkp$A._8dur, gkpt$A.fno, gkp$A._8fm, gkp$A._8flt, gkptrn$A._8
schedkwhen	ktrig_ptrn$A._9,  0, 0, $B., 0, ksoundlen$A.*gkp$A._9dur, gkpt$A.fno, gkp$A._9fm, gkp$A._9flt, gkptrn$A._9
schedkwhen	ktrig_ptrn$A._10, 0, 0, $B., 0, ksoundlen$A.*gkp$A._10dur, gkpt$A.fno, gkp$A._10fm, gkp$A._10flt, gkptrn$A._10
schedkwhen	ktrig_ptrn$A._11, 0, 0, $B., 0, ksoundlen$A.*gkp$A._11dur, gkpt$A.fno, gkp$A._11fm, gkp$A._11flt, gkptrn$A._11
schedkwhen	ktrig_ptrn$A._12, 0, 0, $B., 0, ksoundlen$A.*gkp$A._12dur, gkpt$A.fno, gkp$A._12fm, gkp$A._12flt, gkptrn$A._12
schedkwhen	ktrig_ptrn$A._13, 0, 0, $B., 0, ksoundlen$A.*gkp$A._13dur, gkpt$A.fno, gkp$A._13fm, gkp$A._13flt, gkptrn$A._13
schedkwhen	ktrig_ptrn$A._14, 0, 0, $B., 0, ksoundlen$A.*gkp$A._14dur, gkpt$A.fno, gkp$A._14fm, gkp$A._14flt, gkptrn$A._14
schedkwhen	ktrig_ptrn$A._15, 0, 0, $B., 0, ksoundlen$A.*gkp$A._15dur, gkpt$A.fno, gkp$A._15fm, gkp$A._15flt, gkptrn$A._15
schedkwhen	ktrig_ptrn$A._16, 0, 0, $B., 0, ksoundlen$A.*gkp$A._16dur, gkpt$A.fno, gkp$A._16fm, gkp$A._16flt, gkptrn$A._16

#

$PatternTrig.(1'335)		; pattern 1 plays instr 335
$PatternTrig.(2'336)		; pattern 2 plays instr 336
$PatternTrig.(3'337)		; pattern 3 plays instr 337

mute:

endin
;****************************************************************
;****************************************************************


;****************************************************************
; Preset handling instruments, no 270 to 273
;****************************************************************

instr 270
i1	= i(gkPresN)
inumSnap, inumVal FLsetsnap	i1
end:
endin

instr 271
i1	= i(gkPresN)
inumSnap	FLgetsnap	i1
endin

instr 272
FLsavesnap	"C:/IS_Jan05.pst"
endin

instr 273
FLloadsnap	"C:/IS_Jan05.pst"
endin

;****************************************************************
;****************************************************************




;****************************************************************
; analyse input amplitude, 
; schedule the sampling instr, 
; and give it an appropriate table number to write to
; Voice 1
;****************************************************************
	instr 	302
	a1,a2	ins
; midi controlled input volume
	a1	= a1 * gactrlvol1
	a2	= a2 * gactrlvol2

if gkinputmix == 0 kgoto skipmix
	a1	= (a1 + a2) * 0.5	; mix both inputs to sampler 1
skipmix:

	k_count		init i(gk_v1_minfno)
	k_atck		= gk_sampthresh1
	k_release	= gk_sampthresh1 * 0.2

	k_inamp		rms	a1, 10									; measure volume of input signal

ainamp	upsamp	k_inamp
; VU meter
;kVu	maxk	ainamp, gkupdate1, 0aVu	init 0
	maxabsaccum  aVu, ainamp
kVu	downsamp aVu
aVu	= 0

	FLsetVal	gkupdate1, kVu, gihInAmp1

;	gk_maxRMS1	init 0							; maximum rms value for each sound stored
;	gk_maxRMS1	= (k_inamp > gk_maxRMS1 ? k_inamp : gk_maxRMS1)		; update only when maximum is exceeded

if gk_manual1 > 0 goto manual
goto contin

manual:
	k_inamp	= gk_mantrig1*10001

contin:
	k_trig		trigger	k_inamp, k_atck, 0				; output 1 if signal is over threshold
	k_trig		= (gk304active == 1 ? 0 : k_trig)			; if sampling instr is active, no new trig should be allowed

	k_tr_off	trigger	k_inamp, k_release, 1
	k_tr_off	= (gk304active == 0 ? 0 : k_tr_off)			; if sampling instr is not active, no new trig is needed
	gk304off	= k_tr_off
	k_tr_off3d	vdelayk	k_tr_off, 0.2, 0.3				; delay  note off trigger
	gk304active	= 0							; reset indicator for sampling instr active, readu for next test
	k_count		= k_count+(k_trig*gk_next1)				; add 1 to k_trig if signal is over threshold, and next button active

; test if previous recorded sound was an error-recording (sound length less than 0.1 seconds)
; if error recording, go back to previous record location(ftable)
if k_trig == 0 kgoto skiptest			
	ksndlen	table k_count-1, 110
if ksndlen == 0 kgoto skiptest						; skip test if previous sound is cpmpletely empty, (never written to ftable)
	k_count	= (ksndlen < 0.05 ? k_count -1 : k_count)		; error recording is defined as a sample shorter than 0.2 seconds
skiptest:	

	k_count	= (k_count > gk_v1_maxfno ? gk_v1_minfno : k_count)	; cyclic counter behaviour
;	k_count	= (k_count < gk_v1_minfno ? gk_v1_minfno : k_count)	; avoid "below zero" counting (after successive -1 counts)
;	k_1	= 3
;	k_1	= (k_1 < gk_v1_minfno ? gk_v1_minfno : k_1)	; avoid "below zero" counting (after successive -1 counts)


	k_count	= (k_count == gksav1 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav2 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav3 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav4 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav5 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav6 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav7 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav8 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav9 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav10 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav11 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav12 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav13 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav14 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count

if k_count < (gk_v1_maxfno+1) kgoto skip_2ndtest
; second test to ensure correct "save" behaviour when wraparound from gk_v1_maxfno to gk_v1_minfno
	k_count = gk_v1_minfno
	k_count	= (k_count == gksav1 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav2 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav3 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav4 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav5 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav6 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav7 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav8 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav9 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav10 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav11 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav12 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav13 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav14 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
skip_2ndtest:

; check time stamp of recording, used to limit sample length (turn off sampling instr after isamplen seconds)
;isamplen	= 5.7		; max length of recording
;ktimStamp	times
;ktimStart	init 0
;ktimStart	= (k_trig == 1 ? ktimStamp : ktimStart )
;ktimeLen	= ktimStamp - ktimStart

;*** generate instr event for sampling /table-writing) instrument ***
;sampling instr scheduling
schedkwhen		k_trig,   0, 0,  304, 0, -1 , k_count	;note on
schedkwhen		k_tr_off3d, 0, 0, -304, 0, 1 , k_count	;note off

;pitch tracker scheduling
schedkwhen		k_trig,  	0, 0, 181, 0, -1, k_count	; on store pitch
schedkwhen		k_tr_off3d,  	0, 0, -181, 0, 1, k_count	; off store pitch

	a1d	delay a1, gi_snc_delay	; delay audio to be recorded, so rms and
					; control functions can set up in due time

zaw	a1d, 1
;outs	a1out*1.1, a1out*0.8	; test, just for recording demo

	endin
;****************************************************************
;****************************************************************

;****************************************************************
; analyse input amplitude, 
; schedule the sampling instr, 
; and give it an appropriate table number to write to
; Voice 2
;****************************************************************
	instr 	303
	a1,a2	ins

; midi controlled input volume
	a2	= a2 * gactrlvol2

	k_count	init i(gk_v2_minfno)
	k_atck	= gk_sampthresh2

	k_inamp	rms	a2, 2							;measure volume of input signal

; VU meter
;kVu	maxk	a2, gkupdate1, 0aVu	init 0
	maxabsaccum  aVu, a2
kVu	downsamp aVu
aVu	= 0

	FLsetVal	gkupdate1, kVu, gihInAmp2

;	gk_maxRMS2	init 0							; maximum rms value for each sound stored
;	gk_maxRMS2	= (k_inamp > gk_maxRMS2 ? k_inamp : gk_maxRMS2)		; update only when maximum is exceeded

if gk_manual2 > 0 goto manual
goto contin

manual:
	k_inamp	= gk_mantrig2*10001

contin:
	k_trig	trigger	k_inamp, k_atck, 0		;output 1 if signal is over threshold

	k_count	= k_count+(k_trig*gk_next2)				;add 1 to k_trig if signal is over threshold

; test if previous recorded sound was an error-recording (sound length less than 0.1 seconds)
; if error recording, go back to previous record location(ftable)
if k_trig == 0 kgoto skiptest			
	ksndlen	table k_count-1, 110
if ksndlen == 0 kgoto skiptest						; skip test if previous sound is cpmpletely empty, (never written to ftable)
	k_count	= (ksndlen < 0.05 ? k_count -1 : k_count)		; error recording is defined as a sample shorter than 0.2 seconds
skiptest:	

	k_count	= (k_count > gk_v2_maxfno ? gk_v2_minfno : k_count)	;cyclic counter behaviour
;	k_count	= (k_count < gk_v1_minfno ? gk_v1_minfno : k_count)	; avoid "below zero" counting (after successive -1 counts)


	k_count	= (k_count == gksav1 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav2 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav3 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav4 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav5 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav6 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav7 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav8 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav9 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav10 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav11 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav12 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav13 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav14 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count

if k_count < (gk_v2_maxfno+1) kgoto skip_2ndtest
; second test to ensure correct "save" behaviour when wraparound from gk_v1_maxfno to gk_v1_minfno
	k_count = gk_v2_minfno
	k_count	= (k_count == gksav1 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav2 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav3 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav4 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav5 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav6 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav7 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav8 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav9 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav10 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav11 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav12 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav13 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
	k_count	= (k_count == gksav14 ? k_count+1 : k_count)		; if current sound is marked "save" add 1 to k_count
skip_2ndtest:


; check time stamp of recording, used to limit sample length (turn off sampling instr after isamplen seconds)
isamplen	= 5.7		; max length of recording
ktimStamp	times
ktimStart	init 0
ktimStart	= (k_trig == 1 ? ktimStamp : ktimStart )
ktimeLen	= ktimStamp - ktimStart

;*** generate instr event for sampling /table-writing) instrument ***
schedkwhen	k_trig,   0, 0,  305, 0, -1 , k_count	;note on
k_tr_off	trigger	k_inamp, k_atck, 1
k_tr_off2	= ( ktimeLen > isamplen ? 1 : 0 )
k_tr_off2t	trigger	k_tr_off2, 0.5, 0
k_tr_off3	= k_tr_off + k_tr_off2t
gk305off	= k_tr_off3
k_tr_off3d	vdelayk	k_tr_off3, 0.2, 0.3		; delay  note off trigger
schedkwhen	k_tr_off3d, 0, 0, -305, 0, 1 , k_count	;note off

					; delay audio to be recorded, so rms and
	a2d	delay a2, gi_snc_delay	; control functions can set up in due time

zaw	a2d, 2
;outs	a1*0, a2*0.7	; test, just for recording demo
	endin
;****************************************************************
;****************************************************************

;****************************************************************
; table writing of audio signal from external input (ins) Voice 1
;****************************************************************
	instr	304

a1	zar	1
a0	init	0

ilength	= ftlen(1) / sr			; length of recording, same as table length, all tables same length

; declick enveloping, attack and release
a_amp	linseg	0, gi_snc_delay, 1, 1, 1
krel	init 0
krel	=  krel + gk304off		; add up each time gk304off is nonzero, this is only once for each instance of this instr
					; so the adding is in effect a sample and hold mechanism
if krel == 0 kgoto norelease
aenv	linseg 1, 0.2, 0, 1, 0
a_amp	= a_amp * aenv
norelease:

a1	= a1 * a_amp

	i_count	= p4
	k_count	= i_count		; redefine as k-rate
	gkcount304 = k_count
	FLprintk2	k_count, gih102	; print value to GUI, current sample number

timout	5.9, 1, self_off		; if input sound is longer than ftable,
					; skip recording after ilength seconds,

; *** table writing of input audio
	tableicopy	i_count, 15 	; clear table (copy from empty table)
	kstart	init 0
	kstart	tablewa	i_count, a1, 0	;write audio a1 to table i_count

; *** write length of recorded sound to table
ktime	timeinsts			; seconds since the start of this instr instance
tablew	ktime, i_count, 110

gktime304	= ktime
gk304active	= 1				; for testing if this instr is active
goto end
self_off:
turnoff
end:
	endin
;****************************************************************
;****************************************************************

;****************************************************************
; table writing of audio signal from external input (ins) Voice 2
;****************************************************************
	instr	305

a1	zar	2
a0	init	0

ilength	= ftlen(1) / sr			; length of recording, same as table length, all tables same length

; declick enveloping, attack and release
a_amp	linseg	0, gi_snc_delay, 1, 1, 1
krel	init 0
krel	=  krel + gk305off		; add up each time gk305off is nonzero, this is only once for each instance of this instr
					; so the adding is in effect a sample and hold mechanism
if krel == 0 kgoto norelease
aenv	linseg 1, 0.2, 0, 1, 0
a_amp	= a_amp * aenv
norelease:

a1	= a1 * a_amp

	i_count	= p4
	k_count	= i_count		; redefine as k-rate
	gkcount305 = k_count
	FLprintk2	k_count, gih106	; print value to GUI, current sample number

;timout	ilength, 10, end		; if input sound is longer than ftable,
					; skip recording after ilength seconds,
					; 10 seconds is set as the duration of skip-rec mode (...)

; *** table writing of input audio
	tableicopy	i_count, 15 	; clear table (copy from empty table)
	kstart init 0	
	kstart	tablewa	i_count, a1, 0	;write audio a1 to table i_count

; *** write length of recorded sound to table
ktime	timeinsts			; seconds since the start of this instr instance
tablew	ktime, i_count, 110

gktime305	= ktime
gk305active	= 1				; for testing if this instr is active
end:
	endin
;****************************************************************
;****************************************************************


;****************************************************************
; test if sampling instr is active, turn on control instrs when sampling stops
;****************************************************************
	instr 306

;for input 1
ktrig1		trigger	gk304active, 0.5, 1
schedkwhen	ktrig1, 0, 1, 200, 0, 0.1, gktime304, gkcount304	; initiate sorting of soundlength when instr 304 stops
;gk304active	= 0

;for input 2
ktrig2		trigger	gk305active, 0.5, 1
schedkwhen	ktrig2, 0, 1, 200, 0, 0.1, gktime305, gkcount305	; initiate sorting of soundlength when instr 305 stops
gk305active	= 0

	endin
;****************************************************************
;****************************************************************




;****************************************************************
; random generation of events for instr 311 (sample playback) RandomPlay Voice 1
;****************************************************************
; based on rythm-tick input from rythm synth instr 5,6,7

	instr	310

gktrig	trigger	gktrig, 0.9, 0	; make sure gktrig gives single pulses (it could hang at value 1)
k_trig	= gktrig*gkbtRplay1On	; trigger from rythm synth instr 5,6,7
kmaxins	= gkRpl1poly	; max number of instr (polyphony)

; *** sound selector statements
; ******************************
; new sound select algorithm, less cpu intensive than betarand
; make random number in 0 - 1 range,
; index this number into a table containing the distribution "shape"
; multiply with krange/2 and +/-1
; offset to krange center (min + range/2)

krange	= (gkRpl1fno2 - gkRpl1fno1) + 0.99		; range of numbers wanted
kcenter	= gkRpl1fno1 + (krange/2)			; center of range
krand0	randh 0.5, 10					; uniform random 
krand0	= krand0 + 0.5					; within normalized range
kfno	= (krand0*krange)+ gkRpl1fno1			; map to range, offset with gkRpl1fno1 (first sound)
kfno	= int(kfno)					; get rid of fractional part

kshort	table kfno, 111					; point to shortest sounds table,
kfno	= (gkRpl1shrt == 1 ? kshort : kfno)		; select amongst the shortest sounds

if kfno = gkhide1 goto reselect				; if this sound is "hidden" from selection, select another sound
if kfno = gkhide2 goto reselect				; actually, this does not work for hiding several neighbouring sounds
if kfno = gkhide3 goto reselect				; in that case, a more sophisticated loop is needed
if kfno = gkhide4 goto reselect
if kfno = gkhide5 goto reselect
if kfno = gkhide6 goto reselect
if kfno = gkhide7 goto reselect
if kfno = gkhide8 goto reselect
if kfno = gkhide9 goto reselect
if kfno = gkhide10 goto reselect
if kfno = gkhide11 goto reselect
if kfno = gkhide12 goto reselect
if kfno = gkhide13 goto reselect
if kfno = gkhide14 goto reselect
goto no_reselect

reselect:
kfno	= kfno + 1
kfo	= (kfno	> gkRpl1fno2 ? 1 : kfno )
no_reselect:


; bypass sound selector in this instr, allowing a global variable to carry the sound selection value
if gks1bypas == 0 goto select_end
kfno	= gks1fno
select_end:

; *** durational statements  ...(affected by playback freq/ratio)
; ******************************
k5frq	= abs(gkRpl1trspo)			; positive only
k5frq	= (k5frq == 0 ? 0.1 : k5frq)	; avoid zeroes
ksndlen	table kfno, 110			; get length of actual audio segment stored, update if it changes while instr is active
kdur	= ksndlen / k5frq		; set duration = tablelength/sr/k5frq
; this allows instr 5 to play once thru the table for each event generated
kdur = (kdur < 0.1 ? 0.1 : kdur)	; safety measure, prevent crash if dur is zero 

; *** scheduling statements
; ******************************
schedkwhen	k_trig, 0, kmaxins, 311, 0, kdur, kfno		; trig table playback

endin
;****************************************************************
;****************************************************************

;****************************************************************
; table playback 
;****************************************************************
	instr	311

ifreq	=	1
iamp	=	i(gkout_amp2)	
iattack		init 0.1 
irelease	init 1.0

;** select sample **
ifno 	= p4
isoundlen	table ifno, 110		; get length of actual audio segment stored
ilength	= (ftlen(ifno) / sr)		; table length in seconds

ifno2	= i(gkRpl1mwav)

;** envelope **
	a_amp	linen	iamp, iattack, p3, irelease
	a_amp	= a_amp * gksRplay1amp
;** oscillator and output **:

	ifnlength	tableng	ifno
	ifrq		= 44100/ifnlength * ifreq
	kfreq		= gkRpl1trspo * ifrq
	iphs		init 0			; iphs sets the starting point for reading from table
	iphs_end	= isoundlen/ilength	; determine ending point for recorded sound in table, normalized value
	iphs		= (i(gkRpl1trspo) < 0 ? iphs_end : iphs)	; if i(kfreq) < 0 (backwards playback), start playback from iphs_end
	
	amod		= 0

;frequency modulation 
	if gkRpl1fm == 0 kgoto skipFM				; conditional branch for FM

	kmodfrq		= gkRpl1mfq		; 150
	kmodndx		= gkRpl1mdx		; 0.01

	;kmodfreq envelope, one breakpoint, breakpoint position set by gk5modfrqP parameter
	kmodfrqenv	linseg	i(gkRpl1mfqS), p3*i(gkRpl1mfqP), i(gkRpl1mfqT), p3*(1-i(gkRpl1mfqP)), i(gkRpl1mfqE)
	kmodfrq		= kmodfrq * kmodfrqenv

	;kmod-index envelope, one breakpoint, breakpoint position set by gk5modndxP parameter
	kmodndxenv	linseg	i(gkRpl1mdxS), p3*i(gkRpl1mdxP), i(gkRpl1mdxT), p3*(1-i(gkRpl1mdxP)), i(gkRpl1mdxE)
	kmodndx		= kmodndx * kmodndxenv

	amod		oscil	kmodndx, kmodfrq, ifno2
skipFM:

	afreq		= kfreq + amod
	a1		poscil	a_amp, afreq, ifno, iphs

; output handled in instr 312
	zawm		a1, 18		; write to temporal storage channel (18)

endin

;****************************************************************
;****************************************************************

;****************************************************************
; filtering and throughput/output of signal from instr 311
;****************************************************************
	instr 	312
a0	zar	18

iamp	= gidenorm
abogus	 rand	iamp	; add low level noise, prevents underflow in the filters

a01	= a0 + abogus
; SV Filter

	alp, ahp, abp	svfilter	a01, gkRpl1SvCf, gkRpl1SvQ
	klp		= (gkRpl1SvMd == 1 ? 1 : 0 )
	kbp		= (gkRpl1SvMd == 2 ? 1 : 0 )
	khp		= (gkRpl1SvMd == 3 ? 1 : 0 )
	kclean		= (gkRpl1SvMd == 0 ? 1 : 0 ) 
	klp		tonek	klp, 1				; filter selector signal, avoids clicks
	kbp		tonek	kbp, 1
	khp		tonek	khp, 1
	kclean		tonek	kclean, 1
	a1f		mac	klp,alp, kbp,abp, khp,ahp, kclean,a01	; mix
	a1		balance	a1f, a0

; VU meter
;kVu	maxk	a1, gkupdate1, 0aVu	init 0
	maxabsaccum  aVu, a1
kVu	downsamp aVu
aVu	= 0

	FLsetVal	gkupdate1, kVu, gihsRplay1ampD

;EFX and dry out amplitudes
	zawm	a1 * gkRplay1_clean * (1-gkRplay1_pan),4	; send to clean out Left
	zawm	a1 * gkRplay1_clean * gkRplay1_pan, 	5	; send to clean out Right
	zawm	a1 * gkRplay1_rm 	, 		6	; send to ring mod
	zawm	a1 * gkRplay1_fm 	, 		7	; send to freq mod
	zawm	a1 * gkRplay1_filt1, 		8	; send to filter 1
	zawm	a1 * gkRplay1_dist , 		9	; send to distrortion
	zawm	a1 * gkRplay1_filt2, 		10	; send to filter 2
	zawm	a1 * gkRplay1_del1	, 		11	; send to delay 1
	zawm	a1 * gkRplay1_del2	, 		12	; send to delay 2
	zawm	a1 * gkRplay1_revb	, 		13	; send to reverb
;	zawm	a1,				14	; to output file
	endin
;****************************************************************
;****************************************************************

;****************************************************************
; random generation of events for instr 314 (sample playback)
;****************************************************************
; based on rythm-tick input from rythm synth instr 5,6,7

	instr	313


gktrig2	trigger	gktrig2, 0.9, 0	; make sure gktrig gives single pulses (it could hang at value 1)
k_trig	= gktrig2*gkbtRplay2On		; trigger from rythm synth instr 5,6,7
kmaxins	= gkRpl2poly		; max number of instr (polyphony)

; *** sound selector statements
; ******************************
; new sound select algorithm, less cpu intensive than betarand
; make random number in 0 - 1 range,
; index this number into a table containing the distribution "shape"
; multiply with krange/2 and +/-1
; offset to krange center (min + range/2)

krange	= gkRpl2fno2 - gkRpl2fno1 + 0.99		; range of numbers wanted
kcenter	= gkRpl2fno1 + (krange/2)			; center of range
krand0	randh 0.5, 10					; uniform random 
krand0	= krand0 + 0.5					; within normalized range
kfno	= (krand0*krange)+ gkRpl2fno1			; map to range, offset with gkRpl1fno1 (first sound)

kshort	table kfno, 111					; point to shortest sounds table,
kfno	= (gkRpl2shrt == 1 ? kshort : kfno)		; select amongst the sortest sounds

if kfno = gkhide1 goto reselect				; if this sound is "hidden" from selection, select another sound
if kfno = gkhide2 goto reselect				; actually, this does not work for hiding several neighbouring sounds
if kfno = gkhide3 goto reselect				; in that case, a more sophisticated loop is needed
if kfno = gkhide4 goto reselect
if kfno = gkhide5 goto reselect
if kfno = gkhide6 goto reselect
if kfno = gkhide7 goto reselect
if kfno = gkhide8 goto reselect
if kfno = gkhide9 goto reselect
if kfno = gkhide10 goto reselect
if kfno = gkhide11 goto reselect
if kfno = gkhide12 goto reselect
if kfno = gkhide13 goto reselect
if kfno = gkhide14 goto reselect
goto no_reselect

reselect:
kfno	= kfno + 1
kfno	= (kfno	> gkRpl2fno2 ? 1 : kfno )
no_reselect:

; bypass sound selector in this instr, allowing a global variable to carry the sound selection value
if gks2bypas == 0 goto select_end
kfno	= gks2fno
select_end:

; *** durational statements  ...(affected by playback freq/ratio)
; ******************************
k52frq	= abs(gkRpl2trspo)			; positive only
k52frq	= (k52frq == 0 ? 0.1 : k52frq)	; avoid zeroes
ksndlen	table kfno, 110			; get length of actual audio segment stored, update if it changes while instr is active
kdur	= ksndlen / k52frq		; set duration = tablelength/sr/k5frq
; this allows instr 5 to play once thru the table for each event generated
kdur = (kdur < 0.1 ? 0.1 : kdur)	; safety measure, prevent crash if dur is zero 

; *** scheduling statements
; ******************************
schedkwhen	k_trig, 0, kmaxins, 314, 0, kdur, kfno		; trig table playback

endin
;****************************************************************
;****************************************************************

;****************************************************************
; table playback 
;****************************************************************
	instr	314

ifreq	=	1
iamp	=	i(gkout_amp22)	
iattack		init 0.1 
irelease	init 1.0


;** select sample **
ifno 	= p4
isoundlen	table ifno, 110		; get length of actual audio segment stored
ilength	= (ftlen(ifno) / sr)		; table length in seconds

ifno2	= i(gkRpl2mwav)

;** envelope **
	a_amp	linen	iamp, iattack, p3, irelease
	a_amp	= a_amp * gksRplay2amp
;** oscillator and output **:

	ifnlength	tableng	ifno
	ifrq		= 44100/ifnlength * ifreq
	kfreq		= gkRpl2trspo * ifrq
	iphs		init 0			; iphs sets the starting point for reading from table
	iphs_end	= isoundlen/ilength	; determine ending point for recorded sound in table, normalized value
	iphs		= (i(gkRpl2trspo) < 0 ? iphs_end : iphs)	; if kfreq < 0 (backwards playback), start playback from iphs_end

	amod		= 0

;frequency modulation 
	if gkRpl2fm == 0 kgoto skipFM				; conditional branch for FM

	kmodfrq		= gkRpl2mfq		; 150
	kmodndx		= gkRpl2mdx		; 0.01

	;kmodfreq envelope, one breakpoint, breakpoint position set by gkRpl2mfqP parameter
	kmodfrqenv	linseg	i(gkRpl2mfqS), p3*i(gkRpl2mfqP), i(gkRpl2mfqT), p3*(1-i(gkRpl2mfqP)), i(gkRpl2mfqE)
	kmodfrq		= kmodfrq * kmodfrqenv

	;kmod-index envelope, one breakpoint, breakpoint position set by gkRpl2mdxP parameter
	kmodndxenv	linseg	i(gkRpl2mdxS), p3*i(gkRpl2mdxP), i(gkRpl2mdxT), p3*(1-i(gkRpl2mdxP)), i(gkRpl2mdxE)
	kmodndx		= kmodndx * kmodndxenv

	amod		oscil	kmodndx, kmodfrq, ifno2
skipFM:

	afreq		= kfreq + amod
	a1		poscil	a_amp, afreq, ifno, iphs

; output handled in instr 315
	zawm		a1, 19		; write to temporal storage channel (18)

endin

;****************************************************************
;****************************************************************

;****************************************************************
; filtering and throughput/output of signal from instr 314
;****************************************************************
	instr 	315
a0	zar	19

iamp	= gidenorm
abogus	 rand	iamp	; add low level noise, prevents underflow in the filters
a01	= a0 + abogus

; SV Filter

	alp, ahp, abp	svfilter	a01, gkRpl2SvCf, gkRpl2SvQ
	klp		= (gkRpl2SvMd == 1 ? 1 : 0 )
	kbp		= (gkRpl2SvMd == 2 ? 1 : 0 )
	khp		= (gkRpl2SvMd == 3 ? 1 : 0 )
	kclean		= (gkRpl2SvMd == 0 ? 1 : 0 ) 
	klp		tonek	klp, 1				; filter selector signal, avoids clicks
	kbp		tonek	kbp, 1
	khp		tonek	khp, 1
	kclean		tonek	kclean, 1
	a1f		mac	klp,alp, kbp,abp, khp,ahp, kclean,a01	; mix
	a1		balance	a1f, a0

; VU meter
;kVu	maxk	a1, gkupdate1, 0aVu	init 0
	maxabsaccum  aVu, a1
kVu	downsamp aVu
aVu	= 0

	FLsetVal	gkupdate1, kVu, gihsRplay2ampD

;EFX and dry out amplitudes
	zawm	a1 * gkRplay2_clean * (1-gkRplay2_pan), 4	; send to clean out Left
	zawm	a1 * gkRplay2_clean * gkRplay2_pan, 	5	; send to clean out Right
	zawm	a1 * gkRplay2_rm	, 		6	; send to ring mod
	zawm	a1 * gkRplay2_fm	, 		7	; send to freq mod
	zawm	a1 * gkRplay2_filt1, 		8	; send to filter 1
	zawm	a1 * gkRplay2_dist	, 		9	; send to distrortion
	zawm	a1 * gkRplay2_filt2, 		10	; send to filter 2
	zawm	a1 * gkRplay2_del1	, 		11	; send to delay 1
	zawm	a1 * gkRplay2_del2	, 		12	; send to delay 2
	zawm	a1 * gkRplay2_revb	, 		13	; send to reverb
;	zawm	a1,				15; to output file
	endin
;****************************************************************
;****************************************************************

;****************************************************************
; granulated playback 
;****************************************************************

;****************************************************************
; voice 1
;****************************************************************

	instr	321

;** envelope **
	iamp	= 0.65
	kamp	= gksGrain1amp*gkveloc
	amp	interp	kamp

;** lfo **
klfo	oscil	gkGrn1lfA, gkGrn1lfq, 93

;** random offset for timepoint **
krand	rand gkGrn1rndA



;** granule setup **:

iolaps	= 400
if gkGrain1Reinit == 0 kgoto ifnoselect
reinit ifnoselect
ifnoselect:
ifna	= i(gkGrn1sel)
ifna	= (ifna == 0 ? i(gkLastRec) : ifna)	; if sound select = zero, use last recorded sound
ifnb	= 101
itotdur	= 6000
ilength	= (ftlen(ifna) / sr)		; table length in seconds
kifna	= ifna				; force update sound length stored in table 110
ksndlen	table kifna, 114		; get length of actual audio segment stored, update if it changes while instr is active
ksndlen	tonek	ksndlen, 0.5		; filter updated soundlength, avoiding clicks in grain module when recording

;reading of midi values:
gkGrn1form_mc	= gkGrn1form * gkbend2midi	; moved from midi instr
gkGrn1oct_mc	= gkGrn1oct + gkctrl2midi		; moved from midi instr

;gk6phs	="Time Ratio", 	-1, 2
kcps	= gkGrn1trat			; time ratio, 1 is "original" speed
kcps	= kcps / ilength		; timeratio / table-length in seconds
;kphs	phasor	kcps			
kphs	oscili	1, kcps, 99		; alternative to clean phasor, ramp and hold

;manual time pointer
kphs_j	jitter	0.01 /gkGrn1grfq, 8, 18	; jitter for manual timepoint
kphs_m	= gkGrn1mPhs + kphs_j		; global ctrl + jitter
kphs_m	tonek	kphs_m, 10		; smooth out manual time pointer
kphs	= (gkGrn1mTim == 1 ? kphs_m : kphs)
kphs	= kphs + klfo + krand		; add lfo and random offset to time pointer
kphs	= kphs * (ksndlen/ilength) 	; scale kphs so that it points only to the part of the table actually used to store audio

;gk6form = "Transposition factor"
kformT	= gkGrn1form_mc *1.01 / ilength

; grain shape/length params
kband	= gkGrn1bw * gkGrn1grfq		; should gk6fund affect this ??
kdur1	= gkGrn1dur / gkGrn1grfq		; gk6dur controls the amount of grain overlaps
kris1	= gkGrn1ris * kdur1			; rise time as a fractional part of kdur (0 < gk6ris < 1 )
kdec	= gkGrn1dec * kdur1			; as for rise time

kdur	= (gkGrn1fsnc == 1 ? kdur1*0.5 : kdur1)	; different grain envelope if synced
kris	= (gkGrn1fsnc == 1 ? kris1*0.1 : kris1)	; different grain envelope if synced
kband	= (gkGrn1fsnc == 1 ? kband*2.5 : kband)	; different grain envelope if synced 

; ** 
; grain cloud
knumvoice	= gkGrn1numv
kQuantPtch	= gkGrn1QPch					; quantize to semitone
kspread		= gkGrn1Sprd					; pitch spread

; random pitch deviation
kform1 	randh	kspread, gkGrn1SprF, 0.1
kform2	randh	kspread, gkGrn1SprF, 0.2
kform3	randh	kspread, gkGrn1SprF, 0.3
kform4	randh	kspread, gkGrn1SprF, 0.4

kform1	= (kQuantPtch == 0 ? (0 + semitone(kform1)) : (0 + semitone(int(kform1))) )	; quantize if needed
kform2	= (kQuantPtch == 0 ? (0 + semitone(kform2)) : (0 + semitone(int(kform2))) )	; quantize if needed
kform3	= (kQuantPtch == 0 ? (0 + semitone(kform3)) : (0 + semitone(int(kform3))) )	; quantize if needed
kform4	= (kQuantPtch == 0 ? (0 + semitone(kform4)) : (0 + semitone(int(kform4))) )	; quantize if needed

kform1	= kform1 * kformT * (semitone(gkGrn1Tr1))	; master transposition and voice transposistion 	
kform2	= kform2 * kformT * (semitone(gkGrn1Tr2))	; 
kform3	= kform3 * kformT * (semitone(gkGrn1Tr3))	; 	
kform4	= kform4 * kformT * (semitone(gkGrn1Tr4))	; 


;grain freq sync to master tempo gkbtpo
kGrnFrqQv	table gkGrn1grfq, 151			; table lookup for quantize values
kGrnFrqQ	= gkbtpo_cps * kGrnFrqQv		; sync to master tempo 
; if grain freq is below 33, and quantize enabled do quantize
kRealFrq	= gkGrn1grfq / (gkGrn1oct+1)
kGrnFrq		= (gkGrn1fsnc == 1 && kRealFrq < 33 ? kGrnFrqQ : gkGrn1grfq)

;** oscillator and output **:

kamp	= kamp * (1-(knumvoice*0.1))			; lower amplitude with more voices active

a1	= 0
a2	= 0
a3	= 0
a4	= 0

if knumvoice == 1 kgoto voice1
if knumvoice == 2 kgoto voice2
if knumvoice == 3 kgoto voice3
if knumvoice == 4 kgoto voice4

voice4:
	a4	fof2	kamp, kGrnFrq, kform4, gkGrn1oct_mc, kband, kris, kdur, kdec, iolaps, ifna, ifnb, itotdur, kphs, gkGrn1gli
voice3:
	a3	fof2	kamp, kGrnFrq, kform3, gkGrn1oct_mc, kband, kris, kdur, kdec, iolaps, ifna, ifnb, itotdur, kphs, gkGrn1gli
voice2:
	a2	fof2	kamp, kGrnFrq, kform2, gkGrn1oct_mc, kband, kris, kdur, kdec, iolaps, ifna, ifnb, itotdur, kphs, gkGrn1gli
voice1:
	a1	fof2	kamp, kGrnFrq, kform1, gkGrn1oct_mc, kband, kris, kdur, kdec, iolaps, ifna, ifnb, itotdur, kphs, gkGrn1gli

ipan1	= 0.55
ipan2	= 0.6
ipan3	= 0.4
ipan4	= 0.45
aLeft	= (a1*(1-ipan1)) + (a2*(1-ipan2)) + (a3*(1-ipan3)) + (a4*(1-ipan4))
aRight	= (a1*ipan1) + (a2*ipan2) + (a3*ipan3) + (a4*ipan4)
amono	= aLeft + aRight

; dynamic amp modification, volume compression
krms	rms	amono
krms1	table	krms, 125
arms	interp	krms1
aLeft	= aLeft * arms
aRight	= aRight * arms
amono	= amono * arms

; VU meter
;kVu	maxk	amono, gkupdate1, 0aVu	init 0
	maxabsaccum  aVu, amono
kVu	downsamp aVu
aVu	= 0

	FLsetVal	gkupdate1, kVu, gihsGrain1ampD

;EFX and dry out amplitudes
	zawm	aLeft * gkGrain1_clean * (1-gkGrain1_pan), 4	; send to clean out Left
	zawm	aRight * gkGrain1_clean * gkGrain1_pan, 5	; send to clean out Right
	zawm	amono * gkGrain1_rm	, 		6	; send to RingMod
	zawm	amono * gkGrain1_fm	, 		7	; send to FreqMod	
	zawm	amono * gkGrain1_filt1, 		8	; send to Filter1	
	zawm	amono * gkGrain1_dist	, 		9	; send to Distortion	
	zawm	amono * gkGrain1_filt2, 		10	; send to Filter2	
	zawm	amono * gkGrain1_del1	, 		11	; send to Delay1	
	zawm	amono * gkGrain1_del2	, 		12	; send to Delay2	
	zawm	amono * gkGrain1_revb	, 		13	; send to Reverb
;	zawm	amono,				16	; to output file
	endin
;****************************************************************
;****************************************************************

;****************************************************************
; voice 2
;****************************************************************

	instr	322

;** envelope **
	iamp	= 0.65
	kamp	= iamp * gksGrain2amp 

;** lfo **
klfo	oscil	gkGrn2lfA, gkGrn2lfq, 93

;** random offset for timepoint **
krand	rand gkGrn2rndA

;** granule setup **:

iolaps	= 400
ifna	= i(gkGrn2sel)
ifna	= (ifna == 0 ? i(gkLastRec) : ifna)	; if sound select = zero, use last recorded sound
ifnb	= 101
itotdur	= 6000
ilength	= (ftlen(ifna) / sr)		; table length in seconds
kifna	= ifna				; force update sound length stored in table 110
ksndlen	table kifna, 114		; get length of actual audio segment stored, update if it changes while instr is active
ksndlen	tonek	ksndlen, 0.5		; filter updated soundlength, avoiding clicks in grain module when recording

;gk6phs	="Time Ratio", 	-1, 2
kcps	= gkGrn2trat			; time ratio, 1 is "original" speed
kcps	= kcps / ilength		; timeratio / table-length in seconds
;kphs	phasor	kcps			
kphs	oscil	1, kcps, 99		; alternative to clean phasor, ramp and hold

;manual time pointer
kphs_j	jitter	0.01 /gkGrn2grfq, 8, 18		; jitter for manual timepoint
kphs_m	= gkGrn2mPhs + kphs_j		; global ctrl + jitter
kphs_m	tonek	kphs_m, 10		; smooth out manual time pointer
kphs	= (gkGrn2mTim == 1 ? kphs_m : kphs)
kphs	= kphs + klfo + krand		; add lfo and random offset to time pointer
kphs	= kphs * (ksndlen/ilength) 	; scale kphs so that it points only to the part of the table actually used to store audio

;gk6form = "Transposition factor"
kformT	= gkGrn2form *1.01 / ilength

; grain shape/length params
kband	= gkGrn2bw * gkGrn2grfq		; should gk6fund affect this ??
kdur1	= gkGrn2dur / gkGrn2grfq		; gk6dur controls the amount of grain overlaps
kris1	= gkGrn2ris * kdur1			; rise time as a fractional part of kdur (0 < gk6ris < 1 )
kdec	= gkGrn2dec * kdur1			; as for rise time

kdur	= (gkGrn2fsnc == 1 ? kdur1*0.5 : kdur1)	; different grain envelope if synced
kris	= (gkGrn2fsnc == 1 ? kris1*0.1 : kris1)	; different grain envelope if synced
kband	= (gkGrn2fsnc == 1 ? kband*2.5 : kband)	; different grain envelope if synced 

; ** 
; grain cloud
knumvoice	= gkGrn2numv
kQuantPtch	= gkGrn2QPch					; quantize to semitone
kspread		= gkGrn2Sprd					; pitch spread

; random pitch deviation
kform1 	randh	kspread, gkGrn2SprF, 0.1
kform2	randh	kspread, gkGrn2SprF, 0.2
kform3	randh	kspread, gkGrn2SprF, 0.3
kform4	randh	kspread, gkGrn2SprF, 0.4

kform1	= (kQuantPtch == 0 ? (0 + semitone(kform1)) : (0 + semitone(int(kform1))) )	; quantize if needed
kform2	= (kQuantPtch == 0 ? (0 + semitone(kform2)) : (0 + semitone(int(kform2))) )	; quantize if needed
kform3	= (kQuantPtch == 0 ? (0 + semitone(kform3)) : (0 + semitone(int(kform3))) )	; quantize if needed
kform4	= (kQuantPtch == 0 ? (0 + semitone(kform4)) : (0 + semitone(int(kform4))) )	; quantize if needed

kform1	= kform1 * kformT * (semitone(gkGrn2Tr1))	; master transposition and voice transposistion 	
kform2	= kform2 * kformT * (semitone(gkGrn2Tr2))	; 
kform3	= kform3 * kformT * (semitone(gkGrn2Tr3))	; 	
kform4	= kform4 * kformT * (semitone(gkGrn2Tr4))	; 

;grain freq sync to master tempo gkbtpo
kGrnFrqQv	table gkGrn2grfq, 151			; table lookup for quantize values
kGrnFrqQ	= gkbtpo_cps * kGrnFrqQv		; sync to master tempo 
	
; if grain freq is below 33, and quantize enabled do quantize
kRealFrq	= gkGrn2grfq / (gkGrn2oct+1)
kGrnFrq		= (gkGrn2fsnc == 1 && kRealFrq < 33 ? kGrnFrqQ : gkGrn2grfq)

;** oscillator and output **:

kamp	= kamp * (1-(knumvoice*0.1))			; lower amplitude with more voices active

a1	= 0
a2	= 0
a3	= 0
a4	= 0

if knumvoice == 1 kgoto voice1
if knumvoice == 2 kgoto voice2
if knumvoice == 3 kgoto voice3
if knumvoice == 4 kgoto voice4

voice4:
	a4	fof2	kamp, kGrnFrq, kform4, gkGrn2oct, kband, kris, kdur, kdec, iolaps, ifna, ifnb, itotdur, kphs, gkGrn2gli
voice3:
	a3	fof2	kamp, kGrnFrq, kform3, gkGrn2oct, kband, kris, kdur, kdec, iolaps, ifna, ifnb, itotdur, kphs, gkGrn2gli
voice2:
	a2	fof2	kamp, kGrnFrq, kform2, gkGrn2oct, kband, kris, kdur, kdec, iolaps, ifna, ifnb, itotdur, kphs, gkGrn2gli
voice1:
	a1	fof2	kamp, kGrnFrq, kform1, gkGrn2oct, kband, kris, kdur, kdec, iolaps, ifna, ifnb, itotdur, kphs, gkGrn2gli

ipan1	= 0.55
ipan2	= 0.6
ipan3	= 0.4
ipan4	= 0.45
aLeft	= (a1*(1-ipan1)) + (a2*(1-ipan2)) + (a3*(1-ipan3)) + (a4*(1-ipan4))
aRight	= (a1*ipan1) + (a2*ipan2) + (a3*ipan3) + (a4*ipan4)
amono	= aLeft + aRight

; dynamic amp modification, volume compression
krms	rms	amono
krms1	table	krms, 125
arms	interp	krms1
aLeft	= aLeft * arms
aRight	= aRight * arms
amono	= amono * arms

; VU meter
;kVu	maxk	amono, gkupdate1, 0aVu	init 0
	maxabsaccum  aVu, amono
kVu	downsamp aVu
aVu	= 0

	FLsetVal	gkupdate1, kVu, gihsGrain2ampD

;EFX and dry out amplitudes
	zawm	aLeft * gkGrain2_clean * (1-gkGrain2_pan), 4	; send to clean out Left
	zawm	aRight * gkGrain2_clean * gkGrain2_pan, 5	; send to clean out Right
	zawm	amono * gkGrain2_rm	, 		6	; send to RingMod
	zawm	amono * gkGrain2_fm	, 		7	; send to FreqMod	
	zawm	amono * gkGrain2_filt1, 		8	; send to Filter1	
	zawm	amono * gkGrain2_dist	, 		9	; send to Distortion	
	zawm	amono * gkGrain2_filt2, 		10	; send to Filter2	
	zawm	amono * gkGrain2_del1	, 		11	; send to Delay1	
	zawm	amono * gkGrain2_del2	, 		12	; send to Delay2	
	zawm	amono * gkGrain2_revb	, 		13	; send to Reverb
;	zawm	amono,				17	; to output file
	endin
;****************************************************************
;****************************************************************

;****************************************************************
; voice 3
;****************************************************************

	instr	323

;** envelope **
	iamp	= 0.65
	kamp	= iamp * gksGrain3amp 

;** lfo **
klfo	oscil	gkGrn3lfA, gkGrn3lfq, 93

;** random offset for timepoint **
krand	rand gkGrn3rndA

;** granule setup **:

iolaps	= 400
ifna	= i(gkGrn3sel)
ifna	= (ifna == 0 ? i(gkLastRec) : ifna)	; if sound select = zero, use last recorded sound
ifnb	= 101
itotdur	= 6000
ilength	= (ftlen(ifna) / sr)		; table length in seconds
kifna	= ifna				; force update sound length stored in table 110
ksndlen	table kifna, 114		; get length of actual audio segment stored, update if it changes while instr is active
ksndlen	tonek	ksndlen, 0.5		; filter updated soundlength, avoiding clicks in grain module when recording

;gk6phs	="Time Ratio", 	-1, 2
kcps	= gkGrn3trat			; time ratio, 1 is "original" speed
kcps	= kcps / ilength		; timeratio / table-length in seconds
kphs	phasor	kcps
kphs	oscil	1, kcps, 99		; alternative to clean phasor, ramp and hold
			
;manual time pointer
kphs_j	jitter	0.01 /gkGrn3grfq, 8, 18		; jitter for manual timepoint
kphs_m	= gkGrn3mPhs + kphs_j		; global ctrl + jitter
kphs_m	tonek	kphs_m, 10		; smooth out manual time pointer
kphs	= (gkGrn3mTim == 1 ? kphs_m : kphs)
kphs	= kphs + klfo + krand		; add lfo and random offset to time pointer
kphs	= kphs * (ksndlen/ilength) 	; scale kphs so that it points only to the part of the table actually used to store audio

;gk6form = "Transposition factor"
kformT	= gkGrn3form *1.01 / ilength

; grain shape/length params
kband	= gkGrn3bw * gkGrn3grfq		; should gk6fund affect this ??
kdur1	= gkGrn3dur / gkGrn3grfq		; gk6dur controls the amount of grain overlaps
kris1	= gkGrn3ris * kdur1			; rise time as a fractional part of kdur (0 < gk6ris < 1 )
kdec	= gkGrn3dec * kdur1			; as for rise time

kdur	= (gkGrn3fsnc == 1 ? kdur1*0.5 : kdur1)	; different grain envelope if synced
kris	= (gkGrn3fsnc == 1 ? kris1*0.1 : kris1)	; different grain envelope if synced
kband	= (gkGrn3fsnc == 1 ? kband*2.5 : kband)	; different grain envelope if synced 

; ** 
; grain cloud
knumvoice	= gkGrn3numv
kQuantPtch	= gkGrn3QPch					; quantize to semitone
kspread		= gkGrn3Sprd					; pitch spread

; random pitch deviation
kform1 	randh	kspread, gkGrn3SprF, 0.1
kform2	randh	kspread, gkGrn3SprF, 0.2
kform3	randh	kspread, gkGrn3SprF, 0.3
kform4	randh	kspread, gkGrn3SprF, 0.4

kform1	= (kQuantPtch == 0 ? (0 + semitone(kform1)) : (0 + semitone(int(kform1))) )	; quantize if needed
kform2	= (kQuantPtch == 0 ? (0 + semitone(kform2)) : (0 + semitone(int(kform2))) )	; quantize if needed
kform3	= (kQuantPtch == 0 ? (0 + semitone(kform3)) : (0 + semitone(int(kform3))) )	; quantize if needed
kform4	= (kQuantPtch == 0 ? (0 + semitone(kform4)) : (0 + semitone(int(kform4))) )	; quantize if needed

kform1	= kform1 * kformT * (semitone(gkGrn3Tr1))	; master transposition and voice transposistion 	
kform2	= kform2 * kformT * (semitone(gkGrn3Tr2))	; 
kform3	= kform3 * kformT * (semitone(gkGrn3Tr3))	; 	
kform4	= kform4 * kformT * (semitone(gkGrn3Tr4))	; 

;grain freq sync to master tempo gkbtpo
kGrnFrqQv	table gkGrn3grfq, 151			; table lookup for quantize values
kGrnFrqQ	= gkbtpo_cps * kGrnFrqQv		; sync to master tempo 
; if grain freq is below 33, and quantize enabled do quantize
kRealFrq	= gkGrn3grfq / (gkGrn3oct+1)
kGrnFrq		= (gkGrn3fsnc == 1 && kRealFrq < 33 ? kGrnFrqQ : gkGrn3grfq)


;** oscillator and output **:

kamp	= kamp * (1-(knumvoice*0.1))			; lower amplitude with more voices active

a1	= 0
a2	= 0
a3	= 0
a4	= 0

if knumvoice == 1 kgoto voice1
if knumvoice == 2 kgoto voice2
if knumvoice == 3 kgoto voice3
if knumvoice == 4 kgoto voice4

voice4:
	a4	fof2	kamp, kGrnFrq, kform4, gkGrn3oct, kband, kris, kdur, kdec, iolaps, ifna, ifnb, itotdur, kphs, gkGrn3gli
voice3:
	a3	fof2	kamp, kGrnFrq, kform3, gkGrn3oct, kband, kris, kdur, kdec, iolaps, ifna, ifnb, itotdur, kphs, gkGrn3gli
voice2:
	a2	fof2	kamp, kGrnFrq, kform2, gkGrn3oct, kband, kris, kdur, kdec, iolaps, ifna, ifnb, itotdur, kphs, gkGrn3gli
voice1:
	a1	fof2	kamp, kGrnFrq, kform1, gkGrn3oct, kband, kris, kdur, kdec, iolaps, ifna, ifnb, itotdur, kphs, gkGrn3gli

ipan1	= 0.55
ipan2	= 0.6
ipan3	= 0.4
ipan4	= 0.45
aLeft	= (a1*(1-ipan1)) + (a2*(1-ipan2)) + (a3*(1-ipan3)) + (a4*(1-ipan4))
aRight	= (a1*ipan1) + (a2*ipan2) + (a3*ipan3) + (a4*ipan4)
amono	= aLeft + aRight

; dynamic amp modification, volume compression
krms	rms	amono
krms1	table	krms, 125
arms	interp	krms1
aLeft	= aLeft * arms
aRight	= aRight * arms
amono	= amono * arms

; VU meter
;kVu	maxk	amono, gkupdate1, 0aVu	init 0
	maxabsaccum  aVu, amono
kVu	downsamp aVu
aVu	= 0

	FLsetVal	gkupdate1, kVu, gihsGrain3ampD

;EFX and dry out amplitudes
	zawm	aLeft * gkGrain3_clean * (1-gkGrain3_pan), 4	; send to clean out Left
	zawm	aRight * gkGrain3_clean * gkGrain3_pan, 5	; send to clean out Right
	zawm	amono * gkGrain3_rm	, 		6	; send to RingMod
	zawm	amono * gkGrain3_fm	, 		7	; send to FreqMod	
	zawm	amono * gkGrain3_filt1, 		8	; send to Filter1	
	zawm	amono * gkGrain3_dist	, 		9	; send to Distortion	
	zawm	amono * gkGrain3_filt2, 		10	; send to Filter2	
	zawm	amono * gkGrain3_del1	, 		11	; send to Delay1	
	zawm	amono * gkGrain3_del2	, 		12	; send to Delay2	
	zawm	amono * gkGrain3_revb	, 		13	; send to Reverb
;	zawm	amono,				18	; to output file
	endin
;****************************************************************
;****************************************************************

;****************************************************************
; voice 4
;****************************************************************

	instr	324

;** envelope **
	iamp	= 0.65
	kamp	= iamp * gksGrain4amp 

;** lfo **
klfo	oscil	gkGrn4lfA, gkGrn4lfq, 93

;** random offset for timepoint **
krand	rand gkGrn4rndA

;** granule setup **:

iolaps	= 400
ifna	= i(gkGrn4sel)
ifna	= (ifna == 0 ? i(gkLastRec) : ifna)	; if sound select = zero, use last recorded sound
ifnb	= 101
itotdur	= 6000
ilength	= (ftlen(ifna) / sr)		; table length in seconds
kifna	= ifna				; force update sound length stored in table 110
ksndlen	table kifna, 114		; get length of actual audio segment stored, update if it changes while instr is active
ksndlen	tonek	ksndlen, 0.5		; filter updated soundlength, avoiding clicks in grain module when recording

;gk6phs	="Time Ratio", 	-1, 2
kcps	= gkGrn4trat			; time ratio, 1 is "original" speed
kcps	= kcps / ilength		; timeratio / table-length in seconds
kphs	phasor	kcps			
kphs	oscil	1, kcps, 99		; alternative to clean phasor, ramp and hold

;manual time pointer
kphs_j	jitter	0.01 /gkGrn4grfq, 8, 18		; jitter for manual timepoint
kphs_m	= gkGrn4mPhs + kphs_j		; global ctrl + jitter
kphs_m	tonek	kphs_m, 10		; smooth out manual time pointer
kphs	= (gkGrn4mTim == 1 ? kphs_m : kphs)
kphs	= kphs + klfo + krand		; add lfo and random offset to time pointer
kphs	= kphs * (ksndlen/ilength) 	; scale kphs so that it points only to the part of the table actually used to store audio

;gk6form = "Transposition factor"
kformT	= gkGrn4form *1.01 / ilength

; grain shape/length params
kband	= gkGrn4bw * gkGrn4grfq		; should gk6fund affect this ??
kdur1	= gkGrn4dur / gkGrn4grfq		; gk6dur controls the amount of grain overlaps
kris1	= gkGrn4ris * kdur1			; rise time as a fractional part of kdur (0 < gk6ris < 1 )
kdec	= gkGrn4dec * kdur1			; as for rise time

kdur	= (gkGrn4fsnc == 1 ? kdur1*0.5 : kdur1)	; different grain envelope if synced
kris	= (gkGrn4fsnc == 1 ? kris1*0.1 : kris1)	; different grain envelope if synced
kband	= (gkGrn4fsnc == 1 ? kband*2.5 : kband)	; different grain envelope if synced 

; ** 
; grain cloud
knumvoice	= gkGrn4numv
kQuantPtch	= gkGrn4QPch					; quantize to semitone
kspread		= gkGrn4Sprd					; pitch spread

; random pitch deviation
kform1 	randh	kspread, gkGrn4SprF, 0.1
kform2	randh	kspread, gkGrn4SprF, 0.2
kform3	randh	kspread, gkGrn4SprF, 0.3
kform4	randh	kspread, gkGrn4SprF, 0.4

kform1	= (kQuantPtch == 0 ? (0 + semitone(kform1)) : (0 + semitone(int(kform1))) )	; quantize if needed
kform2	= (kQuantPtch == 0 ? (0 + semitone(kform2)) : (0 + semitone(int(kform2))) )	; quantize if needed
kform3	= (kQuantPtch == 0 ? (0 + semitone(kform3)) : (0 + semitone(int(kform3))) )	; quantize if needed
kform4	= (kQuantPtch == 0 ? (0 + semitone(kform4)) : (0 + semitone(int(kform4))) )	; quantize if needed

kform1	= kform1 * kformT * (semitone(gkGrn4Tr1))	; master transposition and voice transposistion 	
kform2	= kform2 * kformT * (semitone(gkGrn4Tr2))	; 
kform3	= kform3 * kformT * (semitone(gkGrn4Tr3))	; 	
kform4	= kform4 * kformT * (semitone(gkGrn4Tr4))	; 

;grain freq sync to master tempo gkbtpo
kGrnFrqQv	table gkGrn4grfq, 151			; table lookup for quantize values
kGrnFrqQ	= gkbtpo_cps * kGrnFrqQv		; sync to master tempo 
; if grain freq is below 33, and quantize enabled do quantize
kRealFrq	= gkGrn4grfq / (gkGrn4oct+1)
kGrnFrq		= (gkGrn4fsnc == 1 && kRealFrq < 33 ? kGrnFrqQ : gkGrn4grfq)


;** oscillator and output **:

kamp	= kamp * (1-(knumvoice*0.1))			; lower amplitude with more voices active

a1	= 0
a2	= 0
a3	= 0
a4	= 0

if knumvoice == 1 kgoto voice1
if knumvoice == 2 kgoto voice2
if knumvoice == 3 kgoto voice3
if knumvoice == 4 kgoto voice4

voice4:
	a4	fof2	kamp, kGrnFrq, kform4, gkGrn4oct, kband, kris, kdur, kdec, iolaps, ifna, ifnb, itotdur, kphs, gkGrn4gli
voice3:
	a3	fof2	kamp, kGrnFrq, kform3, gkGrn4oct, kband, kris, kdur, kdec, iolaps, ifna, ifnb, itotdur, kphs, gkGrn4gli
voice2:
	a2	fof2	kamp, kGrnFrq, kform2, gkGrn4oct, kband, kris, kdur, kdec, iolaps, ifna, ifnb, itotdur, kphs, gkGrn4gli
voice1:
	a1	fof2	kamp, kGrnFrq, kform1, gkGrn4oct, kband, kris, kdur, kdec, iolaps, ifna, ifnb, itotdur, kphs, gkGrn4gli

ipan1	= 0.55
ipan2	= 0.6
ipan3	= 0.4
ipan4	= 0.45
aLeft	= (a1*(1-ipan1)) + (a2*(1-ipan2)) + (a3*(1-ipan3)) + (a4*(1-ipan4))
aRight	= (a1*ipan1) + (a2*ipan2) + (a3*ipan3) + (a4*ipan4)
amono	= aLeft + aRight

; dynamic amp modification, volume compression
krms	rms	amono
krms1	table	krms, 125
arms	interp	krms1
aLeft	= aLeft * arms
aRight	= aRight * arms
amono	= amono * arms

; VU meter
;kVu	maxk	amono, gkupdate1, 0aVu	init 0
	maxabsaccum  aVu, amono
kVu	downsamp aVu
aVu	= 0

	FLsetVal	gkupdate1, kVu, gihsGrain4ampD

;EFX and dry out amplitudes
	zawm	aLeft * gkGrain4_clean * (1-gkGrain4_pan), 4	; send to clean out Left
	zawm	aRight * gkGrain4_clean * gkGrain4_pan, 5	; send to clean out Right
	zawm	amono * gkGrain4_rm	, 		6	; send to RingMod
	zawm	amono * gkGrain4_fm	, 		7	; send to FreqMod	
	zawm	amono * gkGrain4_filt1, 		8	; send to Filter1	
	zawm	amono * gkGrain4_dist	, 		9	; send to Distortion	
	zawm	amono * gkGrain4_filt2, 		10	; send to Filter2	
	zawm	amono * gkGrain4_del1	, 		11	; send to Delay1	
	zawm	amono * gkGrain4_del2	, 		12	; send to Delay2	
	zawm	amono * gkGrain4_revb	, 		13	; send to Reverb
;	zawm	amono,				19	; to output file
	endin
;****************************************************************
;****************************************************************

;****************************************************************
;  Random Access Single Granulator, voice 1, control instr
;****************************************************************
	instr	330

; durational statements 
kdur	= gkRAGdur + (rnd(gkRAGrdur*gkRAGdur))

; time pointer statements (what part of the sound to use)
; phasor moves through the soundfile
; manual pointer sets location
; random offset added to any of the two above
; lfo added to any of the same two

krand	= birnd(gkRAGrphs)		; random timepoint variation 
klfo	oscil	gkRAGlfA, gkRAGlfq, 93	; lfo for timepoint

kcps	= gkRAGtrat			; time ratio, in cps ...
kphs	phasor	kcps			
;kphs	oscil	1, kcps, 99		; alternative to clean phasor, ramp and hold

;manual time pointer
kphs_m	= gkRAGmPhs
kphs_m	tonek	kphs_m, 10		; smooth out manual time pointer
kphs	= (gkRAGmTim == 1 ? kphs_m : kphs)
kphs	= kphs + klfo + krand		; add lfo and random offset to time pointer
kphs	= kphs % 1			; no kphs above 1, wrap around (modulo 1)
kphs	= (kphs < 0 ? 0 : kphs)		; avoid kphs below zero, crashes poscil/Csound

; generate event
imintime	= 0
imaxinst	= 0
krag	= gktrig3 * gkbtRAGOn
schedkwhen	krag, imintime, imaxinst, 331, gi_snc_delay, kdur, kphs		; trig Random Access Granulator

	endin
;****************************************************************
;****************************************************************

;****************************************************************
;  Random Access Single Granulator, voice 1, audio instr
;****************************************************************
	instr	331

;*********
; amp envelope, with rise and decay control

iamp	= i(gksRAGamp)*i(gkout_amp32)*2

irise	= i(gkRAGris)*p3
irise	= (irise < 0.01 ? 0.01 : irise)		; will click if irise is too low
idur	= p3
idec	= i(gkRAGdec)*p3
idec	= (idec < 0.01 ? 0.01 : idec)			; will click if idec is too low
ifn	= 101
iatss	= 1	; steady state, may implement a knob for this one
iatdec	= 0.01
;amp	envlpx	iamp, irise, idur, idec, ifn, iatss, iatdec
amp	linen	iamp, irise, idur, idec


ifno	= i(gkRAGsel)				; select original sound to read audio grains from
ifno	= (ifno == 0 ? i(gkLastRec) : ifno)	; if sound select = zero, use last recorded sound
isndlen	table ifno, 110				; get length of actual audio segment stored

ilength	= (ftlen(ifno) / sr)			; table length in seconds

; ioffset normalized value from p4
iphs	= (p4*isndlen) / ilength

ifreq		= 1				; original playback rate
ifnlength	tableng	ifno			; table length in samples
ifrq		= 44100/ifnlength * ifreq
kfreq		= gkRAGtrspo * ifrq		; playback rate value from GUI
kfr_rand	rspline	0, gkRAGrpch, 0.1, 7	; random pitch variation
kfreq		= kfreq + (kfreq * kfr_rand)	

	a1		poscil	amp, kfreq, ifno, iphs


;a1	oscil	1000, 440, 93
; VU meter
;kVu	maxk	a1, gkupdate1, 0aVu	init 0
	maxabsaccum  aVu, a1
kVu	downsamp aVu
aVu	= 0

	FLsetVal	gkupdate1, kVu, gihsRAGampD

;EFX and dry out amplitudes
	zawm	a1 * gkRAG_clean * (1-gkRAG_pan), 4	; send to clean out Left
	zawm	a1 * gkRAG_clean * gkRAG_pan, 5	; send to clean out Right
	zawm	a1 * gkRAG_rm,     		6	; send to RingMod
	zawm	a1 * gkRAG_fm,     		7	; send to FreqMod	
	zawm	a1 * gkRAG_filt1,  		8	; send to Filter1	
	zawm	a1 * gkRAG_dist,   		9	; send to Distortion	
	zawm	a1 * gkRAG_filt2, 		10	; send to Filter2	
	zawm	a1 * gkRAG_del1,  		11	; send to Delay1	
	zawm	a1 * gkRAG_del2,  		12	; send to Delay2	
	zawm	a1 * gkRAG_revb,  		13	; send to Reverb
;	zawm	a1,				20	; to output file
	endin
;****************************************************************
;****************************************************************


;****************************************************************
; table playback for pattern sequencer
;****************************************************************
	instr	335

ifno		= p4
ifrq		= 0.1682281494140625	; 44100/ifnlength * icps
iamp		= p7			; p7 is amp factor

ifadein		= (i(gkp1fdin)*p3) + 0.008
ifadeout	= (i(gkp1fdout)*p3) + 0.012
ifmfreq		= i(gkp1fmfrq)
ifmindx		= p5* i(gkp1fmindx)
ifiltQ		= i(gkp1fltQ)
ifiltfrq	= p6 * i(gkp1fltfrq)

amod	oscil	ifmindx, ifmfreq, 93
a1	poscil	iamp, ifrq+amod, ifno

iampB	= gidenorm
abogus	 rand	iampB	; add low level noise, prevents underflow in the filters

a1f, ahigh, aband	svfilter	a1, ifiltfrq, ifiltQ
a1f	balance	a1f, a1
idur	= p3 - ifadein - ifadeout	; sustain part of sound
idur	= (idur < 0.01 ? 0.01 : idur )	; avoid zero duration
;aenv	linen	1, ifadein, idur, ifadeout
aenv	expseg	0.1, ifadein, 1.1, idur, 1.1, ifadeout, 0.1, 1, 0.1
a1f	= a1f * (aenv-0.1)

;write audio to instr 339 for output, efx and bbcut
	zawm	a1f, 	17	

	endin

;****************************************************************
; table playback for pattern sequencer
;****************************************************************
	instr	336

ifno		= p4
ifrq		= 0.1682281494140625	; 44100/ifnlength * icps
iamp		= p7			; p7 is amp factor

ifadein		= (i(gkp2fdin)*p3) + 0.008
ifadeout	= (i(gkp2fdout)*p3) + 0.012
ifmfreq		= i(gkp2fmfrq)
ifmindx		= p5* i(gkp2fmindx)
ifiltQ		= i(gkp2fltQ)
ifiltfrq	= p6 * i(gkp2fltfrq)

amod	oscil	ifmindx, ifmfreq, 93
a1	poscil	iamp, ifrq+amod, ifno

iampB	= gidenorm
abogus	 rand	iampB	; add low level noise, prevents underflow in the filters

a1f, ahigh, aband	svfilter	a1, ifiltfrq, ifiltQ
a1f	balance	a1f, a1
idur	= p3 - ifadein - ifadeout	; sustain part of sound
idur	= (idur < 0.01 ? 0.01 : idur )	; avoid zero duration
;aenv	linen	1, ifadein, idur, ifadeout
aenv	expseg	0.1, ifadein, 1.1, idur, 1.1, ifadeout, 0.1, 1, 0.1
a1f	= a1f * (aenv-0.1)

;write audio to instr 339 for output, efx and bbcut
	zawm	a1f, 	18	

	endin
;****************************************************************
; table playback for pattern sequencer
;****************************************************************
	instr	337

ifno		= p4
ifrq		= 0.1682281494140625	; 44100/ifnlength * icps
iamp		= p7			; p7 is amp factor

ifadein		= (i(gkp3fdin)*p3) + 0.008
ifadeout	= (i(gkp3fdout)*p3) + 0.012
ifmfreq		= i(gkp3fmfrq)
ifmindx		= p5* i(gkp3fmindx)
ifiltQ		= i(gkp3fltQ)
ifiltfrq	= p6 * i(gkp3fltfrq)

amod	oscil	ifmindx, ifmfreq, 93
a1	poscil	iamp, ifrq+amod, ifno

iampB	= gidenorm
abogus	 rand	iampB	; add low level noise, prevents underflow in the filters

a1f, ahigh, aband	svfilter	a1, ifiltfrq, ifiltQ
a1f	balance	a1f, a1
idur	= p3 - ifadein - ifadeout	; sustain part of sound
idur	= (idur < 0.01 ? 0.01 : idur )	; avoid zero duration
;aenv	linen	1, ifadein, idur, ifadeout
aenv	expseg	0.1, ifadein, 1.1, idur, 1.1, ifadeout, 0.1, 1, 0.1
a1f	= a1f * (aenv-0.1)


;write audio to instr 339 for output, efx and bbcut
	zawm	a1f, 	19	

	endin
;****************************************************************
;****************************************************************

;****************************************************************
; output, efx, and bbcut for PatternSeq
;****************************************************************
	instr	339

if gkBeatOne == 0 goto contin
reinit	start
contin:
start:
a1	zar	17						; read from zak channel
a2	zar	18						; read from zak channel
a3	zar	19						; read from zak channel
a1	= a1 * gksPtSeqamp
a2	= a2 * gksPtSeqamp
a3	= a3 * gksPtSeqamp

ibps		= i(gkbtpo_cps)
isubdiv		= i(gkDLsubdiv)
ibarlength	= i(gkDLbarlen)
iphrasebars	= i(gkDLphrbar)
inumrepeats 	= i(gkDLnumrep)
istutterspeed	= i(gkDLstuspd)
istutterchance	= (i(gkDLsturnd)*0.01)
ienvchoice  	= i(gkDLenv)

a1_Lb	bbcutm	a1, ibps, isubdiv, ibarlength, iphrasebars, inumrepeats , istutterspeed, istutterchance, ienvchoice  
a1_Rb	bbcutm	a1, ibps, isubdiv, ibarlength, iphrasebars, inumrepeats , istutterspeed, istutterchance, ienvchoice 
a2_Lb	bbcutm	a2, ibps, isubdiv, ibarlength, iphrasebars, inumrepeats , istutterspeed, istutterchance, ienvchoice  
a2_Rb	bbcutm	a2, ibps, isubdiv, ibarlength, iphrasebars, inumrepeats , istutterspeed, istutterchance, ienvchoice 
a3_Lb	bbcutm	a3, ibps, isubdiv, ibarlength, iphrasebars, inumrepeats , istutterspeed, istutterchance, ienvchoice  
a3_Rb	bbcutm	a3, ibps, isubdiv, ibarlength, iphrasebars, inumrepeats , istutterspeed, istutterchance, ienvchoice 

a1_L	= (a1 * (1-gkDLbbmix)) + (a1_Lb * gkDLbbmix) 	; mix/balance of original and bbcut loop
a1_R	= (a1 * (1-gkDLbbmix)) + (a1_Rb * gkDLbbmix) 	; mix/balance of original and bbcut loop
a2_L	= (a2 * (1-gkDLbbmix)) + (a2_Lb * gkDLbbmix) 	; mix/balance of original and bbcut loop
a2_R	= (a2 * (1-gkDLbbmix)) + (a2_Rb * gkDLbbmix) 	; mix/balance of original and bbcut loop
a3_L	= (a3 * (1-gkDLbbmix)) + (a3_Lb * gkDLbbmix) 	; mix/balance of original and bbcut loop
a3_R	= (a3 * (1-gkDLbbmix)) + (a3_Rb * gkDLbbmix) 	; mix/balance of original and bbcut loop

a1_M	= (a1_L + a1_R) * 0.5
a2_M	= (a2_L + a2_R) * 0.5
a3_M	= (a3_L + a3_R) * 0.5

	zawm	a1_L * gkPtn1_clean * (1-gkPtn1_pan), 	4	; send to clean out Left
	zawm	a1_R * gkPtn1_clean * gkPtn1_pan,	5	; send to clean out Right
	zawm	a1_M * gkPtn1_rm	, 		6	; send to ring mod
	zawm	a1_M * gkPtn1_fm	, 		7	; send to freq mod
	zawm	a1_M * gkPtn1_filt1, 			8	; send to filter 1
	zawm	a1_M * gkPtn1_dist	, 		9	; send to distrortion
	zawm	a1_M * gkPtn1_filt2, 			10	; send to filter 2
	zawm	a1_M * gkPtn1_del1	, 		11	; send to delay 1
	zawm	a1_M * gkPtn1_del2	, 		12	; send to delay 2
	zawm	a1_M * gkPtn1_revb	, 		13	; send to reverb
	zawm	a1_M,					14	; to VU meter

	zawm	a2_L * gkPtn2_clean * (1-gkPtn2_pan), 	4	; send to clean out Left
	zawm	a2_R * gkPtn2_clean * gkPtn2_pan,	5	; send to clean out Right
	zawm	a2_M * gkPtn2_rm	, 		6	; send to ring mod
	zawm	a2_M * gkPtn2_fm	, 		7	; send to freq mod
	zawm	a2_M * gkPtn2_filt1, 			8	; send to filter 1
	zawm	a2_M * gkPtn2_dist	, 		9	; send to distrortion
	zawm	a2_M * gkPtn2_filt2, 			10	; send to filter 2
	zawm	a2_M * gkPtn2_del1	, 		11	; send to delay 1
	zawm	a2_M * gkPtn2_del2	, 		12	; send to delay 2
	zawm	a2_M * gkPtn2_revb	, 		13	; send to reverb
	zawm	a2_M,					14	; to VU meter

	zawm	a3_L * gkPtn3_clean * (1-gkPtn3_pan), 	4	; send to clean out Left
	zawm	a3_R * gkPtn3_clean * gkPtn3_pan,	5	; send to clean out Right
	zawm	a3_M * gkPtn3_rm	, 		6	; send to ring mod
	zawm	a3_M * gkPtn3_fm	, 		7	; send to freq mod
	zawm	a3_M * gkPtn3_filt1, 			8	; send to filter 1
	zawm	a3_M * gkPtn3_dist	, 		9	; send to distrortion
	zawm	a3_M * gkPtn3_filt2, 			10	; send to filter 2
	zawm	a3_M * gkPtn3_del1	, 		11	; send to delay 1
	zawm	a3_M * gkPtn3_del2	, 		12	; send to delay 2
	zawm	a3_M * gkPtn3_revb	, 		13	; send to reverb
	zawm	a3_M,					14	; to VU meter

	endin
;****************************************************************
;****************************************************************

;****************************************************************
; metronome instr (Bass Drum)
;****************************************************************
	instr	340
iamp	= p4 * 5000
a1	loscil	iamp, 1, 50, 1
	outs	a1, a1
	endin
;****************************************************************
;****************************************************************

;****************************************************************
; phrase metronome instr (hihat)
;****************************************************************
	instr	341
iamp	= p4 * 10000
a1	loscil	iamp, 1, 51, 1
	outs	a1, a1
	endin
;****************************************************************
;****************************************************************

;****************************************************************
; phrase2 metronome instr (hihat)
;****************************************************************
	instr	342
iamp	= p4 * 2000
a1	loscil	iamp, 0.5, 51, 1
	outs	a1, a1
	endin
;****************************************************************
;****************************************************************

;****************************************************************
; phrase3 metronome instr (hihat)
;****************************************************************
	instr	343
iamp	= p4 * 8000
a1	loscil	iamp, 1.5, 51, 1
	outs	a1, a1
	endin
;****************************************************************
;****************************************************************



;****************************************************************
; midi out metronome instr
;****************************************************************
	instr	345



	endin
;****************************************************************
;****************************************************************


;****************************************************************
; drumloop instr, loop should fill exactly one measure of the current time signature
;****************************************************************
	instr	350

kampR		init 1		; release envelope
krinflag	init 1		; reinit for release flag
ireltime	= 0.02

if gkdrmoff = 0 kgoto contin
if krinflag < 1 goto skip_rin	; reinit only once, at start of release stage
reinit	release
krinflag	= 0
skip_rin:
timout	0, ireltime, release
turnoff

release:
kampR	linseg	1, ireltime, 0, 1, 0
rireturn
contin:

iamp	= 0.68
kamp	= iamp * kampR

; DrumLoop
ifno	=  i(gkDrmLopN) + 250		; select table number
ilength_0 = ftlen(ifno) 			; get number of samples in table
ilength = nsamp(ifno) 			; get number of samples in table
print ilength_0, ilength
iorig	= sr / ilength			; get "original pitch", so that a kcps=1 through the loop in 1 second
icps	init 0.5
icps	= i(gkdrumlop_ptch)
kcps	= (gkbtpo_cps * 0.25) * icps
kamp1	= kamp * gk1DrmLopAm
a1o,a2o	loscil	kamp1, kcps/iorig, ifno, 1, 1, 1, ilength/2


; DrumLoop2
ifno2	=  i(gkDrmLopN2) + 250		; select table number
ilength2 = ftlen(ifno2)			; get number of samples in table
iorig2	= sr / ilength2			; get "original pitch", so that a kcps=1 through the loop in 1 second
; icps and kcps reused from drumloop1
kamp2	= kamp * gk2DrmLopAm
kamp2	= (ifno2 == 250 ? 0 : kamp2)	; mute if selected table is 0
kamp2	tonek	kamp2, 100
a21o,a22o loscil	kamp2, kcps, ifno2, iorig2, 1, 1, ilength2/2

; DrumLoop3
ifno3	=  i(gkDrmLopN3) + 250		; select table number
ilength3 = ftlen(ifno3)			; get number of samples in table
iorig3	= sr / ilength3			; get "original pitch", so that a kcps=1 through the loop in 1 second
; icps and kcps reused from drumloop1
kamp3	= kamp * gk3DrmLopAm
kamp3	= (ifno3 == 250 ? 0 : kamp3)	; mute if selected table is 0
kamp3	tonek	kamp3, 100
a31o,a32o loscil	kamp3, kcps, ifno3, iorig3, 1, 1, ilength3/2
abogus	rand	gidenorm			; bogus signal, to feed the filters when instrument is active and silent,
						; prevents underflow in filters

a1o	= a1o + abogus				; denorm
a2o	= a2o + abogus
a21o	= a21o + abogus
a22o	= a22o + abogus
a31o	= a31o + abogus
a32o	= a32o + abogus



; beat cutting layer 2
ibps		= i(gkbtpo_cps)
isubdiv		= i(gkDLsubdiv)
ibarlength	= i(gkDLbarlen)
iphrasebars	= i(gkDLphrbar)
inumrepeats 	= i(gkDLnumrep)
istutterspeed	= i(gkDLstuspd)
istutterchance	= (i(gkDLsturnd)*0.01)
ienvchoice  	= i(gkDLenv)
a21b	bbcutm	a21o, ibps, isubdiv, ibarlength, iphrasebars, inumrepeats , istutterspeed, istutterchance, ienvchoice  
a22b	bbcutm	a22o, ibps, isubdiv, ibarlength, iphrasebars, inumrepeats , istutterspeed, istutterchance, ienvchoice 
a21o	= (a21o * (1-gk2DLbbmix)) + (a21b * gk2DLbbmix) 	; mix/balance of original and bbcut loop
a22o	= (a22o * (1-gk2DLbbmix)) + (a22b * gk2DLbbmix) 	; mix/balance of original and bbcut loop

;filter layer 2
k2lowcut		= 20 + (gk2Loop_HP*gk2Loop_HP * 7000)
a21l, a21h, abd	svfilter	a21o, k2lowcut, (2+gk2Loop_LP*6), 1
a22l, a22h, abd	svfilter	a22o, k2lowcut, (2+gk2Loop_LP*6), 1
k2HPfact	pow (gk2Loop_HP+1), 2
k2LPfact	pow (gk2Loop_LP+1), 2
 
a21h	= a21h * k2HPfact
a22h	= a22h * k2HPfact
a21l	= a21l * k2LPfact
a22l	= a22l * k2LPfact

a21o		= (a21l*gk2Loop_LP) + (a21h*gk2Loop_Clean)
a22o		= (a22l*gk2Loop_LP) + (a22h*gk2Loop_Clean)


; beat cutting layer 3
ibps		= i(gkbtpo_cps)
isubdiv		= i(gkDLsubdiv)
ibarlength	= i(gkDLbarlen)
iphrasebars	= i(gkDLphrbar)
inumrepeats 	= i(gkDLnumrep)
istutterspeed	= i(gkDLstuspd)
istutterchance	= (i(gkDLsturnd)*0.01)
ienvchoice  	= i(gkDLenv)
a31b	bbcutm	a31o, ibps, isubdiv, ibarlength, iphrasebars, inumrepeats , istutterspeed, istutterchance, ienvchoice  
a32b	bbcutm	a32o, ibps, isubdiv, ibarlength, iphrasebars, inumrepeats , istutterspeed, istutterchance, ienvchoice 
a31o	= (a31o * (1-gk3DLbbmix)) + (a31b * gk3DLbbmix) 	; mix/balance of original and bbcut loop
a32o	= (a32o * (1-gk3DLbbmix)) + (a32b * gk3DLbbmix) 	; mix/balance of original and bbcut loop

;****
;filter layer 3
k3lowcut		= 20 + (gk3Loop_HP*gk3Loop_HP * 7000)
a31l, a31h, abd	svfilter	a31o, k3lowcut, (2+gk3Loop_LP*6), 1
a32l, a32h, abd	svfilter	a32o, k3lowcut, (2+gk3Loop_LP*6), 1
k3HPfact	pow (gk3Loop_HP+1), 2
k3LPfact	pow (gk3Loop_LP+1), 2
 
a31h		= a31h * k3HPfact
a32h		= a32h * k3HPfact
a31l		= a31l * k3LPfact
a32l		= a32l * k3LPfact

a31o		= (a31l*gk3Loop_LP) + (a31h*gk3Loop_Clean)
a32o		= (a32l*gk3Loop_LP) + (a32h*gk3Loop_Clean)


; Master control Loop
a1	= a1o + a21o + a31o
a2	= a2o + a22o + a32o

; beat cutting
ibps		= i(gkbtpo_cps)
isubdiv		= i(gkDLsubdiv)
ibarlength	= i(gkDLbarlen)
iphrasebars	= i(gkDLphrbar)
inumrepeats 	= i(gkDLnumrep)
istutterspeed	= i(gkDLstuspd)
istutterchance	= (i(gkDLsturnd)*0.01)
ienvchoice  	= i(gkDLenv)
a1b	bbcutm	a1, ibps, isubdiv, ibarlength, iphrasebars, inumrepeats , istutterspeed, istutterchance, ienvchoice  
a2b	bbcutm	a2, ibps, isubdiv, ibarlength, iphrasebars, inumrepeats , istutterspeed, istutterchance, ienvchoice 

a1	= (a1 * (1-gkDLbbmix)) + (a1b * gkDLbbmix) 	; mix/balance of original and bbcut loop
a2	= (a2 * (1-gkDLbbmix)) + (a2b * gkDLbbmix) 	; mix/balance of original and bbcut loop

klowcut		= 20 + (gkLoop_HP * 12000)
alow, a1, abd	svfilter	a1, klowcut, 2, 1 ; [, iscl]
alow, a2, abd	svfilter	a2, klowcut, 2, 1 ; [, iscl]
kHPfact	pow (gkLoop_HP+1), 2
a1		= a1 * kHPfact * gkDrmLopAm 
a2		= a2 * kHPfact * gkDrmLopAm 

; drumloop fills/cuts
kfill1	= gkfill1 + gkfill2 + gkfill3 + gkfill4
ktempo	= gkfill1*(2/3) + gkfill2*2 + gkfill3*3 + gkfill4*5
ktempo	= (ktempo == 0 ? 1 : ktempo)
kmetro	metro	gkbtpo_cps*ktempo*2
kcount	init 1
kcount	= (kcount > 8 || kfill1 == 0 ? 1 : kcount + kmetro)
ktime	= 0.5 / (gkbtpo_cps * ktempo)

imaxdel	= 16
abogus	delayr	imaxdel, 1
kdlt	= (ktime) * kcount
atap1	deltapi	kdlt
delayw a1

abogus	delayr	imaxdel, 1
kdlt	= (ktime) * kcount
atap2	deltapi	kdlt
delayw a2

kfillvol1	tonek	kfill1, 4
a1	= (atap1*kfillvol1) + a1*(1-kfillvol1)
a2	= (atap2*kfillvol1) + a2*(1-kfillvol1)
	


; VU meter
;kVu	maxk	a1, gkupdate1, 0aVu	init 0
	maxabsaccum  aVu, a1
kVu	downsamp aVu
aVu	= 0

	FLsetVal	gkupdate1, kVu, gihsLoopampD

;EFX and dry out amplitudes
	zawm	a1 * gkLoop_clean * (1-gkLoop_pan), 4	; send to clean out Left
	zawm	a2 * gkLoop_clean * gkLoop_pan, 	5	; send to clean out Right
	zawm	a1 * gkLoop_rm,     		6	; send to RingMod
	zawm	a1 * gkLoop_fm,     		7	; send to FreqMod	
	zawm	a1 * gkLoop_filt1,  		8	; send to Filter1	
	zawm	a1 * gkLoop_dist,   		9	; send to Distortion	
	zawm	a1 * gkLoop_filt2, 		10	; send to Filter2	
	zawm	a1 * gkLoop_del1,  		11	; send to Delay1	
	zawm	a1 * gkLoop_del2,  		12	; send to Delay2	
	zawm	a1 * gkLoop_revb,  		13	; send to Reverb
;	zawm	a1,				21	; to output fileL
;	zawm	a2,				22	; to output fileR

	endin
;****************************************************************
;****************************************************************

;****************************************************************
; Pad 1, Gui controlled by note on buttons
;****************************************************************

	instr 360
iorig	= 647		;(e)
iamp	= 3000
kamp	= iamp * gksPadamp
icps1	= cpspch(p4) * 1.0001
icps2	= cpspch(p4) * 0.9999

a1	loscil	kamp, icps1, 90, iorig
a2	loscil	kamp, icps2, 90, iorig
ao	= (a1 + a2) * 0.5

; VU meter
;kVu	maxk	ao, gkupdate1, 0aVu	init 0
	maxabsaccum  aVu, ao
kVu	downsamp aVu
aVu	= 0

	FLsetVal	gkupdate1, kVu, gihsPadampD

;EFX and dry out amplitudes

	zawm	a1 * gkPad_clean * (1-gkPad_pan), 4	; send to clean out Left
	zawm	a2 * gkPad_clean * gkPad_pan, 	5	; send to clean out Right
	zawm	ao * gkPad_rm	, 		6	; send to RingMod
	zawm	ao * gkPad_fm	, 		7	; send to FreqMod	
	zawm	ao * gkPad_filt1, 		8	; send to Filter1	
	zawm	ao * gkPad_dist	, 		9	; send to Distortion	
	zawm	ao * gkPad_filt2, 		10	; send to Filter2	
	zawm	ao * gkPad_del1	, 		11	; send to Delay1	
	zawm	ao * gkPad_del2	, 		12	; send to Delay2	
	zawm	ao * gkPad_revb	, 		13	; send to Reverb

	endin
;****************************************************************
;****************************************************************

;****************************************************************
; Pad 1, played via midi, efx sends in GUI (same as instr 60)
;****************************************************************
	instr 361

inum	notnum
icps	cpsmidi
iamp	ampmidi	5000
;DT control notes
if inum >= 84 goto DTcontrol
kamp	linenr	iamp, 0.01, 0.7, 0.01
;iorig	= 523.251	; C
;iorig	= 261.6256	;
iorig	= 65.4064
ifno	= int((inum / 12)) - 2 ; note num 35 gets ifno 1, +1 for each octave over
ifno	= (ifno > 6 ? 6 : ifno)
ifno	= (ifno < 1 ? 1 : ifno)
ioct	pow	2, ifno
ioct	= ioct * 0.5
iorig	= iorig * ioct
icps1	= icps * 1.0001
icps2	= icps * 0.9999

a1	loscil	kamp, icps1, ifno + 83, iorig
a2	loscil	kamp, icps2, ifno + 83, iorig
ao	= (a1 + a2) * 0.5 * gksPadamp

; VU meter
;kVu	maxk	ao, gkupdate1, 0aVu	init 0
	maxabsaccum  aVu, ao
kVu	downsamp aVu
aVu	= 0

	FLsetVal	gkupdate1, kVu, gihsPadampD

;EFX and dry out amplitudes

	zawm	a1 * gkPad_clean * (1-gkPad_pan), 4	; send to clean out Left
	zawm	a2 * gkPad_clean * gkPad_pan, 	5	; send to clean out Right
	zawm	ao * gkPad_rm	, 		6	; send to RingMod
	zawm	ao * gkPad_fm	, 		7	; send to FreqMod	
	zawm	ao * gkPad_filt1, 		8	; send to Filter1	
	zawm	ao * gkPad_dist	, 		9	; send to Distortion	
	zawm	ao * gkPad_filt2, 		10	; send to Filter2	
	zawm	ao * gkPad_del1	, 		11	; send to Delay1	
	zawm	ao * gkPad_del2	, 		12	; send to Delay2	
	zawm	ao * gkPad_revb	, 		13	; send to Reverb

;Dual Theme
DTcontrol:
iDTfn	= 331		; table for storing pitches
iDTempty = 330		; empty table

if inum < 84 goto record
if inum == 84 goto delete
if inum == 85 goto stop
if inum == 87 goto start
goto end

start:
ktrig init 1
schedkwhen	ktrig, 0, 0, 382, 0, -1
ktrig = 0
goto end

stop:
ktrig init 1
schedkwhen	ktrig, 0, 0, -382, 0, 1
ktrig = 0
goto end

delete:
; clear recorded melodies
giDTwindx = 0
tableicopy	iDTfn, iDTempty
goto end

record:
;store pitches for DualTheme
giDTwindx	= giDTwindx + 1
tableiw	icps, giDTwindx, iDTfn 
goto end

end:
	endin
;****************************************************************
;****************************************************************

;****************************************************************
; DualTheme instruments
;****************************************************************

;****************************************************************
; clear stored pitches
;****************************************************************
	instr 381
giDTwindx = 0
	endin
;****************************************************************

;*********************************************************************
; DualTheme metronome instr
;*********************************************************************
	instr	382

kbtpo	= 0.5	; basic tempo
k1tpo	table	gkDTf1, 341, 1
k2tpo	table	gkDTf2, 341, 1

kfreq1	= k1tpo*kbtpo
kfreq2	= k2tpo*kbtpo

kmetro1	metro	kfreq1
kmetro2	metro	kfreq2

kskip1	randh	1, kfreq1, 0.2
kskip2	randh	1, kfreq2, 0.6

ipercent1 = 0.8
ipercent2 = 0.7
kmetro1	= (kskip1 < ipercent1 ? kmetro1 : 0 )
kmetro2	= (kskip2 < ipercent2 ? kmetro2 : 0 )

kdur1	limit	1/kfreq1, 0.7, 2
kdur2	limit	1/kfreq2, 0.7, 2

schedkwhen	kmetro1, 2/kr, 15, 383, 0, kdur1, gkDTtime1
schedkwhen	kmetro2, 2/kr, 15, 384, 0, kdur1, gkDTtime2


; time reading must be after schedkwhen
if kmetro1 < 1 kgoto timeread1
reinit timeread1
timeread1:
ktime1	timeinsts		; time in seconds
gkDTtime1	= ktime1
rireturn

; time reading must be after schedkwhen
if kmetro2 < 1 kgoto timeread2
reinit timeread2
timeread2:
ktime2	timeinsts		; time in seconds
gkDTtime2	= ktime2
rireturn
	
	endin
;*********************************************************************

;*********************************************************************
; DT tone 1 instr
;*********************************************************************
	instr	383
	ipan	= 0.2
	iamp	= 2000 + (p4*4000)		; amp affected by time since previous note
	iamp	limit	iamp, 1000, 15000		; limit amp, just in case ...
	kamp	adsr	0.01, 0.3*p3, 0.2, 0.3*p3
	kvol	table gkDTf3, 339, 1
;	kvol	portk	kvol, 2, i(kvol)
	kamp	= kamp * iamp * i(kvol) * gksDTamp
	amp	interp	kamp	

	giDTcpsindx1 = (giDTcpsindx1 > giDTwindx ? 0 : giDTcpsindx1)
	giDTcpsindx1 = giDTcpsindx1 + 1
	icpsindx = giDTcpsindx1
	itab1	table	icpsindx, 331

if itab1 < 65 goto end
; if non valid note number (in Hz) skip note

	icps	= itab1
	ioct	table	p4*4, 340	; time since previous note affects octaviation
	icps	= icps * ioct

	kmodfq	= icps * 1.3333 
	imodndx	= 1000 + (icps*2)
	kmodenv	adsr	0.01, 0.5*p3, 0.8, 0.1*p3
	kmod	table gkDTf3, 338, 1
	kmod	portk	kmod, 0.05, i(kmod)
	kmodenv	= kmodenv * imodndx * kmod
	amod	oscil	kmodenv, kmodfq, 93
	acps	= icps + amod

	a1	oscil	amp, acps, 93


; VU meter
;kVu	maxk	a1, gkupdate1, 0aVu	init 0
	maxabsaccum  aVu, a1
kVu	downsamp aVu
aVu	= 0

	FLsetVal	gkupdate1, kVu, gihsDTampD

;EFX and dry out amplitudes

	zawm	a1 * gkDT_clean * (1-ipan), 4	; send to clean out Left
	zawm	a1 * gkDT_clean * ipan, 	5	; send to clean out Right
	zawm	a1 * gkDT_rm	, 		6	; send to RingMod
	zawm	a1 * gkDT_fm	, 		7	; send to FreqMod	
	zawm	a1 * gkDT_filt1, 		8	; send to Filter1	
	zawm	a1 * gkDT_dist	, 		9	; send to Distortion	
	zawm	a1 * gkDT_filt2, 		10	; send to Filter2	
	zawm	a1 * gkDT_del1	, 		11	; send to Delay1	
	zawm	a1 * gkDT_del2	, 		12	; send to Delay2	
	zawm	a1 * gkDT_revb	, 		13	; send to Reverb

end:
	endin
;*********************************************************************

;*********************************************************************
; DT tone 2 instr
;*********************************************************************
	instr	384
	ipan	= 0.8
	iamp	= 2000 + (p4*4000)		; amp affected by time since previous note
	iamp	limit	iamp, 1000, 15000		; limit amp, just in case ...
	kamp	adsr	0.01, 0.3*p3, 0.8, 0.3*p3
	kvol	table gkDTf3, 339, 1
;	kvol	portk	kvol, 0.05, i(kvol)
	kamp	= kamp * iamp * i(kvol) * gksDTamp
	amp	interp	kamp

	giDTcpsindx2 = (giDTcpsindx2 > giDTwindx ? 0 : giDTcpsindx2)
	giDTcpsindx2 = giDTcpsindx2 + 1
	icpsindx = giDTcpsindx2
	itab1	table	icpsindx, 331

if itab1 < 65 goto end
; if non valid note number (in Hz) skip note

	icps	= itab1 * 0.5
	ioct	table	p4*4, 340	; time since previous note affects octaviation
	icps	= icps * ioct * 0.5	; octave down for this voice


	kmodfq	= icps * 1.5 
	imodndx	= 1500 + (icps*3)
	kmodenv	adsr	0.01, 0.5*p3, 0.4, 0.1*p3
	kmod	table gkDTf3, 338, 1
	kmod	portk	kmod, 0.05, i(kmod)
	kmodenv	= kmodenv * imodndx * kmod
	amod	oscil	kmodenv, kmodfq, 93
	acps	= icps + amod

	a1	oscil	amp, acps, 93

; VU meter
;kVu	maxk	a1, gkupdate1, 0aVu	init 0
	maxabsaccum  aVu, a1
kVu	downsamp aVu
aVu	= 0

	FLsetVal	gkupdate1, kVu, gihsDTampD

;EFX and dry out amplitudes

	zawm	a1 * gkDT_clean * (1-ipan), 4	; send to clean out Left
	zawm	a1 * gkDT_clean * ipan, 	5	; send to clean out Right
	zawm	a1 * gkDT_rm	, 		6	; send to RingMod
	zawm	a1 * gkDT_fm	, 		7	; send to FreqMod	
	zawm	a1 * gkDT_filt1, 		8	; send to Filter1	
	zawm	a1 * gkDT_dist	, 		9	; send to Distortion	
	zawm	a1 * gkDT_filt2, 		10	; send to Filter2	
	zawm	a1 * gkDT_del1	, 		11	; send to Delay1	
	zawm	a1 * gkDT_del2	, 		12	; send to Delay2	
	zawm	a1 * gkDT_revb	, 		13	; send to Reverb
end:
	endin
;*********************************************************************


;****************************************************************
; WYL Noises instruments
;****************************************************************

;****************************************************************
instr	387

iamp	= 8000 
kctrl1	ctrl7	1, 1, 0, 1			;ch1, midi ctrl1, min, max
kctrl2	ctrl7	1, 2, 0, 1			;ch1, midi ctrl1, min, max

ifno1	= 351
ifno2	= 352
iorig	init 440	

a_amp	linenr	iamp, 0.4, 1.7, 0.01
a_amp	= a_amp * kctrl2 * gksWLNamp
kvol1	table	1-kctrl1, 360, 1
kvol2	table	kctrl1, 360, 1
a_amp1	= a_amp * kvol1
a_amp2	= a_amp * kvol2

	a1,a2	loscil	a_amp1, iorig, ifno1, iorig
	a3,a4	loscil	a_amp2, iorig, ifno2, iorig

	aoutL	= a1 + a3
	aoutR	= a2 + a4
	aout	= (a1 + a2 + a3 + a4) * 0.5

; VU meter
;kVu	maxk	aout, gkupdate1, 0aVu	init 0
	maxabsaccum  aVu, aout
kVu	downsamp aVu
aVu	= 0

	FLsetVal	gkupdate1, kVu, gihsWLNampD

;EFX and dry out amplitudes

	zawm	aoutL * gkWLN_clean * (1-gkWLN_pan), 4	; send to clean out Left
	zawm	aoutR * gkWLN_clean * gkWLN_pan, 5	; send to clean out Right
	zawm	aout * gkWLN_rm	, 		6	; send to RingMod
	zawm	aout * gkWLN_fm	, 		7	; send to FreqMod	
	zawm	aout * gkWLN_filt1, 		8	; send to Filter1	
	zawm	aout * gkWLN_dist	, 	9	; send to Distortion	
	zawm	aout * gkWLN_filt2, 		10	; send to Filter2	
	zawm	aout * gkWLN_del1	, 	11	; send to Delay1	
	zawm	aout * gkWLN_del2	, 	12	; send to Delay2	
	zawm	aout * gkWLN_revb	, 	13	; send to Reverb

endin
;******************************************************************
instr	388

iamp	= 3000 
kctrl1	ctrl7	1, 1, 0, 1			;ch1, midi ctrl1, min, max
kctrl2	ctrl7	1, 2, 0, 1			;ch1, midi ctrl2, min, max
kctrl3	ctrl7	1, 3, 0, 1			;ch1, midi ctrl3, min, max
klfo1	oscil	0.5, 0.2, 93
klfo1	= klfo1 + 0.5

a_amp	linenr	iamp, 0.001, 0.7, 0.01
a_amp	= a_amp * gksWLNamp

kdens	= (kctrl2 * 40) + 0.3
ktrans	= (kctrl1*4) + 1
aphs	linseg	0, 2.8, 0.7, 1, 0.7
aphs	= aphs + (klfo1*0.2)
koct	= 0
kband	= 0
kdur	= (kctrl3 * 0.1) + 0.01
kris	= kdur * 0.2
kdec	= kdur * 0.2
iolaps	= 50
ifna	= 353
ifnb	= 360
itotdur	= 6000

a1	fog	a_amp, kdens, ktrans, aphs, koct, kband, kris, kdur, kdec, iolaps, ifna, ifnb, itotdur

; VU meter
;kVu	maxk	a1, gkupdate1, 0aVu	init 0
	maxabsaccum  aVu, a1
kVu	downsamp aVu
aVu	= 0

	FLsetVal	gkupdate1, kVu, gihsWLNampD

;EFX and dry out amplitudes

	zawm	a1 * gkWLN_clean * (1-gkWLN_pan), 4	; send to clean out Left
	zawm	a1 * gkWLN_clean * gkWLN_pan, 	5	; send to clean out Right
	zawm	a1 * gkWLN_rm	, 		6	; send to RingMod
	zawm	a1 * gkWLN_fm	, 		7	; send to FreqMod	
	zawm	a1 * gkWLN_filt1, 		8	; send to Filter1	
	zawm	a1 * gkWLN_dist	, 		9	; send to Distortion	
	zawm	a1 * gkWLN_filt2, 		10	; send to Filter2	
	zawm	a1 * gkWLN_del1	, 		11	; send to Delay1	
	zawm	a1 * gkWLN_del2	, 		12	; send to Delay2	
	zawm	a1 * gkWLN_revb	, 		13	; send to Reverb

endin
;******************************************************************
instr	389

iamp	= 6000 
kctrl1	ctrl7	1, 1, 0, 1			;ch1, midi ctrl1, min, max
kctrl2	ctrl7	1, 2, 0, 1			;ch1, midi ctrl2, min, max
kctrl3	ctrl7	1, 3, 0, 1			;ch1, midi ctrl3, min, max
klfo1	oscil	0.5, 0.2, 93
klfo1	= klfo1 + 0.5

a_amp	linenr	iamp, 0.001, 0.7, 0.01
a_amp	= a_amp * gksWLNamp

kdens	= (kctrl2 * 40) + 0.3
ktrans	= (2+(kctrl1*0.3))
aphs	phasor	0.3 * (1.01 - kctrl2) * (1 - (kctrl1*0.3))
koct	= kctrl1*4
kband	= kctrl1 * 50
kdur	= (kctrl3 * 0.1) + 0.01 + (kctrl1*0.1)
kris	= kdur * 0.2
kdec	= kdur * 0.2
iolaps	= 50
ifna	= 354 
ifnb	= 360
itotdur	= 6000
a_amp = a_amp * (1-(kctrl1*0.6)) * (1-(kctrl3*0.5))
a1	fog	a_amp, kdens, ktrans, aphs, koct, kband, kris, kdur, kdec, iolaps, ifna, ifnb, itotdur

; VU meter
;kVu	maxk	a1, gkupdate1, 0aVu	init 0
	maxabsaccum  aVu, a1
kVu	downsamp aVu
aVu	= 0

	FLsetVal	gkupdate1, kVu, gihsWLNampD

;EFX and dry out amplitudes

	zawm	a1 * gkWLN_clean * (1-gkWLN_pan), 	4	; send to clean out Left
	zawm	a1 * gkWLN_clean * gkWLN_pan, 		5	; send to clean out Right
	zawm	a1 * gkWLN_rm	, 		6	; send to RingMod
	zawm	a1 * gkWLN_fm	, 		7	; send to FreqMod	
	zawm	a1 * gkWLN_filt1, 		8	; send to Filter1	
	zawm	a1 * gkWLN_dist	, 		9	; send to Distortion	
	zawm	a1 * gkWLN_filt2, 		10	; send to Filter2	
	zawm	a1 * gkWLN_del1	, 		11	; send to Delay1	
	zawm	a1 * gkWLN_del2	, 		12	; send to Delay2	
	zawm	a1 * gkWLN_revb	, 		13	; send to Reverb

endin
;******************************************************************
instr 390

iamp	= 6000
kctrl1	ctrl7	1, 1, 0, 1			;ch1, midi ctrl1, min, max
kctrl2	ctrl7	1, 2, 0, 1			;ch1, midi ctrl1, min, max
kctrl3	ctrl7	1, 3, 0, 1			;ch1, midi ctrl1, min, max

icps	= 220
kcps	= icps * ((kctrl2+1) * 3)

ifno1	= 355
ifno2	= 356
iorig	init 440	

a_amp	linenr	iamp, 1, 2.7, 0.01
a_amp	= a_amp * kctrl3 * gksWLNamp

kvol1	table	1-kctrl1, 360, 1
kvol2	table	kctrl1, 360, 1
a_amp1	= a_amp * kvol1
a_amp2	= a_amp * kvol2

	a1,a2	loscil	a_amp1, kcps, ifno1, iorig
	a3,a4	loscil	a_amp2, kcps, ifno2, iorig

	aoutL	= a1 + a3
	aoutR	= a2 + a4
	aout	= (a1 + a2 + a3 + a4) * 0.5

; VU meter
;kVu	maxk	aout, gkupdate1, 0aVu	init 0
	maxabsaccum  aVu, aout
kVu	downsamp aVu
aVu	= 0

	FLsetVal	gkupdate1, kVu, gihsWLNampD

;EFX and dry out amplitudes

	zawm	aoutL * gkWLN_clean * (1-gkWLN_pan), 	4	; send to clean out Left
	zawm	aoutR * gkWLN_clean * gkWLN_pan, 	5	; send to clean out Right
	zawm	aout * gkWLN_rm	, 		6	; send to RingMod
	zawm	aout * gkWLN_fm	, 		7	; send to FreqMod	
	zawm	aout * gkWLN_filt1, 		8	; send to Filter1	
	zawm	aout * gkWLN_dist	, 	9	; send to Distortion	
	zawm	aout * gkWLN_filt2, 		10	; send to Filter2	
	zawm	aout * gkWLN_del1	, 	11	; send to Delay1	
	zawm	aout * gkWLN_del2	, 	12	; send to Delay2	
	zawm	aout * gkWLN_revb	, 	13	; send to Reverb

endin
;******************************************************************
;******************************************************************




;****************************************************************
; EFX channel "keep it alive instr", 
;****************************************************************
; this instr runs bogus/unhearable audio values through the efx/output channels
; this stabilizes the audio patching channels and thus avoids dropouts
; it's a hack, it works around the underflow bug of intel processors

	instr 401

aVU	zar	14			; mixed signal from PatternSequencer, for VU

; VU meter
;kVu	maxk	aVU, gkupdate1, 0aVu1	init 0
	maxabsaccum  aVu1, aVU
kVu	downsamp aVu1
aVu1	= 0

	FLsetVal	gkupdate1, kVu, gihsPtSeqampD

; prevents underflow in filters
iamp	= gidenorm
a1	 rand	iamp

;EFX and dry out amplitudes

	zawm	a1, 4	; send to clean out Left
	zawm	a1, 5	; send to clean out Right
	zawm	a1, 6	; send to RingMod
	zawm	a1, 7	; send to FreqMod	
	zawm	a1, 8	; send to Filter1	
	zawm	a1, 9	; send to Distortion	
	zawm	a1, 10	; send to Filter2	
	zawm	a1, 11	; send to Delay1	
	zawm	a1, 12	; send to Delay2	
	zawm	a1, 13	; send to Reverb

	endin
;****************************************************************
;****************************************************************


;****************************************************************
; Ring Mod1 instr
;****************************************************************
	instr 491

	a1	zar	6
	a1	= a1 / 32768

	kmodfrq	= gkfx_rm_mfrq				; modulator freq
	kbal	= gkfx_rm_mndx				; modulation index (balance)
	krms	rms	a1, 5				; get rms of input signal
	kampmod	= krms * gkfx_rm_afrq / 32000		; amount of amp->freq
	kmodfrq	= kmodfrq + (kmodfrq*kampmod)		; input amp modifies mod freq
	klfo	oscil	gkfx_rm_lamt, gkfx_rm_lfrq, 93	; make lfo
	kmodfrq	= kmodfrq + (kmodfrq*klfo)		; lfo modifies mod freq
	amod	oscil	1, kmodfrq, 93			; modulator oscil
	arm	= a1 * amod				; calculate ring mod
	aout	= ((arm * kbal) + (a1 * (1-kbal)) ) * 32768
	aout	= aout * gksRngModamp

; VU meter
;kVu	maxk	aout, gkupdate1, 0aVu	init 0
	maxabsaccum  aVu, aout
kVu	downsamp aVu
aVu	= 0

	FLsetVal	gkupdate1, kVu, gihsRngModampD

;EFX and dry out amplitudes
	zawm	aout * gkfx_rm_dry * (1-gkpanRngMod), 	4	; send to clean out Left
	zawm	aout * gkfx_rm_dry * gkpanRngMod, 	5	; send to clean out Right
	zawm	aout * gkfx_rm_fm  , 			7	; send to FreqMod	
	zawm	aout * gkfx_rm_flt1, 			8	; send to Filter1	
	zawm	aout * gkfx_rm_dist, 			9	; send to Distortion	
	zawm	aout * gkfx_rm_flt2, 			10	; send to Filter2	
	zawm	aout * gkfx_rm_dly1, 			11	; send to Delay1	
	zawm	aout * gkfx_rm_dly2, 			12	; send to Delay2	
	zawm	aout * gkfx_rm_rvb , 			13	; send to Reverb

	endin
;****************************************************************
;****************************************************************

;****************************************************************
; Freq Mod effect instr
;****************************************************************
	instr 492

;frequency modulation implemented as an a-rate variable delay line
	a1	zar	7

	kmodfrq	= gkfx_fm_mfrq				; modulator freq
	kmodndx	= gkfx_fm_mndx*0.1			; modulation index
	krms	rms	a1, 5				; get rms of input signal
	kampmod	= krms * gkfx_fm_afrq / 32000		; amount of amp->freq
	kmodfrq	= kmodfrq + (kmodfrq*kampmod)		; input amp modifies mod freq
	klfo	oscil	gkfx_fm_lamt, gkfx_fm_lfrq, 93	; make lfo
	kmodfrq	= kmodfrq + (kmodfrq*klfo)		; lfo modifies mod freq

	imaxdel	= 1	; lower is CPU-cheaper
;	imaxdel	= 2
;	iwinsiz	= 8
	iwinsiz	= 4	; lower is CPU-cheaper

	amod	oscil	kmodndx, kmodfrq, 93
	amod	= amod + kmodndx + 0.001
	acar	vdelayx	a1, amod, imaxdel, iwinsiz

	acar	= acar * gksFrqModamp

; VU meter
;kVu	maxk	acar, gkupdate1, 0aVu	init 0
	maxabsaccum  aVu, acar
kVu	downsamp aVu
aVu	= 0

	FLsetVal	gkupdate1, kVu, gihsFrqModampD

;EFX and dry out amplitudes
	zawm	acar * gkfx_fm_dry * (1-gkpanFrqMod), 	4	; send to clean out Left
	zawm	acar * gkfx_fm_dry * gkpanFrqMod, 	5	; send to clean out Right
	zawm	acar * gkfx_fm_flt1, 			8	; send to Filter1	
	zawm	acar * gkfx_fm_dist, 			9	; send to Distortion	
	zawm	acar * gkfx_fm_flt2, 			10	; send to Filter2	
	zawm	acar * gkfx_fm_dly1, 			11	; send to Delay1	
	zawm	acar * gkfx_fm_dly2, 			12	; send to Delay2	
	zawm	acar * gkfx_fm_rvb , 			13	; send to Reverb

	endin
;****************************************************************
;****************************************************************

;****************************************************************
; Filter 1  instr
;****************************************************************
	instr 493

	a1	zar	8

	kfreq	= gkfx_f1_cfrq				; filter freq
	kq	= gkfx_f1_q*(kfreq*0.5)			; filter Q
	krms	rms	a1, 5				; get rms of input signal
	kampmod	= krms * gkfx_f1_afrq / 32000		; amount of amp->freq
	kfreq	= kfreq + (kfreq*kampmod)		; input amp modifies freq
	klfo	oscil	gkfx_f1_lamt, gkfx_f1_lfrq, 93	; make lfo
	kfreq 	= kfreq + (kfreq*klfo)			; lfo modifies freq
	kfreq	= (kfreq > 20000 ? 20000 : kfreq)	; limit upper range to 20000
	kfreq	= (kfreq < 20 ? 20 : kfreq)		; limit lower range to 20

	alp,ahp,abp	svfilter	a1, kfreq, kq
	alp	balance	alp, a1
	abp	balance	abp, a1
	ahp	balance	ahp, a1
	ares	mac	gkfx_f1_lp, alp, gkfx_f1_bp, abp, gkfx_f1_hp, ahp	; add and multiply
	ares	= ares * gksFilt1amp

; VU meter
;kVu	maxk	ares, gkupdate1, 0aVu	init 0
	maxabsaccum  aVu, ares
kVu	downsamp aVu
aVu	= 0

	FLsetVal	gkupdate1, kVu, gihsFilt1ampD

;EFX and dry out amplitudes
	zawm	ares * gkfx_f1_dry * (1-gkpanFilt1), 	4	; send to clean out Left
	zawm	ares * gkfx_f1_dry * gkpanFilt1, 	5	; send to clean out Right
	zawm	ares * gkfx_f1_dist, 			9	; send to Distortion	
	zawm	ares * gkfx_f1_flt2, 			10	; send to Filter2	
	zawm	ares * gkfx_f1_dly1, 			11	; send to Delay1	
	zawm	ares * gkfx_f1_dly2, 			12	; send to Delay2	
	zawm	ares * gkfx_f1_rvb , 			13	; send to Reverb

	endin
;****************************************************************
;****************************************************************

;****************************************************************
; Distortion  instr
;****************************************************************
	instr 494

	a1	zar	9

	kpregain	= gkfx_ds_drv
	krms		rms	a1, 5				; get rms of input signal
	kampmod		= krms * gkfx_ds_adrv / 32000		; amount of amp->freq
	kpregain	= kpregain + (kpregain*kampmod)		; input amp modifies dist drive (+/- range)
	kpostgain	= (0.5 / kpregain) * (kpregain*0.5)	; auto set output gain corresponding to input drive
	kshape1 	= gkfx_ds_shp*2				
	kshape2		= gkfx_ds_shp

; prevents underflow in filters
iampbog	= gidenorm
abogus	 rand	iampbog
a1	= a1 + abogus
	adist	distort1	a1, kpregain, kpostgain, kshape1, kshape2
adist	= adist + abogus
	;aout	rezzy	adist, gkfx_ds_pflt*0.4, 2		; post dist filter
	;aout	= aout * gksDistamp
	aout	= adist * gksDistamp		; hack

; VU meter
;kVu	maxk	aout, gkupdate1, 0aVu	init 0
	maxabsaccum  aVu, aout
kVu	downsamp aVu
aVu	= 0

	FLsetVal	gkupdate1, kVu, gihsDistampD

;EFX and dry out amplitudes
	zawm	aout * gkfx_ds_dry * (1-gkpanDist), 	4	; send to clean out Left
	zawm	aout * gkfx_ds_dry * gkpanDist, 	5	; send to clean out Right
	zawm	aout * gkfx_ds_flt2, 			10	; send to Filter2	
	zawm	aout * gkfx_ds_dly1, 			11	; send to Delay1	
	zawm	aout * gkfx_ds_dly2, 			12	; send to Delay2	
	zawm	aout * gkfx_ds_rvb , 			13	; send to Reverb

	endin
;****************************************************************
;****************************************************************

;****************************************************************
; Filter 2  instr
;****************************************************************
	instr 495

	a1	zar	10

	kfreq	= gkfx_f2_cfrq				; filter freq
	kres	= gkfx_f2_res				; filter bandwidth
	kdist	= gkfx_f2_dst				; filter dist
	krms	rms	a1				; get rms of input signal
	kampmod	= krms * gkfx_f2_afrq / 32000		; amount of amp->freq
	kfreq	= kfreq + (kfreq*kampmod)		; input amp modifies mod freq
	klfo	oscil	gkfx_f2_lamt, gkfx_f2_lfrq, 93	; make lfo
	kfreq	= kfreq + (kfreq*klfo)			; lfo modifies mod freq
	kfreq	= (kfreq > 20000 ? 20000 : kfreq)	; limit upper range to 20000
	kfreq	= (kfreq < 20 ? 20 : kfreq)		; limit lower range to 20

	a2	= a1 / 32000
; prevents underflow in filters
iampbog	= gidenorm
abogus	 rand	iampbog
a2	= a2 + abogus
	ares	lpf18	a2, kfreq, kres, kdist
	ares	balance	ares, a2
	ares	= ares * 32000 * gksFilt2amp

; VU meter
;kVu	maxk	ares, gkupdate1, 0aVu	init 0
	maxabsaccum  aVu, ares
kVu	downsamp aVu
aVu	= 0

	FLsetVal	gkupdate1, kVu, gihsFilt2ampD

;EFX and dry out amplitudes
	zawm	ares * gkfx_f2_dry * (1-gkpanFilt2), 	4	; send to clean out Left
	zawm	ares * gkfx_f2_dry * gkpanFilt2, 	5	; send to clean out Right
	zawm	ares * gkfx_f2_dly1, 			11	; send to Delay1	
	zawm	ares * gkfx_f2_dly2, 			12	; send to Delay2	
	zawm	ares * gkfx_f2_rvb , 			13	; send to Reverb

	endin
;****************************************************************
;****************************************************************

;****************************************************************
; delay 1  instr
;****************************************************************
	instr 496
; Delay 1:
; Xfeed ??

	a1	zar	11
	kinlevl	= 1					; input level
	kfblevl	= gkfx_d1_fb				; feedback level
	kffrq	= gkfx_d1_flt				; feedback filter freq
	kfineL	= gkfx_d1_timfL				; Left  delay time fine adjust
	kfineR	= gkfx_d1_timfR				; Right delay time fine adjust

	klfo	oscil	gkfx_d1_lfrq, 1, 93
	klfoL	= (klfo * gkfx_d1_lamtL)+ gkfx_d1_lamtL	; range and offset
	klfoR	= (klfo * gkfx_d1_lamtR)+ gkfx_d1_lamtR	; range and offset


	imaxdel	= 14					; maximum delay time
	kbtpo	init	4				; init in case unlink on
if gkfx_d1_unl = 1 kgoto contin				; skip master tempo synchronizing if "unlink" is active
	kbtpo	= 240 / gkbtpo 				; sync to master tempo
contin:
	kmult	= kbtpo / gkfx_d1_timul			; multiply, master delay tempo factor
	kdeltL	= kmult / (gkfx_d1_subL * gkfx_d1_noteL); calculate subdivision and note value
	kdeltR	= kmult / (gkfx_d1_subR * gkfx_d1_noteR); calculate subdivision and note value
	kdeltL	= (kdeltL + (kdeltL*kfineL) + (kdeltL*klfoL)) * gkDel1ManualTime	; fine tune and LFO
	kdeltR	= (kdeltR + (kdeltR*kfineR) + (kdeltR*klfoR)) * gkDel1ManualTime	; fine tune and LFO
	kdeltL	limit	kdeltL, 0.001, imaxdel
	kdeltR	limit	kdeltR, 0.001, imaxdel
;	FLprintk2	kdeltL, gih1651vL		; print to GUI
;	FLprintk2	kdeltR, gih1651vR		; print to GUI
;	FLsetVal	gkupdate1, kdeltL, gihDel1timL	; print to GUI
;	FLsetVal	gkupdate1, kdeltR, gihDel1timR	; print to GUI

	adeltL	upsamp 	kdeltL				; smoothing
	adeltR	upsamp 	kdeltR				; smoothing
	adeltL	tone	adeltL, 20			; smoothing
	adeltR	tone	adeltR, 20			; smoothing

	adummy	delayr imaxdel				; establish delay line
	adelayL	deltapi adeltL 				; tap delay Left
	adelwL	= (a1*kinlevl) + (adelayL*kfblevl)	; mix input and feedback
	adelwL	butterlp	adelwL, kffrq		; filter delay signal
		delayw	adelwL				; write source to delay line

	adummy	delayr imaxdel				; establish delay line
	adelayR	deltapi adeltR				; tap delay Right
	adelwR	= (a1*kinlevl) + (adelayR*kfblevl)	; mix input and feedback
	adelwR	butterlp	adelwR, kffrq		; filter delay signal
		delayw	adelwR				; write source to delay line


	amono	= (adelayL + adelayR ) * 0.5 * gksDel1amp
	adelayL	= adelayL * gksDel1amp
	adelayR	= adelayR * gksDel1amp

; VU meter
;kVu	maxk	amono, gkupdate1, 0aVu	init 0
	maxabsaccum  aVu, amono
kVu	downsamp aVu
aVu	= 0

	FLsetVal	gkupdate1, kVu*2, gihsDel1ampD	; double VU-meter values for Delay, just my taste

;EFX and dry out amplitudes

	zawm	adelayL * gkfx_d1_dry * (1-gkpanDel1),4	; send to clean out Left
	zawm	adelayR * gkfx_d1_dry * gkpanDel1, 	5	; send to clean out Right
	zawm	amono * gkfx_d1_dly2, 			12	; send to Delay2	
	zawm	amono * gkfx_d1_rvb , 			13	; send to Reverb

	endin
;****************************************************************
;****************************************************************

;****************************************************************
; delay 2  instr
;****************************************************************
	instr 497

	a1	zar	12
	kinlevl	= 1					; input level
	kfblevl	= gkfx_d2_fb				; feedback level
	kffrq	= gkfx_d2_flt				; feedback filter freq
	kfineL	= gkfx_d2_timfL				; Left  delay time fine adjust
	kfineR	= gkfx_d2_timfR				; Right delay time fine adjust

	klfo	oscil	gkfx_d2_lfrq, 1, 93
	klfoL	= (klfo * gkfx_d2_lamtL)+ gkfx_d2_lamtL	; range and offset
	klfoR	= (klfo * gkfx_d2_lamtR)+ gkfx_d2_lamtR	; range and offset


	imaxdel	= 14					; maximum delay time
	kbtpo	init	4				; init in case unlink on
if gkfx_d2_unl = 1 kgoto contin				; skip master tempo synchronizing if "unlink" is active
	kbtpo	= 240 / gkbtpo 				; sync to master tempo
contin:
	kmult	= kbtpo / gkfx_d2_timul			; multiply, master delay tempo factor
	kdeltL	= kmult / (gkfx_d2_subL * gkfx_d2_noteL); calculate subdivision and note value
	kdeltR	= kmult / (gkfx_d2_subR * gkfx_d2_noteR); calculate subdivision and note value
	kdeltL	= (kdeltL + (kdeltL*kfineL) + (kdeltL*klfoL)) * gkDel2ManualTime	; fine tune and LFO
	kdeltR	= (kdeltR + (kdeltR*kfineR) + (kdeltR*klfoR)) * gkDel2ManualTime	; fine tune and LFO
	kdeltL	limit	kdeltL, 0.001, imaxdel
	kdeltR	limit	kdeltR, 0.001, imaxdel
;	FLprintk2	kdeltL, gih1751vL		; print to GUI
;	FLprintk2	kdeltR, gih1751vR		; print to GUI
;	FLsetVal	gkupdate1, kdeltL, gihDel2timL	; print to GUI
;	FLsetVal	gkupdate1, kdeltR, gihDel2timR	; print to GUI

	adeltL	upsamp 	kdeltL				; smoothing
	adeltR	upsamp 	kdeltR				; smoothing
	adeltL	tone	adeltL, 20			; smoothing
	adeltR	tone	adeltR, 20			; smoothing

	adummy	delayr imaxdel				; establish delay line
	adelayL	deltapi adeltL 				; tap delay Left
	adelwL	= (a1*kinlevl) + (adelayL*kfblevl)	; mix input and feedback
	adelwL	butterlp	adelwL, kffrq		; filter delay signal
		delayw	adelwL				; write source to delay line

	adummy	delayr imaxdel				; establish delay line
	adelayR	deltapi adeltR				; tap delay Right
	adelwR	= (a1*kinlevl) + (adelayR*kfblevl)	; mix input and feedback
	adelwR	butterlp	adelwR, kffrq		; filter delay signal
		delayw	adelwR				; write source to delay line


	amono	= (adelayL + adelayR ) * 0.5 * gksDel2amp
	adelayL	= adelayL * gksDel2amp
	adelayR	= adelayR * gksDel2amp

; VU meter
;kVu	maxk	amono, gkupdate1, 0aVu	init 0
	maxabsaccum  aVu, amono
kVu	downsamp aVu
aVu	= 0

	FLsetVal	gkupdate1, kVu*2, gihsDel2ampD	; double VU-meter values for Delay, just my taste

;EFX and dry out amplitudes

	zawm	adelayL * gkfx_d2_dry * (1-gkpanDel2),4	; send to clean out Left
	zawm	adelayR * gkfx_d2_dry * gkpanDel2, 	5	; send to clean out Right
	zawm	amono * gkfx_d2_rvb , 			13	; send to Reverb

	endin
;****************************************************************
;****************************************************************

;****************************************************************
; WG reverb instr
;****************************************************************

; 8 delay line FDN reverb, with feedback matrix based upon 
; physical modeling scattering junction of 8 lossless waveguides
; of equal characteristic impedance. Based on Julius O. Smith III, 
; "A New Approach to Digital Reverberation using Closed Waveguide
; Networks," Proceedings of the International Computer Music 
; Conference 1985, p. 47-53 (also available as a seperate
; publication from CCRMA), as well as some more recent papers by
; Smith and others.
;
; Coded by Sean Costello, October 1999.
; Small modifications by Oeyvind Brandtsegg, 2001.

	instr 498        

ain	zar	13			; input signal

kpre	= gkfx_rv_pdly*1000		; predelay is in millisecs
a1	vdelay	ain, kpre, 1000		; Pre Delay

inlevl	= 0.5				; input level
ioutlevl = 0.5				; output level
klfroll		tonek gkfx_rv_lf, 0.1	; LF rolloff freq

kgain 		tonek gkfx_rv_tim, 0.1	; gain of reverb. Adjust empirically
                			; for desired reverb time. .6 gives
                			; a good small "live" room sound, .8
                			; a small hall, .9 a large hall,
                			; .99 an enormous stone cavern.

kpitchmod	tonek gkfx_rv_pmod, 0.1	; amount of random pitch modulation
                			; for the delay lines. 1 is the "normal"
                			; amount, but this may be too high for
                			; held pitches such as piano tones.
                			; Adjust to taste.

ktone 		tonek gkfx_rv_hf, 0.1	; Cutoff frequency of lowpass filters
                			; in feedback loops of delay lines,
                			; in Hz. Lower cutoff frequencies results
                			; in a sound with more high-frequency
                			; damping.

        
afilt1 init 0
afilt2 init 0
afilt3 init 0
afilt4 init 0
afilt5 init 0
afilt6 init 0
afilt7 init 0
afilt8 init 0

; Delay times chosen to be prime numbers.
; Works with sr=44100 ONLY. If you wish to
; use a different delay time, find some new
; prime numbers that will give roughly the
; same delay times for the new sampling rate. 
; Or adjust to taste.
idel1 = (2473.000/sr)
idel2 = (2767.000/sr)
idel3 = (3217.000/sr)
idel4 = (3557.000/sr)
idel5 = (3907.000/sr)
idel6 = (4127.000/sr)
idel7 = (2143.000/sr)
idel8 = (1933.000/sr)

; k1-k8 are used to add random pitch modulation to the
; delay lines. Helps eliminate metallic overtones
; in the reverb sound.
k1      randi   .001, 3.1, .06
k2      randi   .0011, 3.5, .9
k3      randi   .0017, 1.11, .7
k4      randi   .0006, 3.973, .3
k5      randi   .001, 2.341, .63
k6      randi   .0011, 1.897, .7
k7      randi   .0017, 0.891, .9
k8      randi   .0006, 3.221, .44

; apj is used to calculate "resultant junction pressure" for 
; the scattering junction of 8 lossless waveguides
; of equal characteristic impedance. If you wish to
; add more delay lines, simply add them to the following 
; equation, and replace the .25 by 2/N, where N is the 
; number of delay lines.
apj = .25 * (afilt1 + afilt2 + afilt3 + afilt4 + afilt5 + afilt6 + afilt7 + afilt8)

a1	= a1 * inlevl

adum1   delayr  1
adel1   deltapi idel1 + k1 * kpitchmod
        delayw  a1 + apj - afilt1

adum2   delayr  1
adel2   deltapi idel2 + k2 * kpitchmod
        delayw  a1 + apj - afilt2

adum3   delayr  1
adel3   deltapi idel3 + k3 * kpitchmod
        delayw  a1 + apj - afilt3

adum4   delayr  1
adel4   deltapi idel4 + k4 * kpitchmod
        delayw  a1 + apj - afilt4

adum5   delayr  1
adel5   deltapi idel5 + k5 * kpitchmod
        delayw  a1 + apj - afilt5

adum6   delayr  1
adel6   deltapi idel6 + k6 * kpitchmod
        delayw  a1 + apj - afilt6

adum7   delayr  1
adel7   deltapi idel7 + k7 * kpitchmod
        delayw  a1 + apj - afilt7

adum8   delayr  1
adel8   deltapi idel8 + k8 * kpitchmod
        delayw  a1 + apj - afilt8

; 1st order lowpass filters in feedback
; loops of delay lines.
afilt1  tone    adel1 * kgain, ktone
afilt2  tone    adel2 * kgain, ktone
afilt3  tone    adel3 * kgain, ktone
afilt4  tone    adel4 * kgain, ktone
afilt5  tone    adel5 * kgain, ktone
afilt6  tone    adel6 * kgain, ktone
afilt7  tone    adel7 * kgain, ktone
afilt8  tone    adel8 * kgain, ktone

; The outputs of the delay lines are summed
; and sent to the stereo outputs. This could
; easily be modified for a 4 or 8-channel 
; sound system.
aoutL = (afilt1 + afilt3 + afilt5 + afilt7) * ioutlevl * gksRevbamp
aoutL buthp	aoutL, klfroll
aoutR = (afilt2 + afilt4 + afilt6 + afilt8) * ioutlevl * gksRevbamp 
aoutR buthp	aoutR, klfroll

; VU meter
;kVu	maxk	aoutL, gkupdate1, 0aVu	init 0
	maxabsaccum  aVu, aoutL
kVu	downsamp aVu
aVu	= 0


	FLsetVal	gkupdate1, kVu*2, gihsRevbampD	; double VU-meter values for Reverb, just my taste

;Send to output
	zawm	aoutL * (1-gkpanRevb), 	4	; send to clean out Left (no clean amp control needed)
	zawm	aoutR * gkpanRevb, 	5	; send to clean out Right (no clean amp control needed)

endin
;****************************************************************
;****************************************************************

;****************************************************************
; dry out, stereo
;****************************************************************
	instr 499
a1	zar	4
a2	zar	5

a1	= a1 * gksMastamp
a2	= a2 * gksMastamp

a1	clip	a1, 2, 32000, 0.75
a2	clip	a2, 2, 32000, 0.75


; VU meter
;kVul	maxk	a1, gkupdate1, 0aVul	init 0
	maxabsaccum  aVul, a1
kVul	downsamp aVul
aVul	= 0

	FLsetVal	gkupdate1, kVul, gihsMLampD
;kVur	maxk	a2, gkupdate1, 0aVur	init 0
	maxabsaccum  aVur, a2
kVur	downsamp aVur
aVur	= 0

	FLsetVal	gkupdate1, kVur, gihsMRampD

outs	a1, a2
	endin
;****************************************************************
;****************************************************************

;****************************************************************
; write output soundfiles
;****************************************************************
	instr 500
a1,a2	ins

a3	zar	4
a4	zar	5

; decrease amplitude by *0.8
; and soft limit
; safety for 16 bit file writing ...
a1	clip	a1*0.6, 0, 32000, 0.9
;a2	clip	a2*0.6, 0, 32000, 0.9
a3	clip	a3*0.6, 0, 32000, 0.9
a4	clip	a4*0.6, 0, 32000, 0.9

	soundout	a1, "C:in1.wav", 4
;	soundout	a2, "C:in2.wav", 4

	soundout	a3, "mixL.wav", 4
	soundout	a4, "mixR.wav", 4

	endin
;****************************************************************
;****************************************************************

;****************************************************************
; clear zak
;****************************************************************
	instr 501
	zkcl	0,10	; clear control channels
	zacl	0,24	; clear audio channels
	endin
;****************************************************************
;****************************************************************


</CsInstruments>


<CsScore>

;audio tables
f1  0  262144  7   0   32768   0   ; bogus table, empty
f2  0  262144  7   0   32768   0   ; bogus table, empty
f3  0  262144  7   0   32768   0   ; bogus table, empty
f4  0  262144  7   0   32768   0   ; bogus table, empty
f5  0  262144  7   0   32768   0   ; bogus table, empty
f6  0  262144  7   0   32768   0   ; bogus table, empty
f7  0  262144  7   0   32768   0   ; bogus table, empty
f8  0  262144  7   0   32768   0   ; bogus table, empty
f9  0  262144  7   0   32768   0   ; bogus table, empty
f10  0  262144  7   0   32768   0   ; bogus table, empty
f11  0  262144  7   0   32768   0   ; bogus table, empty
f12  0  262144  7   0   32768   0   ; bogus table, empty
f13  0  262144  7   0   32768   0   ; bogus table, empty
f14  0  262144  7   0   32768   0   ; bogus table, empty
f15  0  262144  7   0   32768   0   ; bogus table, kept empty to clear other tables by tablecopy
; old table size: 131072


;control, pitch/amp
f21  0  262144  7   0   32768   0   ; bogus table, empty, for pitchtracker
f22  0  262144  7   0   32768   0   ; bogus table, empty, amptracking
f23  0  262144  7   0   32768   0   ; bogus table, empty, for pitchtracker
f24  0  262144  7   0   32768   0   ; bogus table, empty, amptracking
f25  0  262144  7   0   32768   0   ; bogus table, empty, for pitchtracker
f26  0  262144  7   0   32768   0   ; bogus table, empty, amptracking
f27  0  262144  7   0   32768   0   ; bogus table, empty, for pitchtracker
f28  0  262144  7   0   32768   0   ; bogus table, empty, amptracking
f29  0  262144  7   0   32768   0   ; bogus table, empty, for pitchtracker
f30  0  262144  7   0   32768   0   ; bogus table, empty, amptracking
f31  0  262144  7   0   32768   0   ; bogus table, empty, for pitchtracker
f32  0  262144  7   0   32768   0   ; bogus table, empty, amptracking
f33  0  262144  7   0   32768   0   ; bogus table, empty, for pitchtracker
f34  0  262144  7   0   32768   0   ; bogus table, empty, amptracking
f35  0  262144  7   0   32768   0   ; bogus table, empty, for pitchtracker
f36  0  262144  7   0   32768   0   ; bogus table, empty, amptracking
f37  0  262144  7   0   32768   0   ; bogus table, empty, for pitchtracker
f38  0  262144  7   0   32768   0   ; bogus table, empty, amptracking
f39  0  262144  7   0   32768   0   ; bogus table, empty, for pitchtracker
f40  0  262144  7   0   32768   0   ; bogus table, empty, amptracking
f41  0  262144  7   0   32768   0   ; bogus table, empty, for pitchtracker
f42  0  262144  7   0   32768   0   ; bogus table, empty, amptracking
f43  0  262144  7   0   32768   0   ; bogus table, empty, for pitchtracker
f44  0  262144  7   0   32768   0   ; bogus table, empty, amptracking
f45  0  262144  7   0   32768   0   ; bogus table, empty, for pitchtracker
f46  0  262144  7   0   32768   0   ; bogus table, empty, amptracking
f47  0  262144  7   0   32768   0   ; bogus table, empty, for pitchtracker
f48  0  262144  7   0   32768   0   ; bogus table, empty, amptracking



f50 0  0  1 "BD_1016.wav"  0  0  0
f51 0  0  1 "D4closed2.wav"  0  0  0

f84  0  0    1  "PadWsSeq1_C2.aif"  0  0  0
f85  0  0    1  "PadWsSeq1_C3.aif"  0  0  0
f86  0  0    1  "PadWsSeq1_C4.aif"  0  0  0
f87  0  0    1  "PadWsSeq1_C5.aif"  0  0  0
f88  0  0    1  "PadWsSeq1_C6.aif"  0  0  0
f89  0  0    1  "PadWsSeq1_C7.aif"  0  0  0

f90  0  0    1  "PadWs_E.aif"  0  0  0


;waveforms
f91 0 128    7   0   64   1   0   -1   64   0 		; saw
f92 0 128    7   0   32   1   64  -1   32   0 		; tri
f93 0 65536 10   1    		 			; sine
f94 0 128    7   0   0    1   64   1   0   -1   64   -1 ; square
f95 0 1024   7   0  4 1 196 0.9 624 -0.9 196 -1 4 0	;saw wave, supersaw

;shapes
f99 0 2048    7   0   1024   1    1024  1		; ramp up, then hold

f101 0   8192 19  .5  1  270  1		; sigmoid rise/decay shape for fof2, half cycle from bottom to top
f102 0   8192 19  1   1  270  1		; sigmoid rise/decay shape for fof2, full cycle start and end at bottom. for RAG
f103 0 8192 7 0 512 0.8 512 1 6144 1 512 0.8 512 0	; alternate table, because gen16 is buggy

;audio info tables
f110 0   64 7 0 64 0					; empty table for storing length of recorded audio segments
f111 0   64 -2 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17	; table for storing sorted indexes to f110, based on ascending length
								; f111 initialized as 1,2,3,4,5 etcetera
f112 0   64 7 0 64 0						; empty table for temp storage in sorting values from f111
f113 0   64 7 0 64 0						; empty table for clearing ftable 112
f114 0   64 7 0 64 0						; empty table for storing a copy of f110, updated after recording finished

;more shapes, control functions
;f122 0   1024 5  0.1 1024 1500		; exp shape 1 for grain freq
f122 0   1024 8  3 128 7 128 30 128 60 128 120 128 240 128 580 128 1160 128 2220 
;f123 0   128 19  .5  1  270  1		; sigmoid rise, for grain freq
f123 0    128  7  1 12 4 12 15 12 36 92 92	; tuned "by hand/ear/preference" table for grain freq

f124 0	2048 5 0.00001 2048 1	; exponential, normalized

f125 0    32768  7  1 4096 1 4096 0.8 8192 0.6 16384 0.4	; amplitude limiter table

f126 0	2048 5 0.001 2048 1	; exponential version 2, normalized

f130 0   8192 19  .5  1  270  1		; sigmoid rise, alternate table because gen16 is buggy

f132 0  32  -2  36 46 52 60 72 84 96 110

f149 0   1024  -7  0.5  512  1  512  2	; pitch bend table

f150 0     32  -2  	; step function for pitch shifting in semitone steps

;0,249999984027651637144924968445418
;0,264865758077886289209637356336585
;0,280615497137047449413538943420162
;0,29730176450485741560276115096665
;0,314980249057786202592489697562695
;0,333709951105534249335867171697835
;0,353553379299117742957550774915221
;0,374576759247719111218809912399082
;0,39685025454054215750112512810106
;0,420448200911311869866830281705846
;0,445449354326921298715908597429949
;0,471937153828198452593582541949786
0.5 					; down one octave
0.529731516155772578419274712673169 	; down 11 semotones
0.561230994274094898827077886840325 	; down 10 semitones
0.5946035290097148312055223019333 	; ...
0.62996049811557240518497939512539	
0.66741990221106849867173434339567
0.707106758598235485915101549830442
0.749153518495438222437619824798164
0.79370050908108431500225025620212
0.840896401822623739733660563411692
0.890898708653842597431817194859898
0.943874307656396905187165083899571	; down 1 semitone
1					; original pitch
1.0594631				; up 1 semitone
1.12246206026161			; up 2 semitones
1.189207133997152141591			; ...
1.2599210767267381991016397921
1.33483988970424790530864050922162
1.41421360754972056892679873068552
1.49830713271681035808894985628814
1.58740111958026332409302889048759
1.68179291109397648015990507670554
1.78179753114564871299730152827219	; up 10 semitones
1.887748735919915536983131368778	; up 11 semitones
2.00000012777879506655031300767278	; up one octave

f151 0     33  -2  	; step function for rhythmic quantizing
1
2
3
4  4
6  6
8  8  8  8
12 12 12 12
16 16 16 16 16 16 16 16
24 24 24 24 
32 32 32 32 32

f180 0 32  -2 	0.0625 0.125 0.25 0.5 1 			; table for drumloop playback frequency ratios (1/4, 1/2, normal, x2, x4)
f181 0 32  -2 	0.5 1 2 4		     			; table for phrase tempo factor
f182 0 32  -2 	2 4 8 16		     			; table for delaytime subdiv factor
f183 0 32  -2 	1 1.333 1.5		     			; table for delaytime note value factor
f184 0 32  -2 	0.5 1 2 3 4 5 6 7 8	     			; table for delaytime factor
f185 0 32  -2 	0.25 0.5 1 2 4		     			; table for freq multiply factor
f186 0 32  -2   21 21 23 25 27 29 31 33 35 37 39 41 43 45 47	; pitch tracker slot selection
f198 0 128 7  1 128 0						; tempest masking table, for taptempo

;ftables 200 -> 299 sets time signature
;contains delta times and amplitudes in the following format:
;part_index  numbeats time amp  
;part_index is not used in any instr, just for reference
f201 0 32  -2   
1   4	1  1.00
2   4	1  0.20
3   4	1  0.50
4   4	1  0.25

f202 0 32  -2   
1   5 	1  1.00
2   5 	1  0.30
3   5 	1  0.60
4   5 	1  1.00
5   5 	1  0.50

f203 0 32  -2   
1   3 	1  1.00
2   3 	1  0.20
3   3 	1  0.50

f204 0 32  -2   
1   3	0.5  1.00
2   3	0.5  0.20
3   3	0.5  0.50

f205 0 32  -2   
1   5	0.5  1.00
2   5	0.5  0.20
3   5	0.5  1.00
4   5	0.5  0.50
5   5	0.5  0.10

f206 0 32  -2   
1   7	0.5  1.00
2   7	0.5  0.20
3   7	0.5  0.50
4   7	0.5  0.20
5   7	0.5  1.00
6   7	0.5  0.20
7   7	0.5  0.40

f207 0 32  -2   
1   3	0.25  1.00
2   3	0.25  0.20
3   3	0.25  0.50

f208 0 32  -2   
1   5	0.25  1.00
2   5	0.25  0.20
3   5	0.25  0.90
4   5	0.25  0.40
5   5	0.25  0.30



; *******************
;drumloops
; *******************
f250  0  0  -1 "improsculpt_set1_1.wav"  0  0  0	; bogus

f251  0  0  -1 "improsculpt_set1_1.wav"  0  0  0
f252  0  0  -1 "improsculpt_set1_2.wav"  0  0  0
f253  0  0  -1 "improsculpt_set1_3.wav"  0  0  0
f254  0  0  -1 "improsculpt_set1_4.wav"  0  0  0
; continue loading more drumloop samples here if needed (f255 ....)

;ftables 300 -> 307 contains rythmic phrases
;delta times and amplitudes in the following format:
;part_index  num_events time  amp  endflag
;endflag should be set to 1 at end of each phrase
;part_index is not used in any instr, just for reference

;rytmikk
; pause definert som (- duration)
; 4th 	= 1
; 8th 	= 2
; 16th 	= 4
; 32nd	= 8
; 8th3	= 3
; 16th3 = 6
; d32nd	= [8/3]
; d16th = [4/3]
; d8th	= [2/3]

; rhythms transcribed from cageish
; padded or cut so as to fill whole n/4 measures
; rhythms "rounded off" as to avoid to many abrupt offbeat hits

f301 0 128 -2 
1   13  4	1.00	0
2   13  -4	1.00	0
3   13  -4 	1.00	0
4   13  4 	1.00	0
5   13  -[4/3]	1.00	0
6   13  4	1.00	0
7   13  -2	1.00	0
8   13  4 	1.00	0
9   13  -4	1.00	0
0   13  -1	1.00	0
11  13  4	1.00	0
12  13  -[4/3] 	1.00	0
13  13  -1	1.00	1

f302 0 128 -2
1   11  4	1.00	0	
2   11  -1	1.00	0
3   11  -4	1.00	0
4   11  4	1.00	0
5   11  -4	1.00	0
6   11  -1	1.00	0
7   11  4	1.00	0
8   11  -[4/3]  1.00	0
9   11  -1	1.00	0
10  11  [2/3]	1.00	0
11  11  -2	1.00	1

f303 0 128 -2
1   9  4	1.00	0
2   9  -[4/3]	1.00	0
3   9  4	1.00	0
4   9  -[4/3] 	1.00	0
5   9  -1	1.00	0
6   9  1	1.00	0
7   9  -1	1.00	0
8   9  1	1.00	0
9   9  -1	1.00	1

f304 0 128 -2
1   17  4	1.00	0
2   17  -[4/3]	1.00	0
3   17  4	1.00	0
4   17  -[4/3] 	1.00	0
5   17  -2	1.00	0
6   17  4	1.00	0
7   17  -2	1.00	0
8   17  4 	1.00	0
9   17  -2	1.00	0
10  17  4 	1.00	0
11  17  -[4/3]	1.00	0
12  17  -2 	1.00	0
13  17  1	1.00	0
14  17  -2	1.00	0
15  17  4	1.00	0
16  17  -[4/3]	1.00	0
17  17  -1	1.00	1

f305 0 128 -2 
1   15  4	1.00	0
2   15  -4	1.00	0
3   15  4	1.00	0
4   15  -4 	1.00	0
5   15  -1	1.00	0
6   15  [2/3]	1.00	0
7   15  -1	1.00	0
8   15  4 	1.00	0
9   15  -4 	1.00	0
10  15  -1	1.00	0
11  15  1	1.00	0
12  15  -2	1.00	0
13  15  4	1.00	0
14  15  -4	1.00	0
15  15  -1	1.00	1
 
f306 0 128 -2 
1   6  1	1.00	0
2   6  -1	1.00	0
3   6  4	1.00	0
4   6  -2	1.00	0
5   6  4	1.00	0
6   6  -1	1.00	1

f307 0 128 -2 
1   15  [2/3]	1.00	0
2   15  -2	1.00	0
3   15  4	1.00	0
4   15  -[4/3] 	1.00	0
5   15  4	1.00	0
6   15  -4	1.00	0
7   15  4	1.00	0
8   15  -4 	1.00	0
9   15  -2	1.00	0
10  15  4	1.00	0
11  15  -4	1.00	0
12  15  -2 	1.00	0
13  15  1	1.00	0
14  15  -2	1.00	0
15  15  -1	1.00	1

; DualTheme tables
f330  0 32   -2 0	; empty
f331  0 32   -2
8.00 8.03 8.05 7.10
7.07 7.10 8.00 8.05
8.07 8.03 8.05 8.09
8.10 9.00 9.03 9.02
8.10 9.00 8.05 8.10
8.02 8.03 7.07 7.05
7.03 7.05 8.03 8.02
8.03 8.10 8.09 8.07

f338  0  8192  7   0 6144 0.3 2048 1			; mod index
f339  0  8192  7   0 2048 0.6 6144 1			; volume


f340  0  4   -2   8 4 2 1				; octaviation table
;f11  0  16  -2   1 2 3 4 5 6 7 8 10 13 16 24 32 64 92 128			; tempo factor table
f341  0  8  -2   1 3 4 8 12 16 32 92 			; tempo factor table

;WYL Noises tables
f351  0  0  1  "Pad_gap1.aif"  0  0  0
f352  0  0  1  "Pad_gap2.aif"  0  0  0
f353  0  65536  1  "Industry1_GrainImpro.aif"  0  0  0
f354  0  262144  1  "Planet2.aif"  0  0  0
f355  0  0  1  "Planet1.aif"  0  0  0
f356  0  0  1  "Planet2.aif"  0  0  0
f360 0 4096 19  .5  1  270  1	; rising sigmoid, for panning


; *******************

f501  0 16  2  1		; bogus ftable, force loading more than 309 ftables .... hack

; *******************

i1   0 60000
;i4   0 60000

i5   4 60000	; metro for update of VU meters etc.
i14  0 60000	; midi control for Grain1
i12  0 60000	; midi faderbox processing

i260  0 60000
i306  0 60000	; control instr, testing if instr 304 is active
i310  0 60000	; Rplay1 event generator, initiate instr 311 events
i312  0 60000	; filtering and throughput/output of signal from instr 311
i313  0 60000	; Rplay2 event generator, initiate instr 314 events
i315  0 60000	; filtering and throughput/output of signal from instr 314


i401  0 60000
i491  0 60000
i492  0 60000
i493  0 60000
i494  0 60000
i495  0 60000
i496  0 60000
i497  0 60000
i498  0 60000

i499  0 60000
;i500 0 60000	; output audio files
i501 0 60000	; clear zak

; test tones
;i360 4 1 9.04
;i360 7 1 9.06
;i360 9 1 9.07


;i273 0 0.2	; load snapshots from disk
;i271 1 0.5	; recall preset no 1
e

</CsScore>

</CsoundSynthesizer>
