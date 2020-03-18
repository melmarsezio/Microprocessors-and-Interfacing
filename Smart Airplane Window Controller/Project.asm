; Created: 11/4/2019 1:24:14 PM
; Author : Chencheng Xie
; Version: 1
; Last Modified: 11/7/2019 03:03:27 AM
; This program simulate the window control operations in an airplane.
; The key '1' and '4' turns the opaque level of window_1 up and down.
; The key '2' and '5' turns the opaque level of window_2 up and down.
; The key '7' and '*' turns the opaque level of window_3 up and down.
; The key '8' and '0' turns the opaque level of window_4 up and down.
; The key 'C' and 'D' turns the opaque level of all windows CLEAR and DARL (central control).
; The push button 0 represent emergency situation, it turns all windows clear.
; The hierarchy of authority is: Emergency > Central control Clear = Central control Dark > Local control.
; So when emergency happens, nothing else can control windows.
; When window is central controlled, no local control can be down.
; LCD screen shows the control status and also window opaque level.

.include "m2560def.inc"
.def delay1 = r8			; to count 0.5s delay for change to happen for window 1
.def delay2 = r9			; to count 0.5s delay for change to happen for window 2
.def delay3 = r10			; to count 0.5s delay for change to happen for window 3
.def delay4 = r11			; to count 0.5s delay for change to happen for window 4
.def timer1 = r12			; timer for window 1, since those register are below r16, need mov temp2 register(r31) to do the comparesion
.def timer2 = r13			; timer for window 2
.def timer3 = r14			; timer for window 3
.def timer4 = r15			; timer for window 4
.def light = r16			; light level value of all windows, bit0&1 for window 1, bit2&3 for window 2, bit4&5 for window 3, bit6&7 for window 4
.def store = r17			; for temporary store key press 7~6/5~4/3~2/1~0 for level up and level down of window 4/3/2/1


.def curLightLevel = r20	; current light level to simulate whether which LED show be on/off
.def timer = r21			; to create time delay
.def change = r22			; status whether some key is pressed, if not, LCD will not be refreshed
.def emerg = r23			; status of emergency
.def centrC = r24			; status of central control CLEAR
.def centrD = r25			; status of central control DARK

.def row    =r26			; current row number
.def col    =r27			; current column number
.def rmask  =r28			; mask for current row
.def cmask	=r29			; mask for current column
.def temp1	=r30			; for temporarily operations
.def temp2  =r31			; for temporarily operations

.equ bounceDelay = 100		; 1 delay = 2ms, to control the length of delay
.equ localDelay = 250		; 
.equ PORTLDIR =0xF0			; use PortL for input/output from keypad: PL7-4, output, PL3-0, input
.equ INITCOLMASK = 0xEF		; scan from the leftmost column, the value to mask output
.equ INITROWMASK = 0x01		; scan from the bottom row
.equ ROWMASK  =0x0F			; low four bits are output from the keypad. This value mask the high 4 bits.



.macro do_lcd_command		; sent command to LCD
	push r25
	ldi r25, @0
	rcall lcd_command
	rcall lcd_wait
	pop r25
.endmacro

.macro do_lcd_data			; sent data to LCD
	push r25
	mov r25, @0
	rcall lcd_data
	rcall lcd_wait
	pop r25
.endmacro

.macro lightLoop			; to simulate changing level of current light
	cpi curLightLevel, 2	; curLightLevel is looping from 0~2
	breq zero				; each window has lightLevel from 0~3
	inc curLightLevel		; if curLightLevel < window lightLevel
	rjmp loopend			; the corresponding LED bits are on
zero:						; otherwise, off
	ldi curLightLevel, 0
loopend:
.endmacro

	jmp RESET				; reset interrupt vector
	jmp EXT_int0			; emergency interrupt vector

EXT_int0:					;
	cpi timer, bounceDelay	; only word until delay length is reached
	brne emerg_end
	cpi emerg, 0x00			; if emerg is off
	breq emerg_on			; turn it on
	clr emerg				; otherwise, turn it off
	ser change				; some button is pressed, change happened, LCD refresh
	clr timer				; reset delay timer
	rjmp emerg_end
emerg_on:					; turn emerg on
	ser emerg
	ser change				; some button is pressed, change happened, LCD refresh
	clr timer				; reset delay timer
emerg_end:
	reti

RESET:
	;reset LCD-----------
	ser temp1
	out DDRF, temp1			; set Port A & F as output Port
	out DDRA, temp1
	clr temp1
	out PORTF, temp1		; empty Port A & F
	out PORTA, temp1
	;--------------------
	; initialize LCD-----
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000 ; 2x5x7
	;do_lcd_command 0b00111000; 2x5x7
	do_lcd_command 0b00001000 ; display off
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001100 ; Cursor off, bar, no blink
	;--------------------
	;reset keypad--------
	ldi temp1, PORTLDIR		; columns are outputs, rows are inputs
	sts	DDRL, temp1
	;--------------------
	;reset LED-----------
	ser temp1
	out DDRC, temp1			; set PORTC as output (LED)
	clr temp1
	OUT PORTC, temp1		; empty LED
	;--------------------
	; setup interrupt ---
	ldi temp1, (2<<ISC00)
	sts EICRA, temp1		; set PB0 interrupt to falling edge
	in temp1, EIMSK
	ori temp1, (1<<INT0)	; enable INT0 (PB0)
	out EIMSK, temp1
	;--------------------
	;reset status registers
	clr light				; initialise all window lights level
	clr curLightLevel		; initial current light level
	clr timer				; reset delay timer for emerg/central CLEAR/central DARK
	clr timer1				; reset delay timer for window 1
	clr timer2				; reset delay timer for window 2
	clr timer3				; reset delay timer for window 3
	clr timer4				; reset delay timer for window 4
	clr change				; reset change (no button is pressed currently)
	clr emerg				;emerg = 0x00 means no emergency, otherwise 0xFF
	clr centrC				;centrC = 0x00 means no central control, central contol CLEAR if 0xFF
	clr centrD				;centrD = 0x00 means no central control, central contol DARK if 0xFF
	ldi temp2, localDelay
	mov delay1, temp2
	mov delay2, temp2
	mov delay3, temp2
	mov delay4, temp2
	sei
	;--------------------
	;display initial content on LCD
	ldi temp1, ' '
	do_lcd_data temp1
	ldi temp1, 'S'
	do_lcd_data temp1
	ldi temp1, ':'
	do_lcd_data temp1
	do_lcd_command 0b11000101	; change LCD location
	ldi temp1, '0'
	do_lcd_data temp1			; currently all window opaque level is 0
	do_lcd_command 0b11001000
	do_lcd_data temp1
	do_lcd_command 0b11001011
	do_lcd_data temp1
	do_lcd_command 0b11001110
	do_lcd_data temp1
	do_lcd_command 0b10000101	; change location for printing
	ldi temp1, 'W'				; "W1 W2 W3 W4"
	do_lcd_data temp1
	ldi temp1, '1'
	do_lcd_data temp1
	ldi temp1, ' '
	do_lcd_data temp1
	ldi temp1, 'W'
	do_lcd_data temp1
	ldi temp1, '2'
	do_lcd_data temp1
	ldi temp1, ' '
	do_lcd_data temp1
	ldi temp1, 'W'
	do_lcd_data temp1
	ldi temp1, '3'
	do_lcd_data temp1
	ldi temp1, ' '
	do_lcd_data temp1
	ldi temp1, 'W'
	do_lcd_data temp1
	ldi temp1, '4'
	do_lcd_data temp1
	;--------------------
	;rjmp main
main:
	ldi cmask, INITCOLMASK		; initial column mask
	clr	col						; initial column
	rcall sleep_2ms
colloop:
	cpi col, 4
	breq function_bridge
	sts	PORTL, cmask			; set column to mask value (one column off)

	ldi temp1, 0xFF
delay:
	dec temp1
	brne delay

	lds	temp1, PINL				; read PORTL
	andi temp1, ROWMASK
	cpi temp1, 0xF				; check if any rows are on
	breq nextcol
								; if yes, find which row is on
	ldi rmask, INITROWMASK		; initialise row check
	clr	row						; initial row
rowloop:
	cpi row, 4
	breq nextcol
	mov temp2, temp1
	and temp2, rmask			; check masked bit
	breq convert 				; if bit is clear, convert the bitcode
nextrow:
	inc row						; else move to the next row
	lsl rmask					; shift the mask to the next bit
	rjmp rowloop
nextcol:
	lsl cmask					; else get new mask by shifting and
	inc col						; increment column value
	rjmp colloop				; and check the next column

function_bridge:					; just a jumping point for out of reach branch
	jmp function

convert:
	cpi col, 0					; if col is 0, 1/4/7/* is pressed(window 1/3)
	breq first_row
	cpi col, 1					; if col is 1, 2/5/8/0 is pressed(window 2/4)
	breq second_row
	cpi col, 3					; if col is 3, A/B/C/D is pressed
	breq central
	jmp nextrow

first_row:
	cpi emerg, 0xFF				; if emerg is on/central CLEAR/ central DARK
	breq display_bridge			; no local button works
	cpi centrC, 0xFF			; go straight to display LED
	breq nextrow
	cpi centrD, 0xFF
	breq nextrow
	cpi row, 0					; otherwise, do each buttons function
	breq button_1				; '1' is pressed
	cpi row, 1
	breq button_4_bridge		; '4' is pressed
	cpi row, 2
	breq button_7_bridge		; '7' is pressed
	cpi row, 3					; bridge just some jumping points take care of out of reach branches
	breq button_star_bridge		; '*' is pressed
	jmp nextrow
second_row:
	cpi emerg, 0xFF				; as above
	breq display_bridge
	cpi centrC, 0xFF
	breq nextrow
	cpi centrD, 0xFF
	breq nextrow
	cpi row, 0
	breq button_2_bridge		; '2' is pressed
	cpi row, 1
	breq button_5_bridge		; '5' is pressed
	cpi row, 2
	breq button_8_bridge		; '8' is pressed, as above
	cpi row, 3
	breq button_0_bridge		; '0' is pressed
	jmp nextrow
central:
	cpi row, 2
	breq central_clear_bridge	; 'C' is pressed
	cpi row, 3
	breq central_dark_bridge	; 'D' is pressed
	jmp nextrow

display_bridge:
	jmp display
button_4_bridge:
	jmp button_4
button_2_bridge:
	jmp button_2
button_7_bridge:
	jmp button_7
button_star_bridge:
	jmp button_star
button_5_bridge:
	jmp button_5
button_8_bridge:
	jmp button_8
button_0_bridge:
	jmp button_0
central_clear_bridge:
	jmp central_clear
central_dark_bridge:
	jmp central_dark

button_1:
	mov temp2,timer1
	cpi temp2, bounceDelay	; if bounce Delay is not reached, skip this press
	brne button_1_end
	cbr store, 1<<0			; otherwise, store window 1 up (clear window 1 down)
	sbr store, 1<<1

	ldi temp2, localDelay	; only reset delay when full 0.5s count is finished
	cp delay1, temp2
	in temp2, SREG
	sbrc temp2, 1
	clr delay1
	clr timer1
button_1_end:
	jmp nextrow

button_4:
	mov temp2,timer1
	cpi temp2, bounceDelay
	brne button_4_end
	cbr store, 1<<1
	sbr store, 1<<0
	
	ldi temp2, localDelay
	cp delay1, temp2
	in temp2, SREG
	sbrc temp2, 1
	clr delay1
	clr timer1
button_4_end:
	jmp nextrow

button_2:
	mov temp2,timer2
	cpi temp2, bounceDelay
	brne button_2_end
	cbr store, 1<<2
	sbr store, 1<<3

	ldi temp2, localDelay
	cp delay2, temp2
	in temp2, SREG
	sbrc temp2, 1
	clr delay2
	clr timer2
button_2_end:
	jmp nextrow

button_5:
	mov temp2,timer2
	cpi temp2, bounceDelay
	brne button_5_end
	cbr store, 1<<3
	sbr store, 1<<2

	ldi temp2, localDelay
	cp delay2, temp2
	in temp2, SREG
	sbrc temp2, 1
	clr delay2
	clr timer2
button_5_end:
	jmp nextrow

button_7:
	mov temp2,timer3
	cpi temp2, bounceDelay
	brne button_7_end
	cbr store, 1<<4
	sbr store, 1<<5

	ldi temp2, localDelay
	cp delay3, temp2
	in temp2, SREG
	sbrc temp2, 1
	clr delay3
	clr timer3
button_7_end:
	jmp nextrow

button_star:
	mov temp2,timer3
	cpi temp2, bounceDelay
	brne button_star_end
	cbr store, 1<<5
	sbr store, 1<<4

	ldi temp2, localDelay
	cp delay3, temp2
	in temp2, SREG
	sbrc temp2, 1
	clr delay3
	clr timer3
button_star_end:
	jmp nextrow

button_8:
	mov temp2,timer4
	cpi temp2, bounceDelay
	brne button_8_end
	cbr store, 1<<6
	sbr store, 1<<7

	ldi temp2, localDelay
	cp delay4, temp2
	in temp2, SREG
	sbrc temp2, 1
	clr delay4
	clr timer4
button_8_end:
	jmp nextrow

button_0:
	mov temp2,timer4
	cpi temp2, bounceDelay
	brne button_0_end
	cbr store, 1<<7
	sbr store, 1<<6

	ldi temp2, localDelay
	cp delay4, temp2
	in temp2, SREG
	sbrc temp2, 1
	clr delay4
	clr timer4
button_0_end:
	jmp nextrow

function:					; actually changes the window opaque level
	mov temp2, delay1		; compare delay counter with Delay limits
	cpi temp2, localDelay-1
	brne function_2
	sbrs store, 0			; determine if its up or down
	rjmp function_1_up		;
	clr temp2				; if its down
	bst light, 1
	bld temp2, 1
	bst light, 0
	bld temp2, 0
	cpi temp2, 0
	breq function_2
	dec temp2				; decrease light1 (bounded by 0)
	bst temp2, 1
	bld light, 1
	bst temp2, 0
	bld light, 0
	ser change
	rjmp function_2
function_1_up:				; if its up
	clr temp2
	bst light, 1
	bld temp2, 1
	bst light, 0
	bld temp2, 0
	cpi temp2, 3			; increase light1 (bounded by 3)
	breq function_2
	inc temp2
	bst temp2, 1
	bld light, 1
	bst temp2, 0
	bld light, 0
	ser change

function_2:
	mov temp2, delay2
	cpi temp2, localDelay-1
	brne function_3
	sbrs store, 2
	rjmp function_2_up
	clr temp2
	bst light, 3
	bld temp2, 1
	bst light, 2
	bld temp2, 0
	cpi temp2, 0
	breq function_3
	dec temp2				; decrease light1 (bounded by 0)
	bst temp2, 1
	bld light, 3
	bst temp2, 0
	bld light, 2
	ser change
	rjmp function_3
function_2_up:
	clr temp2
	bst light, 3
	bld temp2, 1
	bst light, 2
	bld temp2, 0
	cpi temp2, 3
	breq function_3
	inc temp2				; increase light1 (bounded by 3)
	bst temp2, 1
	bld light, 3
	bst temp2, 0
	bld light, 2
	ser change

function_3:
	mov temp2, delay3
	cpi temp2, localDelay-1
	brne function_4
	sbrs store, 4
	rjmp function_3_up
	clr temp2
	bst light, 5
	bld temp2, 1
	bst light, 4
	bld temp2, 0
	cpi temp2, 0
	breq function_4
	dec temp2				; decrease light1 (bounded by 0)
	bst temp2, 1
	bld light, 5
	bst temp2, 0
	bld light, 4
	ser change
	rjmp function_4
function_3_up:
	clr temp2
	bst light, 5
	bld temp2, 1
	bst light, 4
	bld temp2, 0
	cpi temp2, 3
	breq function_4
	inc temp2				; increase light1 (bounded by 3)
	bst temp2, 1
	bld light, 5
	bst temp2, 0
	bld light, 4
	ser change

function_4:
	mov temp2, delay4
	cpi temp2, localDelay-1
	brne function_end
	sbrs store, 6
	rjmp function_4_up
	clr temp2
	bst light, 7
	bld temp2, 1
	bst light, 6
	bld temp2, 0
	cpi temp2, 0
	breq function_end
	dec temp2				; decrease light1 (bounded by 0)
	bst temp2, 1
	bld light, 7
	bst temp2, 0
	bld light, 6
	ser change
	rjmp function_end
function_4_up:
	clr temp2
	bst light, 7
	bld temp2, 1
	bst light, 6
	bld temp2, 0
	cpi temp2, 3
	breq function_end
	inc temp2				; increase light1 (bounded by 3)
	bst temp2, 1
	bld light, 7
	bst temp2, 0
	bld light, 6
	ser change

function_end:
	jmp display

central_clear:
	cpi timer, bounceDelay
	brne central_clear_end
	cpi emerg, 0xFF				; if emerg is on, no central control available
	breq central_clear_end
	cpi centrC, 0xFF			; if central CLEAR is on, turn it off
	breq central_clear_off
	ser centrC					; otherwise, turn CLEAR on, and double check DARK is off
	clr centrD
	ser change
	clr timer
	jmp central_clear_end
central_clear_off:				; turn CLEAR off
	clr centrC
	ser change
	clr timer
central_clear_end:
	jmp display

central_dark:					; similar to central_clear, only setting windows to DARK
	cpi timer, bounceDelay
	brne central_dark_end
	cpi emerg, 0xFF
	breq central_dark_end
	cpi centrD, 0xFF
	breq central_dark_off
	ser centrD
	clr centrC
	ser change
	clr timer
	jmp central_dark_end
central_dark_off:
	clr centrD
	ser change
	clr timer
central_dark_end:
	jmp display

display:
	;LED display
	cpi centrD, 0				; if in DARK mode, set LED to 0xFF
	breq A						; otherwise, clear LED to 0x00
	ser temp1
	rjmp B
A:
	clr temp1
B:
	sbrc emerg, 0				; still set LED to 0x00 even if in DARK mode if emergency happens
	clr temp1					; (emergency has higher priority)
	cpi emerg, 0xFF				; display LED according to different situation
	breq display_LED
	cpi centrC, 0xFF
	breq display_LED
	cpi centrD, 0xFF
	breq display_LED

	clr temp2
	bst light, 1
	bld temp2, 1
	bst light, 0
	bld temp2, 0
	cp curLightLevel, temp2		; local control case:
	brsh second_window			; compare curLightLevel with each window lightLevel
	ori temp1, 0x03				; turn corresponding bits on if window lightLevel > curLightLevel
second_window:
	bst light, 3
	bld temp2, 1
	bst light, 2
	bld temp2, 0
	cp curLightLevel, temp2
	brsh third_window
	ori temp1, 0x0C
third_window:
	bst light, 5
	bld temp2, 1
	bst light, 4
	bld temp2, 0
	cp curLightLevel, temp2
	brsh fourth_window
	ori temp1, 0x30
fourth_window:
	bst light, 7
	bld temp2, 1
	bst light, 6
	bld temp2, 0
	cp curLightLevel, temp2
	brsh display_LED
	ori temp1, 0xC0

display_LED:
	cpi timer, bounceDelay		; if timer reach designed length, timer stop
	in temp2, SREG				; (otherwise, it could overflow)
	sbrs temp2, 1
	inc timer

	mov temp2, timer1
	cpi temp2, bounceDelay		; if bounce timer for window 1 reach designed bounce delay length
	in temp2, SREG				; timer stops (otherwise, it could overflow)
	sbrs temp2, 1
	inc timer1

	mov temp2, timer2
	cpi temp2, bounceDelay		; if bounce timer for window 2 reach designed bounce delay length
	in temp2, SREG				; timer stops (otherwise, it could overflow)
	sbrs temp2, 1
	inc timer2

	mov temp2, timer3
	cpi temp2, bounceDelay		; if bounce timer for window 3 reach designed bounce delay length
	in temp2, SREG				; timer stops (otherwise, it could overflow)
	sbrs temp2, 1
	inc timer3

	mov temp2, timer4
	cpi temp2, bounceDelay		; if bounce timer for window 4 reach designed bounce delay length
	in temp2, SREG				; timer stops (otherwise, it could overflow)
	sbrs temp2, 1
	inc timer4

	mov temp2, delay1
	cpi temp2, localDelay		; if delay timer for window 1 reach designed delay length
	in temp2, SREG				; timer stops (otherwise, it could overflow)
	sbrs temp2, 1
	inc delay1

	mov temp2, delay2
	cpi temp2, localDelay		; if delay timer for window 2 reach designed delay length
	in temp2, SREG				; timer stops (otherwise, it could overflow)
	sbrs temp2, 1
	inc delay2

	mov temp2, delay3
	cpi temp2, localDelay		; if delay timer for window 3 reach designed delay length
	in temp2, SREG				; timer stops (otherwise, it could overflow)
	sbrs temp2, 1
	inc delay3

	mov temp2, delay4
	cpi temp2, localDelay		; if delay timer for window 4 reach designed delay length
	in temp2, SREG				; timer stops (otherwise, it could overflow)
	sbrs temp2, 1
	inc delay4

loadLED:
	lightLoop					; get next curLightLevel
	out PORTC, temp1			; output LED

	; LCD display
	cpi change, 0				; if no change happens, skip displaying LCD
	breq LCDEnd_bridge
	clr change					; otherwise, reset change
	do_lcd_command 0b00000010	; move LCD cursor to upper left (text unchanged)
	cpi emerg, 0xFF				; display LCD in different situation
	breq emerg_display_bridge

	cpi centrC, 0xFF
	breq centrC_display_bridge

	cpi centrD, 0xFF
	breq centrD_display_bridge
	rjmp normal_LCD

LCDEnd_bridge:
	jmp LCDEnd
emerg_display_bridge:
	jmp emerg_display
centrC_display_bridge:
	jmp centrC_display
centrD_display_bridge:
	jmp centrD_display

normal_LCD:						; normal case, display 4 window level
	ldi temp1, ' '				; get ascii value of each 4 window opaque level
	do_lcd_data temp1
	ldi temp1, 'L'
	do_lcd_data temp1
	ldi temp1, ':'
	do_lcd_data temp1
	do_lcd_command 0b11000101
	clr temp1
	bst light, 1
	bld temp1, 1
	bst light, 0
	bld temp1, 0
	subi temp1, -'0'
	do_lcd_data temp1
	do_lcd_command 0b11001000
	clr temp1
	bst light, 3
	bld temp1, 1
	bst light, 2
	bld temp1, 0
	subi temp1, -'0'
	do_lcd_data temp1
	do_lcd_command 0b11001011
	clr temp1
	bst light, 5
	bld temp1, 1
	bst light, 4
	bld temp1, 0
	subi temp1, -'0'
	do_lcd_data temp1
	do_lcd_command 0b11001110
	clr temp1
	bst light, 7
	bld temp1, 1
	bst light, 6
	bld temp1, 0
	subi temp1, -'0'
	do_lcd_data temp1
	rjmp LCDEnd

centrC_display:					; "0 0 0 0" if CLEAR
	ldi temp1, ' '
	do_lcd_data temp1
	ldi temp1, 'C'				; " C:"
	do_lcd_data temp1
	ldi temp1, ':'
	do_lcd_data temp1
	do_lcd_command 0b11000101
	ldi temp1, '0'
	do_lcd_data temp1
	do_lcd_command 0b11001000
	do_lcd_data temp1
	do_lcd_command 0b11001011
	do_lcd_data temp1
	do_lcd_command 0b11001110
	do_lcd_data temp1
	rjmp LCDEnd

centrD_display:					; "3 3 3 3" if DARK
	ldi temp1, ' '
	do_lcd_data temp1
	ldi temp1, 'C'				; " C:"
	do_lcd_data temp1
	ldi temp1, ':'
	do_lcd_data temp1
	do_lcd_command 0b11000101
	ldi temp1, '3'
	do_lcd_data temp1
	do_lcd_command 0b11001000
	do_lcd_data temp1
	do_lcd_command 0b11001011
	do_lcd_data temp1
	do_lcd_command 0b11001110
	do_lcd_data temp1
	rjmp LCDEnd

emerg_display:					; "0 0 0 0: if emergency
	ldi temp1, ' '
	do_lcd_data temp1
	ldi temp1, '!'				; " !!"
	do_lcd_data temp1
	ldi temp1, '!'
	do_lcd_data temp1
	do_lcd_command 0b11000101
	ldi temp1, '0'
	do_lcd_data temp1
	do_lcd_command 0b11001000
	do_lcd_data temp1
	do_lcd_command 0b11001011
	do_lcd_data temp1
	do_lcd_command 0b11001110
	do_lcd_data temp1
LCDEnd:
	jmp main


.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4
; 4 cycles per iteration - setup/call-return overhead
sleep_1ms:						; get 1ms delay
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

sleep_2ms:						; get 2ms delay
	rcall sleep_1ms
	rcall sleep_1ms
	ret

sleep_5ms:						; get 5ms delay
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
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
	push r25			;save conflict register on stack
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
	sbrc r25, 7			; check if BF is 0
	rjmp lcd_wait_loop
	lcd_clr LCD_RW
	ser r25
	out DDRF, r25
	pop r25				;resume conflict register from stack
	ret
