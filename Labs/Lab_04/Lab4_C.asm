//Lab 04 Part C
//2016-05-03
//Ian Bartlett and Aaron Schnieder
//Adapted from sample LCD file

.include "m2560def.inc"

#define ASCII_OFFSET 48

.def row = r16
.def col = r17
.def rmask = r18
.def cmask = r19
.def temp1 = r20
.def temp2 = r21
.def accum = r22
.def readFlag = r23
.def countDigit = r24
.def ourNumber = r25

.equ PORTADIR = 0xF0
.equ INITCOLMASK = 0xEF
.equ INITROWMASK = 0x01
.equ ROWMASK = 0x0F

.macro do_lcd_command
	ldi r16, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro
.macro do_lcd_data
	ld r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

.org 0
	jmp RESET


RESET:
	ldi r16, low(RAMEND)
	out SPL, r16
	ldi r16, high(RAMEND)
	out SPH, r16

	ser r16
	out DDRF, r16
	out DDRA, r16
	clr r16
	out PORTF, r16
	out PORTA, r16

    ldi temp1, PORTADIR
    sts DDRL, temp1

	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001000 ; display off?
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink

    clr accum

	do_lcd_command 0b11000000
	
	clr countDigit

//Begin main
main:
   
   do_lcd_command 0b10000000  
  
   ldi r16, ASCII_OFFSET
   add r16, accum
   rcall lcd_data 
   rcall lcd_wait

   do_lcd_command 0b11000000

   ldi cmask, INITCOLMASK
   clr col
     
colloop: 
   cpi  col, 4
   breq resetReadFlag
   sts PORTL, cmask

   ldi temp1, 0xFF
delay: 
   dec temp1
   brne delay    //wait for the decrement to hit a zero flag
    
   lds temp1, PINL
   andi temp1, ROWMASK 
   cpi temp1, 0xF
   breq nextcol

   ldi rmask, INITROWMASK
   clr row

rowloop:
   cpi row, 4
   breq nextcol
   mov temp2, temp1
   and temp2, rmask
   breq convert
   inc row
   lsl rmask
   rjmp rowloop
   
nextcol:
   lsl cmask
   inc cmask
   inc col
   rjmp colloop

convert_end:
   //temp1 IS r16
   // hax hax hax
   cpi readFlag, 1
   breq main

   ldi temp2, ASCII_OFFSET
   add temp1, temp2
   mov r16, temp1
   rcall lcd_data
   rcall lcd_wait
   ldi readFlag, 1

   rjmp main

convert:
   cpi col, 3
   breq letters  //letters- ignore for now
   
   cpi row, 3
   breq symbols
   
   inc countDigit
   mov temp1, row
   lsl temp1
   add temp1, row
   add temp1, col
   inc temp1
   //subi temp1, -'1'
   push temp1
   jmp convert_end
   
symbols: 
   cpi col, 1
   breq zero
   jmp reject

resetReadFlag:
   clr readFlag
   rjmp main

zero:
   clr temp1
   jmp convert_end

letters:

   cpi row, 0
   breq addition

   cpi row, 1
   //breq subtraction

   rjmp main

reject:
   clr temp1
   rjmp convert_end



//Calculator ops
   
addition:

	cpi countDigit, 3
	breq addition3

	cpi countDigit, 2
	breq addition2

	cpi countDigit, 1
	breq addition1

addition3:

	pop temp1
	ldi temp2, 100
	mul temp1, temp2
	add ourNumber, r0

addition2:
	
	pop temp1
	ldi temp2, 10
	mul temp1, temp2
	add ourNumber, r0

addition1:

	pop temp1
	add ourNumber, r0
	add ourNumber, accum

	rjmp main

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

;
; Send a command to the LCD (r16)
;

lcd_command:
	out PORTF, r16
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	ret

lcd_data:
	out PORTF, r16
	lcd_set LCD_RS
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	lcd_clr LCD_RS
	ret

lcd_wait:
	push r16
	clr r16
	out DDRF, r16
	out PORTF, r16
	lcd_set LCD_RW
lcd_wait_loop:
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	in r16, PINF
	lcd_clr LCD_E
	sbrc r16, 7
	rjmp lcd_wait_loop
	lcd_clr LCD_RW
	ser r16
	out DDRF, r16
	pop r16
	ret

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
