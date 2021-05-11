# Fibonacci Sequence, RISC-V
# First version: 2021-05-08 (non-memoized) 
# This version: 2021-05-11

# RV64IM via RARS 1.5

# This version is memoized for greater speed. See 
# https://en.wikipedia.org/wiki/Memoization for details

.eqv	MAX_FIBO	10	# Largest n, edit below if changed
.eqv	PRINT_INT	1	# System call: print_int
.eqv	PRINT_STRING	4	# System call: print_string
.eqv	EXIT		10	# Sysstem call: exit

	.data
text_mid:	.asciz " --> "
text_post:	.asciz "\n"

	.text
	.align 3
	# Initialize storage for memoization. We use -1 to mark as empty
	li t0, -1
	li t1, MAX_FIBO		# Loop control
	la t2, storage
	
init_loop:
	sd t0, 0(t2)
	addi t2, t2, 64		# Assumes RV64
	addi t1, t1, -1
	bgez t1, init_loop
	
	# Set up fibo(0) and fibo(1) to get rid of special cases
	li t0, 0
	la t1, storage
	sd t0, 0(t1)		# fibo(0) = 0 -> storage
	li t0, 1
	sd t0, 64(t1)		# fibo(1) = 1 --> storage+64
	
	# Main
	li a0, 0		# Clear accumulator
	li s0, 0		# Clear loop counter
	li s1, MAX_FIBO		# Loop limit
	
main_loop:
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
	j main_loop
	
done:			
	li a7, EXIT
	ecall
	
fibo:
	# Argument n is in a0. First, see if we already 
	# know the value
	la t2, storage
	li t1, 64
	mul t1, t1, a0		# Turn n into an offset for storage
	add t2, t2, t1		# Address in storage
	ld t1, 0(t2)
	bltz t1, calc_new	# If negative number, we have to calculate
	
	# Value is known, we get off light
	mv a0, t1
	j is_known

	# Value is not known, we have to do this the hard way
	
calc_new:
	# Save the storage address on the stack	
	addi sp, sp, -8
	sd t2, 0(sp)

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
	
	# Remember result for next time 
	ld t2, 0(sp)		# Get address for storage
	sd a0, 0(t2)		# Store new value
	addi sp, sp, 8		# Clean up stack
	
	# Fall through
is_known:	
	ret
	
	.align 3
	.data 
storage:
	# RARS doesn't seem to allow math for parameters. This assumes
	# MAX_FIBO of 10
	.space 640
	