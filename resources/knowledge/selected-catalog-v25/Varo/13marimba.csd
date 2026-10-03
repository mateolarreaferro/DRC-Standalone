<CsoundSynthesizer>
<CsOptions>
</CsOptions>
<CsInstruments>
sr             =              44100
kr             =              4410
ksmps          =              10
nchnls         =              1
;========================================================================;
;                 Yamaha DX7 Algorithm 07                                ;
;========================================================================;
         instr    1
ihold                          
idur           =              abs(p3)
ibase          =              (exp((p4/12) * log(2))/log(2.71828183)) * 8.175
iroct          =              octcps(p4)
irbase         =              octpch(4.09)          
irrange        =              octpch(13.06)-irbase
iveloc         =              p5                    
iop1fn         =              p10                   
iop2fn         =              p11
iop3fn         =              p12
iop4fn         =              p13
iop5fn         =              p14
iop6fn         =              p15
iampfn         =              p16                   
ipkamp         =              p17                   
irsfn          =              p18                   
idevfn         =              p19                   
irisefn        =              p20                   
idecfn         =              p21                   
ivsfn          =              p22                   
ivelfn         =              p23                   
iveloc         table          iveloc,ivelfn         
iveloc         =              iveloc * 1.10         
ifeedfn        =              p24
ifeed          table          p25,ifeedfn                
ifeed          =              ifeed/(2 * 3.14159)   
idetfac        =              4                          
imap128        =              127/99                     
irscl          table          (iroct-irbase)/irrange*127,irsfn
irscl          =              irscl*6
iop            =              1                          
iopfn          =              iop1fn
loop:
;---------------------------------READ OPERATOR PARAMETERS
ilvl           table          0,iopfn
ivel           table          1,iopfn
iegr1          table          2,iopfn
iegr2          table          3,iopfn
iegr3          table          4,iopfn
iegr4          table          5,iopfn
iegl1          table          6,iopfn
iegl2          table          7,iopfn
iegl3          table          8,iopfn
iegl4          table          9,iopfn
iams           table          10,iopfn
imode          table          11,iopfn
ifreq          table          12,iopfn
idet           table          13,iopfn
irss           table          14,iopfn
;----------------------------------INITIALIZE OPERATOR
ihz            =              (imode > 0 ? ifreq : ibase * ifreq) + idet/idetfac
iamp           =              ilvl/99       
ivfac          table          ivel,ivsfn
  
iegl1          =              iamp*iegl1
iegl2          =              iamp*iegl2
iegl3          =              iamp*iegl3
iegl4          =              iamp*iegl4
  
iegl1          =              iegl1*(1-ivfac)+iegl1*ivfac*iveloc
iegl2          =              iegl2*(1-ivfac)+iegl2*ivfac*iveloc
iegl3          =              iegl3*(1-ivfac)+iegl3*ivfac*iveloc
iegl4          =              iegl4*(1-ivfac)+iegl4*ivfac*iveloc

irs            =              irscl*irss
iegr1          =              (iegr1+irs > 99 ? 99 : iegr1+irs)
iegr2          =              (iegr2+irs > 99 ? 99 : iegr2+irs)
iegr3          =              (iegr3+irs > 99 ? 99 : iegr3+irs)
iegr4          =              (iegr4+irs > 99 ? 99 : iegr4+irs)
     
irfn           =              (iegl1 > iegl4 ? irisefn : idecfn)
iegd1          table          iegr1,irfn                                   ;CONVERT RATE->DUR
ipct1          table          iegl4,irfn+1                                 ;PCT FN IS NEXT ONE
ipct2          table          iegl1,irfn+1
iegd1          =              abs(iegd1*ipct1-iegd1*ipct2)
iegd1          =              (iegd1 == 0 ? .001 : iegd1)

irfn           =              (iegl2 > iegl1 ? irisefn : idecfn)
iegd2          table          iegr2,irfn
ipct1          table          iegl1,irfn+1
ipct2          table          iegl2,irfn+1
iegd2          =              abs(iegd2*ipct1-iegd2*ipct2)
iegd2          =              (iegd2 == 0 ? .001 : iegd2)

irfn           =              (iegl3 > iegl2 ? irisefn : idecfn)
iegd3          table          iegr3,irfn
ipct1          table          iegl2,irfn+1
ipct2          table          iegl3,irfn+1
iegd3          =              abs(iegd3*ipct1-iegd3*ipct2)
iegd3          =              (iegd3 == 0 ? .001 : iegd3)

iegd4          table          iegr4,idecfn
if      (iegl3 <= iegl4)      igoto continue
ipct1          table          iegl3,irfn+1
ipct2          table          iegl4,irfn+1
iegd4          =              abs(iegd4*ipct1-iegd4*ipct2)
iegd4          =              (iegd4 == 0 ? .001 : iegd4)

continue:
if      (iop > 1)             igoto op2
op1:   
i1egd1         =              iegd1
i1egd2         =              iegd2
i1egd3         =              iegd3
i1egd4         =              iegd4
i1egl1         =              iegl1
i1egl2         =              iegl2
i1egl3         =              iegl3
i1egl4         =              iegl4
i1ams          =              iams
i1hz           =              ihz
iop            =              iop + 1
iopfn          =              iop2fn
igoto          loop

op2:     if       (iop > 2) igoto op3
i2egd1         =              iegd1
i2egd2         =              iegd2
i2egd3         =              iegd3
i2egd4         =              iegd4
i2egl1         =              iegl1
i2egl2         =              iegl2
i2egl3         =              iegl3
i2egl4         =              iegl4
i2ams          =              iams
i2hz           =              ihz
iop            =              iop + 1
iopfn          =              iop3fn
igoto          loop

op3:     if       (iop > 3) igoto op4
i3egd1         =              iegd1
i3egd2         =              iegd2
i3egd3         =              iegd3
i3egd4         =              iegd4
i3egl1         =              iegl1
i3egl2         =              iegl2
i3egl3         =              iegl3
i3egl4         =              iegl4
i3ams          =              iams
i3hz           =              ihz
iop            =              iop + 1
iopfn          =              iop4fn
igoto          loop

op4:     if       (iop > 4) igoto op5
i4egd1         =              iegd1
i4egd2         =              iegd2
i4egd3         =              iegd3
i4egd4         =              iegd4
i4egl1         =              iegl1
i4egl2         =              iegl2
i4egl3         =              iegl3
i4egl4         =              iegl4
i4ams          =              iams
i4hz           =              ihz
iop            =              iop + 1
iopfn          =              iop5fn
igoto          loop

op5:     if       (iop > 5) igoto op6
i5egd1         =              iegd1
i5egd2         =              iegd2
i5egd3         =              iegd3
i5egd4         =              iegd4
i5egl1         =              iegl1
i5egl2         =              iegl2
i5egl3         =              iegl3
i5egl4         =              iegl4
i5ams          =              iams
i5hz           =              ihz
iop            =              iop + 1
iopfn          =              iop6fn
igoto          loop

op6:
i6egd1         =              iegd1
i6egd2         =              iegd2
i6egd3         =              iegd3
i6egd4         =              iegd4
i6egl1         =              iegl1
i6egl2         =              iegl2
i6egl3         =              iegl3
i6egl4         =              iegl4
i6ams          =              iams
i6hz           =              ihz
;============================================================
                
timout         idur,999,final                               
k1sus          linseg         i1egl4,i1egd1,i1egl1,i1egd2,i1egl2,i1egd3,i1egl3,1,i1egl3
k2sus          linseg         i2egl4,i2egd1,i2egl1,i2egd2,i2egl2,i2egd3,i2egl3,1,i2egl3
k3sus          linseg         i3egl4,i3egd1,i3egl1,i3egd2,i3egl2,i3egd3,i3egl3,1,i3egl3
k4sus          linseg         i4egl4,i4egd1,i4egl1,i4egd2,i4egl2,i4egd3,i4egl3,1,i4egl3
k5sus          linseg         i5egl4,i5egd1,i5egl1,i5egd2,i5egl2,i5egd3,i5egl3,1,i5egl3
k6sus          linseg         i6egl4,i6egd1,i6egl1,i6egd2,i6egl2,i6egd3,i6egl3,1,i6egl3
k1phs          =              k1sus
k2phs          =              k2sus
k3phs          =              k3sus
k4phs          =              k4sus
k5phs          =              k5sus
k6phs          =              k6sus
kgoto          structure

final:   
k1fin          linseg         1,i1egd4,0,1,0
k1phs          =              i1egl4+(k1sus-i1egl4)*k1fin
k2fin          linseg         1,i2egd4,0,1,0
k2phs          =              i2egl4+(k2sus-i2egl4)*k2fin
k3fin          linseg         1,i3egd4,0,1,0
k3phs          =              i3egl4+(k3sus-i3egl4)*k3fin
k4fin          linseg         1,i4egd4,0,1,0
k4phs          =              i4egl4+(k4sus-i4egl4)*k4fin
k5fin          linseg         1,i5egd4,0,1,0
k5phs          =              i5egl4+(k5sus-i5egl4)*k5fin
k6fin          linseg         1,i6egd4,0,1,0
k6phs          =              i6egl4+(k6sus-i6egl4)*k6fin
kgoto          carrier       
;====================================================================
;DETERMINE ALGORITHM PATHWAY!!!!!!!!!!!!!!!!!!!!!!!!
;====================================================================
carrier: if       (k1fin + k3fin) > 0 kgoto structure
               turnoff

;=========================================================================
;STRUCTURE SECTION - TELLS OPS WHETHER THEY ARE CARRIERS OR MODULATORS.
;=========================================================================
structure:
k1gate         tablei         k1phs,iampfn
k2gate         tablei         k2phs,idevfn
k3gate         tablei         k3phs,iampfn
k4gate         tablei         k4phs,idevfn
k5gate         tablei         k5phs,idevfn
k6gate         tablei         k6phs,idevfn

;==========================================================================
;MODULATION SECTION- DETERMINES WHAT'S MODULATED AND WHAT'S NOT.
;========================================================================== 
a6sig          init           0
a6phs          phasor         i6hz
a6sig          tablei         a6phs+a6sig*ifeed,1,1,0,1
a6sig          =              a6sig*k6gate
      
a5phs          phasor         i5hz
a5sig          tablei         a5phs+a6sig,1,1,0,1
a5sig          =              a5sig*k5gate
      
a4sig          oscili         k4gate,i4hz,1
    
a3phs          phasor         i3hz
a3sig          tablei         a3phs+a4sig+a5sig,1,1,0,1
a3sig          =              a3sig*k3gate
      
a2sig          oscili         k2gate,i2hz,1
    
a1phs          phasor         i1hz
a1sig          tablei         a1phs+a2sig,1,1,0,1
a1sig          =              a1sig*k1gate
      
out            (a1sig + a3sig) * ipkamp*.5
endin 

</CsInstruments>
<CsScore>
;============================================================================
; MARIMBA - ALGORITHM #7
;============================================================================
; SIMPLE SINE FUNCTION
f01     0       4096     10      1
; OPERATOR OUTPUT LEVEL TO AMP SCALE FUNCTION (DATA FROM CHOWNING/BRISTOW)
f02     0       128     7       0       10      .003    10      .013
        10      .031    10      .079    10      .188    10      .446
        5       .690    5       1.068   5       1.639   5       2.512
        5       3.894   5       6.029   5       9.263   4       13.119
        29      13.119
; RATE SCALING FUNCTION
f03     0       128     7       0       128     1
; EG RATE RISE FUNCTION FOR LVL CHANGE BETWEEN 0 AND 99 (DATA FROM OPCODE)
f04     0       128     -7      38      5       22.8    5       12      5
        7.5     5       4.8     5       2.7     5       1.8     5       1.3
        8       .737    3       .615    3       .505    3       .409    3       
        .321    6       .080    6       .055    2       .032    3       .024
        3       .018    3       .014    3       .011    3       .008    3       
        .008    3       .007    3       .005    3       .003    32      .003
; EG RATE RISE PERCENTAGE FUNCTION
f05     0       128     -7      .00001  31      .00001  4       .02     5
        .06     10      .14     10      .24     10      .35     10      .50
        10      .70     5       .86     4       1.0     29      1.0
; EG RATE DECAY FUNCTION FOR LVL CHANGE BETWEEN 0 AND 99
f06     0       128     -7      318     4       181     5       115     5
        63      5       39.7    5       20      5       11.2    5       7       
        8       5.66    3       3.98    6       1.99    3       1.34    3       
        .99     3       .71     5       .41     3       .15     3       .081
        3       .068    3       .047    3       .037    3       .025    3
        .02     3       .013    3       .008    36      .008
; EG RATE DECAY PERCENTAGE FUNCTION
f07     0       128     -7      .00001  10      .25     10      .35     10
        .43     10      .52     10      .59     10      .70     10      .77
        10      .84     10      .92     9       1.0     29      1.0
; EG LEVEL TO AMP FACTOR MAPPING FUNCTION (INDEX IN RADIANS = INDEX / 2PI)
;f08     0       128     6      .001    96      .5      32      1
;f08   0   128   -6    0   64   .0318   0       .0318   64      2.08795
f08     0       128     -7      0       10      .000477 10      .002
        10      .00493  10      .01257  10      .02992  10      .07098
        5       .10981  5       .16997  5       .260855 5       .39979
        5       .61974  5       .95954  5       1.47425 4       2.08795
        29      2.08795
; VELOCITY TO AMP FACTOR MAPPING FUNCTION (ROUGH GUESS)
f09     0       129     9       .25     1       0
; VELOCITY SENSITIVITY SCALING FUNCTION
f10     0       8       -7      0       8       1
; FEEDBACK SCALING FUNCTION
f11     0       8       -6      0       8       6            
;============================================================================
; OPERATOR 1 PARAMETERS:    
f12     0       32      -2    
;OUTLVL   KEYVEL   EGR1   EGR2   EGR3   EGR4   EGL1   EGL2   EGL3   EGL4
 96       1        95     40     49     55     99     92     0      0
;AMS      FIXED?   FREQ   DET    RSC
 0        0        2      0      3

; OPERATOR 2 PARAMETERS
f13     0       32      -2             
;OUTLVL   KEYVEL   EGR1   EGR2   EGR3   EGR4   EGL1   EGL2   EGL3   EGL4
 69       1        99     72     20     46     82     48     0      0
;AMS      FIXED?   FREQ   DET    RSC
 0        0        6      0      0
                                                
; OPERATOR 3 PARAMETERS
f14     0       32      -2
;OUTLVL   KEYVEL   EGR1   EGR2   EGR3   EGR4   EGL1   EGL2   EGL3   EGL4
 99       0        95     33     49     41     99     92     0      0
;AMS      FIXED?   FREQ   DET    RSC
 0        0        .5     0      3
                                                
; OPERATOR 4 PARAMETERS
f15     0       32      -2         
;OUTLVL   KEYVEL   EGR1   EGR2   EGR3   EGR4   EGL1   EGL2   EGL3   EGL4
 85       3        99     75     20     82     82     48     0      0
;AMS      FIXED?   FREQ   DET    RSc
 0        0        4      0      0
                                               
; OPERATOR 5 PARAMETERS
f16     0       32      -2
;OUTLVL   KEYVEL   EGR1   EGR2   EGR3   EGR4   EGL1   EGL2   EGL3   EGL4
 93       3        99     75     20     46     82     48     0      0
;AMS      FIXED?   FREQ   DET    RSC
 0        0        .5     0      3
 
; OPERATOR 6 PARAMETERS
f17     0       32      -2
;OUTLVL   KEYVEL   EGR1   EGR2   EGR3   EGR4   EGL1   EGL2   EGL3   EGL4
 99       3        20     63     55     44     78     78     0      0
;AMS      FIXED?   FREQ   DET    RSC
 0        0        6      0      3
                                                
;====================================================================;
;                       Yamaha DX7 Algorithm 16                      ;
;                                                                    ;
;    p02 = start     p03 = dur       p04 = pch       p05 = vel       ;
;    p06 = panfac    p07 = vibdel    p08 = vibwth    p09 = vibhz     ;
;    p10 = op1fn     p11 = op2fn     p12 = op3fn     p13 = op4fn     ;
;    p14 = op5fn     p15 = op6fn     p16 = ampfn     p17 = pkamp     ;
;    p18 = rsfn      p19 = devfn     p20 = erisfn    p21 = edecfn    ;
;    p22 = vsfn      p23 = velfn     p24 = feedfn    p25 = feedbk    ;
;                    p26 = Algorithm Number (Disabled)               ;
;====================================================================;
t 0.000 82.000
i1.00 0.000    0.410    76    65      0      0      0      0
12    13       14       15    16      17     2      15000
3     8        4        6     10      9      11     5
i1.01  0.500 0.463 75 46
i1.02  1.000 0.506 76 80
i1.03  1.500 0.494 75 72
i1.04  2.000 0.633 76 77
i1.05  2.500 0.490 71 66
i1.06  3.000 0.583 74 98
i1.07  3.500 0.467 72 95
i1.08  4.000 2.100 45 103
i1.09  4.000 0.567 69 87
i1.10  4.500 1.442 52 75
i1.11  5.000 1.117 57 86
i1.12  5.500 0.615 60 72
i1.13  6.000 0.577 64 92
i1.14  6.500 0.502 69 95
i1.15  7.000 0.554 40 92
i1.16  7.000 1.481 71 93
i1.17  7.500 0.502 52 90
i1.18  8.000 0.946 56 96
i1.19  8.500 0.550 64 81
i1.20  9.000 0.442 68 100
i1.21  9.500 0.575 71 89
i1.22  10.000 0.635 45 87
i1.23  10.000 1.483 72 100
i1.24  10.500 0.471 52 86
i1.25  11.000 2.281 57 80
i1.26  11.500 0.506 64 79
i1.27  12.000 0.512 76 90
i1.28  12.500 0.500 75 85
i1.29  13.000 0.485 76 98
i1.30  13.500 0.573 75 77
i1.31  14.000 0.590 76 96
i1.32  14.500 0.490 71 74
i1.33  15.000 0.546 74 82
i1.34  15.500 0.460 72 86
i1.35  16.000 0.640 69 80
i1.36  16.000 1.752 45 81
i1.37  16.500 0.879 52 68
i1.38  17.000 0.794 57 79
i1.39  17.500 0.535 60 70
i1.40  18.000 0.473 64 85
i1.41  18.494 0.483 69 86
i1.42  18.994 0.563 40 92
i1.43  18.994 1.575 71 92
i1.44  19.494 0.398 52 93
i1.45  19.994 0.563 56 94
i1.46  20.494 0.510 64 81
i1.47  20.994 0.458 72 95
i1.48  21.494 0.498 71 77
i1.49  21.994 3.175 45 73
i1.50  21.994 3.190 69 85
i1.51  22.494 2.631 52 71
i1.52  22.994 2.138 57 84
f0     26
e
</CsScore>
</CsoundSynthesizer>
