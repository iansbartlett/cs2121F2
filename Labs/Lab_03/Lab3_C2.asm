//Lab 3 Part C, Attempt 2
//Ian Bartlett z3419581 and Aaron Schneider z502001

.include "m2560def.inc"

#define SEQUENCE_COUNT 7	
#define ACCEPT_CUTOFF_0 15
#define ACCEPT_CUTOFF_1 50
#define REJECT_CUTOFF_0 0
#define REJECT_CUTOFF_1 0

#define PB0_pin 0b00000001
#define PB1_pin 0b00000010

.def temp = r16
.def leds = r17
.def buttonStatus = r18
.def PB0Count = r19
.def PB1Count = r20
.def read = r21
.def readCounter = r22

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

.org INT0addr
   jmp PB0_Interrupt

.org INT1addr
   jmp PB1_Interrupt

.org OVF0addr
    jmp TimerInterrupt

main:

clr leds
out PORTC, leds
clear TempCounter
clear SecondCounter

ldi temp, (2 << ISC10)
ori temp, (2 << ISC00)
sts EICRA, temp

in temp, EIMSK
ori temp, (1<<INT0)
ori temp, (1<<INT1)
out EIMSK, temp

ldi temp, 0b00000000
out TCCR0A, temp
ldi temp, 0b00000011
out TCCR0B, temp
ldi temp, 1<<TOIE0
sts TIMSK0, temp
sei

loop: rjmp loop

RESET:
    ldi temp, high(RAMEND)    
    out SPH, temp 
    ldi temp, low(RAMEND)
    out SPL, temp  
    
	ser temp
    out DDRC, temp

   	clr temp
	out DDRD, temp

    ldi PB0Count, 10
	ldi PB1Count, 10

	clr readCounter
	clr buttonStatus

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

   //Millisecond routine

   //Check status register
   //If PB0, PB1 both active, reject
   //Set both to 0
   cpi buttonStatus, 0b00000011
   breq rejectButton

   //Debounce counter
   cpi buttonStatus, 0b00000001
   breq debouncePB0

   cpi buttonStatus, 0b00000010
   breq debouncePB1

   rjmp secondRoutine

debouncePB0:

   in temp, PORTD
   andi temp, PB0_pin
   cpi temp, PB0_pin
   breq increasePB0Count
   inc PB0Count
   rjmp checkPB0Value

//ACTUALLY DECREASES AT THE MOMENT- FIX NAMING IF THIS WORKS
increasePB0Count:
   dec PB0Count

checkPB0Value:
   
   cpi PB0Count, ACCEPT_CUTOFF_0
   breq storePB0

   cpi PB0Count, REJECT_CUTOFF_0
   breq rejectButton

   rjmp secondRoutine

storePB0:

   clr buttonStatus
   ldi PB1Count, 10

   inc readCounter
   lsl read
   
   out PORTC, read

   cpi readCounter, SEQUENCE_COUNT
   breq outputBuffer

   rjmp secondRoutine

debouncePB1:

   in temp, PORTD
   andi temp, PB1_pin
   cpi temp, PB1_pin
   breq increasePB1Count
   dec PB1Count
   rjmp checkPB1Value

increasePB1Count:
   inc PB1Count

checkPB1Value:
   rjmp storePB1
  
   cpi PB1Count, ACCEPT_CUTOFF_1
   breq storePB1

   cpi PB1Count, REJECT_CUTOFF_1
   breq rejectButton
   
   rjmp secondRoutine

storePB1:
   clr buttonStatus
   ldi PB1Count, 10

   inc readCounter
   lsl read
   inc read
   out PORTC, read

   cpi readCounter, SEQUENCE_COUNT
   breq outputBuffer

   rjmp secondRoutine

outputBuffer:
   clr readCounter
   mov leds, read
   clr read

   rjmp secondRoutine

rejectButton:   

   clr buttonStatus
   ldi PB0Count, 10
   ldi PB1Count, 10

   //One second routine
secondRoutine:

   lds r24, TempCounter
   lds r25, TempCounter+1
   adiw r25:r24, 1
   cpi r24, low(976)
   ldi temp, high(976)
   cpc r25, temp
   brne NotSecond


writeLEDs:
   //out PORTC, leds
   clear TempCounter 

   lds r24, SecondCounter
   lds r25, SecondCounter+1
   adiw r25:r24, 1



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


PB0_Interrupt:

//Set a flag that something is happening on PB0
ori buttonStatus, 0b00000001

reti

PB1_Interrupt:

//Set a flag that something is happening on PB1
ori buttonStatus, 0b00000010

reti
