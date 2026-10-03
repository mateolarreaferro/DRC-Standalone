<CsoundSynthesizer>
<CsOptions>
--limiter=0.9
</CsOptions>
<CsInstruments>


;orchestra ---------------

  sr      =           44100
  kr      =            441
  ksmps   =              100
  nchnls  =               1

          instr 01                     ;example of a guiro
  a1      guiro       p4, 0.01
          out         a1
          endin

          instr 02                     ;example of a tambourine
  a1      tambourine  p4, 0.01
          out         a1
          endin

          instr 03                     ;example of bamboo
  a1      bamboo      p4, 0.01
          out         a1
          endin

          instr 04                     ;example of a water drip
  a1      line        5, p3, 5         ;preset an amplitude boost
  a2      dripwater   p4, 0.01, 0, .9  ;dripwater needs a little amplitude help at these values
  a3      product     a1, a2           ;increase amplitude
          out         a3
          endin

          instr 05                     ;an example of sleighbells
  a1      sleighbells p4, 0.01
          out         a1
          endin
</CsInstruments>
<CsScore>
;score -------------------

   i1 0 1 20000
   i2 2 1 20000
   i3 4 1 20000
   i4 6 1 20000
   i5 8 1 20000
</CsScore>

</CsoundSynthesizer>
<MacOptions>
Version: 3
Render: File
Ask: Yes
Functions: Window
Listing: Window
WindowBounds: 29 50 951 782
CurrentView: orc
IOViewEdit: On
Options: -b128 -A -s -m167 -R 
</MacOptions>
<MacGUI>
ioView nobackground {65535, 65535, 65535}
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
