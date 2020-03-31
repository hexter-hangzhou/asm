
# CMPUT 229 Student Submission License
# Version 1.0
#
# Copyright 2018 <student name>
#
# Unauthorized redistribution is forbidden in all circumstances. Use of this
# software without explicit authorization from the author or CMPUT 229
# Teaching Staff is prohibited.
#
# This software was produced as a solution for an assignment in the course
# CMPUT 229 - Computer Organization and Architecture I at the University of
# Alberta, Canada. This solution is confidential and remains confidential 
# after it is submitted for grading.
#
# Copying any part of this solution without including this copyright notice
# is illegal.
#
# If any portion of this software is included in a solution submitted for
# grading at an educational institution, the submitter will be subject to
# the sanctions for plagiarism at that institution.
#
# If this software is found in any public website or public repository, the
# person finding it is kindly requested to immediately report, including 
# the URL or other repository locating information, to the following email
# address:
#
#          cmput229@ualberta.ca
#

################################
# Handler Data #################
################################

	.kdata
ktemp:	.space 16


###############################
# Exception Interrupt Handler #
###############################

	# Overwrites previous handler defined in exceptions.s
	.ktext 0x80000180
	.set noat
     move $k0, $at
	.set at

	la $k1, ktemp
	sw $a0, 0($k1)
	sw $a1, 4($k1)
	sw $v0, 8($k1)
	sw $ra, 12($k1)

    mfc0 $a0, $13  # Obtain cause register
	andi $a1, $a0, 0x8000  #Check for timer interrupts
    andi $k1, $a0, 0x0800  #Check for keypress interrupts
	beq $a1, $zero, keyboardinput #if zero goto check keypress interrupt so jump
   #############timer interrupt#################
steps:		
	mtc0 $zero, $9		
	addi $a0 $zero 100
	mtc0 $a0 $11
    
    li $v0, 1
    sw $v0,hastimer

    
keyboardinput:     
        beq $k1, $zero, finish #if zero it is interrupt so jump
        #lw      $a0, 0xffff0000
		#andi 	$a0,$a0, 0x01		
		#beq	    $a0, $zero, finish
        
        lw      $a0, 0xffff0000
		andi 	$a0,$a0, 0x01		
		beq	    $a0, $zero, finish
        
        addi        $v0,$zero,1
        sw          $v0,haskeypress
             
finish:
        
	la $k1, ktemp
	lw $a0, 0($k1)
	lw $a1, 4($k1)
	lw $v0, 8($k1)
	lw $ra, 12($k1)

	.set noat
	move $at, $k0
	.set at
	
        mtc0    $zero, $13      # Clear Cause register	
		# Re-enable interrupts, which were automatically disabled
		# when the exception occurred, using read-modify-write cycle.
		mfc0    $k0, $12        # Read status register
		andi    $k0, 0xfffd     # Clear exception level bit
		ori     $k0, 0x0001     # Set interrupt enable bit
		mtc0    $k0, $12        # Write back

	eret

.data
msg: .asciiz "timer!\n"
msg2: .asciiz "key2!\n"
msg8: .asciiz "key8!\n"
msg4: .asciiz "key4!\n"
msg6: .asciiz "key6!\n"
msg5: .asciiz "key5!\n"
msg7: .asciiz "key7!\n"
msg3: .asciiz "key3!\n"
msgq: .asciiz "keyq!\n"
#have keypress
haskeypress: 	.word 0
#have timer
hastimer: 	.word 0
	#save game
gameresume: 	.word 0
onetick: 	.space 4
batchPrintinf0:  .space 9612
.text
main:

# Stack Adjustments
	addi	$sp, $sp, -4		
	sw	$fp, 0($sp)		
	add	$fp, $zero, $sp		
	addi	$sp, $sp, -12		
	sw	$ra, -4($fp)		
	sw	$s0, -8($fp)		
	sw	$s1, -12($fp)

    #test inf0
    #addi	$t2, $zero,19  #gameRows
	#addi	$t3, $zero,40     #gameCols
    lw	$t2, gameRows	
	lw	$t3, gameCols
    
    #sw	$t2, gameRows	
	#sw	$t3, gameCols
   
   
    la $s5 ,gameBoard   #gameBoard address    
    addi	$s0,	$zero, 	0    #rowid loop
    addi	$s1,	$zero, 	8    #colid loop
     addi $t0,$zero,1
    copygameboard2:   
    #sb  $t0,0($s5)
    addi $s5,$s5,1
    addi $s0,$s0,1
    bgt $s1,$s0,copygameboard2
   
    
    la	$t0, newCursorRow
	la	$t1, newCursorCol
    sw	$zero, 0($t0) #row
	sw	$zero, 0($t1) #col
    
     
    
 
    
    #enable interupter
    jal     console_int_enable
    #li $v0, 4
    #la $a0, msg
    #syscall
        
mainloop:

        #timer call
        lw	$t0,hastimer
        beq $t0, $zero,notimer
        sw	$zero,hastimer
        #li $v0, 4
        #la $a0, msg
        #syscall        
        lw	$t0, gameresume	    
        beq $t0, $zero,checkkeypress
        jal updateBoard
        la $a0,batchPrintinf0
        jal batchPrint 
        
notimer:
                
        #check haskey press
        checkkeypress:
        lw          $t0,haskeypress        
        beq         $t0,$zero,mainloop      
        sw          $zero,haskeypress
        
        #test 8 2 4 6 press
        la	$t0, newCursorRow
        la	$t1, newCursorCol
        #li $v0, 1
        #lw $a0, 0($t0) #row
        #syscall
       # lw $a0,  0($t1) #col
        #syscall

        #lw	$a0, 0($t0) #row
        #lw	$a1, 0($t1) #col
        #jal getByte
        #move $a0, $v0 #row
        #li $v0, 1        
        #syscall
        
        
        addi 	$s0,$zero,56                #'8' moves the cursor up 
		addi 	$s1,$zero,50                #'2' moves the cursor down
		addi 	$s2,$zero,52               #'4' moves the cursor left
		addi	$s3,$zero,54                #'6' moves the cursor right
		addi	$s4,$zero,53                #'5' toggles the cell under the cursor from dead to live or from live to dead
		addi	$s5,$zero,55                #'7' plays/pauses the simulation	
		addi	$s6,$zero,51                #'3' moves the simulation by 1 tick manually
		addi	$s7,$zero,113               #'q' quits the program
		#####
        lw	$t6, 0xffff0004
        beq 	$s0,$t6,input8					#'8' moves the cursor up 
		beq 	$s1,$t6,input2					 #'2' moves the cursor down
        beq 	$s2,$t6,input4					#'4' moves the cursor left
		beq 	$s3,$t6,input6					#'6' moves the cursor right
        beq 	$s4,$t6,input5					#'5' toggles the cell under the cursor from dead to live or from live to dead
		beq 	$s5,$t6,input7					#'7' plays/pauses the simulation	
        beq 	$s6,$t6,input3					#'3' moves the simulation by 1 tick manually
		beq 	$s7,$t6,inputq					#'q' quits the program
		j mainloop
input8:
     #li $v0, 4
     #   la $a0, msg8
    #    syscall
     
    la	$t0, newCursorRow
	la	$t1, newCursorCol
    lw	$t2, 0($t0) #row
	lw	$t3, 0($t1) #col
    la	$t4, gameRows	
	la	$t5, gameCols
    lw	$t6, 0($t4)  #gameRows
	lw	$t7, 0($t5)     #gameCols
    addi $t2,$t2,-1
    sw $t2, 0($t0)
    bge $t2,$zero ,mainloop
    addi $t2,$t6,-1
    sw $t2, 0($t0)
    
        
	j mainloop

input2:
      #  li $v0, 4
     #   la $a0, msg2
     #   syscall


    la	$t0, newCursorRow
	la	$t1, newCursorCol
    lw	$t2, 0($t0) #row
	lw	$t3, 0($t1) #col
    la	$t4, gameRows	
	la	$t5, gameCols
    lw	$t6, 0($t4)  #gameRows
	lw	$t7, 0($t5)     #gameCols
    addi $t2,$t2,1
    sw $t2, 0($t0)
    blt $t2,$t6 ,mainloop
    addi $t2,$zero,0
    sw $t2, 0($t0)
	j mainloop
        
input4:
   # li $v0, 4
    #    la $a0, msg4
    #    syscall

    la	$t0, newCursorRow
	la	$t1, newCursorCol
    lw	$t2, 0($t0) #row
	lw	$t3, 0($t1) #col
    la	$t4, gameRows	
	la	$t5, gameCols
    lw	$t6, 0($t4)  #gameRows
	lw	$t7, 0($t5)     #gameCols
    addi $t3,$t3,-1
    sw	$t3, 0($t1) #col
    bge $t3,$zero, mainloop
    addi $t3,$t7,-1
    sw	$t3, 0($t1) #col	
	j mainloop
        
input6:
    #    li $v0, 4
    #    la $a0, msg6
    #    syscall

    la	$t0, newCursorRow
	la	$t1, newCursorCol
    lw	$t2, 0($t0) #row
	lw	$t3, 0($t1) #col
    la	$t4, gameRows	
	la	$t5, gameCols
    lw	$t6, 0($t4)  #gameRows
	lw	$t7, 0($t5)     #gameCols
    addi $t3,$t3,1
    sw	$t3, 0($t1) #col
    blt $t3,$t7, mainloop
    addi $t3,$zero,0
    sw	$t3, 0($t1) #col	
	j mainloop
        
input5:   #toggles the cell under the cursor from dead to live or from live to dead
     #   li $v0, 4
     #   la $a0, msg5
     #   syscall
        
    la	$t0, newCursorRow
	la	$t1, newCursorCol
    lw	$a0, 0($t0) #row
	lw	$a1, 0($t1) #col
    jal getByte
    move $t0,$v0
    la $a3,gameBoard
   
    beq $t0,$zero,toggleto1    
    move $a2,$zero
    jal setByte
    
    jal updateCursor
    j 	mainloop
    toggleto1:addi,$a2,$zero,1
    jal setByte
    
    
  
    jal updateCursor    
	j mainloop
        
        #'7' plays/pauses the simulation	
input7:
     #   li $v0, 4
     #   la $a0, msg7
    #    syscall


        la	$t0, gameresume
	    lw	$t2, 0($t0) #row
        beq $t2, $zero,gameresume1
        sw	$zero, 0($t0) #row
        j mainloop
gameresume1:
        addi $t2,$zero,1
        sw	$t2, 0($t0) #row
        
       
	j mainloop
        
        
        #'3' moves the simulation by 1 tick manually
input3:
    li $v0, 4
       la $a0, msg3
       #syscall
  
 
        jal updateBoard
        la $a0,batchPrintinf0
        jal batchPrint 
        
                
	j mainloop
        
inputq:
        li $v0, 4
        la $a0, msgq
        syscall
    j exitmain

    
j mainloop


exitmain:
#Stack Restore
	lw	$ra, -4($fp)
	lw	$s0, -8($fp)
	lw	$s1, -12($fp)
	addi	$sp, $sp, 12
	lw	$fp, 0($sp)
	addi	$sp, $sp, 4	
	jr	$ra




 console_int_enable:
		mfc0	$t7, $12  					# Status		
        ori 	$t7, 0x8801 					# interrupts enable,interrupts enable keyboard timer
		mtc0 	$t7, $12  					# Status
		
		addi	$t7, $zero, 100					#set coprocessor0 register 11 to a second
		mtc0	$t7, $11					#set coprocessor0 register 11 to a second
		
			
		addi	$t8, $zero, 0					#set coprocessor0 register 9 to zero
		mtc0	$t8, $9						#set coprocessor0 register 9 to zero
        
        lw      $t0, 0xffff0000     # Receiver control register
        ori      $t0,$t0, 0x02     # Interrupt enable bit
        sw      $t0, 0xffff0000
		jr      $ra	
        
        
        #getByte
 #$a0 = row of byte to get
    #$a1 = column of byte to get
getByte:
    
    la	$t0, gameRows	
	la	$t1, gameCols
    lw	$t2, 0($t0)  #gameRows
	lw	$t3, 0($t1)     #gameCols
    
    blt $a0,$zero,rowless0
    bge $a0,$t2,gterow
    j checkcol
rowless0:addi $a0,$t2,-1
    j checkcol
gterow:move $a0,$zero       
    
checkcol:
    blt $a1,$zero,colless0
    bge $a1,$t3,gtecol
    j calpos
colless0:addi $a1,$t3,-1
    j calpos
gtecol:move $a1,$zero
    
calpos:
    mul $t4, $a0, $t3
    add $t4, $t4, $a1 #t4= pos
    la $t5 ,gameBoard   #gameBoard address
    add $t4, $t4, $t5 #t4= pos address
    lb $v0,0($t4)
    jr	$ra
    
    #setByte
    #$a0 = row of byte to get
    #$a1 = column of byte to get
    #$a2 = value to set the byte to (0 or 1)
    #$a3 = start address of list representing a 2D byte array (&gameBoard or &newGameBoard)
setByte:    
    la	$t0, gameRows	
	la	$t1, gameCols
    lw	$t2, 0($t0)  #gameRows
	lw	$t3, 0($t1)     #gameCols

    mul $t4, $a0, $t3
    add $t4, $t4, $a1 #t4= pos
    add $t4, $t4, $a3 #t4= pos address
    sb  $a2,0($t4)
    jr	$ra
    
############################################################
#							   #
#	- Any live cell with fewer than 		   #
#	  two live neighbours dies, as 			   #
#	  if caused by under-population.		   #
#							   #
#	- Any live cell with two or three 		   #
#	  live neighbours lives on to the 		   #
#	  next generation.			  	   #
#							   #
#	- Any live cell with more than three 		   #
#	  live neighbours dies, as if by 		   #
#	  overcrowding.					   #
#							   #
#	- Any dead cell with exactly three 		   #
#	  live neighbours becomes a live 		   #
#	  cell, as if by reproduction.			   #
#							   #
############################################################
 #update gameboard
    updateBoard:
    # Stack Adjustments
	addi	$sp, $sp, -4		
	sw	$fp, 0($sp)		
	add	$fp, $zero, $sp		
	addi	$sp, $sp, -28		
	sw	$ra, -4($fp)		
	sw	$s0, -8($fp)		
	sw	$s1, -12($fp)
	sw	$s2, -16($fp)
	sw	$s3, -20($fp)
	sw	$s6, -24($fp)
	sw	$s7, -28($fp)
    
    la	$s0, gameRows	
	la	$s1, gameCols
    lw	$s2, 0($s0)  #gameRows
	lw	$s3, 0($s1)     #gameCols
    
    
    #batchPrintinf0
       la  $s5, batchPrintinf0
    
    move	$s0,	$zero    #rowid loop
    move	$s1,	$zero    #colid loop
    
    
    verify_loop:
	bge	$s0, 	$s2, 	endupdateBoard
    move	$s1,	$zero    #colid=0
    colloop:
    bge $s1 , $s3,rowidplus
	
    
    
	verify:
    move	$a0, 	$s0
    move	$a1, 	$s1
    jal getByte
	move	$s7,	$v0  #cell value 
	move	$a2,	$zero	#a2 livecells

    
	verify_1:
    addi	$a0, 	$s0,	0
    addi	$a1, 	$s1,	1
    
	li	$s6,	1
	jal getByte
	move	$s4,	$v0  #rowid colid
	andi	$s6,	$s4,	1
	add	$a2,	$a2,	$s6
     
	
	verify_2:
	addi	$a0, 	$s0,	0
    addi	$a1, 	$s1,	-1
    
	li	$s6,	1
	jal getByte
	move	$s4,	$v0  #rowid colid
	and	$s6,	$s4,	$s6
	add	$a2,	$a2,	$s6
	
	verify_3:
	addi	$a0, 	$s0,	1
    addi	$a1, 	$s1,	-1
    
	li	$s6,	1
	jal getByte
	move	$s4,	$v0  #rowid colid
	and	$s6,	$s4,	$s6
	add	$a2,	$a2,	$s6
	
	verify_4:
	addi	$a0, 	$s0,	1
    addi	$a1, 	$s1,	0
    
	li	$s6,	1
	jal getByte
	move	$s4,	$v0  #rowid colid
	and	$s6,	$s4,	$s6
	add	$a2,	$a2,	$s6
	
	verify_5:
	addi	$a0, 	$s0,	1
    addi	$a1, 	$s1,	1
    
	li	$s6,	1
	jal getByte
	move	$s4,	$v0  #rowid colid
	and	$s6,	$s4,	$s6
	add	$a2,	$a2,	$s6
	
	verify_6:
	addi	$a0, 	$s0,	-1
    addi	$a1, 	$s1,	-1
    
	li	$s6,	1
	jal getByte
	move	$s4,	$v0  #rowid colid
	and	$s6,	$s4,	$s6
	add	$a2,	$a2,	$s6
	
	verify_7:
	addi	$a0, 	$s0,	-1
    addi	$a1, 	$s1,	0
    
	li	$s6,	1
	jal getByte
	move	$s4,	$v0  #rowid colid
	and	$s6,	$s4,	$s6
	add	$a2,	$a2,	$s6
	
	verify_8:
	addi	$a0, 	$s0,	-1
    addi	$a1, 	$s1,	1
    
	li	$s6,	1
	jal getByte
	move	$s4,	$v0  #rowid colid
	and	$s6,	$s4,	$s6
	add	$a2,	$a2,	$s6
	
    
	verify_condition:	
	beq	$s7,	$zero,	verify_false
	j	verify_true
	
	verify_true:
	blt	$a2,	2,	verify_dies
	blt	$a2,	4,	verify_lives
	j	verify_dies
	
	verify_false:
	beq	$a2,	3,	verify_lives
	j	verify_dies
	
	verify_lives:
	
    move	$a0, 	$s0
    move	$a1, 	$s1
    addi	$a2, 	$zero,1
    la      $a3 ,newGameBoard   #newGameBoard address   
    jal setByte
    
    sh  $s0 ,0($s5)
    sh  $s1 ,2($s5)
    addi $t1,$zero,1
    sb   $t1 ,4($s5) 
    la  $t1,char
    sw   $t1,8($s5)    
    addi $s5,$s5,12
    
	j	verify_end
	
	verify_dies:
	move	$a0, 	$s0
    move	$a1, 	$s1
    addi	$a2, 	$zero,0
    la      $a3 ,newGameBoard   #newGameBoard address   
    jal setByte
    
    sh  $s0 ,0($s5)
    sh  $s1 ,2($s5)
    addi $t1,$zero,1
    sb   $t1 ,4($s5) 
    la  $t1,deadChar
    sw   $t1,8($s5)    
    addi $s5,$s5,12
    
    
    
	j	verify_end
	
    
    
    
	verify_end:
    
     move $a0,$a2
       li	$v0, 1	
	#syscall
    #addiu	$t1,	$t1, 	1
    addi	$s1,$s1,1 #col ++
    
  
	j	colloop
    
    rowidplus:
    addi	$s0,$s0,1 #rowid++
    j verify_loop
    
    
	endupdateBoard:
       addi  $s0 ,$zero,0xFF
    sb  $s0 ,0($s5)
    sb  $s0 ,1($s5)

    
    
    
    la $s5 ,gameBoard   #gameBoard address
    la $s6 ,newGameBoard   #newGameBoard address   
    
    addi	$s0,	$zero, 	0    #rowid loop
    addi	$s1,	$zero, 	800    #colid loop
    copygameboard:
    lb $t0,0($s6)
    sb  $t0,0($s5)
    addi $s5,$s5,1
    addi $s6,$s6,1
    addi $s0,$s0,1
    bgt $s1,$s0,copygameboard
    


    
    
    #Stack Restore
	lw	$ra, -4($fp)
	lw	$s0, -8($fp)
	lw	$s1, -12($fp)
	lw	$s2, -16($fp)
	lw	$s3, -20($fp)
	lw	$s6, -24($fp)
	lw	$s7, -28($fp)
	addi	$sp, $sp, 28
	lw	$fp, 0($sp)
	addi	$sp, $sp, 4
    
    jr	$ra
