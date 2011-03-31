/*
	TEST PROGRAM #2: compute even numbers that are less than 16


	long output[16];
	
	void
	main(void)
	{
	  long i,j;
	
	  for (i=0,j=0; i < 16; i++)
	    {
	      if ((i & 1) == 0)
	        output[j++] = i;
	    }
	}
*/
	data = 0x1000
	lda     $r2,0
	nop
	nop
	nop
	nop
	lda     $r3,data
	nop
	nop
	nop
	nop
loop1:	blbs    $r2,loop2
	nop
	nop
	nop
	nop
	stq     $r2,0($r3)
	nop
	nop
	nop
	nop
	addq    $r3,0x8,$r3
	nop
	nop
	nop
	nop
loop2:	addq    $r2,0x1,$r2
	nop
	nop
	nop
	nop
	cmple   $r2,0xf,$r1
	nop
	nop
	nop
	nop
	bne     $r1,loop1
	nop
	nop
	nop
	nop
	call_pal        0x555
	nop
	nop
	nop
	nop

