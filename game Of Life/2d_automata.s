			.data

cursor_move_prefix:	.byte 0x1B, 0x5B, 0x00
direction_chars:	.byte 0x41, 0x42, 0x43, 0x44
newline_char: 		.byte 0x0A
on_state_char:		.byte 0x31
off_state_char:		.byte 0x30

old_grid_loc:		.word 0
new_grid_loc:		.word 0
grid_ptr_lst:		.word 0
grid_size_x:		.word 0
grid_size_y:		.word 0

set_grid_x:			.word 48
set_grid_y:			.word 20
set_iterations:		.word 1000

initial_state_buff:	.space 2048

newline: 			.asciiz "\n"
intro: 				.asciiz "Welcome to the MIPS Game of Life simulator!\n"
default_file_ptr: 	.asciiz "/Users/nick/Desktop/school/RPI_Semester_2/Computer_Organization/MIPS_2d_automata/state_1.txt"
cspace:				.asciiz ", "
debug:				.asciiz "DEBUG\n"
			
			
			.text
			.globl main
    main:	lw $a0, set_grid_x
			lw $a1, set_grid_y
			jal construct_grid
						
			la $a0, default_file_ptr
			la $a1, initial_state_buff
			jal load_state_from_file
			
			jal print_grid
						
			li $v0, 4
			la $a0, newline
			syscall
			
			li $s0, 0
			lw $s1, set_iterations
main_loop:
			jal step_automata
			
			jal print_grid
			
			lw $a0, grid_size_y
			li $a1, 0
			jal move_cursor
			
			addi $s0, $s0, 1
			
			li $a0, 0
			jal sleep_cycles
						
			blt $s0, $s1, main_loop
# End main_loop
						
			li $v0, 10
			syscall
			

# $a0 = x dimension
# $a1 = y dimension
# $v0 = beginning of board ptr lister

# $a0 = number of cycles to sleep
sleep_cycles:
			li $t0, 0
			move $t1, $a0
sleep_loop:
			addi $t0, $t0, 1
			blt $t0, $t1, sleep_loop
			jr $ra
			
construct_grid:
			move $t0, $a0			# $t0 = x dimension
			move $t1, $a1			# $t1 = y dimension
			
			sw $t0, grid_size_x
			sw $t1, grid_size_y
			
			mul $t2, $t0, $t1		# $t2 = size of the grid
			sll $t2, $t2, 1
			
			li $v0, 9				# Allocate the grid space
			move $a0, $t2
			syscall
			
			move $t3, $v0			# $t3 = beginning of space allocated for grid
			
			move $t4, $t3 			# $t4 = beginning counter, $t5 is the end
			add $t5, $t3, $t2
CG_clear_mem_loop:
			sb $zero, ($t4)
			addi $t4, $t4, 1
			blt $t4, $t5, CG_clear_mem_loop
# end CG_clear_mem_loop
			
			li $v0, 9
			sll $a0, $t1, 3
			syscall
			
			move $t4, $v0			# $t4 = beginning of grid ptr array
			
			move $t5, $t4
			sll $t6, $t1, 3 		# $t5 is the loop counter, and $t6 the boundary
			add $t6, $t4, $t6
			move $t7, $t3			# $t7 will be our place withing the grid
CG_ptr_loop:

			sw $t7, ($t5)			# Store the row ptr to it's place in the grid ptr array
			add $t7, $t7, $t0		# Move to the beginning of the next row
			addi $t5, $t5, 4 		# Move to the next space of the grid ptr array
			
			blt $t5, $t6, CG_ptr_loop
# end CG_ptr_loop
			move $v0, $t4
			sw $v0, grid_ptr_lst
			jr $ra

# $a0 = amount to move
# $a1 = direction (0 = up, 1 = down, 2 = forward, 3 = backward)
move_cursor:
			move $t0, $a0
			move $t1, $a1
			li $v0, 4
			la $a0, cursor_move_prefix
			syscall
			
			li $v0, 1
			move $a0, $t0
			syscall
			
			li $v0, 11
			la $t2, direction_chars
			add $t2, $t2, $t1
			lb $a0, ($t2)
			syscall
			jr $ra
			
			
			
print_grid:
			lw $t0, grid_ptr_lst 	# $t0 is the loop variable for the y axis
			lw $t1, grid_size_y		# $t1 is the end of the y part
			sll $t1, $t1, 2
			lw $t4, grid_size_x 	# $t2 is the loop variable for x, and $t3 is it's end
			add $t1, $t1, $t0
PG_y_loop:
			lw $t2, ($t0)
			add $t3, $t4, $t2
			addi $t0, $t0, 4
PG_x_loop:
			lb $a0, ($t2)
			li $v0, 1
			syscall
			
			addi $t2, $t2, 1
# end PG_x_loop
			blt $t2, $t3, PG_x_loop
			li $v0, 4
			la $a0, newline
			syscall
# end PG_y_loop
			blt $t0, $t1, PG_y_loop
			
			jr $ra

# $a0 = ptr to zero terminated string (file name)
# $a1 = ptr to buffer
load_state_from_file:
			move $t0, $a0
			move $t1, $a1
			
			li $v0, 13 			# $a0 already initialized to file path
			li $a1, 0
			li $a2, 0
			syscall 			# TODO: Handle -1 return value
			
			move $t2, $v0 		# #t2 temporarily the file descirptor
			
			li $v0, 14
			move $a0, $t2
			move $a1, $t1
			li $a2, 2048
			syscall
			
			move $t4, $v0 		# $t4 = number of character's read
			
			li $v0, 16
			move $a0, $t2
			syscall
			
			move $t2, $t1		# $t2 = initial position in read buffer, $t3 = endpoint
			add $t3, $t1, $t4
			
			lw $t5, grid_ptr_lst 	
			lw $t5, ($t5)			# This should be the beginning of the old grid.
			lw $a0, grid_size_x  	# Calculate size of grid and add on to initial ptr
			lw $a1, grid_size_y		# to find end of grid.
			mul $a0, $a0, $a1
			add $t6, $t5, $a0		# $t5 is initial position in grid, $t6 is end.
			
			lb $t8, on_state_char
LS_loop:
			bge $t5, $t6, LS_loop_end # skip to end if we've exceeded size of grid.
			lb $t4, ($t2)			# $t4 is now the variable used to hold the char from the
									# read buffer
			lb $a0, newline_char
			bne $a0, $t4, LS_not_newline 	# skip newlines
			addi $t2, $t2, 1
			j LS_loop
LS_not_newline:
			seq $a0, $t4, $t8 		# only check for the on_state_char and use the result
									# to properly set the grid's state.
			sb $a0, ($t5)
			
			addi $t2, $t2, 1
			addi $t5, $t5, 1
			
			blt $t2, $t3, LS_loop
LS_loop_end:
			jr $ra

step_automata:
			addi $sp, $sp, -4
			sw $ra, ($sp)
			addi $sp, $sp, -4
			sw $s0, ($sp)
			addi $sp, $sp, -4
			sw $s1, ($sp)
			addi $sp, $sp, -4
			sw $s2, ($sp)
			addi $sp, $sp, -4
			sw $s3, ($sp)
			addi $sp, $sp, -4
			sw $s4, ($sp)
			addi $sp, $sp, -4
			sw $s5, ($sp)
			
			
			li $s0, 0 					# $s0 / $s1 x loop counter / boundary
			lw $s1, grid_size_x
			li $s2, 0 					# $s2 / $s3 y loop counter / boundary
			lw $s3, grid_size_y
step_automata_loop:			
			move $a0, $s0
			move $a1, $s2
			jal get_adjacent
			move $s4, $v0
									
			move $a0, $s0
			move $a1, $s2
			jal load_value
			move $s5, $v0
							
			li $a0, 1
			beq $s5, $a0, step_automata_if_1
			
			li $a0, 3
			beq $s4, $a0, step_automata_if_2
			move $a0, $s0
			move $a1, $s2
			li $a2, 0
			jal store_value
			j step_automata_if_1_end
			
step_automata_if_2:
			move $a0, $s0
			move $a1, $s2
			li $a2, 1
			jal store_value
			j step_automata_if_1_end

step_automata_if_1:
			li $a0, 2
			beq $s4, $a0, step_automata_if_3
			li $a0, 3
			beq $s4, $a0, step_automata_if_3
			move $a0, $s0
			move $a1, $s2
			li $a2, 0
			jal store_value
			j step_automata_if_1_end
step_automata_if_3:
			move $a0, $s0
			move $a1, $s2
			li $a2, 1
			jal store_value
step_automata_if_1_end:
			addi $s0, 1
			blt $s0, $s1, step_automata_loop
			li $s0, 0
			addi $s2, 1
			blt $s2, $s3, step_automata_loop
# end of step_automata_loop
			
			jal copy_field
			
			lw $s5, ($sp)
			addi $sp, $sp, 4
			lw $s4, ($sp)
			addi $sp, $sp, 4
			lw $s3, ($sp)
			addi $sp, $sp, 4
			lw $s2, ($sp)
			addi $sp, $sp, 4
			lw $s1, ($sp)
			addi $sp, $sp, 4
			lw $s0, ($sp)
			addi $sp, $sp, 4
			lw $ra, ($sp)
			addi $sp, $sp, 4
			jr $ra


# Copies over the new field to the old field
copy_field:
			lw $t0, grid_ptr_lst
			lw $t1, grid_size_y
			sll $t1, $t1, 2
			add $t0, $t0, $t1
			lw $t0, ($t0) 				# $t0 is the ptr to the new grid
			
			lw $t4, grid_ptr_lst
			lw $t4, ($t4) 				# $t4 is the ptr to the old grid
			
			srl $t1, $t1, 2
			lw $a0, grid_size_x
			mul $t1, $a0, $t1			# $t1 is the size of one grid
			
			li $t3, 0
copy_field_loop:
			lb $t2, ($t0)
			sb $t2, ($t4)
			addi $t0, $t0, 1
			addi $t4, $t4, 1
			addi $t3, $t3, 1
			blt $t3, $t1, copy_field_loop
			jr $ra

# $a0  = x, $a1 = y
# $v0 is the sum of the neighbors
get_adjacent:
			# Possible optimization: move the stack ptr the full distance in one addi
			addi $sp, $sp, -4
			sw $s0, ($sp)
			addi $sp, $sp, -4
			sw $s1, ($sp)
			addi $sp, $sp, -4
			sw $s2, ($sp)
			addi $sp, $sp, -4
			sw $s3, ($sp)
			addi $sp, $sp, -4
			sw $s4, ($sp)
			addi $sp, $sp, -4
			sw $ra, ($sp)

			
			move $t0, $a0			# $t0 = x, $t1 = y
			move $t1, $a1
			lw $t2, grid_size_x		# $t2 = grid_size_x, $t3 = grid_size_y
			lw $t3, grid_size_y
			addi $t2, $t2, -1
			addi $t3, $t3, -1
			# $s3-5 y coords
			# $s0-2 x coords
			
			move $s1, $t0
			move $s4, $t1
	
			# Series of if-else setatements to handle looping at edges.
			bne $t1, $zero, GA_else_1
			move $s3, $t3
			j GA_else_1_end
GA_else_1:
			addi $s3, $t1, -1
GA_else_1_end:
			bne $t1, $t3, GA_else_2
			li $s5, 0
			j GA_else_2_end
GA_else_2:
			addi $s5, $t1, 1
GA_else_2_end:
			
			bne $t0, $zero, GA_else_3
			move $s0, $t2
			j GA_else_3_end
GA_else_3:
			addi $s0, $t0, -1
GA_else_3_end:
			bne $t0, $t2, GA_else_4
			li $s2, 0
			j GA_else_4_end
GA_else_4:
			addi $s2, $t0, 1
GA_else_4_end:
			
			li $s6, 0 				# $s6 will be the sum of the neighbors
			
			
			move $a0, $s0 			# Grab each of the neighbors values and add to $s6
			move $a1, $s3
			jal load_value
			add $s6, $s6, $v0
			
			move $a0, $s1
			move $a1, $s3
			jal load_value
			add $s6, $s6, $v0
			
			move $a0, $s2
			move $a1, $s3
			jal load_value
			add $s6, $s6, $v0
			
			move $a0, $s0
			move $a1, $s5
			jal load_value
			add $s6, $s6, $v0
			
			move $a0, $s1
			move $a1, $s5
			jal load_value
			add $s6, $s6, $v0
			
			move $a0, $s2
			move $a1, $s5
			jal load_value
			add $s6, $s6, $v0
			
			move $a0, $s0
			move $a1, $s4
			jal load_value
			add $s6, $s6, $v0
			
			move $a0, $s2
			move $a1, $s4
			jal load_value
			add $s6, $s6, $v0
			
			move $v0, $s6
			
			lw $ra, ($sp)
			addi $sp, $sp, 4
			lw $s4, ($sp)
			addi $sp, $sp, 4
			lw $s3, ($sp)
			addi $sp, $sp, 4
			lw $s2, ($sp)
			addi $sp, $sp, 4
			lw $s1, ($sp)
			addi $sp, $sp, 4
			lw $s0, ($sp)
			addi $sp, $sp, 4
			
			jr $ra
			
# $a0 = x, $a1 = y
# $v0 = val
# For now always loads from old_grid
load_value:
			move $t0, $a0
			move $t1, $a1
			lw $t2, grid_ptr_lst
			sll $t1, $t1, 2
			add $t2, $t2, $t1
			lw $t2, ($t2)
			add $t2, $t2, $t0
			lb $v0, ($t2)
			jr $ra

# $a0 = x, $a1 = y, $a3 = byte to store
# For now always stores to new_grid
store_value:
			move $t0, $a0
			move $t1, $a1
			move $t4, $a2
			lw $t2, grid_ptr_lst
			lw $t3, grid_size_y
			sll $t3, $t3, 2
			add $t2, $t2, $t3
			
			
			
			sll $t1, $t1, 2
			add $t2, $t2, $t1
			lw $t2, ($t2)
			add $t2, $t2, $t0
						
			sb $t4, ($t2)
			jr $ra
			
#DEBUG: print a list of the pointers in grid_ptr_lst
print_grid_ptr_list:
			lw $t0, grid_ptr_lst
			lw $t1, grid_size_y
			sll $t1, $t1, 3
			add $t1, $t1, $t0
			
print_grid_ptr_list_loop:
			lw $a0, ($t0)
			li $v0, 1
			syscall
			
			li $v0, 4
			la $a0, cspace
			syscall
			
			addi $t0, $t0, 4
			blt $t0, $t1, print_grid_ptr_list_loop
			
			li $v0, 4
			la $a0, newline
			syscall
			
			
			jr $ra