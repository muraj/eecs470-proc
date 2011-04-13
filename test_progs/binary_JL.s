/*
  Assembly code compiled from Decaf by 'decaf470', written by Doug Li.
*/

	  .set noat
	  .set noreorder
	  .set nomacro
	  data = 0x1000
	  global = 0x2000
	  lda		$r30, 0x7FF0	# set stack ptr to a sufficiently high addr
	  lda		$r15, 0x0000	# initialize frame ptr to something
	  lda		$r29, global	# initialize global ptr to 0x2000
	# Initialize Heap Management Table
	#   could be done at compile-time, but then we get a super large .mem file
	  heap_srl_3 = 0x1800
	  lda		$r28, heap_srl_3	# work-around since heap-start needs >15 bits
	  sll		$r28, 3, $r28	# using the $at as the heap-pointer
	# Do not write to heap-pointer!
	  stq		$r31, -32*8($r28)	# init heap table
	  stq		$r31, -31*8($r28)	# init heap table
	  stq		$r31, -30*8($r28)	# init heap table
	  stq		$r31, -29*8($r28)	# init heap table
	  stq		$r31, -28*8($r28)	# init heap table
	  stq		$r31, -27*8($r28)	# init heap table
	  stq		$r31, -26*8($r28)	# init heap table
	  stq		$r31, -25*8($r28)	# init heap table
	  stq		$r31, -24*8($r28)	# init heap table
	  stq		$r31, -23*8($r28)	# init heap table
	  stq		$r31, -22*8($r28)	# init heap table
	  stq		$r31, -21*8($r28)	# init heap table
	  stq		$r31, -20*8($r28)	# init heap table
	  stq		$r31, -19*8($r28)	# init heap table
	  stq		$r31, -18*8($r28)	# init heap table
	  stq		$r31, -17*8($r28)	# init heap table
	  stq		$r31, -16*8($r28)	# init heap table
	  stq		$r31, -15*8($r28)	# init heap table
	  stq		$r31, -14*8($r28)	# init heap table
	  stq		$r31, -13*8($r28)	# init heap table
	  stq		$r31, -12*8($r28)	# init heap table
	  stq		$r31, -11*8($r28)	# init heap table
	  stq		$r31, -10*8($r28)	# init heap table
	  stq		$r31, -9*8($r28)	# init heap table
	  stq		$r31, -8*8($r28)	# init heap table
	  stq		$r31, -7*8($r28)	# init heap table
	  stq		$r31, -6*8($r28)	# init heap table
	  stq		$r31, -5*8($r28)	# init heap table
	  stq		$r31, -4*8($r28)	# init heap table
	  stq		$r31, -3*8($r28)	# init heap table
	  stq		$r31, -2*8($r28)	# init heap table
	  stq		$r31, -1*8($r28)	# init heap table
	# End Initialize Heap Management Table
	  bsr		$r26, main	# branch to subroutine
	  call_pal	0x555		# (halt)
	  .data
	  L_DATA:			# this is where the locals and temps end up at run-time
	  .text
main:
	# BeginFunc 1344
	  subq		$r30, 16, $r30	# decrement sp to make space to save ra, fp
	  stq		$r15, 16($r30)	# save fp
	  stq		$r26, 8($r30)	# save ra
	  addq		$r30, 16, $r15	# set up new fp
	  lda		$r2, 1344	# stack frame size
	  subq		$r30, $r2, $r30	# decrement sp to make space for locals/temps
	# _tmp0 = 16
	  lda		$r3, 16		# load (signed) int constant value 16 into $r3
	  stq		$r3, -24($r15)	# spill _tmp0 from $r3 to $r15-24
	# _tmp1 = _tmp0 < ZERO
	  ldq		$r1, -24($r15)	# fill _tmp0 to $r1 from $r15-24
	  cmplt		$r1, $r31, $r3	# perform the ALU op
	  stq		$r3, -32($r15)	# spill _tmp1 from $r3 to $r15-32
	# IfZ _tmp1 Goto __L0
	  ldq		$r1, -32($r15)	# fill _tmp1 to $r1 from $r15-32
	  blbc		$r1, __L0	# branch if _tmp1 is zero
	# Throw Exception: Array size is <= 0
	  call_pal	0xDECAF		# (exception: Array size is <= 0)
	  call_pal	0x555		# (halt)
__L0:
	# _tmp2 = _tmp0 + 1
	  ldq		$r1, -24($r15)	# fill _tmp0 to $r1 from $r15-24
	  addq		$r1, 1, $r3	# perform the ALU op
	  stq		$r3, -40($r15)	# spill _tmp2 from $r3 to $r15-40
	# PushParam _tmp2
	  subq		$r30, 8, $r30	# decrement stack ptr to make space for param
	  ldq		$r1, -40($r15)	# fill _tmp2 to $r1 from $r15-40
	  stq		$r1, 8($r30)	# copy param value to stack
	# _tmp3 = LCall __Alloc
	  bsr		$r26, __Alloc	# branch to function
	  mov		$r0, $r3	# copy function return value from $v0
	  stq		$r3, -48($r15)	# spill _tmp3 from $r3 to $r15-48
	# PopParams 8
	  addq		$r30, 8, $r30	# pop params off stack
	# *(_tmp3) = _tmp0
	  ldq		$r1, -24($r15)	# fill _tmp0 to $r1 from $r15-24
	  ldq		$r3, -48($r15)	# fill _tmp3 to $r3 from $r15-48
	  stq		$r1, 0($r3)	# store with offset
	# _tmp4 = _tmp3 + 8
	  ldq		$r1, -48($r15)	# fill _tmp3 to $r1 from $r15-48
	  addq		$r1, 8, $r3	# perform the ALU op
	  stq		$r3, -56($r15)	# spill _tmp4 from $r3 to $r15-56
	# values = _tmp4
	  ldq		$r3, -56($r15)	# fill _tmp4 to $r3 from $r15-56
	  stq		$r3, 0($r29)	# spill values from $r3 to $r29+0
	# _tmp5 = 16
	  lda		$r3, 16		# load (signed) int constant value 16 into $r3
	  stq		$r3, -64($r15)	# spill _tmp5 from $r3 to $r15-64
	# _tmp6 = _tmp5 < ZERO
	  ldq		$r1, -64($r15)	# fill _tmp5 to $r1 from $r15-64
	  cmplt		$r1, $r31, $r3	# perform the ALU op
	  stq		$r3, -72($r15)	# spill _tmp6 from $r3 to $r15-72
	# IfZ _tmp6 Goto __L1
	  ldq		$r1, -72($r15)	# fill _tmp6 to $r1 from $r15-72
	  blbc		$r1, __L1	# branch if _tmp6 is zero
	# Throw Exception: Array size is <= 0
	  call_pal	0xDECAF		# (exception: Array size is <= 0)
	  call_pal	0x555		# (halt)
__L1:
	# _tmp7 = _tmp5 + 1
	  ldq		$r1, -64($r15)	# fill _tmp5 to $r1 from $r15-64
	  addq		$r1, 1, $r3	# perform the ALU op
	  stq		$r3, -80($r15)	# spill _tmp7 from $r3 to $r15-80
	# PushParam _tmp7
	  subq		$r30, 8, $r30	# decrement stack ptr to make space for param
	  ldq		$r1, -80($r15)	# fill _tmp7 to $r1 from $r15-80
	  stq		$r1, 8($r30)	# copy param value to stack
	# _tmp8 = LCall __Alloc
	  bsr		$r26, __Alloc	# branch to function
	  mov		$r0, $r3	# copy function return value from $v0
	  stq		$r3, -88($r15)	# spill _tmp8 from $r3 to $r15-88
	# PopParams 8
	  addq		$r30, 8, $r30	# pop params off stack
	# *(_tmp8) = _tmp5
	  ldq		$r1, -64($r15)	# fill _tmp5 to $r1 from $r15-64
	  ldq		$r3, -88($r15)	# fill _tmp8 to $r3 from $r15-88
	  stq		$r1, 0($r3)	# store with offset
	# _tmp9 = _tmp8 + 8
	  ldq		$r1, -88($r15)	# fill _tmp8 to $r1 from $r15-88
	  addq		$r1, 8, $r3	# perform the ALU op
	  stq		$r3, -96($r15)	# spill _tmp9 from $r3 to $r15-96
	# results = _tmp9
	  ldq		$r3, -96($r15)	# fill _tmp9 to $r3 from $r15-96
	  stq		$r3, 8($r29)	# spill results from $r3 to $r29+8
	# _tmp10 = 0
	  lda		$r3, 0		# load (signed) int constant value 0 into $r3
	  stq		$r3, -104($r15)	# spill _tmp10 from $r3 to $r15-104
	# _tmp11 = _tmp10 < ZERO
	  ldq		$r1, -104($r15)	# fill _tmp10 to $r1 from $r15-104
	  cmplt		$r1, $r31, $r3	# perform the ALU op
	  stq		$r3, -112($r15)	# spill _tmp11 from $r3 to $r15-112
	# _tmp12 = *(values + -8)
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -120($r15)	# spill _tmp12 from $r3 to $r15-120
	# _tmp13 = _tmp12 <= _tmp10
	  ldq		$r1, -120($r15)	# fill _tmp12 to $r1 from $r15-120
	  ldq		$r2, -104($r15)	# fill _tmp10 to $r2 from $r15-104
	  cmple		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -128($r15)	# spill _tmp13 from $r3 to $r15-128
	# _tmp14 = _tmp11 || _tmp13
	  ldq		$r1, -112($r15)	# fill _tmp11 to $r1 from $r15-112
	  ldq		$r2, -128($r15)	# fill _tmp13 to $r2 from $r15-128
	  bis		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -136($r15)	# spill _tmp14 from $r3 to $r15-136
	# IfZ _tmp14 Goto __L2
	  ldq		$r1, -136($r15)	# fill _tmp14 to $r1 from $r15-136
	  blbc		$r1, __L2	# branch if _tmp14 is zero
	# Throw Exception: Array subscript out of bounds
	  call_pal	0xDECAF		# (exception: Array subscript out of bounds)
	  call_pal	0x555		# (halt)
__L2:
	# _tmp15 = _tmp10 << 3
	  ldq		$r1, -104($r15)	# fill _tmp10 to $r1 from $r15-104
	  sll		$r1, 3, $r3	# perform the ALU op
	  stq		$r3, -144($r15)	# spill _tmp15 from $r3 to $r15-144
	# _tmp16 = values + _tmp15
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r2, -144($r15)	# fill _tmp15 to $r2 from $r15-144
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -152($r15)	# spill _tmp16 from $r3 to $r15-152
	# _tmp17 = 1
	  lda		$r3, 1		# load (signed) int constant value 1 into $r3
	  stq		$r3, -160($r15)	# spill _tmp17 from $r3 to $r15-160
	# *(_tmp16) = _tmp17
	  ldq		$r1, -160($r15)	# fill _tmp17 to $r1 from $r15-160
	  ldq		$r3, -152($r15)	# fill _tmp16 to $r3 from $r15-152
	  stq		$r1, 0($r3)	# store with offset
	# _tmp18 = 1
	  lda		$r3, 1		# load (signed) int constant value 1 into $r3
	  stq		$r3, -168($r15)	# spill _tmp18 from $r3 to $r15-168
	# _tmp19 = _tmp18 < ZERO
	  ldq		$r1, -168($r15)	# fill _tmp18 to $r1 from $r15-168
	  cmplt		$r1, $r31, $r3	# perform the ALU op
	  stq		$r3, -176($r15)	# spill _tmp19 from $r3 to $r15-176
	# _tmp20 = *(values + -8)
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -184($r15)	# spill _tmp20 from $r3 to $r15-184
	# _tmp21 = _tmp20 <= _tmp18
	  ldq		$r1, -184($r15)	# fill _tmp20 to $r1 from $r15-184
	  ldq		$r2, -168($r15)	# fill _tmp18 to $r2 from $r15-168
	  cmple		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -192($r15)	# spill _tmp21 from $r3 to $r15-192
	# _tmp22 = _tmp19 || _tmp21
	  ldq		$r1, -176($r15)	# fill _tmp19 to $r1 from $r15-176
	  ldq		$r2, -192($r15)	# fill _tmp21 to $r2 from $r15-192
	  bis		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -200($r15)	# spill _tmp22 from $r3 to $r15-200
	# IfZ _tmp22 Goto __L3
	  ldq		$r1, -200($r15)	# fill _tmp22 to $r1 from $r15-200
	  blbc		$r1, __L3	# branch if _tmp22 is zero
	# Throw Exception: Array subscript out of bounds
	  call_pal	0xDECAF		# (exception: Array subscript out of bounds)
	  call_pal	0x555		# (halt)
__L3:
	# _tmp23 = _tmp18 << 3
	  ldq		$r1, -168($r15)	# fill _tmp18 to $r1 from $r15-168
	  sll		$r1, 3, $r3	# perform the ALU op
	  stq		$r3, -208($r15)	# spill _tmp23 from $r3 to $r15-208
	# _tmp24 = values + _tmp23
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r2, -208($r15)	# fill _tmp23 to $r2 from $r15-208
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -216($r15)	# spill _tmp24 from $r3 to $r15-216
	# _tmp25 = 2
	  lda		$r3, 2		# load (signed) int constant value 2 into $r3
	  stq		$r3, -224($r15)	# spill _tmp25 from $r3 to $r15-224
	# *(_tmp24) = _tmp25
	  ldq		$r1, -224($r15)	# fill _tmp25 to $r1 from $r15-224
	  ldq		$r3, -216($r15)	# fill _tmp24 to $r3 from $r15-216
	  stq		$r1, 0($r3)	# store with offset
	# _tmp26 = 2
	  lda		$r3, 2		# load (signed) int constant value 2 into $r3
	  stq		$r3, -232($r15)	# spill _tmp26 from $r3 to $r15-232
	# _tmp27 = _tmp26 < ZERO
	  ldq		$r1, -232($r15)	# fill _tmp26 to $r1 from $r15-232
	  cmplt		$r1, $r31, $r3	# perform the ALU op
	  stq		$r3, -240($r15)	# spill _tmp27 from $r3 to $r15-240
	# _tmp28 = *(values + -8)
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -248($r15)	# spill _tmp28 from $r3 to $r15-248
	# _tmp29 = _tmp28 <= _tmp26
	  ldq		$r1, -248($r15)	# fill _tmp28 to $r1 from $r15-248
	  ldq		$r2, -232($r15)	# fill _tmp26 to $r2 from $r15-232
	  cmple		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -256($r15)	# spill _tmp29 from $r3 to $r15-256
	# _tmp30 = _tmp27 || _tmp29
	  ldq		$r1, -240($r15)	# fill _tmp27 to $r1 from $r15-240
	  ldq		$r2, -256($r15)	# fill _tmp29 to $r2 from $r15-256
	  bis		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -264($r15)	# spill _tmp30 from $r3 to $r15-264
	# IfZ _tmp30 Goto __L4
	  ldq		$r1, -264($r15)	# fill _tmp30 to $r1 from $r15-264
	  blbc		$r1, __L4	# branch if _tmp30 is zero
	# Throw Exception: Array subscript out of bounds
	  call_pal	0xDECAF		# (exception: Array subscript out of bounds)
	  call_pal	0x555		# (halt)
__L4:
	# _tmp31 = _tmp26 << 3
	  ldq		$r1, -232($r15)	# fill _tmp26 to $r1 from $r15-232
	  sll		$r1, 3, $r3	# perform the ALU op
	  stq		$r3, -272($r15)	# spill _tmp31 from $r3 to $r15-272
	# _tmp32 = values + _tmp31
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r2, -272($r15)	# fill _tmp31 to $r2 from $r15-272
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -280($r15)	# spill _tmp32 from $r3 to $r15-280
	# _tmp33 = 3
	  lda		$r3, 3		# load (signed) int constant value 3 into $r3
	  stq		$r3, -288($r15)	# spill _tmp33 from $r3 to $r15-288
	# *(_tmp32) = _tmp33
	  ldq		$r1, -288($r15)	# fill _tmp33 to $r1 from $r15-288
	  ldq		$r3, -280($r15)	# fill _tmp32 to $r3 from $r15-280
	  stq		$r1, 0($r3)	# store with offset
	# _tmp34 = 3
	  lda		$r3, 3		# load (signed) int constant value 3 into $r3
	  stq		$r3, -296($r15)	# spill _tmp34 from $r3 to $r15-296
	# _tmp35 = _tmp34 < ZERO
	  ldq		$r1, -296($r15)	# fill _tmp34 to $r1 from $r15-296
	  cmplt		$r1, $r31, $r3	# perform the ALU op
	  stq		$r3, -304($r15)	# spill _tmp35 from $r3 to $r15-304
	# _tmp36 = *(values + -8)
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -312($r15)	# spill _tmp36 from $r3 to $r15-312
	# _tmp37 = _tmp36 <= _tmp34
	  ldq		$r1, -312($r15)	# fill _tmp36 to $r1 from $r15-312
	  ldq		$r2, -296($r15)	# fill _tmp34 to $r2 from $r15-296
	  cmple		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -320($r15)	# spill _tmp37 from $r3 to $r15-320
	# _tmp38 = _tmp35 || _tmp37
	  ldq		$r1, -304($r15)	# fill _tmp35 to $r1 from $r15-304
	  ldq		$r2, -320($r15)	# fill _tmp37 to $r2 from $r15-320
	  bis		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -328($r15)	# spill _tmp38 from $r3 to $r15-328
	# IfZ _tmp38 Goto __L5
	  ldq		$r1, -328($r15)	# fill _tmp38 to $r1 from $r15-328
	  blbc		$r1, __L5	# branch if _tmp38 is zero
	# Throw Exception: Array subscript out of bounds
	  call_pal	0xDECAF		# (exception: Array subscript out of bounds)
	  call_pal	0x555		# (halt)
__L5:
	# _tmp39 = _tmp34 << 3
	  ldq		$r1, -296($r15)	# fill _tmp34 to $r1 from $r15-296
	  sll		$r1, 3, $r3	# perform the ALU op
	  stq		$r3, -336($r15)	# spill _tmp39 from $r3 to $r15-336
	# _tmp40 = values + _tmp39
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r2, -336($r15)	# fill _tmp39 to $r2 from $r15-336
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -344($r15)	# spill _tmp40 from $r3 to $r15-344
	# _tmp41 = 4
	  lda		$r3, 4		# load (signed) int constant value 4 into $r3
	  stq		$r3, -352($r15)	# spill _tmp41 from $r3 to $r15-352
	# *(_tmp40) = _tmp41
	  ldq		$r1, -352($r15)	# fill _tmp41 to $r1 from $r15-352
	  ldq		$r3, -344($r15)	# fill _tmp40 to $r3 from $r15-344
	  stq		$r1, 0($r3)	# store with offset
	# _tmp42 = 4
	  lda		$r3, 4		# load (signed) int constant value 4 into $r3
	  stq		$r3, -360($r15)	# spill _tmp42 from $r3 to $r15-360
	# _tmp43 = _tmp42 < ZERO
	  ldq		$r1, -360($r15)	# fill _tmp42 to $r1 from $r15-360
	  cmplt		$r1, $r31, $r3	# perform the ALU op
	  stq		$r3, -368($r15)	# spill _tmp43 from $r3 to $r15-368
	# _tmp44 = *(values + -8)
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -376($r15)	# spill _tmp44 from $r3 to $r15-376
	# _tmp45 = _tmp44 <= _tmp42
	  ldq		$r1, -376($r15)	# fill _tmp44 to $r1 from $r15-376
	  ldq		$r2, -360($r15)	# fill _tmp42 to $r2 from $r15-360
	  cmple		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -384($r15)	# spill _tmp45 from $r3 to $r15-384
	# _tmp46 = _tmp43 || _tmp45
	  ldq		$r1, -368($r15)	# fill _tmp43 to $r1 from $r15-368
	  ldq		$r2, -384($r15)	# fill _tmp45 to $r2 from $r15-384
	  bis		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -392($r15)	# spill _tmp46 from $r3 to $r15-392
	# IfZ _tmp46 Goto __L6
	  ldq		$r1, -392($r15)	# fill _tmp46 to $r1 from $r15-392
	  blbc		$r1, __L6	# branch if _tmp46 is zero
	# Throw Exception: Array subscript out of bounds
	  call_pal	0xDECAF		# (exception: Array subscript out of bounds)
	  call_pal	0x555		# (halt)
__L6:
	# _tmp47 = _tmp42 << 3
	  ldq		$r1, -360($r15)	# fill _tmp42 to $r1 from $r15-360
	  sll		$r1, 3, $r3	# perform the ALU op
	  stq		$r3, -400($r15)	# spill _tmp47 from $r3 to $r15-400
	# _tmp48 = values + _tmp47
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r2, -400($r15)	# fill _tmp47 to $r2 from $r15-400
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -408($r15)	# spill _tmp48 from $r3 to $r15-408
	# _tmp49 = 5
	  lda		$r3, 5		# load (signed) int constant value 5 into $r3
	  stq		$r3, -416($r15)	# spill _tmp49 from $r3 to $r15-416
	# *(_tmp48) = _tmp49
	  ldq		$r1, -416($r15)	# fill _tmp49 to $r1 from $r15-416
	  ldq		$r3, -408($r15)	# fill _tmp48 to $r3 from $r15-408
	  stq		$r1, 0($r3)	# store with offset
	# _tmp50 = 5
	  lda		$r3, 5		# load (signed) int constant value 5 into $r3
	  stq		$r3, -424($r15)	# spill _tmp50 from $r3 to $r15-424
	# _tmp51 = _tmp50 < ZERO
	  ldq		$r1, -424($r15)	# fill _tmp50 to $r1 from $r15-424
	  cmplt		$r1, $r31, $r3	# perform the ALU op
	  stq		$r3, -432($r15)	# spill _tmp51 from $r3 to $r15-432
	# _tmp52 = *(values + -8)
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -440($r15)	# spill _tmp52 from $r3 to $r15-440
	# _tmp53 = _tmp52 <= _tmp50
	  ldq		$r1, -440($r15)	# fill _tmp52 to $r1 from $r15-440
	  ldq		$r2, -424($r15)	# fill _tmp50 to $r2 from $r15-424
	  cmple		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -448($r15)	# spill _tmp53 from $r3 to $r15-448
	# _tmp54 = _tmp51 || _tmp53
	  ldq		$r1, -432($r15)	# fill _tmp51 to $r1 from $r15-432
	  ldq		$r2, -448($r15)	# fill _tmp53 to $r2 from $r15-448
	  bis		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -456($r15)	# spill _tmp54 from $r3 to $r15-456
	# IfZ _tmp54 Goto __L7
	  ldq		$r1, -456($r15)	# fill _tmp54 to $r1 from $r15-456
	  blbc		$r1, __L7	# branch if _tmp54 is zero
	# Throw Exception: Array subscript out of bounds
	  call_pal	0xDECAF		# (exception: Array subscript out of bounds)
	  call_pal	0x555		# (halt)
__L7:
	# _tmp55 = _tmp50 << 3
	  ldq		$r1, -424($r15)	# fill _tmp50 to $r1 from $r15-424
	  sll		$r1, 3, $r3	# perform the ALU op
	  stq		$r3, -464($r15)	# spill _tmp55 from $r3 to $r15-464
	# _tmp56 = values + _tmp55
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r2, -464($r15)	# fill _tmp55 to $r2 from $r15-464
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -472($r15)	# spill _tmp56 from $r3 to $r15-472
	# _tmp57 = 6
	  lda		$r3, 6		# load (signed) int constant value 6 into $r3
	  stq		$r3, -480($r15)	# spill _tmp57 from $r3 to $r15-480
	# *(_tmp56) = _tmp57
	  ldq		$r1, -480($r15)	# fill _tmp57 to $r1 from $r15-480
	  ldq		$r3, -472($r15)	# fill _tmp56 to $r3 from $r15-472
	  stq		$r1, 0($r3)	# store with offset
	# _tmp58 = 6
	  lda		$r3, 6		# load (signed) int constant value 6 into $r3
	  stq		$r3, -488($r15)	# spill _tmp58 from $r3 to $r15-488
	# _tmp59 = _tmp58 < ZERO
	  ldq		$r1, -488($r15)	# fill _tmp58 to $r1 from $r15-488
	  cmplt		$r1, $r31, $r3	# perform the ALU op
	  stq		$r3, -496($r15)	# spill _tmp59 from $r3 to $r15-496
	# _tmp60 = *(values + -8)
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -504($r15)	# spill _tmp60 from $r3 to $r15-504
	# _tmp61 = _tmp60 <= _tmp58
	  ldq		$r1, -504($r15)	# fill _tmp60 to $r1 from $r15-504
	  ldq		$r2, -488($r15)	# fill _tmp58 to $r2 from $r15-488
	  cmple		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -512($r15)	# spill _tmp61 from $r3 to $r15-512
	# _tmp62 = _tmp59 || _tmp61
	  ldq		$r1, -496($r15)	# fill _tmp59 to $r1 from $r15-496
	  ldq		$r2, -512($r15)	# fill _tmp61 to $r2 from $r15-512
	  bis		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -520($r15)	# spill _tmp62 from $r3 to $r15-520
	# IfZ _tmp62 Goto __L8
	  ldq		$r1, -520($r15)	# fill _tmp62 to $r1 from $r15-520
	  blbc		$r1, __L8	# branch if _tmp62 is zero
	# Throw Exception: Array subscript out of bounds
	  call_pal	0xDECAF		# (exception: Array subscript out of bounds)
	  call_pal	0x555		# (halt)
__L8:
	# _tmp63 = _tmp58 << 3
	  ldq		$r1, -488($r15)	# fill _tmp58 to $r1 from $r15-488
	  sll		$r1, 3, $r3	# perform the ALU op
	  stq		$r3, -528($r15)	# spill _tmp63 from $r3 to $r15-528
	# _tmp64 = values + _tmp63
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r2, -528($r15)	# fill _tmp63 to $r2 from $r15-528
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -536($r15)	# spill _tmp64 from $r3 to $r15-536
	# _tmp65 = 7
	  lda		$r3, 7		# load (signed) int constant value 7 into $r3
	  stq		$r3, -544($r15)	# spill _tmp65 from $r3 to $r15-544
	# *(_tmp64) = _tmp65
	  ldq		$r1, -544($r15)	# fill _tmp65 to $r1 from $r15-544
	  ldq		$r3, -536($r15)	# fill _tmp64 to $r3 from $r15-536
	  stq		$r1, 0($r3)	# store with offset
	# _tmp66 = 7
	  lda		$r3, 7		# load (signed) int constant value 7 into $r3
	  stq		$r3, -552($r15)	# spill _tmp66 from $r3 to $r15-552
	# _tmp67 = _tmp66 < ZERO
	  ldq		$r1, -552($r15)	# fill _tmp66 to $r1 from $r15-552
	  cmplt		$r1, $r31, $r3	# perform the ALU op
	  stq		$r3, -560($r15)	# spill _tmp67 from $r3 to $r15-560
	# _tmp68 = *(values + -8)
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -568($r15)	# spill _tmp68 from $r3 to $r15-568
	# _tmp69 = _tmp68 <= _tmp66
	  ldq		$r1, -568($r15)	# fill _tmp68 to $r1 from $r15-568
	  ldq		$r2, -552($r15)	# fill _tmp66 to $r2 from $r15-552
	  cmple		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -576($r15)	# spill _tmp69 from $r3 to $r15-576
	# _tmp70 = _tmp67 || _tmp69
	  ldq		$r1, -560($r15)	# fill _tmp67 to $r1 from $r15-560
	  ldq		$r2, -576($r15)	# fill _tmp69 to $r2 from $r15-576
	  bis		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -584($r15)	# spill _tmp70 from $r3 to $r15-584
	# IfZ _tmp70 Goto __L9
	  ldq		$r1, -584($r15)	# fill _tmp70 to $r1 from $r15-584
	  blbc		$r1, __L9	# branch if _tmp70 is zero
	# Throw Exception: Array subscript out of bounds
	  call_pal	0xDECAF		# (exception: Array subscript out of bounds)
	  call_pal	0x555		# (halt)
__L9:
	# _tmp71 = _tmp66 << 3
	  ldq		$r1, -552($r15)	# fill _tmp66 to $r1 from $r15-552
	  sll		$r1, 3, $r3	# perform the ALU op
	  stq		$r3, -592($r15)	# spill _tmp71 from $r3 to $r15-592
	# _tmp72 = values + _tmp71
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r2, -592($r15)	# fill _tmp71 to $r2 from $r15-592
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -600($r15)	# spill _tmp72 from $r3 to $r15-600
	# _tmp73 = 8
	  lda		$r3, 8		# load (signed) int constant value 8 into $r3
	  stq		$r3, -608($r15)	# spill _tmp73 from $r3 to $r15-608
	# *(_tmp72) = _tmp73
	  ldq		$r1, -608($r15)	# fill _tmp73 to $r1 from $r15-608
	  ldq		$r3, -600($r15)	# fill _tmp72 to $r3 from $r15-600
	  stq		$r1, 0($r3)	# store with offset
	# _tmp74 = 8
	  lda		$r3, 8		# load (signed) int constant value 8 into $r3
	  stq		$r3, -616($r15)	# spill _tmp74 from $r3 to $r15-616
	# _tmp75 = _tmp74 < ZERO
	  ldq		$r1, -616($r15)	# fill _tmp74 to $r1 from $r15-616
	  cmplt		$r1, $r31, $r3	# perform the ALU op
	  stq		$r3, -624($r15)	# spill _tmp75 from $r3 to $r15-624
	# _tmp76 = *(values + -8)
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -632($r15)	# spill _tmp76 from $r3 to $r15-632
	# _tmp77 = _tmp76 <= _tmp74
	  ldq		$r1, -632($r15)	# fill _tmp76 to $r1 from $r15-632
	  ldq		$r2, -616($r15)	# fill _tmp74 to $r2 from $r15-616
	  cmple		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -640($r15)	# spill _tmp77 from $r3 to $r15-640
	# _tmp78 = _tmp75 || _tmp77
	  ldq		$r1, -624($r15)	# fill _tmp75 to $r1 from $r15-624
	  ldq		$r2, -640($r15)	# fill _tmp77 to $r2 from $r15-640
	  bis		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -648($r15)	# spill _tmp78 from $r3 to $r15-648
	# IfZ _tmp78 Goto __L10
	  ldq		$r1, -648($r15)	# fill _tmp78 to $r1 from $r15-648
	  blbc		$r1, __L10	# branch if _tmp78 is zero
	# Throw Exception: Array subscript out of bounds
	  call_pal	0xDECAF		# (exception: Array subscript out of bounds)
	  call_pal	0x555		# (halt)
__L10:
	# _tmp79 = _tmp74 << 3
	  ldq		$r1, -616($r15)	# fill _tmp74 to $r1 from $r15-616
	  sll		$r1, 3, $r3	# perform the ALU op
	  stq		$r3, -656($r15)	# spill _tmp79 from $r3 to $r15-656
	# _tmp80 = values + _tmp79
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r2, -656($r15)	# fill _tmp79 to $r2 from $r15-656
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -664($r15)	# spill _tmp80 from $r3 to $r15-664
	# _tmp81 = 9
	  lda		$r3, 9		# load (signed) int constant value 9 into $r3
	  stq		$r3, -672($r15)	# spill _tmp81 from $r3 to $r15-672
	# *(_tmp80) = _tmp81
	  ldq		$r1, -672($r15)	# fill _tmp81 to $r1 from $r15-672
	  ldq		$r3, -664($r15)	# fill _tmp80 to $r3 from $r15-664
	  stq		$r1, 0($r3)	# store with offset
	# _tmp82 = 9
	  lda		$r3, 9		# load (signed) int constant value 9 into $r3
	  stq		$r3, -680($r15)	# spill _tmp82 from $r3 to $r15-680
	# _tmp83 = _tmp82 < ZERO
	  ldq		$r1, -680($r15)	# fill _tmp82 to $r1 from $r15-680
	  cmplt		$r1, $r31, $r3	# perform the ALU op
	  stq		$r3, -688($r15)	# spill _tmp83 from $r3 to $r15-688
	# _tmp84 = *(values + -8)
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -696($r15)	# spill _tmp84 from $r3 to $r15-696
	# _tmp85 = _tmp84 <= _tmp82
	  ldq		$r1, -696($r15)	# fill _tmp84 to $r1 from $r15-696
	  ldq		$r2, -680($r15)	# fill _tmp82 to $r2 from $r15-680
	  cmple		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -704($r15)	# spill _tmp85 from $r3 to $r15-704
	# _tmp86 = _tmp83 || _tmp85
	  ldq		$r1, -688($r15)	# fill _tmp83 to $r1 from $r15-688
	  ldq		$r2, -704($r15)	# fill _tmp85 to $r2 from $r15-704
	  bis		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -712($r15)	# spill _tmp86 from $r3 to $r15-712
	# IfZ _tmp86 Goto __L11
	  ldq		$r1, -712($r15)	# fill _tmp86 to $r1 from $r15-712
	  blbc		$r1, __L11	# branch if _tmp86 is zero
	# Throw Exception: Array subscript out of bounds
	  call_pal	0xDECAF		# (exception: Array subscript out of bounds)
	  call_pal	0x555		# (halt)
__L11:
	# _tmp87 = _tmp82 << 3
	  ldq		$r1, -680($r15)	# fill _tmp82 to $r1 from $r15-680
	  sll		$r1, 3, $r3	# perform the ALU op
	  stq		$r3, -720($r15)	# spill _tmp87 from $r3 to $r15-720
	# _tmp88 = values + _tmp87
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r2, -720($r15)	# fill _tmp87 to $r2 from $r15-720
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -728($r15)	# spill _tmp88 from $r3 to $r15-728
	# _tmp89 = 10
	  lda		$r3, 10		# load (signed) int constant value 10 into $r3
	  stq		$r3, -736($r15)	# spill _tmp89 from $r3 to $r15-736
	# *(_tmp88) = _tmp89
	  ldq		$r1, -736($r15)	# fill _tmp89 to $r1 from $r15-736
	  ldq		$r3, -728($r15)	# fill _tmp88 to $r3 from $r15-728
	  stq		$r1, 0($r3)	# store with offset
	# _tmp90 = 10
	  lda		$r3, 10		# load (signed) int constant value 10 into $r3
	  stq		$r3, -744($r15)	# spill _tmp90 from $r3 to $r15-744
	# _tmp91 = _tmp90 < ZERO
	  ldq		$r1, -744($r15)	# fill _tmp90 to $r1 from $r15-744
	  cmplt		$r1, $r31, $r3	# perform the ALU op
	  stq		$r3, -752($r15)	# spill _tmp91 from $r3 to $r15-752
	# _tmp92 = *(values + -8)
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -760($r15)	# spill _tmp92 from $r3 to $r15-760
	# _tmp93 = _tmp92 <= _tmp90
	  ldq		$r1, -760($r15)	# fill _tmp92 to $r1 from $r15-760
	  ldq		$r2, -744($r15)	# fill _tmp90 to $r2 from $r15-744
	  cmple		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -768($r15)	# spill _tmp93 from $r3 to $r15-768
	# _tmp94 = _tmp91 || _tmp93
	  ldq		$r1, -752($r15)	# fill _tmp91 to $r1 from $r15-752
	  ldq		$r2, -768($r15)	# fill _tmp93 to $r2 from $r15-768
	  bis		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -776($r15)	# spill _tmp94 from $r3 to $r15-776
	# IfZ _tmp94 Goto __L12
	  ldq		$r1, -776($r15)	# fill _tmp94 to $r1 from $r15-776
	  blbc		$r1, __L12	# branch if _tmp94 is zero
	# Throw Exception: Array subscript out of bounds
	  call_pal	0xDECAF		# (exception: Array subscript out of bounds)
	  call_pal	0x555		# (halt)
__L12:
	# _tmp95 = _tmp90 << 3
	  ldq		$r1, -744($r15)	# fill _tmp90 to $r1 from $r15-744
	  sll		$r1, 3, $r3	# perform the ALU op
	  stq		$r3, -784($r15)	# spill _tmp95 from $r3 to $r15-784
	# _tmp96 = values + _tmp95
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r2, -784($r15)	# fill _tmp95 to $r2 from $r15-784
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -792($r15)	# spill _tmp96 from $r3 to $r15-792
	# _tmp97 = 11
	  lda		$r3, 11		# load (signed) int constant value 11 into $r3
	  stq		$r3, -800($r15)	# spill _tmp97 from $r3 to $r15-800
	# *(_tmp96) = _tmp97
	  ldq		$r1, -800($r15)	# fill _tmp97 to $r1 from $r15-800
	  ldq		$r3, -792($r15)	# fill _tmp96 to $r3 from $r15-792
	  stq		$r1, 0($r3)	# store with offset
	# _tmp98 = 11
	  lda		$r3, 11		# load (signed) int constant value 11 into $r3
	  stq		$r3, -808($r15)	# spill _tmp98 from $r3 to $r15-808
	# _tmp99 = _tmp98 < ZERO
	  ldq		$r1, -808($r15)	# fill _tmp98 to $r1 from $r15-808
	  cmplt		$r1, $r31, $r3	# perform the ALU op
	  stq		$r3, -816($r15)	# spill _tmp99 from $r3 to $r15-816
	# _tmp100 = *(values + -8)
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -824($r15)	# spill _tmp100 from $r3 to $r15-824
	# _tmp101 = _tmp100 <= _tmp98
	  ldq		$r1, -824($r15)	# fill _tmp100 to $r1 from $r15-824
	  ldq		$r2, -808($r15)	# fill _tmp98 to $r2 from $r15-808
	  cmple		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -832($r15)	# spill _tmp101 from $r3 to $r15-832
	# _tmp102 = _tmp99 || _tmp101
	  ldq		$r1, -816($r15)	# fill _tmp99 to $r1 from $r15-816
	  ldq		$r2, -832($r15)	# fill _tmp101 to $r2 from $r15-832
	  bis		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -840($r15)	# spill _tmp102 from $r3 to $r15-840
	# IfZ _tmp102 Goto __L13
	  ldq		$r1, -840($r15)	# fill _tmp102 to $r1 from $r15-840
	  blbc		$r1, __L13	# branch if _tmp102 is zero
	# Throw Exception: Array subscript out of bounds
	  call_pal	0xDECAF		# (exception: Array subscript out of bounds)
	  call_pal	0x555		# (halt)
__L13:
	# _tmp103 = _tmp98 << 3
	  ldq		$r1, -808($r15)	# fill _tmp98 to $r1 from $r15-808
	  sll		$r1, 3, $r3	# perform the ALU op
	  stq		$r3, -848($r15)	# spill _tmp103 from $r3 to $r15-848
	# _tmp104 = values + _tmp103
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r2, -848($r15)	# fill _tmp103 to $r2 from $r15-848
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -856($r15)	# spill _tmp104 from $r3 to $r15-856
	# _tmp105 = 12
	  lda		$r3, 12		# load (signed) int constant value 12 into $r3
	  stq		$r3, -864($r15)	# spill _tmp105 from $r3 to $r15-864
	# *(_tmp104) = _tmp105
	  ldq		$r1, -864($r15)	# fill _tmp105 to $r1 from $r15-864
	  ldq		$r3, -856($r15)	# fill _tmp104 to $r3 from $r15-856
	  stq		$r1, 0($r3)	# store with offset
	# _tmp106 = 12
	  lda		$r3, 12		# load (signed) int constant value 12 into $r3
	  stq		$r3, -872($r15)	# spill _tmp106 from $r3 to $r15-872
	# _tmp107 = _tmp106 < ZERO
	  ldq		$r1, -872($r15)	# fill _tmp106 to $r1 from $r15-872
	  cmplt		$r1, $r31, $r3	# perform the ALU op
	  stq		$r3, -880($r15)	# spill _tmp107 from $r3 to $r15-880
	# _tmp108 = *(values + -8)
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -888($r15)	# spill _tmp108 from $r3 to $r15-888
	# _tmp109 = _tmp108 <= _tmp106
	  ldq		$r1, -888($r15)	# fill _tmp108 to $r1 from $r15-888
	  ldq		$r2, -872($r15)	# fill _tmp106 to $r2 from $r15-872
	  cmple		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -896($r15)	# spill _tmp109 from $r3 to $r15-896
	# _tmp110 = _tmp107 || _tmp109
	  ldq		$r1, -880($r15)	# fill _tmp107 to $r1 from $r15-880
	  ldq		$r2, -896($r15)	# fill _tmp109 to $r2 from $r15-896
	  bis		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -904($r15)	# spill _tmp110 from $r3 to $r15-904
	# IfZ _tmp110 Goto __L14
	  ldq		$r1, -904($r15)	# fill _tmp110 to $r1 from $r15-904
	  blbc		$r1, __L14	# branch if _tmp110 is zero
	# Throw Exception: Array subscript out of bounds
	  call_pal	0xDECAF		# (exception: Array subscript out of bounds)
	  call_pal	0x555		# (halt)
__L14:
	# _tmp111 = _tmp106 << 3
	  ldq		$r1, -872($r15)	# fill _tmp106 to $r1 from $r15-872
	  sll		$r1, 3, $r3	# perform the ALU op
	  stq		$r3, -912($r15)	# spill _tmp111 from $r3 to $r15-912
	# _tmp112 = values + _tmp111
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r2, -912($r15)	# fill _tmp111 to $r2 from $r15-912
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -920($r15)	# spill _tmp112 from $r3 to $r15-920
	# _tmp113 = 13
	  lda		$r3, 13		# load (signed) int constant value 13 into $r3
	  stq		$r3, -928($r15)	# spill _tmp113 from $r3 to $r15-928
	# *(_tmp112) = _tmp113
	  ldq		$r1, -928($r15)	# fill _tmp113 to $r1 from $r15-928
	  ldq		$r3, -920($r15)	# fill _tmp112 to $r3 from $r15-920
	  stq		$r1, 0($r3)	# store with offset
	# _tmp114 = 13
	  lda		$r3, 13		# load (signed) int constant value 13 into $r3
	  stq		$r3, -936($r15)	# spill _tmp114 from $r3 to $r15-936
	# _tmp115 = _tmp114 < ZERO
	  ldq		$r1, -936($r15)	# fill _tmp114 to $r1 from $r15-936
	  cmplt		$r1, $r31, $r3	# perform the ALU op
	  stq		$r3, -944($r15)	# spill _tmp115 from $r3 to $r15-944
	# _tmp116 = *(values + -8)
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -952($r15)	# spill _tmp116 from $r3 to $r15-952
	# _tmp117 = _tmp116 <= _tmp114
	  ldq		$r1, -952($r15)	# fill _tmp116 to $r1 from $r15-952
	  ldq		$r2, -936($r15)	# fill _tmp114 to $r2 from $r15-936
	  cmple		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -960($r15)	# spill _tmp117 from $r3 to $r15-960
	# _tmp118 = _tmp115 || _tmp117
	  ldq		$r1, -944($r15)	# fill _tmp115 to $r1 from $r15-944
	  ldq		$r2, -960($r15)	# fill _tmp117 to $r2 from $r15-960
	  bis		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -968($r15)	# spill _tmp118 from $r3 to $r15-968
	# IfZ _tmp118 Goto __L15
	  ldq		$r1, -968($r15)	# fill _tmp118 to $r1 from $r15-968
	  blbc		$r1, __L15	# branch if _tmp118 is zero
	# Throw Exception: Array subscript out of bounds
	  call_pal	0xDECAF		# (exception: Array subscript out of bounds)
	  call_pal	0x555		# (halt)
__L15:
	# _tmp119 = _tmp114 << 3
	  ldq		$r1, -936($r15)	# fill _tmp114 to $r1 from $r15-936
	  sll		$r1, 3, $r3	# perform the ALU op
	  stq		$r3, -976($r15)	# spill _tmp119 from $r3 to $r15-976
	# _tmp120 = values + _tmp119
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r2, -976($r15)	# fill _tmp119 to $r2 from $r15-976
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -984($r15)	# spill _tmp120 from $r3 to $r15-984
	# _tmp121 = 14
	  lda		$r3, 14		# load (signed) int constant value 14 into $r3
	  stq		$r3, -992($r15)	# spill _tmp121 from $r3 to $r15-992
	# *(_tmp120) = _tmp121
	  ldq		$r1, -992($r15)	# fill _tmp121 to $r1 from $r15-992
	  ldq		$r3, -984($r15)	# fill _tmp120 to $r3 from $r15-984
	  stq		$r1, 0($r3)	# store with offset
	# _tmp122 = 14
	  lda		$r3, 14		# load (signed) int constant value 14 into $r3
	  stq		$r3, -1000($r15)	# spill _tmp122 from $r3 to $r15-1000
	# _tmp123 = _tmp122 < ZERO
	  ldq		$r1, -1000($r15)	# fill _tmp122 to $r1 from $r15-1000
	  cmplt		$r1, $r31, $r3	# perform the ALU op
	  stq		$r3, -1008($r15)	# spill _tmp123 from $r3 to $r15-1008
	# _tmp124 = *(values + -8)
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -1016($r15)	# spill _tmp124 from $r3 to $r15-1016
	# _tmp125 = _tmp124 <= _tmp122
	  ldq		$r1, -1016($r15)	# fill _tmp124 to $r1 from $r15-1016
	  ldq		$r2, -1000($r15)	# fill _tmp122 to $r2 from $r15-1000
	  cmple		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -1024($r15)	# spill _tmp125 from $r3 to $r15-1024
	# _tmp126 = _tmp123 || _tmp125
	  ldq		$r1, -1008($r15)	# fill _tmp123 to $r1 from $r15-1008
	  ldq		$r2, -1024($r15)	# fill _tmp125 to $r2 from $r15-1024
	  bis		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -1032($r15)	# spill _tmp126 from $r3 to $r15-1032
	# IfZ _tmp126 Goto __L16
	  ldq		$r1, -1032($r15)	# fill _tmp126 to $r1 from $r15-1032
	  blbc		$r1, __L16	# branch if _tmp126 is zero
	# Throw Exception: Array subscript out of bounds
	  call_pal	0xDECAF		# (exception: Array subscript out of bounds)
	  call_pal	0x555		# (halt)
__L16:
	# _tmp127 = _tmp122 << 3
	  ldq		$r1, -1000($r15)	# fill _tmp122 to $r1 from $r15-1000
	  sll		$r1, 3, $r3	# perform the ALU op
	  stq		$r3, -1040($r15)	# spill _tmp127 from $r3 to $r15-1040
	# _tmp128 = values + _tmp127
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r2, -1040($r15)	# fill _tmp127 to $r2 from $r15-1040
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -1048($r15)	# spill _tmp128 from $r3 to $r15-1048
	# _tmp129 = 15
	  lda		$r3, 15		# load (signed) int constant value 15 into $r3
	  stq		$r3, -1056($r15)	# spill _tmp129 from $r3 to $r15-1056
	# *(_tmp128) = _tmp129
	  ldq		$r1, -1056($r15)	# fill _tmp129 to $r1 from $r15-1056
	  ldq		$r3, -1048($r15)	# fill _tmp128 to $r3 from $r15-1048
	  stq		$r1, 0($r3)	# store with offset
	# _tmp130 = 15
	  lda		$r3, 15		# load (signed) int constant value 15 into $r3
	  stq		$r3, -1064($r15)	# spill _tmp130 from $r3 to $r15-1064
	# _tmp131 = _tmp130 < ZERO
	  ldq		$r1, -1064($r15)	# fill _tmp130 to $r1 from $r15-1064
	  cmplt		$r1, $r31, $r3	# perform the ALU op
	  stq		$r3, -1072($r15)	# spill _tmp131 from $r3 to $r15-1072
	# _tmp132 = *(values + -8)
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -1080($r15)	# spill _tmp132 from $r3 to $r15-1080
	# _tmp133 = _tmp132 <= _tmp130
	  ldq		$r1, -1080($r15)	# fill _tmp132 to $r1 from $r15-1080
	  ldq		$r2, -1064($r15)	# fill _tmp130 to $r2 from $r15-1064
	  cmple		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -1088($r15)	# spill _tmp133 from $r3 to $r15-1088
	# _tmp134 = _tmp131 || _tmp133
	  ldq		$r1, -1072($r15)	# fill _tmp131 to $r1 from $r15-1072
	  ldq		$r2, -1088($r15)	# fill _tmp133 to $r2 from $r15-1088
	  bis		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -1096($r15)	# spill _tmp134 from $r3 to $r15-1096
	# IfZ _tmp134 Goto __L17
	  ldq		$r1, -1096($r15)	# fill _tmp134 to $r1 from $r15-1096
	  blbc		$r1, __L17	# branch if _tmp134 is zero
	# Throw Exception: Array subscript out of bounds
	  call_pal	0xDECAF		# (exception: Array subscript out of bounds)
	  call_pal	0x555		# (halt)
__L17:
	# _tmp135 = _tmp130 << 3
	  ldq		$r1, -1064($r15)	# fill _tmp130 to $r1 from $r15-1064
	  sll		$r1, 3, $r3	# perform the ALU op
	  stq		$r3, -1104($r15)	# spill _tmp135 from $r3 to $r15-1104
	# _tmp136 = values + _tmp135
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r2, -1104($r15)	# fill _tmp135 to $r2 from $r15-1104
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -1112($r15)	# spill _tmp136 from $r3 to $r15-1112
	# _tmp137 = 16
	  lda		$r3, 16		# load (signed) int constant value 16 into $r3
	  stq		$r3, -1120($r15)	# spill _tmp137 from $r3 to $r15-1120
	# *(_tmp136) = _tmp137
	  ldq		$r1, -1120($r15)	# fill _tmp137 to $r1 from $r15-1120
	  ldq		$r3, -1112($r15)	# fill _tmp136 to $r3 from $r15-1112
	  stq		$r1, 0($r3)	# store with offset
	# _tmp138 = 0
	  lda		$r3, 0		# load (signed) int constant value 0 into $r3
	  stq		$r3, -1128($r15)	# spill _tmp138 from $r3 to $r15-1128
	# i = _tmp138
	  ldq		$r3, -1128($r15)	# fill _tmp138 to $r3 from $r15-1128
	  stq		$r3, -16($r15)	# spill i from $r3 to $r15-16
__L18:
	# _tmp139 = 15
	  lda		$r3, 15		# load (signed) int constant value 15 into $r3
	  stq		$r3, -1136($r15)	# spill _tmp139 from $r3 to $r15-1136
	# _tmp140 = i < _tmp139
	  ldq		$r1, -16($r15)	# fill i to $r1 from $r15-16
	  ldq		$r2, -1136($r15)	# fill _tmp139 to $r2 from $r15-1136
	  cmplt		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -1144($r15)	# spill _tmp140 from $r3 to $r15-1144
	# IfZ _tmp140 Goto __L19
	  ldq		$r1, -1144($r15)	# fill _tmp140 to $r1 from $r15-1144
	  blbc		$r1, __L19	# branch if _tmp140 is zero
__L20:
	# _tmp141 = i < ZERO
	  ldq		$r1, -16($r15)	# fill i to $r1 from $r15-16
	  cmplt		$r1, $r31, $r3	# perform the ALU op
	  stq		$r3, -1152($r15)	# spill _tmp141 from $r3 to $r15-1152
	# _tmp142 = *(values + -8)
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -1160($r15)	# spill _tmp142 from $r3 to $r15-1160
	# _tmp143 = _tmp142 <= i
	  ldq		$r1, -1160($r15)	# fill _tmp142 to $r1 from $r15-1160
	  ldq		$r2, -16($r15)	# fill i to $r2 from $r15-16
	  cmple		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -1168($r15)	# spill _tmp143 from $r3 to $r15-1168
	# _tmp144 = _tmp141 || _tmp143
	  ldq		$r1, -1152($r15)	# fill _tmp141 to $r1 from $r15-1152
	  ldq		$r2, -1168($r15)	# fill _tmp143 to $r2 from $r15-1168
	  bis		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -1176($r15)	# spill _tmp144 from $r3 to $r15-1176
	# IfZ _tmp144 Goto __L22
	  ldq		$r1, -1176($r15)	# fill _tmp144 to $r1 from $r15-1176
	  blbc		$r1, __L22	# branch if _tmp144 is zero
	# Throw Exception: Array subscript out of bounds
	  call_pal	0xDECAF		# (exception: Array subscript out of bounds)
	  call_pal	0x555		# (halt)
__L22:
	# _tmp145 = i << 3
	  ldq		$r1, -16($r15)	# fill i to $r1 from $r15-16
	  sll		$r1, 3, $r3	# perform the ALU op
	  stq		$r3, -1184($r15)	# spill _tmp145 from $r3 to $r15-1184
	# _tmp146 = values + _tmp145
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r2, -1184($r15)	# fill _tmp145 to $r2 from $r15-1184
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -1192($r15)	# spill _tmp146 from $r3 to $r15-1192
	# _tmp147 = *(_tmp146)
	  ldq		$r1, -1192($r15)	# fill _tmp146 to $r1 from $r15-1192
	  ldq		$r3, 0($r1)	# load with offset
	  stq		$r3, -1200($r15)	# spill _tmp147 from $r3 to $r15-1200
	# _tmp148 = 1
	  lda		$r3, 1		# load (signed) int constant value 1 into $r3
	  stq		$r3, -1208($r15)	# spill _tmp148 from $r3 to $r15-1208
	# _tmp149 = _tmp148 <= _tmp147
	  ldq		$r1, -1208($r15)	# fill _tmp148 to $r1 from $r15-1208
	  ldq		$r2, -1200($r15)	# fill _tmp147 to $r2 from $r15-1200
	  cmple		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -1216($r15)	# spill _tmp149 from $r3 to $r15-1216
	# IfZ _tmp149 Goto __L21
	  ldq		$r1, -1216($r15)	# fill _tmp149 to $r1 from $r15-1216
	  blbc		$r1, __L21	# branch if _tmp149 is zero
	# _tmp150 = i < ZERO
	  ldq		$r1, -16($r15)	# fill i to $r1 from $r15-16
	  cmplt		$r1, $r31, $r3	# perform the ALU op
	  stq		$r3, -1224($r15)	# spill _tmp150 from $r3 to $r15-1224
	# _tmp151 = *(values + -8)
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -1232($r15)	# spill _tmp151 from $r3 to $r15-1232
	# _tmp152 = _tmp151 <= i
	  ldq		$r1, -1232($r15)	# fill _tmp151 to $r1 from $r15-1232
	  ldq		$r2, -16($r15)	# fill i to $r2 from $r15-16
	  cmple		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -1240($r15)	# spill _tmp152 from $r3 to $r15-1240
	# _tmp153 = _tmp150 || _tmp152
	  ldq		$r1, -1224($r15)	# fill _tmp150 to $r1 from $r15-1224
	  ldq		$r2, -1240($r15)	# fill _tmp152 to $r2 from $r15-1240
	  bis		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -1248($r15)	# spill _tmp153 from $r3 to $r15-1248
	# IfZ _tmp153 Goto __L23
	  ldq		$r1, -1248($r15)	# fill _tmp153 to $r1 from $r15-1248
	  blbc		$r1, __L23	# branch if _tmp153 is zero
	# Throw Exception: Array subscript out of bounds
	  call_pal	0xDECAF		# (exception: Array subscript out of bounds)
	  call_pal	0x555		# (halt)
__L23:
	# _tmp154 = i << 3
	  ldq		$r1, -16($r15)	# fill i to $r1 from $r15-16
	  sll		$r1, 3, $r3	# perform the ALU op
	  stq		$r3, -1256($r15)	# spill _tmp154 from $r3 to $r15-1256
	# _tmp155 = values + _tmp154
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r2, -1256($r15)	# fill _tmp154 to $r2 from $r15-1256
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -1264($r15)	# spill _tmp155 from $r3 to $r15-1264
	# _tmp156 = i < ZERO
	  ldq		$r1, -16($r15)	# fill i to $r1 from $r15-16
	  cmplt		$r1, $r31, $r3	# perform the ALU op
	  stq		$r3, -1272($r15)	# spill _tmp156 from $r3 to $r15-1272
	# _tmp157 = *(values + -8)
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r3, -8($r1)	# load with offset
	  stq		$r3, -1280($r15)	# spill _tmp157 from $r3 to $r15-1280
	# _tmp158 = _tmp157 <= i
	  ldq		$r1, -1280($r15)	# fill _tmp157 to $r1 from $r15-1280
	  ldq		$r2, -16($r15)	# fill i to $r2 from $r15-16
	  cmple		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -1288($r15)	# spill _tmp158 from $r3 to $r15-1288
	# _tmp159 = _tmp156 || _tmp158
	  ldq		$r1, -1272($r15)	# fill _tmp156 to $r1 from $r15-1272
	  ldq		$r2, -1288($r15)	# fill _tmp158 to $r2 from $r15-1288
	  bis		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -1296($r15)	# spill _tmp159 from $r3 to $r15-1296
	# IfZ _tmp159 Goto __L24
	  ldq		$r1, -1296($r15)	# fill _tmp159 to $r1 from $r15-1296
	  blbc		$r1, __L24	# branch if _tmp159 is zero
	# Throw Exception: Array subscript out of bounds
	  call_pal	0xDECAF		# (exception: Array subscript out of bounds)
	  call_pal	0x555		# (halt)
__L24:
	# _tmp160 = i << 3
	  ldq		$r1, -16($r15)	# fill i to $r1 from $r15-16
	  sll		$r1, 3, $r3	# perform the ALU op
	  stq		$r3, -1304($r15)	# spill _tmp160 from $r3 to $r15-1304
	# _tmp161 = values + _tmp160
	  ldq		$r1, 0($r29)	# fill values to $r1 from $r29+0
	  ldq		$r2, -1304($r15)	# fill _tmp160 to $r2 from $r15-1304
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -1312($r15)	# spill _tmp161 from $r3 to $r15-1312
	# _tmp162 = *(_tmp161)
	  ldq		$r1, -1312($r15)	# fill _tmp161 to $r1 from $r15-1312
	  ldq		$r3, 0($r1)	# load with offset
	  stq		$r3, -1320($r15)	# spill _tmp162 from $r3 to $r15-1320
	# _tmp163 = 1
	  lda		$r3, 1		# load (signed) int constant value 1 into $r3
	  stq		$r3, -1328($r15)	# spill _tmp163 from $r3 to $r15-1328
	# _tmp164 = _tmp162 - _tmp163
	  ldq		$r1, -1320($r15)	# fill _tmp162 to $r1 from $r15-1320
	  ldq		$r2, -1328($r15)	# fill _tmp163 to $r2 from $r15-1328
	  subq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -1336($r15)	# spill _tmp164 from $r3 to $r15-1336
	# *(_tmp155) = _tmp164
	  ldq		$r1, -1336($r15)	# fill _tmp164 to $r1 from $r15-1336
	  ldq		$r3, -1264($r15)	# fill _tmp155 to $r3 from $r15-1264
	  stq		$r1, 0($r3)	# store with offset
	# Goto __L20
	  br		__L20		# unconditional branch
__L21:
	# _tmp165 = 1
	  lda		$r3, 1		# load (signed) int constant value 1 into $r3
	  stq		$r3, -1344($r15)	# spill _tmp165 from $r3 to $r15-1344
	# _tmp166 = i + _tmp165
	  ldq		$r1, -16($r15)	# fill i to $r1 from $r15-16
	  ldq		$r2, -1344($r15)	# fill _tmp165 to $r2 from $r15-1344
	  addq		$r1, $r2, $r3	# perform the ALU op
	  stq		$r3, -1352($r15)	# spill _tmp166 from $r3 to $r15-1352
	# i = _tmp166
	  ldq		$r3, -1352($r15)	# fill _tmp166 to $r3 from $r15-1352
	  stq		$r3, -16($r15)	# spill i from $r3 to $r15-16
	# Goto __L18
	  br		__L18		# unconditional branch
__L19:
	# EndFunc
	# (below handles reaching end of fn body with no explicit return)
	  mov		$r15, $r30	# pop callee frame off stack
	  ldq		$r26, -8($r15)	# restore saved ra
	  ldq		$r15, 0($r15)	# restore saved fp
	  ret				# return from function
	# EndProgram
	#
	# (below is reserved for auto-appending of built-in functions)
	#
__Alloc:
	  ldq		$r16, 8($r30)	# fill arg0 to $r16 from $r30+8
	#
	# $r28 holds addr of heap-start
	# $r16 is the number of lines we want
	# $r1 holds the number of lines remaining to be allocated
	# $r2 holds the curent heap-table-entry
	# $r3 holds temp results of various comparisons
	# $r4 is used to generate various bit-masks
	# $r24 holds the current starting "bit-addr" in the heap-table
	# $r25 holds the bit-pos within the current heap-table-entry
	# $r27 holds the addr of the current heap-table-entry
	#
	  lda		$r4, 0x100
	  subq		$r28, $r4, $r27	# make addr of heap-table start
    __AllocFullReset:
	  mov		$r16, $r1	# reset goal amount
	  sll		$r27, 3, $r24	# reset bit-addr into heap-table
	  clr		$r25		# clear bit-pos marker
    __AllocSearchStart:
	  cmpult	$r27, $r28, $r3	# check if pass end of heap-table
	  blbc		$r3, __AllocReturnFail
	  ldq		$r2, 0($r27)	# dereference, to get current heap-table entry
	  cmpult	$r1, 64, $r3	# less than a page to allocate?
	  blbs		$r3, __AllocSearchStartLittle
	  blt		$r2, __AllocSearchStartSetup	# MSB set?
	  lda		$r4, -1		# for next code-block
    __AllocSearchStartShift:
	  and		$r2, $r4, $r3
	  beq		$r3, __AllocSearchStartDone
	  sll		$r4, 1, $r4
	  addq		$r24, 1, $r24
	  and		$r24, 63, $r25
	  bne		$r25, __AllocSearchStartShift
    __AllocSearchStartSetup:
	  srl		$r24, 6, $r27
	  sll		$r27, 3, $r27
	  br		__AllocSearchStart	# unconditional branch
    __AllocSearchStartLittle:
	  lda		$r4, 1
	  sll		$r4, $r1, $r4
	  subq		$r4, 1, $r4
	  br		__AllocSearchStartShift	# unconditional branch
    __AllocSearchStartDone:
	  subq		$r1, 64, $r1
	  addq		$r1, $r25, $r1
	  bgt		$r1, __AllocNotSimple
    __AllocSimpleCommit:
	  bis		$r2, $r4, $r2
	  stq		$r2, 0($r27)
	  br		__AllocReturnGood	# unconditional branch
    __AllocNotSimple:
	  srl		$r24, 6, $r27
	  sll		$r27, 3, $r27
    __AllocSearchBlock:
	  cmpult	$r1, 64, $r3
	  blbs		$r3, __AllocSearchEnd
	  addq		$r27, 8, $r27	# next heap-table entry
	  cmpult	$r27, $r28, $r3	# check if pass end of heap-table
	  blbc		$r3, __AllocReturnFail
	  ldq		$r2, 0($r27)	# dereference, to get current heap-table entry
	  bne		$r2, __AllocFullReset
	  subq		$r1, 64, $r1
	  br		__AllocSearchBlock	# unconditional branch
    __AllocSearchEnd:
	  beq		$r1,__AllocCommitStart
	  addq		$r27, 8, $r27	# next heap-table entry
	  cmpult	$r27, $r28, $r3	# check if pass end of heap-table
	  blbc		$r3, __AllocReturnFail
	  ldq		$r2, 0($r27)	# dereference, to get current heap-table entry
	  lda		$r4, 1
	  sll		$r4, $r1, $r4
	  subq		$r4, 1, $r4
	  and		$r2, $r4, $r3
	  bne		$r3, __AllocFullReset
    __AllocCommitEnd:
	  bis		$r2, $r4, $r2
	  stq		$r2, 0($r27)
	  subq		$r16, $r1, $r16
    __AllocCommitStart:
	  srl		$r24, 6, $r27
	  sll		$r27, 3, $r27
	  ldq		$r2, 0($r27)
	  lda		$r4, -1
	  sll		$r4, $r25, $r4
	  bis		$r2, $r4, $r2
	  stq		$r2, 0($r27)
	  subq		$r16, 64, $r16
	  addq		$r16, $r25, $r16
	  lda		$r4, -1		# for next code-block
    __AllocCommitBlock:
	  cmpult	$r16, 64, $r3
	  blbs		$r3, __AllocReturnCheck
	  addq		$r27, 8, $r27	# next heap-table entry
	  stq		$r4, 0($r27)	# set all bits in that entry
	  subq		$r16, 64, $r16
	  br		__AllocCommitBlock	# unconditional branch
    __AllocReturnCheck:
	  beq		$r16, __AllocReturnGood	# verify we are done
	  call_pal	0xDECAF		# (exception: this really should not happen in Malloc)
	  call_pal	0x555		# (halt)
    __AllocReturnGood:
	# magically compute address for return value
	  lda		$r0, 0x2F
	  sll		$r0, 13, $r0
	  subq		$r24, $r0, $r0
	  sll		$r0, 3, $r0
	  ret				# return to caller
    __AllocReturnFail:
	  call_pal	0xDECAF		# (exception: Malloc failed to find space in heap)
	  call_pal	0x555		# (halt)
	# EndFunc
