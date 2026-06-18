The Csound Blog
by     Jacob Joaquin
email  jacobjoaquin@gmail.com
web    www.thumbuki.com/csound/blog

(C)2007 Jacob Joaquin
Licensed under Creative Commons (see below)




2007.05.02
Drum Sequencer Event Generator


Getting lost within a list of instrument events is sometimes less
desirable than being able to place events on a grid or lattice. This
is especially true when working with rhythms. I'm a firm believer
that the interface influences the compositional process. This is why
I've begun development on dseq, an instrument that allows me to input
drum patterns in a manner that is much more user-friendly.

I originally prototyped dseq as a Perl subroutine. I used this
subroutine to generate the drums in the blog entry "Adding Zak to the
Mix"[1]. Recently, I've been spending time exploring the string
capabilities of Csound. Even though Csound strings aren't yet fully
mature, they are still mighty powerful in their current state. I had
some spare time on my hands while I was in San Francisco this past
weekend, so I spent two hours making a version in Csound.

The dseq instrument is a work in progress that allows a user to enter
drum patterns into a horizontal grid, using a string of text. The
instrument then parses the patterns and generates i-events. The
syntax I've chosen is influenced by my personal experiences with
Triton's Fast Tracker II[2], Max V. Mathew's Radio Baton Conductor
program[3], and graphical MIDI editors such as the one found in
Ableton Live[4].

The dseq instrument reads a pattern from left to right and recognizes
four different types of data: event, rest, white space and rhythm
directive.

An event is generated when the string pattern parser matches a digit
or a character between a and f. These characters correspond to the
range of hexadecimal numbers between 0x0 and 0xF. The hexadecimal
value is translated into a decimal value between 0 and 1, placed into
p-field 4, and is generally used to control dynamics of the generated
event.

A rest is denoted by a period. A period does not trigger a note
event, but it does act as a spacer between events.

White space allows users to align the text of a pattern to make the
rhythms easier to read. They do not trigger any note events, nor do
they act as a rest. White space is also required before and after a
rhythm directive is used.

A rhythm directive changes the rhythmic resolution for the the
proceeding events and rests. The default resolution is a sixteenth
note. The r directive can be used at any point in a pattern, allowing
any combination of resolutions. The directive comes in three
different flavors: r#, r#t and r#d#.



r#    The # is an integer that represents the division of a whole
note. An r4 indicates a quarter note.

r#t   The t indicates that the resolution will be a triplet. An r8t
indicates a resolution of an eighth note triplet.

r#d#  This version allows for irregular rhythms. The d# represents
another division of the resolution. An r4d3 is a quarter note divided
by three, which is the same as an eighth note triplet. An r4d7
divides a quarter note into seven equal rhythmic parts, known as a
septuplet.



The following figure lists examples of r directives and their
translated resolutions.



	r1   = whole note
	r2   = half note
	r4   = quarter note
	r8   = eigth note
	r6   = eight note triplet
	r8t  = eigth note triplet
	r4d3 = quarter note divided by three, the same as an eigth note triplet
	r4d7 = quarter note divided by 7, or eighth note septuplet.

	
	
I plan on implementing the ability to add swing to a pattern. It
would be nice to allow a user to specify a range of values for the
dynamics, rather than just have it spit out a value between 0 and 1.
And the name dseq is likely to change.

The long term goal is to incorporate this into Csound as a permanent
opcode, though not until the design of dseq has been thoroughly
tested and used in real-world situations. If you have any
suggestions, please send me an email, and I'll take them into serious
consideration.



Until next time,

Jake






Permalink

http://www.thumbuki.com/20070502/drum-sequencer-event-generator.html






References

[1]  The Csound Blog - Adding Zak to the Mix
     http://www.thumbuki.com/csound/files/thumbuki20070410.csd

[2]  Fasttracker II @ Wikipedia.org
     http://en.wikipedia.org/wiki/Fast_Tracker

[3]  Mathews, Max V. Radio Baton Conductor Program. 2000. 
     http://csounds.com/mathews/manuals/ConductorManual.pdf

[4]  Ableton Live
     http://www.ableton.com/live

	
	
	
	
	
License

(cc) Creative Commons Attribution-ShareAlike 2.5
	 
	You are free:
	
		* to Share -- to copy, distribute, display, and perform the work
		* to Remix -- to make derivative works
		

	Under the following conditions:

		* Attribution. You must attribute the work in the manner specified by
		  the author or licensor.
		  
		* Share Alike. If you alter, transform, or build upon this work, you
		  may distribute the resulting work only under a license identical to
		  this one.
		
		
	* For any reuse or distribution, you must make clear to others the license
	  terms of this work.

	* Any of these conditions can be waived if you get permission from the
	  copyright holder.

	  
	http://creativecommons.org/licenses/by-sa/2.5/

	
	
	
	
	
<CsoundSynthesizer>
<CsInstruments>
sr     = 44100
kr     = 4410
ksmps  = 10
nchnls = 1



; ---- Instrument Definitions ----

#define dseq   # 1 #    ; dseq drum pattern event generator
#define kick   # 2 #    ; Kick Drum
#define snare  # 3 #    ; Snare Drum
#define hihat  # 4 #    ; Hihat






; ---- dseq drum pattern event generator ----

instr $dseq
	itempo      =      p3         ; You should set p3 to 1 in the score.
	iinstr      =      p4         ; The instrument to generate events for.
	Spattern    strget p5         ; A drum pattern string.
	ilength     strlen Spattern   ; Length of the pattern.
	iSindex     =      0          ; Points to the current string index.
	itime       =      0          ; Position in time, relative to the pattern.
	iresolution =      1 / 16 * 4 ; Defaults to a sixteenth note.

	
	
	Spattern strlower Spattern	  ; Converts all letters to lower case.


	
	begin:
	
		Schar strsub Spattern, iSindex, iSindex + 1
	
		
		icompare strcmp Schar, "."
		if( icompare == 0 ) igoto stringdot
	
		
		icompare strcmp Schar, " "
		if( icompare == 0 ) igoto stringspace
	
		
		ic_0 strchar "0"
		ic_9 strchar "9"
		ic_a strchar "a"
		ic_f strchar "f"
		ic_x strchar Schar
	
		if( ( ic_x >= ic_0 && ic_x <= ic_9 ) || ( ic_x >= ic_a && ic_x <= ic_f ) ) igoto stringx
	
		
		icompare strcmp Schar, "r"
		if( icompare == 0 ) igoto stringr
		
		
		igoto advanceSindex
		
		
	
			
	stringdot:
	
		itime = itime + iresolution

	
		igoto advanceSindex
	
	
	
		
	stringspace:
	
		igoto advanceSindex
	
		
			
			
	stringx:
	
		Svalue strcpy "0x0"
		Svalue strcat Svalue, Schar
		ivalue strtol Svalue
	
		ivalue = ivalue / 15
	
		schedule iinstr, itime * itempo, 1, ivalue			
	
		itime = itime + iresolution

		
		igoto advanceSindex
	
		
		
		
	stringr:		
		
		Ssub_r strcpy ""
	
	
	
		
	get_r:
	
		iSindex  =      iSindex + 1
		Schar    strsub Spattern, iSindex, iSindex + 1
	
		
		icompare strcmp Schar, " "
		if( icompare == 0 ) igoto continue_r
	
		
		icompare strcmp Schar, "t"
		if( icompare == 0 ) igoto continue_t
	
		
		icompare strcmp Schar, "d"
		if( icompare == 0 ) igoto continue_d
	
		
		Ssub_r strcat Ssub_r, Schar


		igoto get_r
	
			
			
			
			
	continue_r:
	
		ivalue      strtol Ssub_r
		iresolution =      1 / ivalue * 4


		igoto advanceSindex
	
		
		
			
	continue_t:
	
		ivalue      strtol Ssub_r
		iresolution =      1 / ivalue * 2 / 3 * 4


		igoto advanceSindex
		
	
			
		
	continue_d:
	
		Ssub_d strcpy ""
		
	
	
		
	get_d:
	
		iSindex  =      iSindex + 1
		Schar    strsub Spattern, iSindex, iSindex + 1
	
		
		icompare strcmp Schar, " "
		if( icompare == 0 ) igoto continue_d2
	
		
		Ssub_d strcat Ssub_d, Schar
	
		
		igoto get_d
		
		
		
		
	continue_d2:
	
		ivalue      strtol Ssub_r
		ivalue2     strtol Ssub_d
		iresolution =      1 / ivalue / ivalue2 * 4
		

		igoto advanceSindex
				
				
				
	
	advanceSindex:
		
		iSindex = iSindex + 1
		if( iSindex < ilength ) igoto begin
endin






; ---- Kick Drum ----

instr $kick
	idur = p3
	iamp = p4
	
	kenv1 expseg 900, 0.01, 50, idur - 0.01, 20
	asig1 oscil3 1, kenv1, 1
	kenv2 line   1, idur, 0
	asig1 =      asig1 * kenv2

	asig2  gauss  1
	kenv5  expseg 800, 0.1, 50, idur - 0.1, 20
	asig2  tone   asig2, kenv5
	
	amix  = asig1 + asig2
	
	kenv5 expseg 500, 0.05, 60, idur - 0.05, 20
	amix  rezzy  amix, kenv5, 10

	kenv6 linseg 50, idur, 20
	aosc  oscil3 1, kenv6, 1

	kenv4 expseg 2, 0.15, 1, idur - 0.15, 1
	kenv4 =      kenv4 - 1

	amix =  ( amix * 0.8 + aosc  * 1.2 ) * kenv4 * iamp

	out amix * 10000 * iamp
endin






; ---- Snare Drum ----

instr $snare
	idur     = p3
	idynamic = p4
	
	atri         oscil3 1, 111 + idynamic * 5, 2	
	areal, aimag hilbert atri

	ifshift =      175
	asin    oscil3 1, ifshift, 1	
	acos    oscil3 1, ifshift, 1, .25	
	amod1   =      areal * acos
	amod2   =      aimag * asin
	ashift1 =      ( amod1 + amod2 ) * 0.7

	ifshift2 =      224
	asin     oscil3 1, ifshift2, 1	
	acos     oscil3 1, ifshift2, 1, .25	
 	amod1    =      areal * acos
	amod2    =      aimag * asin
	ashift2  =      ( amod1 + amod2 ) * 0.7
	
	kenv1     linseg 1, 0.15, 0, idur - 0.15, 0
	ashiftmix =      ( ashift1 + ashift2 ) * kenv1
	
	aosc1   oscil3 1, 180, 1
	aosc2   oscil3 1, 330, 1
	kenv2   linseg 1, 0.08, 0, idur - 0.08, 0
	aoscmix =      ( aosc1 + aosc2 ) * kenv2

	anoise gauss    1
	anoise butterhp anoise, 2000
	anoise butterlp anoise, 3000 + idynamic * 3000
	anoise butterbr anoise, 4000, 200
	kenv3  expseg   2, 0.15, 1, idur - 0.15, 1
	anoise =        anoise * ( kenv3 - 1 )
	
	amix = aoscmix + ashiftmix + anoise * 4
	
	out amix * 10000 * idynamic
endin






; ---- Hihat ----

instr $hihat
	idur     = p3
	idynamic = p4

	ifreq =     125 + ( 2 * idynamic )
	a1    oscil 1, ifreq * 1, 5
	a2    oscil 1, ifreq * 2.333, 5
	a3    oscil 1, ifreq * 3.578, 5
	a4    oscil 1, ifreq * 5.123, 5
	a5    oscil 1, ifreq * 7.632, 5
	a6    oscil 1, ifreq * 9.843, 5
	amix  =     a1 + a2 + a3 + a4 + a5 + a6
	
	idecay1 =      0.08 + ( 0.03 * ( 1 - idynamic ) )
	kenv1   expseg 1, 0.01, 2, idecay1, 1, idur - idecay1 - 0.01, 1
	kenv1   =      kenv1 - 1
	amix    =      amix * kenv1
	
	idecay2 =      0.11 + 0.05 * idynamic
	kenv2   linseg 1, idecay2, 0, idur - idecay2, 0
	anoise  gauss  1
	
	amix =        ( anoise * kenv2 ) + amix * 0.5
	amix butterhp amix, 7000	
	amix butterlp amix, 9000 + idynamic * 3000
	
	out amix * 10000 * idynamic
endin






</CsInstruments>

<CsScore>

; ---- Instrument Definitions ----

#define dseq   # 1 #    ; dseq drum pattern event generator
#define kick   # 2 #    ; Kick Drum
#define snare  # 3 #    ; Snare Drum
#define hihat  # 4 #    ; Hihat




; ---- f-tables ----

f1 0 65536 10 1
f2 0 8192 -7 -1 4096 1 4096 -1
f3 0 8192 -7 -1 8192 1
f5 0 8192 -7 1 200 1 0 -1 7912 -1




; ---- Set Tempo ----

t 0 90




; ---- dseq pattern event generator ----

; Classic Rock Beat

i $dseq 0 1 $hihat "f.f.  f.f.  f.f.  f.f."
i $dseq 0 1 $snare "....  f...  ....  f..."
i $dseq 0 1 $kick  "f...  ....  f.f.  ...."



; Classic Rock Beat with upper case letters

i $dseq 4 1 $hihat "F.F.  F.F.  F.F.  F.F."
i $dseq 4 1 $snare "....  F...  ....  F..."
i $dseq 4 1 $kick  "F...  ....  F.F.  ...."



; Classic rock beat with dynamics

i $dseq 8 1 $hihat "c.6.  a.6.  c.6.  a.6."
i $dseq 8 1 $snare "....  8...  ....  8..a"
i $dseq 8 1 $kick  "8...  ....  c.a.  ...."



; Classic rock beat pattern rewritten with resolution directive "r#"

i $dseq 12 1 $hihat "r8 c6a6     c6      a   6 "
i $dseq 12 1 $snare "r4 . 8      .   r16 8.  .a"
i $dseq 12 1 $kick  "r4 8 .   r8 a8      .   . "



; Triplet hi-hats using resolution triplet directive "r#t"

i $dseq 16 1 $hihat "r8t f88   a88   f88   a88 "
i $dseq 16 1 $snare "    ....  c...  ....  c..."
i $dseq 16 1 $kick  "    f...  ....  f...  ...."



; Triplet hi-hats rewritten using resolution divide directive "r#d#"

i $dseq 20 1 $hihat "r4d3 f88   a88   f88   a88 "
i $dseq 20 1 $snare "     ....  c...  ....  c..."
i $dseq 20 1 $kick  "     f...  ....  f...  ...."



; Demonstration using "r#d#" with irregular rhythms

i $dseq 24 1 $hihat "r4d4 aaaa r4d5 aaaaa r4d6 aaaaaa r4d7 aaaaaaa"
i $dseq 24 1 $snare "     ....      f...       ....        f...   "
i $dseq 24 1 $kick  "     f...      ....       f..f        ....   "



; Dirt + H2O

i $dseq 28 1 $hihat "a...  a...  a...  a..."
i $dseq 28 1 $snare "....  c...  ..c.  ...."
i $dseq 28 1 $kick  "f.f.  ..f.  f...  ...."

i $dseq 32 1 $hihat "a...  a...  a...  a..."
i $dseq 32 1 $snare "....  c...  ..c.  ...."
i $dseq 32 1 $kick  "f.f.  ..f.  f...  ...."

e 36

</CsScore>
</CsoundSynthesizer>
