<CsoundSynthesizer>
<CsOptions>
--limiter=0.9
</CsOptions>
<CsInstruments>
sr=44100
kr=441
ksmps=100
nchnls=2

	instr 1	;untitled
ipch1 = p4
ipch2 = p5

iamp  = ampdb(68)
kpch 	linseg ipch1, 13, ipch1, 3, ipch2, p3 - 16, ipch2
kjit	jitter 30, 1, 3
kjitAdjust linseg 1, 11, 0, 1, 0
kjit = kjit * kjitAdjust
kpch = kpch + kjit
kamp	linseg 0, 13, .5, 3, 1, p3 - 20, 1, 4, 0
aout	vco2	1, kpch, 4, 0.95
aout	moogvcf	aout, 10000, 0.1
aout 	= aout * iamp * kamp
outs	aout, aout
	endin

</CsInstruments>
<CsScore>

i1	0.0	24	242.123632	154.717337	
i1	0.0	24	388.549784	151.822915	
i1	0.0	24	216.403754	302.895552	
i1	0.0	24	295.778015	604.147337	
i1	0.0	24	335.026763	304.845763	
i1	0.0	24	281.487874	154.978345	
i1	0.0	24	335.942032	153.791617	
i1	0.0	24	226.934174	301.752344	
i1	0.0	24	378.336862	152.036373	
i1	0.0	24	291.885806	603.636450	
i1	0.0	24	363.968490	300.789268	
i1	0.0	24	232.261404	152.623117	
i1	0.0	24	248.091672	301.957560	
i1	0.0	24	222.733215	150.588412	
i1	0.0	24	392.451897	303.456524	
i1	0.0	24	351.061276	302.576620	
i1	0.0	24	256.316071	602.694086	
i1	0.0	24	251.832031	154.105900	
i1	0.0	24	266.233030	301.967995	
i1	0.0	24	334.284821	151.193947	
i1	0.0	24	335.962437	603.125565	
i1	0.0	24	256.082340	151.669756	
i1	0.0	24	381.245917	153.183438	
i1	0.0	24	352.979642	304.568759	
i1	0.0	24	343.574373	152.269498	
i1	0.0	24	367.537508	304.809161	
i1	0.0	24	240.386441	151.680442	
i1	0.0	24	203.584975	601.311741	
i1	0.0	24	396.644814	600.977800	
i1	0.0	24	256.140783	151.566829	
e

</CsScore>

</CsoundSynthesizer>
<MacOptions>
Version: 3
Render: File
Ask: Yes
Functions: Window
Listing: Window
WindowBounds: 181 140 1305 877
CurrentView: orc
IOViewEdit: Off
Options: -b128 -A -s -m167 -R --midi-velocity-amp=4 --midi-key-cps=5 
</MacOptions>
<MacGUI>
ioView nobackground {65535, 65535, 65535}
</MacGUI>
