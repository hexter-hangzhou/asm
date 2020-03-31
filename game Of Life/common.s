#
# CMPUT 229 Public Materials License
# Version 1.1
#
# Copyright 2017 University of Alberta
# Copyright 2017 Austin Crapo
#
# This software is distributed to students in the course
# CMPUT 229 - Computer Organization and Architecture I at the University of
# Alberta, Canada. 
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the disclaimer below in the documentation
#    and/or other materials provided with the distribution.
# 
# 2. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from this
#    software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
######################
#Author: Austin Crapo
#Date: June 2017
#
# Implementation of Conways "game of life" using GLIM
# Requires interrupts and field handling by student
# submission.
#
######################
.data
deadChar:
	.align 2
	.asciiz " "
	.align 2
char:
	.align 2
	.asciiz "█"	#while it may look like there is no ending quote, there is.
	.align 2
prompt1:
	.align 2
	.asciiz "Number of rows for this session: "
	.align 2
prompt2:
	.align 2
	.asciiz "Number of columns for this session: "
	.align 2
gameBoard:
	.space 800
newGameBoard:
	.align 2
	.space 800
gameRows:
	.space 4
gameCols:
	.space 4
.text
.globl __start
__start:
#############
# update: used to track game updates
# action: used to track action requests
#############
	# Stack Adjustments
	addi	$sp, $sp, -4		# Adjust the stack to save $fp
	sw	$fp, 0($sp)		# Save $fp
	add	$fp, $zero, $sp		# $fp <= $sp
	addi	$sp, $sp, -12		# Adjust stack to save variables
	sw	$ra, -4($fp)		# Save $ra
	sw	$s0, -8($fp)		
	sw	$s1, -12($fp)
	
	
	##read the display size
	#Rows
	li	$v0, 4
	la	$a0, prompt1
	syscall
	li	$v0, 5
	syscall
	move	$s0, $v0
	#Cols
	li	$v0, 4
	la	$a0, prompt2
	syscall
	li	$v0, 5
	syscall
	move	$s1, $v0
	#set the display size
	move	$a0, $s0
	move	$a1, $s1
	jal	startGLIM
	la	$t0, gameRows
	sw	$s0, 0($t0)
	la	$t0, gameCols
	sw	$s1, 0($t0)
	jal	clearScreen
	
	
	jal	main
	
		
	
	#MUST BE CALLED BEFORE ENDING PROGRAM
	jal	endGLIM
	
	#Stack Restore
	lw	$ra, -4($fp)
	lw	$s0, -8($fp)
	lw	$s1, -12($fp)
	addi	$sp, $sp, 12
	lw	$fp, 0($sp)
	addi	$sp, $sp, 4
	
	# Exit
	li	$v0, 10
	syscall


.data
cursorRow:
	.space 4
cursorCol:
	.space 4
newCursorRow:
	.space 4
newCursorCol:
	.space 4
.text
updateCursor:
	########################################################################
	# Compares the new cursor value to the current cursor value, then updates
	# accordingly the screen. After this function is called, cursorRow
	# and cursorCol contain the current cursor coordinates.
	#
	# Does not operate on inputs, only the memory addresses
	# newCursorRow, newCursorCol, cursorRow, cursorCol
	#
	#
	# Register Usage
	# 
	# $s0 = newCursorRow storage
	# $s1 = newCursorCol storage
	# $s2 = cursorRow storage
	# $s3 = cursorCol storage
	########################################################################
	# Stack Adjustments
	addi	$sp, $sp, -4		# Adjust the stack to save $fp
	sw	$fp, 0($sp)			# Save $fp
	add	$fp, $zero, $sp		# $fp <= $sp
	addi	$sp, $sp, -20		# Adjust stack to save variables
	sw	$ra, -4($fp)		# Save $ra
	sw	$s0, -8($fp)		# Save $s0
	sw	$s1, -12($fp)		# Save $s1
	sw	$s2, -16($fp)		# Save $s2
	sw	$s3, -20($fp)		# Save $s2
	
	la	$s0, newCursorRow
	la	$s1, newCursorCol
	la	$s2, cursorRow
	la	$s3, cursorCol
	
	#get the state of the old position
	lw	$a0, 0($s2)
	lw	$a1, 0($s3)
	jal	getByte
	
	#redraw the old position tile
	bne	$v0, $zero, uMoldDead
		#if old cursor position was on a dead tile print a dead tile
		la	$a0, deadChar
		lw	$a1, 0($s2)
		lw	$a2, 0($s3)
		jal	printString
		j	uMoldDone
	uMoldDead:
		#if old cursor position was on a live tile print a live tile
		la	$a0, char
		lw	$a1, 0($s2)
		lw	$a2, 0($s3)
		jal	printString
		j	uMoldDone
	uMoldDone:
	
	#update the cursor pointer position
	lw	$t0, 0($s0)
	sw	$t0, 0($s2)
	lw	$t0, 0($s1)
	sw	$t0, 0($s3)
	
	#set the color to show the cursor pointer
	li	$a0	9
	li	$a1	0
	jal	setColor
	
	#get the state of the new position
	lw	$a0, 0($s2)
	lw	$a1, 0($s3)
	jal	getByte
	
	#print the state of the new position with the pointer color
	beq	$v0, $zero, uMnewDead
		la	$a0, char
		j	uMnewDone
	uMnewDead:
		la	$a0, deadChar
	uMnewDone:
	lw	$a1, 0($s2)
	lw	$a2, 0($s3)
	jal	printString
	
	#restore the color
	jal	restoreSettings
	
	
	
	#Stack Restore
	lw	$ra, -4($fp)
	lw	$s0, -8($fp)
	lw	$s1, -12($fp)
	lw	$s2, -16($fp)
	lw	$s3, -20($fp)
	addi	$sp, $sp, 20
	lw	$fp, 0($sp)
	addi	$sp, $sp, 4
	
	jr	$ra

#############################START GRAPHICS LIB###############################
# LAST IMPORT: JUNE 27
###############################################################################
######################
#Author: Austin Crapo
#Date: June 2017
#Version: 2017.6.27
#
#This is a graphics library, supports pixel drawing
# High Level documentation is provided in the index.html file.
# Per-method documentation is provided in the block comment 
# following each function definition
######################
.data
.align 2
clearScreenCmd:
	.byte 0x1b, 0x5b, 0x32, 0x4a, 0x00
.text
clearScreen:
	########################################################################
	# Uses xfce4-terminal escape sequence to clear the screen
	#
	# Register Usage
	# Overwrites $v0 and $a0 during operation
	########################################################################
	li	$v0, 4
	la	$a0, clearScreenCmd
	syscall
	
	jr	$ra

.data
setCstring:
	.byte 0x1b, 0x5b, 0x30, 0x30, 0x30, 0x3b, 0x30, 0x30, 0x30, 0x48, 0x00
.text
setCursor:
	########################################################################
	#Moves the cursor to the specified location on the screen. Max location
	# is 3 digits for row number, and 3 digits for column number. (row, col)
	#
	# $a0 = row number to move to
	# $a1 = col number to move to
	#
	# Register Usage
	# Overwrites $v0 and $a0 during operation
	########################################################################
	# Stack Adjustments
	addi	$sp, $sp, -4		# Adjust the stack to save $fp
	sw	$fp, 0($sp)		# Save $fp
	add	$fp, $zero, $sp		# $fp <= $sp
	addi	$sp, $sp, -12		# Adjust stack to save variables
	sw	$ra, -4($fp)		# Save $ra
	#skip $s0, this could be cleaned up
	sw	$s1, -8($fp)		
	sw	$s2, -12($fp)		
	
	#The control sequence we need is "\x1b[$a1;$a2H" where "\x1b"
	#is xfce4-terminal's method of passing the hex value for the ESC key.
	#This moves the cursor to the position, where we can then print.
	
	#The command is preset in memory, with triple zeros as placeholders
	#for the char coords. We translate the args to decimal chars and edit
	# the command string, then print
	
	move	$s1, $a0
	move	$s2, $a1
	
	li	$t0, 0x30	#'0' in ascii, we add according to the number
	#separate the three digits of the passed in number
	#1's = x%10
	#10's = x%100 - x%10
	#100's = x - x$100
	
	# NOTE: we add 1 to each coordinate because we want (0,0) to be the top
	# left corner of the screen, but most terminals define (1,1) as top left
	#ROW
	addi	$a0, $s1, 1
	la	$t2, setCstring
	jal	intToChar
	lb	$t0, 0($v0)
	sb	$t0, 4($t2)
	lb	$t0, 1($v0)
	sb	$t0, 3($t2)
	lb	$t0, 2($v0)
	sb	$t0, 2($t2)
	
	#COL
	addi	$a0, $s2, 1
	la	$t2, setCstring
	jal	intToChar
	lb	$t0, 0($v0)
	sb	$t0, 8($t2)
	lb	$t0, 1($v0)
	sb	$t0, 7($t2)
	lb	$t0, 2($v0)
	sb	$t0, 6($t2)

	#move the cursor
	li	$v0, 4
	la	$a0, setCstring
	syscall
	
	#Stack Restore
	lw	$ra, -4($fp)
	lw	$s1, -8($fp)
	lw	$s2, -12($fp)
	addi	$sp, $sp, 12
	lw	$fp, 0($sp)
	addi	$sp, $sp, 4
	
	jr	$ra

.text
printString:
	########################################################################
	# Prints the specified null-terminated string started at the
	# specified location to the string and then continuing until
	# the end of the string, according to the printing preferences of your
	# terminal (standard terminals print left to right, top to bottom).
	# Is not screen aware, passing paramaters that would print a character
	# off screen have undefined effects on your terminal window. For most
	# terminals the cursor will wrap around to the next row and continue
	# printing. If you have hit the bottom of the terminal window,
	# the xfce4-terminal window default behavior is to scroll the window 
	# down. This can offset your screen without you knowing and is 
	# dangerous since it is undetectable. The most likely useage of this
	# function is to print characters. The reason that it is a string it
	# prints is to support the printing of escape character sequences
	# around the character so that fancy effects are supported. Some other
	# terminals may treat the boundaries of the terminal window different,
	# for example some may not wrap or scroll. It is up to the user to
	# test their terminal window for its default behaviour.
	# Is built for xfce4-terminal.
	# Position (0, 0) is defined as the top left of the terminal.
	#
	# $a0 = address of string to print
	# $a1 = integer value 0-999, row to print to (y position)
	# $a2 = integer value 0-999, col to print to (x position)
	#
	# Register Usage
	# $t0 - $t3, $t7-$t9 = temp storage of bytes and values
	########################################################################
	# Stack Adjustments
	addi	$sp, $sp, -4		# Adjust the stack to save $fp
	sw	$fp, 0($sp)		# Save $fp
	add	$fp, $zero, $sp		# $fp <= $sp
	addi	$sp, $sp, -8		# Adjust stack to save variables
	sw	$ra, -4($fp)		# Save $ra
	sw	$s0, -8($fp)		# Save $s0
	
	move	$s0, $a0
	
	move	$a0, $a1
	move	$a1, $a2
	jal	setCursor
	
	#print the char
	li	$v0, 4
	move	$a0, $s0
	syscall
	
	#Stack Restore
	lw	$ra, -4($fp)
	lw	$s0, -8($fp)
	addi	$sp, $sp, 8
	lw	$fp, 0($sp)
	addi	$sp, $sp, 4
	
	jr	$ra

batchPrint:
	########################################################################
	# A batch is a list of print jobs. The print jobs are in the format
	# below, and will be printed from start to finish. This function does
	# some basic optimization of color printing (eg. color changing codes
	# are not printed if they do not need to be), but if the list constantly
	# changes color and is not sorted by color, you may notice flickering.
	#
	# List format:
	# Each element contains the following words in order together
	# half words unsigned:[row] [col]
	# bytes unsigned:     [printing code] [foreground color] [background color] 
	#			    [empty] 
	# word: [address of string to print here]
	# total = 3 words
	#
	# The batch must be ended with the halfword sentinel: 0xFFFF
	#
	# Valid Printing codes:
	# 0 = skip printing
	# 1 = standard print, default terminal settings
	# 2 = print using foreground color
	# 3 = print using background color
	# 4 = print using all colors
	# 
	# xfce4-terminal supports the 256 color lookup table assignment, 
	# see the index for a list of color codes.
	#
	# The payload of each job in the list is the address of a string. 
	# Escape sequences for prettier or bolded printing supported by your
	# terminal can be included in the strings. However, including such 
	# escape sequences can effect not just this print, but also future 
	# prints for other GLIM methods.
	#
	# $a0 = address of batch list to print
	#
	# Register Usage
	# $s0 = scanner for the list
	# $s1 = store row info
	# $s2 = store column info
	# $s3 = store print code info
	# $s6 = temporary color info storage accross calls
	# $s7 = temporary color info storage accross calls
	########################################################################
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
	
	#store the last known colors, to avoid un-needed printing
	li	$s6, -1		#lastFG = -1
	li	$s7, -1		#lastBG = -1
	
	
	move	$s0, $a0		#scanner = list
	#for item in list
	bPscan:
		#extract row and col to vars
		lhu	$s1, 0($s0)		#row
		lhu	$s2, 2($s0)		#col
		
		#if row is 0xFFFF: break
		li	$t0, 0xFFFF
		beq	$s1, $t0, bPsend
		
		#extract printing code
		lbu	$s3, 4($s0)		#print code
		
		#skip if printing code is 0
		beq	$s3, $zero, bPscont
		
		#print to match printing code if needed
		#if standard print, make sure to have clear color
		li	$t0, 1		#if pcode == 1
		beq	$s3, $t0, bPscCend
		bPsclearColor:
			li	$t0, -1	#if lastFG != -1 
			bne	$s6, $t0, bPscCreset
			bne	$s7, $t0, bPscCreset	#OR lastBG != -1:
			j	bPscCend
			bPscCreset:
				jal	restoreSettings
				li	$s6, -1
				li	$s7, -1
		bPscCend:
		
		#change foreground color if needed
		li	$t0, 2		#if pcode == 2 or pcode == 4
		beq	$s3, $t0, bPFGColor
		li	$t0, 4
		beq	$s3, $t0, bPFGColor
		j	bPFCend
		bPFGColor:
			lbu	$t0, 5($s0)
			beq	$t0, $s6, bPFCend	#if color != lastFG
				move	$s6, $t0	#store to lastFG
				move	$a0, $t0	#set as FG color
				li	$a0, 1
				jal	setColor
		bPFCend:
		
		#change background color if needed
		li	$t0, 3		#if pcode == 2 or pcode == 4
		beq	$s3, $t0, bPBGColor
		li	$t0, 4
		beq	$s3, $t0, bPBGColor
		j	bPBCend
		bPBGColor:
			lbu	$t0, 6($s0)
			beq	$t0, $s7, bPBCend	#if color != lastBG
				move	$s7, $t0	#store to lastBG
				move	$a0, $t0	#set as BG color
				li	$a0, 0
				jal	setColor
		bPBCend:
		
		
		#then print string to (row, col)
		lw	$a0, 8($s0)
		move	$a1, $s1
		move	$a2, $s2
		jal	printString
		
		bPscont:
		addi	$s0, $s0, 12
		j	bPscan
	bPsend:

	
	
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
	
.data
.align 2
intToCharSpace:
	.space	4	#storing 4 bytes, only using 3, because of spacing.
.text
intToChar:
	########################################################################
	# Given an int x where 0 <= x <= 999, converts the integer into 3 bytes,
	# which are the character representation of the int. If the integer
	# requires larger than 3 chars to represent, only the 3 least 
	# significant digits will be converted.
	#
	# $a0 = integer to convert
	#
	# Return Values:
	# $v0 = address of the bytes, in the following order, 1's, 10's, 100's
	#
	# Register Usage
	# $t0-$t9 = temporary value storage
	########################################################################
	li	$t0, 0x30	#'0' in ascii, we add according to the number
	#separate the three digits of the passed in number
	#1's = x%10
	#10's = x%100 - x%10
	#100's = x - x$100
	la	$v0, intToCharSpace
	#ones
	li	$t1, 10		
	div	$a0, $t1
	mfhi	$t7			#x%10
	add	$t1, $t0, $t7	#byte = 0x30 + x%10
	sb	$t1, 0($v0)
	#tens
	li	$t1, 100		
	div	$a0, $t1
	mfhi	$t8			#x%100
	sub	$t1, $t8, $t7	#byte = 0x30 + (x%100 - x%10)/10
	li	$t3, 10
	div	$t1, $t3
	mflo	$t1
	add	$t1, $t0, $t1	
	sb	$t1, 1($v0)
	#100s
	li	$t1, 1000		
	div	$a0, $t1
	mfhi	$t9			#x%1000
	sub	$t1, $t9, $t8	#byte = 0x30 + (x%1000 - x%100)/100
	li	$t3, 100
	div	$t1, $t3
	mflo	$t1
	add	$t1, $t0, $t1	
	sb	$t1, 2($v0)
	
	jr	$ra
	
.data
.align 2
setFGorBG:
	.byte 0x1b, 0x5b, 0x34, 0x38, 0x3b, 0x35, 0x3b, 0x30, 0x30, 0x30, 0x6d, 0x00
.text
setColor:
	########################################################################
	# Prints the escape sequence that sets the color of the text to the
	# color specified.
	# 
	# xfce4-terminal supports the 256 color lookup table assignment, 
	# see the index for a list of color codes.
	#
	#
	# $a0 = color code (see index)
	# $a1 = 0 if setting background, 1 if setting foreground
	#
	# Register Usage
	# $s0 = temporary arguement storage accross calls
	# $s1 = temporary arguement storage accross calls
	########################################################################
	# Stack Adjustments
	addi	$sp, $sp, -4		
	sw	$fp, 0($sp)		
	add	$fp, $zero, $sp		
	addi	$sp, $sp, -12		
	sw	$ra, -4($fp)		
	sw	$s0, -8($fp)		
	sw	$s1, -12($fp)		
	
	move	$s0, $a0
	move	$s1, $a1
	
	jal	intToChar		#get the digits of the color code to print
	
	move	$a0, $s0
	move	$a1, $s1
	
	la	$t0, setFGorBG
	lb	$t1, 0($v0)		#alter the string to print
	sb	$t1, 9($t0)
	lb	$t1, 1($v0)
	sb	$t1, 8($t0)
	lb	$t1, 2($v0)
	sb	$t1, 7($t0)
	
	beq	$a1, $zero, sCsetBG	#set the code to print FG or BG
		#setting FG
		li	$t1, 0x33
		j	sCset
	sCsetBG:
		li	$t1, 0x34
	sCset:
		sb	$t1, 2($t0)
	
	li	$v0, 4
	move	$a0, $t0
	syscall
		
	#Stack Restore
	lw	$ra, -4($fp)
	lw	$s0, -8($fp)
	lw	$s1, -12($fp)
	addi	$sp, $sp, 12
	lw	$fp, 0($sp)
	addi	$sp, $sp, 4
	
	jr	$ra

.data
.align 2
rSstring:
	.byte 0x1b, 0x5b, 0x30, 0x6d, 0x00
.text
restoreSettings:
	########################################################################
	# Prints the escape sequence that restores all default color settings to
	# the terminal
	#
	# Register Usage
	# NA
	########################################################################
	la	$a0, rSstring
	li	$v0, 4
	syscall
	
	jr	$ra

.text
startGLIM:
	########################################################################
	# Sets up the display in order to provide
	# a stable environment. Call endGLIM when program is finished to return
	# to as many defaults and stable settings as possible.
	# Unfortunately screen size changes are not code-reversible, so endGLIM
	# will only return the screen to the hardcoded value of 24x80.
	#
	#
	# $a0 = number of rows to set the screen to
	# $a1 = number of cols to set the screen to
	#
	# Register Usage
	# NA
	########################################################################
	# Stack Adjustments
	addi	$sp, $sp, -4		
	sw	$fp, 0($sp)		
	add	$fp, $zero, $sp		
	addi	$sp, $sp, -4		
	sw	$ra, -4($fp)
	
	jal	setDisplaySize
	
	jal	hideCursor
	
	#Stack Restore
	lw	$ra, -4($fp)
	addi	$sp, $sp, 4
	lw	$fp, 0($sp)
	addi	$sp, $sp, 4
	
	jr	$ra
	

.text
endGLIM:
	########################################################################
	# Reverts to default as many settings as it can, meant to end a program
	# that was started with startGLIM. The default terminal window in
	# xfce4-terminal is 24x80, so this is the assumed default we want to
	# return to.
	#
	# Register Usage
	# NA
	########################################################################
	# Stack Adjustments
	addi	$sp, $sp, -4		
	sw	$fp, 0($sp)		
	add	$fp, $zero, $sp		
	addi	$sp, $sp, -4		
	sw	$ra, -4($fp)
	
	li	$a0, 24
	li	$a1, 80
	jal	setDisplaySize
	
	jal	clearScreen
	
	jal	restoreSettings
	jal	showCursor
	li	$a0, 0
	li	$a1, 0
	jal	setCursor
	
	#Stack Restore
	lw	$ra, -4($fp)
	addi	$sp, $sp, 4
	lw	$fp, 0($sp)
	addi	$sp, $sp, 4
	
	jr	$ra
	
.data
.align 2
hCstring:
	.byte 0x1b, 0x5b, 0x3f, 0x32, 0x35, 0x6c, 0x00
.text
hideCursor:
	########################################################################
	# Prints the escape sequence that hides the cursor
	#
	# Register Usage
	# NA
	########################################################################
	la	$a0, hCstring
	li	$v0, 4
	syscall
	
	jr	$ra

.data
.align 2
sCstring:
	.byte 0x1b, 0x5b, 0x3f, 0x32, 0x35, 0x68, 0x00
.text
showCursor:
	########################################################################
	#Prints the escape sequence that restores the cursor visibility
	#
	# Register Usage
	# NA
	########################################################################
	la	$a0, sCstring
	li	$v0, 4
	syscall
	
	jr	$ra

.data
.align 2
sDSstring:
	.byte 0x1b, 0x5b, 0x38, 0x3b, 0x30, 0x30, 0x30, 0x3b, 0x30, 0x30, 0x30, 0x74 0x00
.text
setDisplaySize:
	########################################################################
	# Prints the escape sequence that changes the size of the display to 
	# match the parameters passed. The number of rows and cols are 
	# ints x and y s.t.:
	# 0<=x,y<=999
	#
	# $a0 = number of rows
	# $a1 = number of columns
	#
	# Register Usage
	# $s0 = temporary $a0 storage
	# $s1 = temporary $a1 storage
	########################################################################
	# Stack Adjustments
	addi	$sp, $sp, -4		
	sw	$fp, 0($sp)		
	add	$fp, $zero, $sp		
	addi	$sp, $sp, -12		
	sw	$ra, -4($fp)		
	sw	$s0, -8($fp)		
	sw	$s1, -12($fp)
	
	move	$s0, $a0
	move	$s1, $a1
	
	#rows
	jal	intToChar		#get the digits of the params to print
	
	la	$t0, sDSstring
	lb	$t1, 0($v0)		#alter the string to print
	sb	$t1, 6($t0)
	lb	$t1, 1($v0)
	sb	$t1, 5($t0)
	lb	$t1, 2($v0)
	sb	$t1, 4($t0)
	
	#cols
	move	$a0, $s1
	jal	intToChar		#get the digits of the params to print
	
	la	$t0, sDSstring
	lb	$t1, 0($v0)		#alter the string to print
	sb	$t1, 10($t0)
	lb	$t1, 1($v0)
	sb	$t1, 9($t0)
	lb	$t1, 2($v0)
	sb	$t1, 8($t0)
	
	li	$v0, 4
	move	$a0, $t0
	syscall
	
	#Stack Restore
	lw	$ra, -4($fp)
	lw	$s0, -8($fp)
	lw	$s1, -12($fp)
	addi	$sp, $sp, 12
	lw	$fp, 0($sp)
	addi	$sp, $sp, 4
	
	jr	$ra
	
##############################################################################
#				STUDENT CODE BELOW THIS LINE
##############################################################################
