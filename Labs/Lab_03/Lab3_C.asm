//Lab 3 Part C
//Ian Bartlett z3419581 and Aaron Schneider z502001

.include "m2560def.inc"

#define SEQUENCE_COUNT 7	
#define ACCEPT_CUTOFF 10
#define REJECT_CUTOFF 8

#define PB0MASK 0b00000001
#define PB1MASK 0b00000010

.def read = r16
.def output = r17
.def buttonStatus = r18
.def PB0Count = r19
.def PB1Count = r20
.def readCounter = r21
.def temp = r22
.def outputCounter = r23
.def testOutput = r24

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
msCounter: .byte 2
TempCounter: .byte 2

.cseg
.org 0x0000
    jmp RESET

.org INT0addr
   jmp PB0_Interrupt

.org INT1addr
   jmp PB1_Interrupt

.org OVF0addr
    jmp TimerInterrupt

main:

clr output
clear TempCounter
clear msCounter

ldi temp, (2 << ISC11)
ori temp, (2 << ISC00)
sts EICRA, temp

in temp, EIMSK
ori temp, (1<<INT0)
ori temp, (1<<INT1)
out EIMSK, temp

ldi temp, 0b00000000
out TCCR0A, temp
ldi temp, 0b00000010
out TCCR0B, temp
ldi temp, 1<<TOIE0
sts TIMSK0, temp
sei

ser testOutput
out PORTC, testOutput

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

	clr buttonStatus
	ldi PB0Count, 10
	ldi PB1Count, 10

rjmp main

TimerInterrupt:

   //Prologue
   in temp, SREG
   push temp
   push YH
   push YL
   push r25
   push r24

   //Body

   //1 ms routine
   lds r24, TempCounter
   lds r25, TempCounter+1
   adiw r25:r24, 1
   cpi r24, low(7812)
   ldi temp, high(7812)
   cpc r25, temp
   brne notMs
   
   com testOutput
   out PORTC, testOutput  

   //Millisecond counter managmenet
   clear TempCounter
  
   lds r24, msCounter
   lds r25, msCounter+1
   adiw r25:r24, 1

   sts msCounter, r24
   sts msCounter+1, r25

/*
   //Check status register
   //If PB0, PB1 both active, reject
   //Set both to 0
   cpi buttonStatus, 0b00000011
   breq rejectButton

   //If PB1 XOR PB0 active, increment or decrement
   //Debounce counter
   cpi buttonStatus, 0b00000001
   breq debouncePB0

   cpi buttonStatus, 0b00000010
   breq debouncePB1

   //If nothing happening to either button, move on
   rjmp secondRoutine
*/

notMs:
   sts TempCounter, r24
   sts TempCounter+1, r25
   rjmp secondRoutine


//**********************************
//DEBOUNCING CODE
//**********************************   
/*
debouncePB0:

   in temp, PORTD
   andi temp, PB0MASK
   
   cpi temp, PB0MASK
   breq incPB0
   
   dec PB0Count
   rjmp CheckPB0Count

incPB0:
   inc PB0Count
   rjmp CheckPB0Count

   //If debounce counter is at 0, reject

   //If debounce counter is at 20, accept
   //Store value

CheckPB0Count:
   cpi PB0Count, ACCEPT_CUTOFF
   breq storePB0

   cpi PB0Count, REJECT_CUTOFF
   breq rejectButton

   rjmp secondRoutine

storePB0:

   //ser temp
   //out PORTC, temp

   inc readCounter
   lsl read

   //If stored counter is at 8, move to output register and 
   //and reset stored counter
   cpi readCounter, SEQUENCE_COUNT
   breq outputBuffer

   rjmp secondRoutine

debouncePB1:

   in temp, PORTD
   andi temp, PB1MASK

   cpi temp, PB1MASK
   breq incPB1
   
   dec PB1Count
   rjmp CheckPB1Count

incPB1:
   inc PB1Count
   rjmp CheckPB1Count
   //If debounce counter is at 0, reject

   //If debounce counter is at 20, accept
   //Store value
 
CheckPB1Count:

   cpi PB1Count, ACCEPT_CUTOFF
   breq storePB1

   cpi PB1Count, REJECT_CUTOFF
   breq rejectButton

   rjmp secondRoutine

storePB1:

   inc readCounter
   lsl read
   inc read

   //If stored counter is at 8, move to output register and 
   //and reset stored counter
   cpi readCounter, SEQUENCE_COUNT
   breq outputBuffer

rjmp secondRoutine

outputBuffer:
   mov output, read
   clr read
   clr readCounter
   clr outputCounter

   rjmp secondRoutine

rejectButton:
    clr buttonStatus
	ldi PB0Count, 10
	ldi PB1Count, 10
*/
//1 s routine
secondRoutine:
/*
   lds r24, msCounter
   lds r25, msCounter+1
   //adiw r25:r24, 1
   cpi r24, low(1000)
   ldi temp, high(1000)
   cpc r25, temp
   brne NotSecond
      
   ldi testOutput, 0b00011000
   out PORTC, testOutput
   
   //If displaying flip on/off
   //Increment counter
   //If counter is at final value, set output register to 0
   clear msCounter  

   com testOutput
   out PORTC, testOutput

   inc outputCounter
   sbrc outputCounter, 0
   //out PORTC, output

   sbrs outputCounter, 0
   clr temp
   //out PORTC, temp

   cpi outputCounter, 7
   breq endOutput

   rjmp exitTimerInterrupt

endOutput:
   clr temp
   //out PORTC, temp
   clr output
   clr outputCounter

NotSecond:
   sts msCounter, r24
   sts msCounter+1, r25
*/
   //Epilogue
exitTimerInterrupt:
   pop r24
   pop r25
   pop YL
   pop YH
   pop temp
   out SREG, temp
   
reti

PB0_Interrupt:

//Set a flag that something is happening on PB0
andi buttonStatus, 0b00000001

reti

PB1_Interrupt:

//Set a flag that something is happening on PB1
andi buttonStatus, 0b00000010

reti
