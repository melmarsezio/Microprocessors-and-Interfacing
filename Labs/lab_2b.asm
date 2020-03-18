; Author : Chencheng Xie
; Created: 10/13/2019 2:49:34 PM
; Version: 1
; Last Modified: 10/16/2019 12:38:53 PM
; Microcontroller repeatedly display 3 patterns through LED
; LED halted when PB0 is pressed
; LED resume when PB0 is released
; Push Button input: PORTD 0
; LED output: PORTC 0~7
; loop cycle calculation:
; 1s -> 16x10^6 cycles, 0.5s -> 8x10^6 cycles
; loop_count = (8000000 - 10)/12 = 666666

.include "m2560def.inc"
.equ loop_count = 166666666	; number of loops
.equ PATTERNA = 0b00111100	; pattern #1
.equ PATTERNB = 0b11110000 	; pattern #2
.equ PATTERNC = 0b00001111	; pattern #3
.def OUTPAT = r16			; define register to store output pattern
.def counter = r17			; counter for repeating patterns
.def temp = r19				; use to set DDR and 0 for calculation
.def loop1 = r20			; 1st byte of the number of loop
.def loop2 = r21			; 2nd byte
.def loop3 = r22			; 3rd byte
.def loop4 = r23			; 4th byte
.def i1 = r24				; 1st byte of counter in loop_count
.def i2 = r25				; 2nd byte
.def i3 = r26				; 3rd byte
.def i4 = r27				; 4th byte
.def switch = r18			; store whether sequence is switch on/off
.def lastSig = r29			; record the last PB signal
.def curSig = r30			; record current PB signal

rjmp prep					; go to start of code

.macro halfSecondDelay		; delay for 0.5 sec
	clr i1 ; 1
	clr i2 ; 1
	clr i3 ; 1
	clr i4 ; 1
loop:
	cp i1, loop1	; 1
	cpc i2, loop2	; 1
	cpc i3, loop3	; 1
	cpc i4, loop4	; 1
	brsh done		; 1, 2 (if true)
	subi i1, -1		; 1
	adc i2, temp	; 1
	adc i3, temp	; 1
	adc i4, temp	; 1
	nop				; 1
	rjmp loop		; 2
done:
.endmacro

.macro nextpat		; get pattern store in OUTPAT
	sbrs switch, 0	; if switch last bit is 0, keep current pattern
	rjmp END		; and return to main
	cpi counter, 0	; if counter == 0
	breq A			; store pattern #1
	cpi counter, 1	; if counter == 1
	breq B			; store pattern #2
	cpi counter, 2	; if counter == 2
	breq C			; store pattern #3
A:
	inc counter
	ldi @0, PATTERNA
	rjmp END
B:
	inc counter
	ldi @0, PATTERNB
	rjmp END
C:
	subi counter, 2
	ldi @0, PATTERNC
	rjmp END
END:

.endmacro

prep:
	ldi loop1, low(loop_count)		; load number of loop
	ldi loop2, high(loop_count)	;
	ldi loop3, byte3(loop_count)	;
	ldi loop4, byte4(loop_count)	;
	cbi DDRD, 0			; set DDRD bit 0 as input
	ser temp			; temp = 0xFF
	out DDRC, temp		; set Port C for output
	ldi counter, 0		; initialize counter
	clr temp			; temp = 0(zero) for calculation
	ldi switch, 1		; switch on
	in lastSig, PIND

main:
	sbis PIND, 0		; skip next instruction if PIND bit 0 is set
	rjmp Button			; Button is pressed
	in lastSig, PIND	; store PIND as last PB signal for next PB comparison


next:
	nextpat OUTPAT		; get next pattern
	out PORTC, OUTPAT	; set PORTC to output pattern
	halfSecondDelay		; delay for 0.5s
	rjmp main			; loop back to main

Button:
	in curSig, PIND		; get current PIND signal
	cp curSig, lastSig	; compare current signal and last signal
	brlo press			; jump to press only last 1 cur 0 (falling edge)
	mov lastSig, curSig	; copy current signal as last signal
	rjmp next			; return back to main
	
press:					; if button is pressed
	inc switch			; turn switch
	mov lastSig, curSig	; copy current signal as last signal
	rjmp next			; return back to main
