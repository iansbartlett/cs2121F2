//Lab 5 Part C
//Ian Bartlett z3419581 and Aaron Schneider z502001

.include "m2560def.inc"

#define GAIN 1

#define START_SPEED 40

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
   clr r16
   st Y+, r16
   st Y, r16                
.endmacro

.dseg

SecondCounter: .byte 1
TempCounter: .byte 2

dataArray: .byte ARRAY_LENGTH

.cseg
.org 0x0000
    jmp RESET

.org INT0addr
    jmp PB0_Interrupt

.org INT1addr
    jmp PB1_Interrupt

.org INT2addr
   jmp countOptoInterrupt

.org OVF0addr
    jmp TimerInterrupt

main:

//PWM Code setup
	ser r16
	out DDRE, r16; Bit 3 will function as OC3.
	//mov r16, r10; the value controls the PWM duty cycle
    //Initialize PWM
	sts OCR3BL, r10
	clr r16
	sts OCR3BH, r16
	//Use Fast PWM on Port E pin 3
	ldi r16, (1 << CS30)
	sts TCCR3B, r16
	ldi r16, (1 << WGM30)|(1 << WGM32 )|(1<<COM3B1)
	sts TCCR3A, r16

//clr leds
//out PORTC, leds
clear TempCounter
clear SecondCounter

ldi r16, (2 << ISC20)|(2 << ISC10)|(2 << ISC00)
sts EICRA, r16

in r16, EIMSK
ori r16, (1<<INT2)|(1<<INT1)|(1<<INT0)
out EIMSK, r16

ldi r16, 0b00000000
out TCCR0A, r16
ldi r16, 0b00000010
out TCCR0B, r16
ldi r16, 1<<TOIE0
sts TIMSK0, r16
sei

ldi XL, low(dataArray)
ldi XH, high(dataArray)

ldi ZL, low(dataArray)
ldi ZH, high(dataArray)

loop: rjmp loop

RESET:
    ldi r16, high(RAMEND)    
    out SPH, r16 
    ldi r16, low(RAMEND)
    out SPL, r16  
    
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

	ldi r18, START_SPEED //Sets motor to full initially - debug only!
    mov r10, r18

    clr r19
 
rjmp main 

//DEFAULT: returns from interrupt
DEFAULT: reti

//Timer0 interrupt function
TimerInterrupt:

   //Prologue
   in r16, SREG
   push r16
   push YH
   push YL
   push r25
   push r24

//Button check/debouncing

  //Check status register
   //If PB0, PB1 both active, reject
   //Set both to 0
   cpi r19, 0b00000011
   breq rejectButton

   //Debounce counter
   cpi r19, 0b00000001
   breq debouncePB0

   cpi r19, 0b00000010
   breq debouncePB1

   rjmp secondRoutine

debouncePB0:

   in r16, PORTD
   andi r16, PB0_pin
   cpi r16, PB0_pin
   breq increasePB0Count
   inc r22
   rjmp checkPB0Value

//ACTUALLY DECREASES AT THE MOMENT- FIX NAMING IF THIS WORKS
increasePB0Count:
   dec r22

checkPB0Value:
   
   cpi r22, ACCEPT_CUTOFF_0
   breq acceptPB0

   cpi r22, REJECT_CUTOFF_0
   breq rejectButton

   rjmp secondRoutine

acceptPB0:
  
   ldi r16, 20
   add r18, r16
   cpi r18, 101
   brlo PB0inRange
   subi r18, 20
 
   PB0inRange:
   clr r19  

   rjmp secondRoutine

debouncePB1:

   in r16, PORTD
   andi r16, PB1_pin
   cpi r16, PB1_pin
   breq increasePB1Count
   inc r23
   rjmp checkPB1Value

increasePB1Count:
   dec r23

checkPB1Value:
  
   cpi r23, ACCEPT_CUTOFF_1
   breq acceptPB1

   cpi r23, REJECT_CUTOFF_1
   breq rejectButton
   
   rjmp secondRoutine

acceptPB1:

   subi r18, 20 
   brpl PB1inRange
   ldi r16, 20
   add r18, r16  

   PB1inRange:
   clr r19  

   rjmp secondRoutine

rejectButton:   

   clr r19
   ldi r22, 10
   ldi r23, 10

//500 ms Routine
//******************
secondRoutine:

mov r16, XL

   lds r24, TempCounter
   lds r25, TempCounter+1
   adiw r25:r24, 1
   cpi r24, low(3406)
   ldi r16, high(3406)
   cpc r25, r16
   brne NotSecond

   //Find rotations per second      
   lsr r17
   
    do_lcd_command 0b10000000  
    do_lcd_command 0b00000001 ; clear display
       

	clr r21
	//Display PWM value instead!
    mov r20, r18
    rcall DisplayNumber


    do_lcd_command 0b11000000 
    clr r21
  	mov r20, r17
    rcall displayNumber

    //Control loop
 
    //hax
	cpi r18, 90
	brlo controlValue
	ldi r16, 0xFF
	mov r10, r16
	rjmp updatePWM
    

controlValue:
	mov r16, r18
    sub r16, r17

    
	ldi r20, GAIN
	mul r16, r20   

    mov r16, r0
	add r10, r16
	
	ldi r16, 0
	cp r10, r16    
    brsh updatePWM
	
	ldi r16, 0
	mov r10, r16 
	
	   

    updatePWM:
	sts OCR3BL, r10


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
   pop r16
   out SREG, r16
   
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


//Displays the value of the r20 register by converting to BCD and outputting digits
//Does not move cursor
displayNumber:


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

    ret

PB0_Interrupt:

   ori r19, 0b00000001    

   reti

PB1_Interrupt:

   ori r19, 0b00000010

   reti
