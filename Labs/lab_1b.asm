; Author : Chencheng Xie
; Created: 9/20/2019 7:59:19 PM
; Version: 2
; Last Modified: 10/1/2019 12:47:13 PM
; This assembly code takes two 2-bytes integer
; Calculate the greatest common divisor of the two number
;pseudo-code:
; int A, B
; while A not equal to B
;	  then if A > B
;		       then A = A - B
;		   else
;		       then B = B - A
;

.include "m2560def.inc"
.def AL = r16		;low byte of A
.def AH = r17		;high byte of A
.def BL = r18		;low byte of B
.def BH = r19		;high byte of B

;ldi AL, low(0x1000)	;for testing purpose
;ldi AH, high(0x1000)	;load magic number into A,B registers
;ldi BL, low(0x0400)	;
;ldi BH, high(0x0400)	;

loop:
	cp BL, AL		;compare low bytes of A and B
	cpc BH, AH		;compare high bytes of A and B with carry
	BREQ END		;if A and B are equal, jump straight to END
	BRLO IF			;else if A > B, jump to IF
	sub BL, AL		;		else low(B) = low(B) - low(A)
	sbc BH, AH		;			high(B) = high(B) - high(A)
	rjmp loop		;loop back to top
IF:
	sub AL, BL		;low(A) = low(A) - low(B)
	sbc AH, BH		;high(A) = high(A) - high(B)
	rjmp loop		;loop back to top

END:
	rjmp END		;END
