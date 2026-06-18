<CsoundSynthesizer>
<CsOptions>
</CsOptions>
<CsInstruments>

; AN UNSUCCESFUL ATTEMPT AT IMPLEMENTING FEEDBACK FM, BY SEAN COSTELLO.
; (UNSUCCESSFUL IN THE SENSE OF NOT DOING WHAT I INTENDED IT TO DO.  IT STILL SOUNDS PRETTY COOL TO ME.)

sr        =         44100
kr        =         4410
ksmps     =         10
nchnls    =         1

          instr     1

aosc1     init      0
idur1     =         p3                  ; OVERALL DURATION OF NOTE
ifreq1    =         p4                  ; MAIN FREQUENCY
iamp1     =         p5 * 4000           ; OVERALL AMPLITUDE OF NOTE
iattack1  =         p6        

; ATTACK OF AD-STYLE ENVELOPE FOR OVERALL AMPLITUDE.   

iamp2     =         p7                  ; FEEDBACK FM INDEX
iattack2  =         p8        

; ATTACK OF AD-STYLE ENVELOPE FOR FEEDBACK AMPLITUDE.

; KAMP1 CONTROLS OVERALL AMPLITUDE OF NOTE
kamp1     linseg    .0001, iattack1, iamp1, (idur1 - iattack1), .0001

; KAMP2 CONTROLS AMPLITUDE OF FEEDBACK
kamp2     linseg    .0001, iattack2, iamp2, (idur1 - iattack2), .0001

; I DIVIDED IAMP2 BY 10, JUST TO GET THE FEEDBACK IN A USEABLE RANGE.
aosc1     oscili    kamp1, ifreq1 + (aosc1 * iamp2/10), 1

          out       aosc1*6
          endin

</CsInstruments>
<CsScore>
; FEEDBACK FM.SCO BY SEAN COSTELLO
; A3 AT DIFFERENT FM INDEX LEVELS.

f1 0 16384 10 1

i1 0 5 220 1 2 .2 2
i1 5 5 220 1 2 .7 2
i1 10 5 220 1 2 1.2 2
i1 15 5 220 1 2 4 2
i1 20 5 220 1 2 10 2
</CsScore>
</CsoundSynthesizer>
