<CsoundSynthesizer>
<CsOptions>

; XO
;-+rtmidi=alsa  --midi-device=hw:1,0 -+rtaudio=alsa -odac -r16000 -k160 ;-O stdout
; Mac
-odac -r44100 -k441

</CsOptions>
<CsInstruments>

gi_time_beat  =  60 / 137  ;; Remeber to set according to t statement

;===============;
; {_ORCHESTRA_} ;
;===============; 

;=========================================================================================================================================================

	instr 2    ; bass drum

i_time_release               	=   		0.03
i_osc_frq_start              	=   		261
i_osc_frq_end                	=   		49  
i_noise_bandpass_frq_start   	=   		7040
i_noise_bandpass_frq_end     	=   		7040
i_noise_lowpass__frq_start   	=   		3520
i_noise_lowpass__frq_end     	=   		55 
i_time_extended              	=  		i_time_release + 0.01  ; extend note duration
  
p3  						=  		p3 + i_time_extended
 
iamp 		 			=  		0.0039 + p4 * p4 / 16192  ; velocity -> amplitude

aenv1  					linseg 	1, p3 - i_time_extended, 1, i_time_release, 0, 1, 0
; aenv1  					expseg 	1, p3 - i_time_extended, 1, i_time_release, 0.00001, 1, 0.000001
aenv1  					=  		aenv1 * aenv1


; [Noise Generator]
a_noise                  rnd31 	13100, 0,                  0
k_noise_filter_line      expon 	1    , gi_time_beat * 0.08, 0.5
k_nsbp  				=  		i_noise_bandpass_frq_end   + (i_noise_bandpass_frq_start - i_noise_bandpass_frq_end) * k_noise_filter_line
k_nslp  				=  		i_noise_lowpass__frq_end   + (i_noise_lowpass__frq_start - i_noise_lowpass__frq_end) * k_noise_filter_line
a_noise  				butterbp 	a_noise, k_nsbp, k_nsbp*2; k_nsbp * insbw

; [Noise Lowpass]
a_noise  				pareq 	a_noise, k_nslp, 0, 0.7071, 2

; [Noise Amp. Envelope, See Shaping an Envelope with Linseg and Expon]
a_noise_amp_1  		linseg 	0, 0.01, 1, 1, 1
a_noise_amp_2  		expon  	1, gi_time_beat * 0.3333, 0.5   ; Noise amp decreases 50% after 0.333 "Beat Units"
a_noise  				=  		a_noise * a_noise_amp_1 * a_noise_amp_2

; [Oscillator]
k_frq_osc 			expon 	i_osc_frq_start-i_osc_frq_end, gi_time_beat* 0.07, 0.5*i_osc_frq_start - i_osc_frq_end
k_frq_osc 			= 		k_frq_osc + i_osc_frq_end

a1  					phasor 	k_frq_osc
a2  					phasor 	k_frq_osc, 0.5
a1  					=  		32768 * (a2 - a1)
a2  					=  		a1        ; a1 = a2 = osc. signal

; [Filters]
a1  					butterhp 	a1, 0.0625 * k_frq_osc  ; highpass 1
a1  					butterbp 	a1, k_frq_osc, 0.5 * k_frq_osc  ; bandpass 1

k_apf  				expon 	1, gi_time_beat * 0.125, 0.5     ; "allpass" 1
k_apf  				=  		(1 + (0.5 - 1) * k_apf) * k_frq_osc
atmp  				tone 	a1, k_apf
a1  					=  		2 * atmp - a1

a3  					butterhp 	a2, 8 * i_osc_frq_end  ; highpass 2
a2  					butterhp 	a2 - a3 * 2, 0.5 * i_osc_frq_end  ; highpass 3
a1  					=  		a1 - 0.4 * a2
a1  					pareq 	a1, 1.5 * i_osc_frq_end, 0, 2, 1  ; output highpass

k1  					expon 	1, gi_time_beat * 0.01, 0.5	; output lowpass
k2  					expon 	1, gi_time_beat * 0.1,  0.5
kfrx  				limit 	(k1 * 40 + k2 * 8) * k_frq_osc, 10, sr * 0.48
a1  					pareq 	a1, kfrx, 0, 0.7071, 2
					out 		(a1 + a_noise) * iamp * aenv1
					
endin

;=========================================================================================================================================================

</CsInstruments>
<CsScore>

;===========;
; {_SCORE_} ;
;===========; 

0 137
;==============
i2  0 0.400 90
i2  1 0.400 80
i2  2 0.400 90
i2  3 0.400 80
i2  4 0.400 90
i2  5 0.400 80
i2  6 0.400 90
i2  7 0.400 80
i2  8 0.400 90
i2  9 0.400 80
i2 10 0.400 90
i2 11 0.400 80
i2 12 0.400 90
i2 13 0.400 80
i2 14 0.400 90
i2 15 0.400 80

</CsScore>
</CsoundSynthesizer>

;_Notes_

;rene.nyffenegger@adp-gmbh.ch
