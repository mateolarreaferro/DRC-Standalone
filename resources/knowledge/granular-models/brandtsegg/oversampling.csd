; oversampling in Csound to avoid aliasing in audio processing
; Oeyvind Brandtsegg 2020 obrandts@gmail.com

<CsoundSynthesizer>
<CsOptions>
</CsOptions>
<CsInstruments>

sr = 48000
ksmps = 32
nchnls = 2
0dbfs = 1

; the audio process to be oversampled
opcode Oversampled_proc, a, aiP
 ; audio in, oversampling factor, optional k-rate parameter for the audio process
 a1, ioversampl, kparm xin
 a1 = tanh(a1*kparm)
 xout a1
endop

; the audio process to be oversampled
opcode Oversampled_proc, a, aiP
 ; audio in, oversampling factor, optional k-rate parameter for the audio process
 a1, ioversampl, kparm xin
 kfq = kparm/ioversampl ; if the upsampled audio process requires a frequency parameter,
   ; this value needs to be scaled relative to the new sampling rate
 ; single sideband modulation
 aSin, aCos	hilbert	a1
 aModSin oscili	1, kfq, -1, 0.0
 aModCos oscili	1, kfq, -1, 0.25
 aMod1 = aSin * aModCos
 aMod2 = aCos * aModSin
 aSum	= aMod1 + aMod2
 aDiff = aMod1 - aMod2
 xout aDiff
endop

; oversampling of audio, to allow processing above Nyquist
; interpolation on upsampling, convolution as lowpass before decimation
; Oeyvind Brandtsegg 2020 obrandts@gmail.com
opcode Oversample, a, aiP
 ; audio in, oversampling factor, optional k-rate parameter for the audio process
 a1, ioversampl, kparm xin
 kaudiobuf[] init ksmps
 kaudiobuf shiftin a1
 kaudioup[] init ksmps*ioversampl

 ; upsample by zero stuffing and interpolation
 kindex = 0
 kprev init 0
 while kindex < ksmps do
  kaudioup[kindex*ioversampl] = kprev
  kindex2 = 1
  while kindex2 < ioversampl do
    kaudioup[kindex*ioversampl+kindex2] = kprev*(1-(kindex2/ioversampl))+kaudiobuf[kindex]*(kindex2/ioversampl)
    kindex2 += 1
  od
  kprev = kaudiobuf[kindex]
	kindex += 1
 od

; set lowpass filter coefficients
 ; --- inlined: filter_coefs.inc ---
; oversampling in Csound to avoid aliasing in audio processing
; Oeyvind Brandtsegg 2020 obrandts@gmail.com

; filter coefficients from http://t-filter.engineerjs.com/
; assuming base sr = 48000, upsampling by a factor of 2,4 or 8 from there
; passband (gain 1) 0 to 16k, 5 dB ripple/att
; stopband (gain 0.01 = -40dB) from  24k to 48k, 5dB ripple/att
iUp2 ftgen 0, 0, 19, -2, 0.006754086920847961,
0.02887867256623345,
0.05154582661834378,
0.042765057954332455,
-0.014132005797116935,
-0.07252666695811986,
-0.04583982307806859,
0.1026891138234764,
0.292580258891611,
0.3899582048062838,
0.292580258891611,
0.1026891138234764,
-0.04583982307806859,
-0.07252666695811986,
-0.014132005797116935,
0.042765057954332455,
0.05154582661834378,
0.02887867256623345,
0.006754086920847961

; passband (gain 1) 0 to 16k, 5 dB ripple/att
; stopband (gain 0.01 = -40dB) from  24k to 96k, 5 dB ripple/att
iUp4 ftgen 0, 0, 37, -2, 0.0031385438711408337,
0.007034923288374264,
0.012750809185273498,
0.01882652201387069,
0.023213459744620617,
0.023510854083956968,
0.01781707699102044,
0.0057083082621170395,
-0.01103973414275012,
-0.02831939495103092,
-0.040396628529465226,
-0.041355710307382325,
-0.02694724974936965,
0.0037460355859862855,
0.047428614578832,
0.09688089694732668,
0.1424888477203368,
0.1746280954473595,
0.19620986104919913,
0.1746280954473595,
0.1424888477203368,
0.09688089694732668,
0.047428614578832,
0.0037460355859862855,
-0.02694724974936965,
-0.041355710307382325,
-0.040396628529465226,
-0.02831939495103092,
-0.01103973414275012,
0.0057083082621170395,
0.01781707699102044,
0.023510854083956968,
0.023213459744620617,
0.01882652201387069,
0.012750809185273498,
0.007034923288374264,
0.0031385438711408337

; passband (gain 1) 0 to 16k, 5 dB ripple/att
; stopband (gain 0.01 = -40dB) from  24k to 192k, 5 dB ripple/att
iUp8 ftgen 0, 0, 71, -2, 0.0018816363396093254,
0.002020612343199422,
0.002926011103000013,
0.0039278863447094236,
0.004942107802124831,
0.005869824123817559,
0.006585517895427554,
0.00695720632705715,
0.006850827152096434,
0.006146102124153559,
0.004755462325555015,
0.0026335764477651,
-0.00020873198574709303,
-0.00369314107174312,
-0.007669585961767334,
-0.011916250468325614,
-0.016148230161052816,
-0.02003126456091799,
-0.02320036267586752,
-0.02528578437134766,
-0.025941123182426116,
-0.024872415809497797,
-0.02186672019074366,
-0.01681590979471364,
-0.009734792731894128,
-0.0007709304326220767,
0.00979511843992762,
0.021558731954384652,
0.03401094038824492,
0.04656744467579209,
0.058604126511785336,
0.0694971588820712,
0.07866422683030846,
0.0856038735068419,
0.08993025005024968,
0.10140010014115386,
0.08993025005024968,
0.0856038735068419,
0.07866422683030846,
0.0694971588820712,
0.058604126511785336,
0.04656744467579209,
0.03401094038824492,
0.021558731954384652,
0.00979511843992762,
-0.0007709304326220767,
-0.009734792731894128,
-0.01681590979471364,
-0.02186672019074366,
-0.024872415809497797,
-0.025941123182426116,
-0.02528578437134766,
-0.02320036267586752,
-0.02003126456091799,
-0.016148230161052816,
-0.011916250468325614,
-0.007669585961767334,
-0.00369314107174312,
-0.00020873198574709303,
0.0026335764477651,
0.004755462325555015,
0.006146102124153559,
0.006850827152096434,
0.00695720632705715,
0.006585517895427554,
0.005869824123817559,
0.004942107802124831,
0.0039278863447094236,
0.002926011103000013,
0.002020612343199422,
0.0018816363396093254

; --- end filter_coefs.inc ---

 ifilter = ioversampl == 2 ? iUp2 : iUp4
 ifilter = ioversampl == 8 ? iUp8 : ifilter
 print ftlen(ifilter), ifilter

 ; oversampled audio processing loop
 ; with lowpass filter to minimize aliasing when decimation is done is the next step
 kindex = 0
 while kindex < ioversampl do
  aup shiftout kaudioup
  aup Oversampled_proc aup, ioversampl, kparm; insert your own processing here
  aup dconv aup, ftlen(ifilter), ifilter ; downsampling filter
  kaudioup shiftin aup ; write audio back to buffer
  kindex += 1
 od

 ; decimation
 kindex = 0
 while kindex < ksmps do
  kaudiobuf[kindex] = kaudioup[(kindex*ioversampl)]
  kindex += 1
 od
 a2 shiftout kaudiobuf
 xout a2
endop

instr 1
; test ooversampling
iamp = ampdbfs(-3)
a1 diskin2 "fox.wav", 1, 0, 1
;a1 poscil 1, 440

kparm line 0, p3, sr
ioversampl = 4
a2 Oversample a1, 8, kparm

; reference signal that has received the same processing, but not in upsampled form
aref Oversampled_proc a1, 1, kparm; insert your own processing here

outs aref*iamp, a2*iamp

endin

</CsInstruments>
<CsScore>
;	start	dur
i1	0	20
e
</CsScore>
</CsoundSynthesizer>
