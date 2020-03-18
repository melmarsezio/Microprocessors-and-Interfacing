; Author : Chencheng Xie
; Created: 9/20/2019 7:59:19 PM
; Version: 2
; Last Modified: 9/24/2019 12:47:13 PM
; This assembly code takes two inputs which are read as ASCII code character
; and convert them into a binary number.
; The way characters are interpreted is determined by the leftmost bit,
; 1 for hexadecimal and 0 for decimal.
; eg: 1 0x37 0x38 = "78" as 0x78 = 0b0111 1000, 0 0x37 0x38 = "78" as 78 = 0b0100 1110.
;     ^											^
;pseudo-code:
; character A, B
; integer result
; if leftmost bit is 1
; 	then A = A - '0'		//it's hexadecimal
; 		B = B - '0'
;  		if A > 9		// A is a letter
; 			then A = A - 7
; 		if B > 9		// B is a letter
; 			then B = B - 7
; 		result = B
; 		result = result + (A<<4)
; 	else A = A - '0'		//it's decimal
; 		 B = B - '0'
; 		 result = B
; 		 result = result + A * 10
; return result

.include "m2560def.inc"
.def input_A = r16	;define input for A and B which is first character
.def input_B = r17	;and second character
.def char_A = r19	;char_A and char_B are the value bits of input_A and input_B
.def char_B = r20	;(char_A is first 7 bits of input_A and char_B == input_B)
.def result = r18	;store the final result of two digits

;read:
;	ldi input_A, 0b00110111	;read two character from somewhere else
;	ldi input_B, 0b00111000	;assume some values for testing purpose only

main:
	mov char_A, input_A		;copy input_A into char_A
	lsl char_A			;clear 7th bit of char_A
	lsr char_A			;
	mov char_B, input_B		;copy input_B into char_B
	cpi input_A, 0x80		;compare input_A with 10000000 to see if its hexa or decimal
	brsh HEXA			;if same or higher, its hexadecimal
	rjmp DECI			;otherwise, its decimal

HEXA:
	subi char_A, 0x30		;subtract char_A by ascii of '0' to get distance to '0'
	subi char_B, 0x30		;subtract char_B by ascii of '0' to get distance to '0'
	rjmp CHECK_A			;check if char_A is letter (A~F)

CHECK_A:
	cpi char_A, 0x0A		;if char_A is greater or equal to 0x0A
	brsh LETT_A			;convert that value into hexadecimal
	rjmp CHECK_B			;otherwise, check if char_B is letter (A~F)

LETT_A:
	subi char_A, 0x07		;subtract char_A by 0x07 (distance between '9' and 'A')
	rjmp CHECK_B			;check if char_B is letter (A~F)

CHECK_B:
	cpi char_B, 0x0A		;same as CHECK_A
	brsh LETT_B			;same as LETT_A
	rjmp CALC			;otherwise, jump to branch CALC to sum up two digits

LETT_B:
	subi char_B, 0x07		;same as LETT_A
	rjmp CALC			;otherwise, jump to branch CALC to sum up two digits

CALC:
	lsl char_A			;left shift char_A 4 times
	lsl char_A			;so char_A is on high bits
	lsl char_A			;
	lsl char_A			;
	mov result, char_A		;copy char_A to result (with char_A << 4)
	add result, char_B		;add char_B to the result (char_B stays at low bits)
	rjmp END			;finish

DECI:
	subi char_A, 0x30		;subtract char_A by ascii of '0' to get distance to '0'
	subi char_B, 0x30		;subtract char_B by ascii of '0' to get distance to '0'
	mov result, char_B		;copy char_B into result
	ldi char_B, 0x0A		;load char_B  with 10(since we cope char_B into result already, char_B is spared)
	mul char_A, char_B		;char_A times 10
	add result, R0			;add the multiplication to the result
	rjmp END			;finish

END:
	rjmp END			;finish
