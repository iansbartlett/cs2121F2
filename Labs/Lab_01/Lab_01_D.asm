//Lab 01 Part D
//Ian Bartlett z3419581 and Aaron Schneider z502001

.include "m2560def.inc"

#define TARGET 0x34

.def result = r16
.def search = r17

.cseg

rjmp start

    target_string: .db "abcdefghijklmnop", 0x0, 0x0

start:

   ldi ZL, low(target_string<<1)
   ldi ZH, high(target_string<<1) 

loop:

   lpm search, Z+

   //Character not found- store 0xFF and end
   cpi search, 0x0
   breq notfound

   cpi search, TARGET
   breq found

   rjmp loop

found:
   ldi result, TARGET
   rjmp end

notfound:
   ldi result, 0xFF
   rjmp end

end:
   rjmp end
