//Lab 02 Part A
//Ian Bartlett z3419581 and Aaron Schneider z502001

//A program to read a string from program memory, push it to the stack
//Then save to program memory in reverse order

.include "m2560def.inc"

#define MAX_STRING_LENGTH 50

.def cursor = r16

.dseg 

	reversed_string: .byte MAX_STRING_LENGTH

.cseg

rjmp start

    target_string: .db "abcdefghijklmnop", 0x0, 0x0

start:

   ldi ZL, low(target_string<<1)
   ldi ZH, high(target_string<<1) 

   ldi cursor, 0x0
   push cursor

read:

   lpm cursor, Z+

   cpi cursor, 0x0
   breq reverse

   push cursor

   rjmp read

reverse:

   ldi ZL, low(reversed_string)
   ldi ZH, high(reversed_string)
   
reverse_loop:

   pop cursor
   
   st Z+, cursor
   
   cpi cursor, 0x0
   breq end

   rjmp reverse_loop

end:
   rjmp end
