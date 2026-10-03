; Handpan version 1
; A handpan instrument for Csound. This is designed for live usage with MIDI
; input. See below to select your audio and MIDI I/O and choose a scale.
; Author: Jeanette C.
<CsoundSynthesizer>
<CsOptions>
; Choose your realtime audio module. Remove the semicolon from the beginning
; of the correct line (ONLY from the beginning!!!)
;-+rtaudio=PortAudio ; All platforms
-+rtaudio=alsa ; Linux: ALSA (Advanced Linux Sound Architecture)
;-+rtaudio=jack ; Linux JACK Audio Connection Kit
;-+rtaudio=mme ; Windows MultiMedia Extension (the Windows standard?)
;-+rtaudio=CoreAudio ; Mac OS standard

; Choose your realtime MIDI module. Rem ove the semicolon from the beginning
; of the correct line
;-+rtmidi=PortMIDI ; All platforms
;-+rtmidi=alsa ; Linux (Advanced Linux Sound Architecture)
-+rtmidi=alsaseq ; Linux (ALSA sequencer)
;-+rtmidi=cmidi ; Mac OS (CoreMidi?)
;-+rtmidi=mme ; Windows MultiMedia Extension
;-+rtmidi=winmm ; Windows

; MIDI input
; You can choose one specific MIDI input, for most rtMIDI drivers this is a
; single number. For alsa this is something like
; hw:0
; Use amidi -l to show alsa port.
; Use aconnect -li to list alsaseq input ports
-Ma ; receive input from all MIDI devices

; Leave these options and go down to sr and nchnls
-o dac -d --messagelevel=2
</CsOptions>
; ==============================================
<CsInstruments>
; sr sets the samplerate, usually either 44100 or 48000Hz.
sr	=	48000
ksmps	=	1
nchnls	=	2 ; This instrument needs 2 channels, i.e. stereo output
0dbfs	=	1

; Ftable holding the MIDI notes for the handpan
; 10 is the number of notes (needs to be written as -10 for every number not
; a power-of-two), -2 is the table generator that reads values from the line
; The next numbers are MIDI note numbers
; La sierna (E dorian)
;giNotes = ftgen(0, 0, -10, -2, 52, 54, 55, 59, 61, 62, 64, 66, 67, 71)

giNotes = ftgen(0, 0, -10, -2, 47, 54, 55, 57, 59, 61, 62, 64, 66, 69)

; Reverse lookup table
giLookup[] init 128

; MIDI assignments
massign 1, "Strike"
massign 2, -1
massign 3, -1
massign 4, -1
massign 5, -1
massign 6, -1

; Finger strike, the impulse to excite the pan, MIDI operated
; p4 = MIDI note, p5 = MIDI velocity
instr Strike
	; Basic initialisation from MIDI parameters
	iNote = notnum()
	iFreq init cpsmidi()
	iVel = veloc(0, 1)
	iModWheel = midic7(1, 0, 2)
	iMode = int(iModWheel) ; the kind of strike
	iIndex = giLookup[iNote] - 1
	SstrikeChannel = sprintf("Strike.%d", iIndex)
	aStrike init 0 ; Audio output

	if (iMode < 1) then ; normal strike
		; Strike impulse parameters derive from velocity and frequency
		iAtt = linlin:i(iVel, .0001, .005)
		iDecay = linlin:i(iVel, .01, .03) ; amp envelope decay
		p3 = iAtt + iDecay
		iClickVol = linlin:i(iVel, .1, .5) ; overall volume
		iNoise = linlin:i(iVel, .1, .7) ; noise mix volume
		iTone = linlin:i(iVel, 1, .4) ; tonal mix volume
		iToneDiff = linlin:i(iVel, 1.1, 1.5) ; envelope amount of frequency mod
		iLpFreq = linlin:i(iVel, 2000, 10000) ; overall lowpass filter cutoff
		kEnv = linseg(0, iAtt, 1, iDecay, 0, (p3 - .04), 0) ; basic envelope shape
		kNoiseEnv = kEnv * .05 * iNoise ; noise amp envelope
		kToneEnv = kEnv * .015 * iTone ; tonal amp envelope
		kFreqEnv = linseg(iToneDiff, .02, 1, (p3 - .02), 1) ; frequency mod envelope

		; Noise and tonal component
		aNoise = butterhp(noise(kNoiseEnv, 0), iLpFreq*.13)
		aTone = oscil(kToneEnv, (iFreq * kFreqEnv), -1)
		aStrike = butterlp((aNoise + aTone)*iClickVol, iLpFreq)
	else ; a kind of knock
		iVol = linlin:i(iVel, .003, .007)
		iDecay = linlin:i(iVel, .01, .02)
		iModAmount = linlin:i(iVel, 1.1, 1.8)
		p3 = iDecay
		kAmpEnv = linseg(1, iDecay, 0, (p3 - iDecay), 0)
		kFreqEnv = linseg(iModAmount, .01, 1, (p3 - .01), 1)
		aNoise = butterlp(noise((kAmpEnv * iVol), 0), 1000)
		aTone = oscil((kAmpEnv * iVol), (iFreq * kFreqEnv), -1)
		aStrike = aNoise + aTone
	endif

	; Mix the output to the dedicated and global strike channels
	if (giLookup[iNote] != 0) then
		chnmix(aStrike, SstrikeChannel)
		chnset(aStrike, "Strike.Global")
	else
		chnset(aStrike*10, "Strike.Global")
	endif
endin

; Instrument simulating one tine
; p4 = iFundamentalFrequency, p5 = iPan, p6 = iTineIndex
instr Tine
	; Initialise basic parameters from p-fileds
	iFreq init p4
	iPan init p5
	iTineIndex init p6

	; Get the relevant strike input
	SstrikeChannel = sprintf("Strike.%d", iTineIndex)
	chn_a(SstrikeChannel, 3)
	aStrike = chnget:a(SstrikeChannel)

	; Modal filters modelling the tines
	aFundamental = mode(aStrike, iFreq, iFreq*2)
	aBeat = mode(aStrike*.3, iFreq*1.992, iFreq*6)
	aHarmonic = mode(aStrike, iFreq*2, iFreq*12)
	aReso = butterlp(wguide1((aStrike * 2), iFreq, (sr/2 - 500), .999), iFreq*3)
	aHi = butterlp(wguide1(aStrike*2, iFreq*2, (sr / 2 - 500), .999), iFreq*2)
	aTine = (aFundamental + aHarmonic + aReso + aBeat + aHi)

	; Audio output
	aOutL, aOutR pan2 aTine, iPan
	outs(aOutL, aOutR)

	; Clear the strike channel
	chnclear(SstrikeChannel)
endin

; Global resonator for one frequency
; p4 = iFreq, p5 = iPan
instr Resonator
	iFreq init p4
	iPan init p5

	; Create the global strike channel and read audio from it
	chn_a("Strike.Global", 3)
	aStrike = chnget:a("Strike.Global")

	; Excite the modal filter for this frequency
	aTone1 = mode((aStrike * .007), iFreq*5, iFreq*2)
	aTone2 = wguide1(aStrike*.8, iFreq*4.003, (sr / 2 - 500), .99)
	aTone3 = wguide1((aStrike * .5), iFreq*2, (sr / 2 - 500), .999)
	aResonator = butterlp(butterhp((aTone1 + aTone2 + aTone3), iFreq*3), iFreq*4)

	; Pand and output the audio, then clear the strike channel
	aOutL, aOutR pan2 aResonator*.4, iPan
	outs(aOutL, aOutR)
endin

; Setup instrument
instr Setup
	; Set up basic parameters
	iTotalNotes = ftlen(giNotes)

	; Create the reverse lookup table and start all tines and resonators
	iPanStep init (2 * $M_PI) / (iTotalNotes - 1)
	iPanOffset init iPanStep / 2
	iTine = nstrnum("Tine")
	iResonator = nstrnum("Resonator")
	iIndex init 0
	while (iIndex < iTotalNotes) do
		iNote = tab_i(iIndex, giNotes, 0)
		iFreq = cpsmidinn(iNote)
		giLookup[iNote] = iIndex + 1 ; so we can easily compare to 0 for blanks
		if (iIndex == 0) then
			iPan = .5
		else
			if ((iIndex % 2) == 1) then
				iPan = .5 + sin(iPanOffset)
			else
				iPan = .5 - sin(iPanOffset)
				iPanOffset += iPanStep
			endif
		endif
		
		; Start tine and resonator for this note
		schedule((iTine + (iIndex * .01)), 0, -1, iFreq, iPan, iIndex)
		schedule((iResonator + (iIndex * .01)), 0, -1, iFreq, iPan)
		iIndex += 1
	od
	turnoff
endin

</CsInstruments>
; ==============================================
<CsScore>
f0 z
i"Setup" 0 .1
e
</CsScore>
</CsoundSynthesizer>
