//Lab 01 Part E - sorting an array
//Ian Bartlett - z3419581 and Aaron Schneider z5020001

//Implements array sorting using bubblesort

.include "m2560def.inc"

.def temp1 = r16
.def temp2 = r17
.def swapflag = r18

.dseg

   array: .byte 8
  
.cseg rjmp start

   data: .db '7','4','5','1','6','3','1', 0x0

start:
   
   ldi ZH, high(data<<1)
   ldi ZL, low(data<<1)

   ldi YH, high(array)
   ldi YL, low(array)

   ldi XH, high(array)
   ldi XL, low(array)

   ldi swapflag, 0x1
   
load:
   
   lpm temp1, Z+
   cpi temp1, 0x0
   breq sort

   st Y+, temp1
   rjmp load

sort:

   cpi swapflag, 0x0
   breq halt

   ldi swapflag, 0x0

   ldi YH, high(array)
   ldi YL, low(array)

   ldi XH, high(array)
   ldi XL, low(array)

   inc XL

loop:

   ld temp1, Y
   ld temp2, X

   cpi temp2, 0x0
   breq sort

   cp temp1, temp2
   brge swapvals
   
   //st Y, temp1
   //st X, temp2
   
   inc XL
   inc YL
   rjmp loop

swapvals:
   ldi swapflag, 1
   st Y, temp2
   st X, temp1
   
   inc XL
   inc YL

   rjmp loop

halt:
   rjmp halt
