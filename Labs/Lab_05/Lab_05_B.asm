//Lab 5 Part B
//Ian Bartlett z3419581 and Aaron Schneider z502001
.include "m2560def.inc"

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

.cseg

.org 0x0000
    jmp RESET

.org OVF0addr
    jmp TimerInterrupt

RESET:

   ldi r18, 0xBF //Start with LED on

main:

	//ldi r16, 0b00010000
	ser r16
	out DDRE, r16; Bit 3 will function as OC3.
	mov r16, r18; the value controls the PWM duty cycle
	sts OCR3BL, r16
	clr r16
	sts OCR3BH, r16
	//Attempting to use Fast PWM on Port E pin 3
	ldi r16, (1 << CS30)
	sts TCCR3B, r16
	ldi r16, (1 << WGM30)|(1 << WGM32 )|(1<<COM3B1)
	sts TCCR3A, r16

	clear TempCounter
	clear SecondCounter

	ldi r16, (2 << ISC20)
	sts EICRA, r16

	in r16, EIMSK
	ori r16, (1<<INT2)
	out EIMSK, r16

	ldi r16, 0b00000000
	out TCCR0A, r16
	ldi r16, 0b00000010
	out TCCR0B, r16
	ldi r16, 1<<TOIE0
	sts TIMSK0, r16
	sei

    halt:
	   rjmp halt

//Timer0 interrupt function
TimerInterrupt:

   //Prologue
   in r16, SREG
   push r16
   push YH
   push YL
   push r25
   push r24

//******************

mov r16, XL

   lds r24, TempCounter
   lds r25, TempCounter+1
   adiw r25:r24, 1
   cpi r24, low(31)
   ldi r16, high(31)
   cpc r25, r16
   brne NotSecond
 
   dec r18
   sts OCR3BL, r18

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
