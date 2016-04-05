//Lab 01 Part C
//Ian Bartlett z3419581 and Aaron Schneider z502001

.include "m2560def.inc"

.def temp = r16

.dseg

Cap_string: .byte 22

.cseg 
rjmp start

Low_string: .db "AAbb* ?winning!12345", 0x0, 0x0

start:
//set up Z pointer 

   ldi ZL, low(Low_string<<1)
   ldi ZH, high(Low_string<<1) 

//set up X pointer to Cap_string

   ldi XL, low(Cap_string)
   ldi XH, high(Cap_string)

loop:

   lpm temp, Z+

   //branch if string finished
   cpi temp, 0x0
   breq end
   //branch if >122
   cpi temp, 0x61
   brlt notlowercase

   //branch if <61
   cpi temp, 0x7B
   brge notlowercase

   subi temp, 32
   st X+, temp
   rjmp loop

notlowercase:

   st X+, temp
   rjmp loop

end:

   rjmp end

