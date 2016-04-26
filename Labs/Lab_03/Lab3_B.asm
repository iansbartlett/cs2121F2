//Lab 3 Part A
//Ian Bartlett z3419581 and Aaron Schneider z502001

.include "m2560def.inc"

.equ PATTERN = 0b1100110000110011

.def temp = r16
.def leds = r17
//Possibly better naming needed: this register holds the extra bits of the sequence
.def leds_extra = r18
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

.cseg
.org 0x0000
    jmp RESET
	//jmp DEFAULT
	//jmp DEFAULT //Why do this?

.org OVF0addr
    jmp TimerInterrupt


main:

//Configure Timer0 
//Enable Timer0 interrupt
//Enable interrupts globablly



ldi leds, low(PATTERN)
ldi leds_extra, high(PATTERN)
clear TempCounter
clear SecondCounter

ldi temp, 0b00000000
out TCCR0A, temp
ldi temp, 0b00000010
out TCCR0B, temp
ldi temp, 1<<TOIE0
sts TIMSK0, temp
sei

loop: rjmp loop

//RESET: initialization function

RESET:
    ldi temp, high(RAMEND)    
    out SPH, temp 
    ldi temp, low(RAMEND)
    out SPL, temp  
    
	ser temp
    out DDRC, temp

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

   //Body
   lds r24, TempCounter
   lds r25, TempCounter+1
   adiw r25:r24, 1
   cpi r24, low(7812)
   ldi temp, high(7812)
   cpc r25, temp
   brne NotSecond

   //Updated LED pattern
   lsr leds_extra
   ror leds
   brcs firstBitSet
   rjmp writeLEDs

firstBitSet:
   sbr leds_extra, 0b10000000

writeLEDs:
   out PORTC, leds
   clear TempCounter 

   lds r24, SecondCounter
   lds r25, SecondCounter+1
   adiw r25:r24, 1
   //Iterate through secondcounter
   //breq resetSeconds
   //rjmp changeDisplay

   sts SecondCounter, r24
   sts SecondCounter, r25
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
