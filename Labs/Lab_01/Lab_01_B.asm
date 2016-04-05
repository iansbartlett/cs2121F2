//Lab 01 Part B
//Ian Bartlett z3419581 and Aaron Schneider z502001

.include "m2560def.inc"

.dseg
   
   sum_string: .byte 5

.cseg 

   //Init registers for target vectors

   ldi r16, 1
   ldi r17, 2
   ldi r18, 3
   ldi r19, 4
   ldi r20, 5

   ldi r21, 5
   ldi r22, 4
   ldi r23, 3
   ldi r24, 2
   ldi r25, 1

   //Set up pointer to sum_string

   ldi XL, low(sum_string)
   ldi XH, high(sum_string)

   //Add, store, and iterate five times

   add r16, r21
   st X+, r16

   add r17, r22
   st X+, r17

   add r18, r23
   st X+, r18

   add r19, r24
   st X+, r19

   add r20, r25
   st X+, r20

end:
   rjmp end
