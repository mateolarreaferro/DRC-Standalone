<CsoundSynthesizer>
<CsOptions>
; XO
;-+rtmidi=alsa  --midi-device=hw:1,0 -+rtaudio=alsa -odac -r16000 -k160 ;-O stdout
; Mac
-odac -+rtmidi=PortMIDI -M1 -r44100 -k441
--limiter=0.9
</CsOptions>
<CsInstruments>

massign 	1,100
ctrlinit  1, 7,110, 73,0, 72,1, 74,126, 71,126, 5,104

;===============;
; {_ORCHESTRA_} ;
;===============; 

;===============================================================================================
	instr 100
	
icps	  	cpsmidib	12
iamp	  	ampmidi	10000
kvol		midic7	7, 0, 1
kcps      midic7	73, 0, 10000
kdens     midic7	72, .01, 1000
kampoff  	midic7	74, .01, 20000
kptchoff  midic7	71, .01, 10000
kgdur     midic7	5, .001, .6
a1        grain	iamp, icps+kcps, kdens, kampoff, kptchoff, kgdur,  1,  3, .1
a2        linenr	a1*kvol, .01, 2, .01
         	out		a2

endin

;===============================================================================================

</CsInstruments>
<CsScore>

;===========;
; {_SCORE_} ;
;===========; 

;=======================================
f0  60
f1  0   4096   10   1    	; GEN10
f3  0   4097   20   2  1		; GEN20
;=======================================

</CsScore>
</CsoundSynthesizer>

<MacGUI>
ioView nobackground {59367, 11822, 65535}
ioSlider {5, 5} {20, 100} 0.000000 1.000000 0.000000 slider1
</MacGUI>
<bsbPanel>
 <label>Widgets</label>
 <objectName/>
 <x>0</x>
 <y>465</y>
 <width>30</width>
 <height>105</height>
 <visible>true</visible>
 <uuid/>
 <bgcolor mode="nobackground">
  <r>231</r>
  <g>46</g>
  <b>255</b>
 </bgcolor>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>slider1</objectName>
  <x>5</x>
  <y>5</y>
  <width>20</width>
  <height>100</height>
  <uuid>{d6077e69-bf94-4658-bf5b-7cbbfadebbbd}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <description/>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.00000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
</bsbPanel>
<bsbPresets>
</bsbPresets>
