# Fibonacci Sequence, RISC-V
# First version: 2021-05-08
# This version: 2021-05-11

# RV64I via RARS 1.5

.eqv	MAX_FIBO	10	# Largest n
.eqv	PRINT_INT	1	# System call: print_int
.eqv	PRINT_STRING	4	# System call: print_string
.eqv	EXIT		10	# Sysstem call: exit


	.data
text_mid:	.asciz " --> "
text_post:	.asciz "\n"

	.text
	li a0, 0		# Clear accumulator
	li s0, 0		# Clear loop counter
	li s1, MAX_FIBO		# Loop limit
	
loop:
	bgt s0, s1, done 	# Loop control, stop if > MAX_FIBO
	
	mv a0, s0		# Pass argument n in a0 to fibo(n) 
	jal fibo		# Return value from fibo(n) a0
	mv s2, a0		# Save return value
	
	mv a0, s0		# n 
	li a7, PRINT_INT
	ecall
	
	la a0, text_mid 	# " --> "
	li a7, PRINT_STRING
	ecall
	
	mv a0, s2		# Get return value back
	li a7, PRINT_INT
	ecall
	
	la a0, text_post	# "\n"
	li a7, PRINT_STRING
	ecall

	addi s0, s0, 1		# Loop control
	j loop
	
done:			
	li a7, EXIT
	ecall
	
fibo:
	# Argument n is in a0
	beqz a0, is_zero	# n = 0?
	addi t0, a0, -1 	# Hack: If a0 == 1 then t0 == 0
	beqz t0, is_one		# n = 1?
	
	# n > 1, do this the hard way

	addi sp, sp, -16	# Make room for two 64-Bit words on stack
	sd a0, 0(sp)		# Save original n
	sd ra, 8(sp)		# Save return address
	
	addi a0, a0, -1		# Now n-1 in a0
	jal fibo		# Calculate fibo(n-1)
	
	ld t0, 0(sp)		# Get original n from stack
	sd a0, 0(sp)		# Save fibo(n-1) to stack in same place
	addi a0, t0, -2		# Now n-2 in a0
	jal fibo		# Calculate fibo(n-2) 
	
	ld t0, 0(sp)		# Get result of fibo(n-1) from stack
	add a0, a0, t0		# add fibo(n-1) and fibo(n-2)
	
	ld ra, 8(sp)		# Get return address from stack
	addi sp, sp, 16		# clean up stack 
	
	# Fall through
	
is_zero:
is_one:
	ret
