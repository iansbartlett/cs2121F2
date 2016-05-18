//Lab 5 Part C
//Ian Bartlett z3419581 and Aaron Schneider z502001

.include "m2560def.inc"

ldi r16, 0b00000100

out DDRE, r16; Bit 3 will function as OC5A.
ldi r16, 0x4A; the value controls the PWM duty cycle
out OCR3BL, r16
clr r16
out OCR3BH, r16

; Set the Timer3 to Phase Correct PWM mode. 
ldi temp, (1 << CS50)
out TCCR3B, r16
ldi r16, (1<< WGM50)|(1<<COM5A1)
out TCCR3A, r16

halt:
   rjmp halt
