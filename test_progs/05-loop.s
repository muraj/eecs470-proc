/* Test simple branch logic on always taken 
   int r0 = 0;
   int r1 = 0xFF;
   while(r1 < 0){
	   r0 += 1;
	   r1 = r0 - 0xFF;
   }
*/
lda $r0, 0x00
lda $r1, 0x00
loop:
	addq $r0, 0x1 , $r0
	subq $r0, 0xFF, $r1
	blt $r1, loop
call_pal 0x555
