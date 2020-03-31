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
#
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
	andi $t0, $a0, 0x8000  #Check for interrupts
    andi $t1, $a0, 0x0800  #Check for interrupts
	beq $t0, $zero, keyboardinput #if zero it is interrupt so jump
   #############just a bunch of cleaning up in steps#################
steps:	
	
	mtc0 $zero, $9		
	addi $a0 $zero 1000
	mtc0 $a0 $11
		
    li $v0, 4
    la $a0, msg
    syscall
	
    
	
    
keyboardinput:
    beq $t1, $zero, finish #if zero it is interrupt so jump
        #lw      $a0, 0xffff0000
		#andi 	$a0,$a0, 0x01		
		#beq	    $a0, $zero, finish
     
      li $v0, 4
        la $a0, msg2
        syscall

keyboardinput:
        lw      $a0, 0xffff0000
		andi 	$a0,$a0, 0x01		
		beq	    $a0, $zero, seecauseregister
        
        
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
		
input8:
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
    bge $t2,$zero gotoupdateCursor
    addi $t2,$t6,-1
    sw $t2, 0($t0)
	j gotoupdateCursor#

input2:
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
    blt $t2,$t6 gotoupdateCursor
    addi $t2,$zero,0
    sw $t2, 0($t0)
	j gotoupdateCursor#
        
input4:
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
    bge $t3,$zero gotoupdateCursor
    addi $t3,$t7,-1
    sw	$t3, 0($t1) #col
	j gotoupdateCursor#
        
input6:
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
    blt $t3,$t7 gotoupdateCursor
    addi $t3,$zero,0
    sw	$t3, 0($t1) #col
	j gotoupdateCursor#
        
input5:   #toggles the cell under the cursor from dead to live or from live to dead
    la	$t0, newCursorRow
	la	$t1, newCursorCol
    lw	$t2, 0($t0) #row
	lw	$t3, 0($t1) #col
    la	$t4, gameRows	
	la	$t5, gameCols
    lw	$t6, 0($t4)  #gameRows
	lw	$t7, 0($t5)     #gameCols

    la $t5 ,gameBoard   #gameBoard address
    mul $t4, $t2, $t7
    add $t4, $t4, $t3 #t4= pos
    add $t4, $t4, $t5 #t4= pos address
    lb $t0,0($t4)
    beq $t0,$zero,toggleto1
    addi,$t0,$zero,0
    sb $t0,0($t4)
    addi 	$s0,$zero,22
    j 	seecauseregister
 toggleto1:addi,$t0,$zero,1
   sb $t0,0($t4)
   addi 	$s0,$zero,22
    j 	seecauseregister
   

        
        #'7' plays/pauses the simulation	
input7:
        la	$t0, gameresume
	    lw	$t2, 0($t0) #row
        beq $t2,$zero,gameresume1
        addi $t2,$zero,0
        sw	$t2, 0($t0) #row
        j seecauseregister
gameresume1:
        addi $t2,$t2,1
        sw	$t2, 0($t0) #row
		j 	seecauseregister					#
        
        
        #'3' moves the simulation by 1 tick manually
input3:
        la	$t0, onetick
	    lw	$t2, 0($t0) #row
        addi $t2,$zero,1
        sw	$t2, 0($t0) #row    
		j 	seecauseregister					#
        
inputq:
    addi 	$s0,$zero,23
    j 	seecauseregister
    
gotoupdateCursor:
    addi 	$s0,$zero,24
    

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
#############################################################
##############   MAIN ######################################
#############################################################
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
haskeypress: 	.word 0
	#保存游戏运行还是暂停0 暂停，1运行
gameresume: 	.space 4
onetick: 	.space 4
batchPrintinf0:  .space 9612
.text
.globl main
main:
# Stack Adjustments
	addi	$sp, $sp, -4		
	sw	$fp, 0($sp)		
	add	$fp, $zero, $sp		
	addi	$sp, $sp, -12		
	sw	$ra, -4($fp)		
	sw	$s0, -8($fp)		
	sw	$s1, -12($fp)

    #batchPrintinf0 构造
    la	$t0, gameresume
	lw	$zero, 0($t0) #游戏开始处于暂停状态
    la	$t0, gameRows	
	la	$t1, gameCols
    lw	$t2, 0($t0)  #gameRows
	lw	$t3, 0($t1)     #gameCols
    la  $t0, batchPrintinf0
    sh  $t2 ,0($t0)
    sh  $t3 ,2($t0)
    addi $t1,$zero,1
    sb   $t1 ,4($t0) 
    la  $t0,gameBoard
    sw   $t0,8($t0)
    
        # Enable interrupts for console
        jal     console_int_enable
        
        #s0和t6一起用来判断键盘输入是否为q
        addi 	$s0,$zero,24
mainloop:
		addi 	$t6,$zero,23
        beq 	$s0,$t6,exitmain					#exit
        
        addi 	$t6,$zero,22
        bne 	$s0,$t6,gotoonetick					#updateCursor
        jal updateCursor
        
 gotoonetick:#one tick mannal
        la	$t0, onetick
	    lw	$t2, 0($t0) #row
        beq $t2,$zero, stoporresume
        addi $t2,$zero, 0
        sw	$t2, 0($t0) #row
        jal updateBoard       
        
stoporresume:
        la	$t0, gameresume
	    lw	$t2, 0($t0) #resume or not
        beq $t2,$zero,mainloop
        jal updateBoard       
        
        
        
        la $a0,batchPrintinf0
        jal batchPrint 
        
        
        
		j 	mainloop					#

        #

        
exitmain:
        #Stack Restore
	lw	$ra, -4($fp)
	lw	$s0, -8($fp)
	lw	$s1, -12($fp)
	addi	$sp, $sp, 12
	lw	$fp, 0($sp)
	addi	$sp, $sp, 4
	
	jr	$ra
    
    #$a0 = row of byte to get
    #$a1 = column of byte to get
getByte:
    la $t5 ,gameBoard   #gameBoard address
    la	$t0, gameRows	
	la	$t1, gameCols
    lw	$t2, 0($t0)  #gameRows
	lw	$t3, 0($t1)     #gameCols
    
    blt $a0,$zero,rowless0
    bge $a0,$t2,gterow
    j checkcol
rowless0:add $a0,$a0,$t2
    blt $a0,$zero,rowless0    
    j checkcol
gterow:sub $a0,$a0,$t2
    bge $a0,$t2,gterow
    
    
checkcol:
    blt $a1,$zero,colless0
    bge $a1,$t3,gtecol
    j calpos
colless0:add $a1,$a1,$t3
    blt $a1,$zero,colless0
    j calpos
gtecol:sub $a1,$a1,$t3
    bge $a1,$t3,gtecol    
    
calpos:
    mul $t4, $a0, $t3
    add $t4, $t4, $a1 #t4= pos
    add $t4, $t4, $t5 #t4= pos address
    lb $v0,0($t4)
    jr	$ra

    #$a0 = row of byte to get
    #$a1 = column of byte to get
    #$a2 = value to set the byte to (0 or 1)
    #$a3 = start address of list representing a 2D byte array (&gameBoard or &newGameBoard)
setByte:    
    la	$t0, gameRows	
	la	$t1, gameCols
    lw	$t2, 0($t0)  #gameRows
	lw	$t3, 0($t1)     #gameCols
    
    blt $a0,$zero,setByterowless0
    bge $a0,$t2,setBytegterow
    j setBytecheckcol
setByterowless0:add $a0,$a0,$t2
    blt $a0,$zero,setByterowless0    
    j setBytecheckcol
setBytegterow:sub $a0,$a0,$t2
    bge $a0,$t2,setBytegterow
    
    
setBytecheckcol:
    blt $a1,$zero,setBytecolless0
    bge $a1,$t3,setBytegtecol
    j setBytecalpos
setBytecolless0:add $a1,$a1,$t3
    blt $a1,$zero,setBytecolless0
    j setBytecalpos
setBytegtecol:sub $a1,$a1,$t3
    bge $a1,$t3,setBytegtecol    
    
setBytecalpos:
    mul $t4, $a0, $t3
    add $t4, $t4, $a1 #t4= pos
    add $t4, $t4, $a3 #t4= pos address
    sb  $a2,0($t4)
    jr	$ra
 

    

    #打开键盘和timer中断并把时间设成1秒
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
        
        
        
############################################################
#							   #
#	Update Auxiliar Array				   #
#							   #
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
 #更新gameboard
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
    lw	$s2, 0($t0)  #gameRows
	lw	$s3, 0($t1)     #gameCols
    
    la $s5 ,gameBoard   #gameBoard address
    la $s6 ,newGameBoard   #newGameBoard address   
    
    addi	$s0,	$zero, 	0    #rowid loop
    addi	$s1,	$zero, 	0    #colid loop
    
    
    verify_loop:
	bge	$s0, 	$s2, 	endupdateBoard
    addi	$s1,	$zero, 	0    #colid=0
    colloop:
    bge $s1 , $s3,rowidplus
	
    
    
	verify:
    move	$a0, 	$s0
    move	$a1, 	$s1
    jal getByte
	move	$s7,	$v0  #rowid colid的值
	addi	$a2,	$zero, 	0	#a2 计数周围 有几个livecell
    
	verify_1:
    addi	$a0, 	$s0,	0
    addi	$a1, 	$s1,	1
    
	li	$t2,	1
	jal getByte
	move	$s4,	$v0  #rowid colid的值
	seq	$t2,	$s4,	$t2
	add	$a2,	$a2,	$t2
    
	
	verify_2:
	addi	$a0, 	$s0,	0
    addi	$a1, 	$s1,	-1
    
	li	$t2,	1
	jal getByte
	move	$s4,	$v0  #rowid colid的值
	seq	$t2,	$s4,	$t2
	add	$a2,	$a2,	$t2
	
	verify_3:
	addi	$a0, 	$s0,	1
    addi	$a1, 	$s1,	-1
    
	li	$t2,	1
	jal getByte
	move	$s4,	$v0  #rowid colid的值
	seq	$t2,	$s4,	$t2
	add	$a2,	$a2,	$t2
	
	verify_4:
	addi	$a0, 	$s0,	1
    addi	$a1, 	$s1,	0
    
	li	$t2,	1
	jal getByte
	move	$s4,	$v0  #rowid colid的值
	seq	$t2,	$s4,	$t2
	add	$a2,	$a2,	$t2
	
	verify_5:
	addi	$a0, 	$s0,	1
    addi	$a1, 	$s1,	1
    
	li	$t2,	1
	jal getByte
	move	$s4,	$v0  #rowid colid的值
	seq	$t2,	$s4,	$t2
	add	$a2,	$a2,	$t2
	
	verify_6:
	addi	$a0, 	$s0,	-1
    addi	$a1, 	$s1,	-1
    
	li	$t2,	1
	jal getByte
	move	$s4,	$v0  #rowid colid的值
	seq	$t2,	$s4,	$t2
	add	$a2,	$a2,	$t2
	
	verify_7:
	addi	$a0, 	$s0,	-1
    addi	$a1, 	$s1,	0
    
	li	$t2,	1
	jal getByte
	move	$s4,	$v0  #rowid colid的值
	seq	$t2,	$s4,	$t2
	add	$a2,	$a2,	$t2
	
	verify_8:
	addi	$a0, 	$s0,	-1
    addi	$a1, 	$s1,	1
    
	li	$t2,	1
	jal getByte
	move	$s4,	$v0  #rowid colid的值
	seq	$t2,	$s4,	$t2
	add	$a2,	$a2,	$t2
	
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
	j	verify_end
	
	verify_dies:
	move	$a0, 	$s0
    move	$a1, 	$s1
    addi	$a2, 	$zero,0
    la      $a3 ,newGameBoard   #newGameBoard address   
    jal setByte
	j	verify_end
	
	verify_end:
    #addiu	$t1,	$t1, 	1
    addi	$s1,$s1,1 #col ++
	j	colloop
    
    rowidplus:
    addi	$s0,$s0,1 #rowid++
    j verify_loop
    
    
	endupdateBoard:
    
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

