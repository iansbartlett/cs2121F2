//Lab 5 Part A
//Ian Bartlett z3419581 and Aaron Schneider z502001

.include "m2560def.inc"

#define ASCII_OFFSET 48

#define SEQUENCE_COUNT 8	
#define ACCEPT_CUTOFF_0 15
#define ACCEPT_CUTOFF_1 50
#define REJECT_CUTOFF_0 0
#define REJECT_CUTOFF_1 0

#define ARRAY_LENGTH

#define PB0_pin 0b00000001
#define PB1_pin 0b00000010


.equ PORTADIR = 0xF0

.def temp = r16
.def leds = r17
.def buttonStatus = r18
.def PB0Count = r19
.def PB1Count = r20
.def read = r21
.def readCounter = r22
.def leds_buffer = r23

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

; The macro clears a word (2 bytes) in a memory
; the parameter @0 is the memory address for that word
.macro clear
   ldi YL, low(@0)
   ldi YH, high(@0)     
   clr temp
   st Y+, temp
   st Y, temp                
.endmacro

.dseg

SecondCounter: .byte 1
TempCounter: .byte 2

dataArray: .byte ARRAY_LENGTH

.cseg
.org 0x0000
    jmp RESET

.org INT2addr
   jmp countOptoInterrupt

.org OVF0addr
    jmp TimerInterrupt

main:

//clr leds
//out PORTC, leds
clear TempCounter
clear SecondCounter

ldi temp, (2 << ISC20)
sts EICRA, temp

in temp, EIMSK
ori temp, (1<<INT2)
out EIMSK, temp

ldi temp, 0b00000000
out TCCR0A, temp
ldi temp, 0b00000011
out TCCR0B, temp
ldi temp, 1<<TOIE0
sts TIMSK0, temp
sei

ldi XL, low(dataArray)
ldi XH, high(dataArray)

ldi ZL, low(dataArray)
ldi ZH, high(dataArray)

loop: rjmp loop

RESET:
    ldi temp, high(RAMEND)    
    out SPH, temp 
    ldi temp, low(RAMEND)
    out SPL, temp  
    
    clr r17

	ser r16
	out DDRF, r16
	out DDRA, r16

	clr r16
	out PORTF, r16
	out PORTA, r16

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


rjmp main 

//DEFAULT: returns from interrupt
DEFAULT: reti

//Timer0 interrupt function
TimerInterrupt:

   //Prologue
   in temp, SREG
   push temp
   push YH
   push YL
   push r25
   push r24

//500 ms Routine
//******************
secondRoutine:

mov temp, XL

   lds r24, TempCounter
   lds r25, TempCounter+1
   adiw r25:r24, 1
   cpi r24, low(244)
   ldi temp, high(244)
   cpc r25, temp
   brne NotSecond

 //Find rotations per second      
   //lsr r17
   
    do_lcd_command 0b10000000  
    do_lcd_command 0b00000001 ; clear display
    
	clr r21
	mov r20, r17

countHundreds:

	cpi r20, 100
	brlo printHundreds
	//brvs printHundreds

    subi r20, 100
	inc r21
	rjmp countHundreds

printHundreds:
    
    //cpi temp2, 0
	//breq countTens

	ldi r16, ASCII_OFFSET
	add r16, r21
	
	rcall lcd_data
	rcall lcd_wait

	//mov temp3, temp2
    clr r21
    
countTens:
	
    cpi r20,10
	brlo printTens

    subi r20, 10
	inc r21
	rjmp countTens

printTens:
    
    //tst temp3
    //NEED AN AND CONDITION HERE
	//cpi temp2, 0
	//breq printOnes

	ldi r16, ASCII_OFFSET
	add r16, r21
	
	rcall lcd_data
	rcall lcd_wait
    clr r21

printOnes:

    //Only thing left should be the ones place
    ldi r16, ASCII_OFFSET
	//debug
	//ldi temp1, 9
    add r16, r20
    rcall lcd_data 
    rcall lcd_wait

   //Clear interrupt counter
   clr r17
   clear TempCounter
   rjmp EndIF  

NotSecond:
   sts TempCounter, r24
   sts TempCounter+1, r25

//Epilogue

EndIF:

   pop r24
   pop r25
   pop YL
   pop YH
   pop temp
   out SREG, temp
   
reti


countOptoInterrupt: 

   inc r17

reti

//LCD Handling Code

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
