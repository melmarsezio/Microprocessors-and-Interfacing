; Author : Chencheng Xie
; Created: 10/21/2019 2:49:34 PM
; Version: 1
; Last Modified: 10/22/2019 20:56:26 PM
; This program gets two number from keypad and display the multiplication of them on LCD
; e.g. To calculate 12X9, we press: '1','2','*','9','#'
; LED is flashed 3 times if the result was overflow
; Port L is used for keypad,RL7-4 connect to C3-0, RL3-0 connect to R3-0.
; Port F is used to display the numbers on LCD.
; Port C is used to control LED overflow flash

.include "m2560def.inc"

.def row    =r16		; current row number
.def col    =r17		; current column number
.def rmask  =r18		; mask for current row
.def cmask  =r19		; mask for current column
.def temp1  =r20
.def temp2  =r21
.def result =r22
.def B =r23
.def carry  =r24
.def overflow =r26
.def temp3  =r27


.equ PORTLDIR = 0xF0		; use PortL for input/output from keypad: PL7-4, output, PL3-0, input
.equ INITCOLMASK = 0xEF		; scan from the leftmost column, the value to mask output
.equ INITROWMASK = 0x01		; scan from the bottom row
.equ ROWMASK  = 0x0F		; low four bits are output from the keypad. This value mask the high 4 bits.


.macro do_lcd_command		; sent command to LCD
	ldi r25, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro

.macro do_lcd_data		; sent data to LCD
	mov r25, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

.macro Rem; A, B, C		; calculate remainder, A-> A%B, C-> A/B, B is unchanged
	ldi @2, 0
Loop:
	cpi @0, @1		; Compare A & B
	BRLO EndRem		; Jump to finish if A < B
	subi @0, @1		; If A >= B: A =  A - B
	inc @2			; Increase C
	rjmp Loop		; Loop back
EndRem:				; when Rem finish, A will be A%B, C will be A/B
.endmacro

.macro display_number
	push temp1		; save temp1 and temp2 in case they still hold useful values
	push temp2
	mov temp1, @0
	cpi temp1, 100
	brsh digit_3		; if number >= 100, we have 3 digits
	cpi temp1, 10
	brsh digit_2		; if number >= 10, we have 2 digits
	subi temp1, -'0'	; else: we have only 1 digit, display ascii of that number by adding '0' to number
	do_lcd_data temp1
	rjmp display_finish
digit_3:
	Rem temp1, 100, temp2	;print the quotient and get remainder overwrite
	subi temp2, -'0'	; print quotient on LCD
	do_lcd_data temp2
	Rem temp1, 10, temp2
	subi temp2, -'0'
	do_lcd_data temp2
	subi temp1, -'0'
	do_lcd_data temp1
	rjmp display_finish
digit_2:
	Rem temp1, 10, temp2
	subi temp2, -'0'
	do_lcd_data temp2
	subi temp1, -'0'
	do_lcd_data temp1
	rjmp display_finish
display_finish:
	pop temp2		; resume temp2 and temp1 from stack
	pop temp1
	rjmp display_end
display_end:
.endmacro

rjmp RESET

RESET:
	;reset keypad
	ldi temp1, PORTLDIR	; columns are outputs, rows are inputs
	sts DDRL, temp1
	ser temp1		; PORTC is outputs
	out DDRC, temp1
	clr temp1
	out PORTC, temp1	; empty the LED
	clr result		; reset all operands and carry
	clr B
	clr carry
	clr overflow

	;reset LCD
	ser r25
	out DDRF, r25		; set Port A & F as output Port
	out DDRA, r25
	clr r25
	out PORTF, r25		; empty Port A & F
	out PORTA, r25
	; initialize LCD
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000 ; 2x5x7
	;do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001000 ; display off
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001100 ; Cursor on, bar, no blink

main:
	ldi cmask, INITCOLMASK	; initial column mask
	clr col			; initial column
colloop:
	cpi col, 4
	breq main
	sts PORTL, cmask	; set column to mask value (one column off)
	ldi temp1, 0xFF
delay:
	dec temp1
	brne delay

	lds temp1, PINL		; read PORTL
	andi temp1, ROWMASK
	cpi temp1, 0xF		; check if any rows are on
	breq nextcol		; if yes, find which row is on
	ldi rmask, INITROWMASK	; initialise row check
	clr row			; initial row
rowloop:
	cpi row, 4
	breq nextcol
	mov temp2, temp1
	and temp2, rmask	; check masked bit
	breq convert 		; if bit is clear, convert the bitcode
	inc row			; else move to the next row
	lsl rmask		; shift the mask to the next bit
	jmp rowloop
nextcol:
	lsl cmask		; else get new mask by shifting and
	inc col			; increment column value
	jmp colloop		; and check the next column

convert:
	cpi col, 3		; if col is 3, we have letters(not useful here) and we jump back to main
	breq letters
	cpi row, 3		; if row is 3 we have a symbol or 0
	breq symbols

	mov temp1, row		; otherwise we have a number in 1-9
	lsl temp1
	add temp1, row		; temp1 = row * 3
	add temp1, col		; add the column address to get the value
	subi temp1, -1		; add the value of character '0'
	mov temp2, temp1
	subi temp2, -'0'
	do_lcd_data temp2

	mov temp3, result
	mov temp2, result	; result times 10
	lsl result
	lsl result
	lsl result
	lsl temp2
	add result, temp2
	add result, temp1	; add current number to the result
	cp result, temp3
	brlo num_OVF
	jmp convert_end

letters:
	do_lcd_command 0b00000001	; clear LED
	clr result		; reset numbers if 'A','B','C' or 'D' is pressed
	clr B
	clr carry
	clr overflow
	jmp convert_end
symbols:
	cpi col, 0		; check if we have a star
	breq star
	cpi col, 1		; or if we have zero
	breq zero
	jmp equal

star:
	ldi temp2, '*'
	do_lcd_data temp2
	mov B, result		; save result to B
	clr result		; clear result, get ready for next number
	jmp convert_end
zero:
	ldi temp2, '0'
	do_lcd_data temp2
	mov temp3, result
	mov temp2, result	; result times 10
	lsl result
	lsl result
	lsl result
	lsl temp2
	add result, temp2
	cp result, temp3
	brlo num_OVF
	jmp convert_end

num_OVF:
	ser overflow
	jmp convert_end

equal:
	ldi temp2, '='
	do_lcd_data temp2
	push r0			; otherwise: we have '#'
	push r1
	mul result, B
	mov result, r0
	mov carry, r1
	pop r1
	pop r0
	display_number result
	jmp convert_end
convert_end:
	;do_lcd_command 0b00000001	; clear LED
	;display_number result		; display results on LEDS

	
	;jmp flash			; check carrys
	cpi overflow, 0
	brne flash
	cpi carry, 0
	brne flash
back:
	rcall sleep_200ms		; delay for 0.4s
	rcall sleep_200ms
	jmp main			; restart main loop

flash:					; LED flash 3 times
	ser temp1
	out PORTC, temp1
	rcall sleep_200ms
	clr temp1
	out PORTC, temp1
	rcall sleep_200ms
	ser temp1
	out PORTC, temp1
	rcall sleep_200ms
	clr temp1
	out PORTC, temp1
	rcall sleep_200ms
	ser temp1
	out PORTC, temp1
	rcall sleep_200ms
	clr temp1
	out PORTC, temp1
	rcall sleep_200ms
	jmp back

.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4
; 4 cycles per iteration - setup/call-return overhead

sleep_1ms:
	push r24
	push r25
	ldi r25, high(DELAY_1MS)
	ldi r24, low(DELAY_1MS)
delayloop_1ms:
	sbiw r25:r24, 1
	brne delayloop_1ms
	pop r25
	pop r24
	ret

sleep_5ms:
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	ret

sleep_25ms:
	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	ret

sleep_100ms:
	rcall sleep_25ms
	rcall sleep_25ms
	rcall sleep_25ms
	rcall sleep_25ms
	ret

sleep_200ms:
	rcall sleep_100ms
	rcall sleep_100ms
	ret

.equ LCD_RS = 7
.equ LCD_E = 6
.equ LCD_RW = 5
.equ LCD_BE = 4

.macro lcd_set
	sbi PORTA, @0
.endmacro

.macro lcd_clr
	cbi PORTA, @0
.endmacro

; Send a command to the LCD (r16)

lcd_command:
	out PORTF, r25
	nop
	lcd_set LCD_E
	nop
	nop
	nop
	lcd_clr LCD_E
	nop
	nop
	nop
	ret

lcd_data:
	out PORTF, r25
	lcd_set LCD_RS
	nop
	nop
	nop
	lcd_set LCD_E
	nop
	nop
	nop
	lcd_clr LCD_E
	nop
	nop
	nop
	lcd_clr LCD_RS
	ret

lcd_wait:
	push r25		;save conflict register on stack
	clr r25
	out DDRF, r25		; set Port F as input port
	out PORTF, r25
	lcd_set LCD_RW
lcd_wait_loop:
	nop
	lcd_set LCD_E
	nop
	nop
    nop
	in r25, PINF
	lcd_clr LCD_E
	sbrc r25, 7		; check if BF is 0
	rjmp lcd_wait_loop
	lcd_clr LCD_RW
	ser r25
	out DDRF, r25
	pop r25			;resume conflict register from stack
	ret
