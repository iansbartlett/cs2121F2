//Lab 01 Part A - 16 bit adder
//Ian Bartlett - z3419581 and Aaron Schneider z502001

.include "m2560def.inc"

start:
    
	//First set of values for 40960 + 2730
    
	ldi r17, high(40960)
	ldi r16, low(40960)

	ldi r19, high(2730)
	ldi r18, low(2730)
    
  
    //Second set of values for 640 + 511
	//Working now
     /*
	ldi r17, high(640)
	ldi r16, low(640)

	ldi r19, high(511)
	ldi r18, low(511)
    */

	add r16, r18
	mov r20, r16

	adc r17, r19
	mov r21, r17 

halt:
	    jmp halt

