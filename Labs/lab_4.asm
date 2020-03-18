; Author : Chencheng Xie
; Created: 11/4/2019 9:29:37 PM
; Version: 1
; Last Modified: 11/5/2019 12:03:37 AM
; This program measures the speed of mot and displays the speed (RPS) on LCD
; The motor speed can be adjusted by the POT (potentiometer).
; Port A is used to control LCD functions
; Port F is used to display the numbers on LCD.
; POT is connected to MOT
; OpO is connected to INT0 to generate interrupts

.include "m2560def.inc"
.def counter = r16
.def temp1	=r17
.def temp2  =r18
.equ factor = 1

	jmp RESET		; interrupts vectors
.org INT0addr
	jmp EXT_INT0

.macro do_lcd_command		; ent command to LCD
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
	ldi temp1, (2<<ISC00)	;set interrupt 0 trigger mode to falling edge
	sts EICRA, temp1

	in temp1, EIMSK
	ori temp1, (1<<INT0)	; enable interrupt 0
	out EIMSK, temp1
	clr counter

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
	sei
	jmp OUTPUTLCD

EXT_INT0:			; interrupt triggered when OpO has falling edge
	push temp1
	in temp1, SREG
	push temp1
	inc counter		; increase counter by 1 (has one OpO signal)
	pop temp1
	out SREG, temp1
	pop temp1
	reti			; return

OUTPUTLCD:				; update RPS
	do_lcd_command 0b00000001	; clear lcd
	ldi temp1, factor
	mul counter, temp1
	mov counter, r0			; calculate RPS & store in counter
	ldi temp1, 'R'			; print 'R'
	do_lcd_data temp1
	ldi temp1, 'P'			; print 'P'
	do_lcd_data temp1
	ldi temp1, 'S'			; print 'S'
	do_lcd_data temp1
	ldi temp1, ':'			; print ':'
	do_lcd_data temp1
	display_number counter		; display ascii of RPS
	clr counter			; reset counter
	rcall sleep_250ms		; wait for 100ms (interrupts can happend during this time)
	rjmp OUTPUTLCD			; loop back to update lcd again


.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4
; 4 cycles per iteration - setup/call-return overhead

sleep_1ms:			; wait for 1ms
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

sleep_5ms:			; wait for 5ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	ret

sleep_25ms:			; wait for 25ms
	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	ret

sleep_250ms:			; wait for 100ms
	rcall sleep_25ms
	rcall sleep_25ms
	rcall sleep_25ms
	rcall sleep_25ms
	rcall sleep_25ms
	rcall sleep_25ms
	rcall sleep_25ms
	rcall sleep_25ms
	rcall sleep_25ms
	rcall sleep_25ms
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

; Send a command to the LCD (r25)
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
	push r25		; save conflict register on stack
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
