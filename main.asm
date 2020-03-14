#################################################################
# 			 Kacper Kipa				#
# 			Madlebrot set				#
#################################################################

#################################################################
#			Useful macros				#
#################################################################
.eqv DIVIDER	1000	# Its in how many parts 1 coordinate will be divided to avoid using floats

.eqv BLACK_0	0x00
.eqv BLACK_1	0x1a
.eqv BLACK_2	0x33
.eqv BLACK_3	0x4d
.eqv BLACK_4	0x66
.eqv GRAY	0x80
.eqv WHITE_4	0x99
.eqv WHITE_3	0xb3
.eqv WHITE_2	0xcc
.eqv WHITE_1	0xe6
.eqv WHITE_0	0xFF

#################################################################
#				Data				#
#################################################################
	.data
err_msg:.asciiz "Error occurs while processing file! :("
file:	.asciiz "mandelbrot_set.bmp"
buffer:	.space 54

	.text
	.globl main

main:

#################################################################
#		Opening file and reading header			#
#################################################################
	li $v0, 13	# Open file
	la $a0, file
	li $a1, 0	# Read-only flag
	li $a2, 0
	syscall
	
	bltz $v0, error
	move $a0, $v0
	li $v0, 14	# Read file
	la $a1, buffer
	li $a2, 54
	syscall
	
	li $v0, 16	# Close file
	syscall
	
	lw $s0, buffer + 18	# $s0 = width
	lw $s1, buffer + 22	# $s1 = height
	
#################################################################
#			Memory allocation			#
#################################################################
	li $t0, 3	# Count memory size (pixels and padding)
	multu $s0, $t0
	mflo $t0
	li $t1, 4
	divu $t0, $t1
	mfhi $t1
	beq $t1, 0x0, pad_0	# pad = 0
	beq $t1, 0x1, pad_1	# pad = 1
	beq $t1, 0x2, pad_2	# pad = 2
	beq $t1, 0x3, pad_3	# pad = 3

pad_0:
	li $s3, 0	# $s3 = padding
	j allocate
		
pad_1:
	li $s3, 1	# $s3 = padding
	addiu $t0, $t0, 1
	j allocate
	
pad_2:
	li $s3, 2	# $s3 = padding
	addiu $t0, $t0, 2
	j allocate

pad_3:
	li $s3, 3	# $s3 = padding
	addiu $t0, $t0, 1
	j allocate
	
allocate:
	multu $s1, $t0
	mflo $s2	# $s2 = size
	li $v0, 9
	move $a0, $s2
	syscall
	move $s4, $v0	# $s4 = address of heap memory
	
	
#################################################################
#	    Scaling and assigned values to points		#
#################################################################
	li $t0, 3	# Intervals for scaling
	li $t1, 2
	divu $s0, $t0
	mflo $s5
	mfhi $s7	# $s7 rest after dividing
	divu $s1, $t1
	mflo $s6
	li $t2, DIVIDER
	divu $t2, $s5
	mflo $t3	# $t3 = 1000/(width/3)
	divu $t2, $s6
	mflo $t4	# $t4 = 1000/(height/2)
	
	li $t8, 2	# Getting left-down corner's pixel coordinates
	multu $s5, $t8
	mflo $t8
	subiu $t8, $t8, 1
	subiu $t9, $s6, 1
	
	not $t8, $t8
	addiu $t8, $t8, 1
	not $t9, $t9
	addiu $t9, $t9, 1	# ($t8, $t9) = (x, y)
	move $t2, $s4		# Move heap address to temporary register
	
	sub $t0, $s0, 54
	li $t7, BLACK_0
fill_header:
	bgt $t0, $s0, loop_on_every_pixel
	sb $t7, 0($t2)
	addiu $t0, $t0, 1
	addiu $t2, $t2, 1
	j fill_header
	
	
#################################################################
#		     Loop on every pixel			#
#################################################################
loop_on_every_pixel:
	multu $t3, $t8	# Compute coordinates of pixel 
	mflo $a0
	multu $t4, $t9
	mflo $a1	# ($a0, $a1) = ( val(x), val(y) )
	jal mandelbrot	# Compute value of Mandelbrot set in this point
	addiu $t8, $t8, 1
	bgt $t8, $s5, one_row_up_rest	# Check if next pixel is in the same row
	bgt $t9, $s6, finish	# Every pixel is checked. Go out of loop
	j loop_on_every_pixel

one_row_up_rest:
	beq $s7, 0x1, rest_1
	beq $s7, 0x2, rest_2
	j one_row_up_padding

rest_1:
	li $t7, BLACK_0
	sb $t7, 0($t2)
	sb $t7, 1($t2)
	sb $t7, 2($t2)
	addiu $t2, $t2, 3
	j one_row_up_padding

rest_2:
	li $t7, BLACK_0
	sb $t7, 0($t2)
	sb $t7, 1($t2)
	sb $t7, 2($t2)
	sb $t7, 3($t2)
	sb $t7, 4($t2)
	sb $t7, 5($t2)
	addiu $t2, $t2, 6
	j one_row_up_padding

one_row_up_padding:
	beq $s3, 0x1, fill_pad_1
	beq $s3, 0x2, fill_pad_2
	beq $s3, 0x3, fill_pad_3
	j one_row_up
	
fill_pad_1:
	li $t7, BLACK_0
	sb $t7, 0($t2)
	sb $t7, 1($t2)
	sb $t7, 2($t2)
	addiu $t2, $t2, 3
	j one_row_up

fill_pad_2:
	li $t7, BLACK_0
	sb $t7, 0($t2)
	sb $t7, 1($t2)
	addiu $t2, $t2, 2
	j one_row_up

fill_pad_3:
	li $t7, BLACK_0
	sb $t7, 0($t2)
	addiu $t2, $t2, 1
	j one_row_up

one_row_up:
	addiu $t9, $t9, 1
	mul $t5, $s5, 3
	sub $t8, $t8, $t5
	j loop_on_every_pixel

#################################################################
#			Mandelbrot function			#
#################################################################
	#li $t5, WHITE_0
	#sb $t5, 0($t2)
	#sb $t5, 1($t2)
	#sb $t5, 2($t2)
	#addiu $t2, $t2, 3
mandelbrot:
	li $t5, 1	# iterator
	li $t6, 64	# max iteration
	move $t0, $a0	# for n=1, $t0 set on $a0, $t1 set on $a1
	move $t1, $a1
	
loop:
	mul $t7, $a0, 2
	mul $t7, $t7, $a1
	div $t7, $t7, DIVIDER	# 2 * (A)n * (B)n	# OK
	
	mul $a0, $a0, $a0
	div $a0, $a0, DIVIDER	# (A)n ^ 2
	mul $a1, $a1, $a1
	div $a1, $a1, DIVIDER	# (B)n ^ 2
	
	sub $a0, $a0, $a1	# (A)n ^ 2 - (B)n ^ 2
	move $a1, $t7		# 2AB
	
	add $a0, $a0, $t0	# Adding our point to (Z)n and getting (Z)n+1
	add $a1, $a1, $t1
	
	
	#################
	mul $a2, $a0, $a0	# Computing absolute value
	div $a2, $a2, DIVIDER
	mul $a3, $a1, $a1
	div $a3, $a3, DIVIDER
	add $a2, $a3, $a2	# (A)n ^ 2 + (B)n ^ 2
	move $t7, $a3
	
	########dopisuje
	blt $t7, 0, white_0
	bgt $t7, 4000, use_value
	
	add $t5, $t5, 1
	bgt $t5, $t6, black_0
	j loop
	
use_value:
	########################
	

	bgt $t5, 10, black_1
	bgt $t5, 9, black_2
	bgt $t5, 8, black_3
	bgt $t5, 7, black_4
	bgt $t5, 6, gray
	bgt $t5, 5, white_4
	bgt $t5, 4, white_3
	bgt $t5, 3, white_2
	bgt $t5, 2, white_1
	bgt $t5, 1, white_0

black_0:
	#color(BLACK_0, $t2)
	li $t7, BLACK_0
	sb $t7, 0($t2)
	sb $t7, 1($t2)
	sb $t7, 2($t2)
	addiu $t2, $t2, 3
	jr $ra
	nop
	
black_1:
	#color(BLACK_0, $t2)
	li $t7, BLACK_1
	sb $t7, 0($t2)
	sb $t7, 1($t2)
	sb $t7, 2($t2)
	addiu $t2, $t2, 3
	jr $ra
	nop

black_2:
	#color(BLACK_0, $t2)
	li $t7, BLACK_2
	sb $t7, 0($t2)
	sb $t7, 1($t2)
	sb $t7, 2($t2)
	addiu $t2, $t2, 3
	jr $ra
	nop
	
black_3:
	#color(BLACK_0, $t2)
	li $t7, BLACK_3
	sb $t7, 0($t2)
	sb $t7, 1($t2)
	sb $t7, 2($t2)
	addiu $t2, $t2, 3
	jr $ra
	nop
	
black_4:
	#color(BLACK_0, $t2)
	li $t7, BLACK_4
	sb $t7, 0($t2)
	sb $t7, 1($t2)
	sb $t7, 2($t2)
	addiu $t2, $t2, 3
	jr $ra
	nop
	
gray:
	#color(BLACK_0, $t2)
	li $t7, GRAY
	sb $t7, 0($t2)
	sb $t7, 1($t2)
	sb $t7, 2($t2)
	addiu $t2, $t2, 3
	jr $ra
	nop
	
white_4:
	#color(BLACK_0, $t2)
	li $t7, WHITE_4
	sb $t7, 0($t2)
	sb $t7, 1($t2)
	sb $t7, 2($t2)
	addiu $t2, $t2, 3
	jr $ra
	nop
	
white_3:
	#color(BLACK_0, $t2)
	li $t7, WHITE_3
	sb $t7, 0($t2)
	sb $t7, 1($t2)
	sb $t7, 2($t2)
	addiu $t2, $t2, 3
	jr $ra
	nop

white_2:
	#color(BLACK_0, $t2)
	li $t7, WHITE_2
	sb $t7, 0($t2)
	sb $t7, 1($t2)
	sb $t7, 2($t2)
	addiu $t2, $t2, 3
	jr $ra
	nop

white_1:
	#color(BLACK_0, $t2)
	li $t7, WHITE_1
	sb $t7, 0($t2)
	sb $t7, 1($t2)
	sb $t7, 2($t2)
	addiu $t2, $t2, 3
	jr $ra
	nop

white_0:
	#color(BLACK_0, $t2)
	li $t7, WHITE_0
	sb $t7, 0($t2)
	sb $t7, 1($t2)
	sb $t7, 2($t2)
	addiu $t2, $t2, 3
	jr $ra
	nop
	
#################################################################
#			   Saving file				#
#################################################################
finish:
	li $v0, 13	# Open file
	la $a0, file
	li $a1, 1	# Write-only flag
	li $a2, 0
	syscall
	
	bltz $v0, error
	move $t9, $v0
	move $a0, $t9
	li $v0, 15
	la $a1, buffer
	li $a2, 54
	syscall
	
	li $v0, 15
	move $a0, $t9
	move $a1, $s4
	move $a2, $s2
	syscall
	beq $v0, $s7, end
	
	li $v0, 16
	move $a0, $t9
	syscall
	j end

#################################################################
#			  Finish program			#
#################################################################
error:
	li $v0, 4
	la $a0, err_msg
	syscall
	li $v0, 10
	syscall

end:	
	li $v0, 10
	syscall

