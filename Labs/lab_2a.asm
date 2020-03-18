; Author : Chencheng Xie
; Created: 10/5/2019 2:49:34 PM
; Version: 2
; Last Modified: 10/7/2019 12:38:53 PM
; This assembly code takes two 2-bytes integer
; Calculate the greatest common divisor of the two number using gcd()

.include "m2560def.inc"
.def ZERO = r19
.def ReL = r20
.def ReH = r21
.def AL = r22
.def AH = r23
.def BL = r24
.def BH = r25

.cseg
	rjmp main

a: .dw 50000			; first parameter
b: .dw 3000			; second parameter

.macro Rem
Loop:
	cp @0, @2		; Compare A & B
	cpc @1, @3		;
	BRLO EndRem		; Jump to finish if A < B
	sub @0, @2		; If A >= B: A =  A - B
	sbc @1, @3		;
	rjmp Loop		; Loop back
EndRem:
.endmacro

.macro Swp
	mov r16, @0		; temp <- A
	mov r17, @1		;
	mov @0, @2		; A <- B
	mov @1, @3		;
	mov @2, r16		; B <- temp
	mov @3, r17		;
.endmacro

main:
	ldi ZL, low(a <<1)	; Let Z point to a
	ldi ZH, high(a <<1)	;
	lpm AL, z+		; Load value a to A
	lpm AH, z		;
	ldi ZL, low(b <<1)	; Let Z point to b
	ldi ZH, high(b <<1)	;
	lpm BL, z+		; Load value b to B
	lpm BH, z		;
	clr ZERO		; Reset ZERO
	rcall gcd		; Call gcd(AL, AH, BL, BH)

halt:
	rjmp halt

gcd: ; Prologue
	push YL			; Save Y on the stack
	push YH			;
	push r16		; Save conflict registers on the stack
	push r17		;
	push AL			;
	push AH			;
	push BL			;
	push BH			;
	in YL, SPL		;
	in YH, SPH		;
	sbiw Y, 4		; Let Y point to the top of the stack frame
	out SPH, YH		; Update SP so that it points to
	out SPL, YL		; the new stack top
	std Y+1, AL		; Get the parameter
	std Y+2, AH		; (AL & AH, BL & BH)
	std Y+3, BL		;
	std Y+4, BH		;
	cpi BL, 0		;
	cpc BH, ZERO		;
	brne L2			; If B!=0
	ldd ReL, Y+1		; B = 0
	ldd ReH, Y+2		; return A
	rjmp L1			; Jump to the epilogue

L2:
	ldd AL, Y+1		; Get A & B values
	ldd AH, Y+2		;
	ldd BL, Y+3		;
	ldd BH, Y+4		;
	Rem AL, AH, BL, BH	; A => A%B
	Swp AL, AH, BL, BH	; A & B swap
	rcall gcd		; call gcd(b, a%b)

L1:	; Epilogue
	adiw Y, 4		; Deallocate the stack frame for gcd()
	out SPH, YH		; Restore SP
	out SPL, YL		;
	pop BH			; Restore original A & B values
	pop BL			;
	pop AH			;
	pop AL			;
	pop r17			; Restore conflict registers
	pop r16			;
	pop YH			; Restore Y
	pop YL			;
	ret			; return
