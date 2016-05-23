//Lab 5 Part B	
//Ian Bartlett z3419581 and Aaron Schneider z502001

.include "m2560def.inc"

.cseg

//ldi r16, 0b00010000

ser r16
out DDRE, r16; Bit 3 will function as OC3.
ldi r16, 0x4A; the value controls the PWM duty cycle
sts OCR3BL, r16
clr r16
sts OCR3BH, r16

//Attempting to use Fast PWM on Port E pin 3
ldi r16, (1 << CS30)
sts TCCR3B, r16
ldi r16, (1 << WGM30)|(1 << WGM32 )|(1<<COM3A1)
sts TCCR3A, r16

halt:
   rjmp halt
