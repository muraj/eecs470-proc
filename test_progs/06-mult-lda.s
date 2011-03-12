/*
  This test was hand written by Joel VanLaven to put pressure on ROBs
  It generates and stores in order 64 32-bit pseudo-random numbers in 
  16 passes using 64-bit arithmetic.  (i.e. it actually generates 64-bit
  values and only keeps the more random high-order 32 bits).  The constants
  are from Knuth.  To be effective in testing the ROB the mult must take
  a while to execute and the ROB must be "small enough".  Assuming that
  there is any reasonably working form of branch prediction and that the
  Icache works and is large enough, multiple passes should end up going
  into the ROB at the same time increasing the efficacy of the test.  If
  for some reason the ROB is not filling with this test is should be
  easily modifiable to fill the ROB.

  In order to properly pass this test the pseudo-random numbers must be
  the correct numbers.
  
  $r1 = 8
*/
        lda     $r1,0x8
start:  lda     $r2,0x27bb
        sll     $r2,16,$r2
        lda     $r0,0x2ee6
        bis     $r2,$r0,$r2
        lda     $r0,0x87b
        sll     $r2,12,$r2
        bis     $r2,$r0,$r2
        lda     $r0,0x0b0
        sll     $r2,12,$r2
        bis     $r2,$r0,$r2
        lda     $r0,0xfd
        sll     $r2,8,$r2
        bis     $r2,$r0,$r2
  lda     $r3,0xb50
        sll     $r3,12,$r3
        lda     $r0,0x4f3
        bis     $r3,$r0,$r3
        lda     $r0,0x2d
        sll     $r3,0x4,$r3
        bis     $r3,$r0,$r3
        lda     $r4,0
loop:   addq    $r4,1,$r4
        cmple   $r4,0xf,$r5
        mulq    $r1,$r2,$r10
        addq    $r10,$r3,$r10
        mulq    $r10,$r2,$r11
        addq    $r11,$r3,$r11
        mulq    $r11,$r2,$r12
        addq    $r12,$r3,$r12
        mulq    $r12,$r2,$r1
        addq    $r1,$r3,$r1
        srl     $r10,32,$r10
        srl     $r11,32,$r11
        srl     $r12,32,$r12
        srl     $r1,32,$r13
        addq    $r0,32,$r0
  bne     $r5,loop
  call_pal        0x555

