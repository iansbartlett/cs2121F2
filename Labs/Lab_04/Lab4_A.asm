//Lab 04 Part A
//2016-05-03
//Ian Bartlett and Aaron Schnieder

.include "m2560def.inc"

.def row = r16
.def col = r17
.def rmask = r18
.def cmask = r19
.def temp1 = r20
.def temp2 = r21

.equ PORTADIR = 0xF0
.equ INITCOLMASK = 0xEF
.equ INITROWMASK = 0x01
.equ ROWMASK = 0x0F

.cseg 

RESET:
   ldi temp1, low(RAMEND)
   out SPL, temp1
   ldi temp1, high(RAMEND)
   out SPH, temp1
   
   ldi temp1, PORTADIR
   sts DDRL, temp1
   ser temp1
   out DDRC, temp1
   out PORTC, temp1 //Light the LEDs at first

main:

   ldi cmask, INITCOLMASK
   clr col
     
colloop: 
   cpi  col, 4
   breq main
   sts PORTL, cmask

   ldi temp1, 0xFF
delay: 
   dec temp1
   brne delay    //wait for the decrement to hit a zero flag
    
   lds temp1, PINL
   andi temp1, ROWMASK 
   cpi temp1, 0xF
   breq nextcol

   ldi rmask, INITROWMASK
   clr row

rowloop:
   cpi row, 4
   breq nextcol
   mov temp2, temp1
   and temp2, rmask
   breq convert
   inc row
   lsl rmask
   rjmp rowloop
   
nextcol:
   lsl cmask
   inc cmask
   inc col
   rjmp colloop
   
convert:
   cpi col, 3
   breq reject  //letters- ignore for now
   
   cpi row, 3
   breq symbols
   
   mov temp1, row
   lsl temp1
   add temp1, row
   add temp1, col
   inc temp1
   //subi temp1, -'1'

   jmp convert_end
   
symbols: 
   cpi col, 1
   breq zero
   jmp reject

zero:
   clr temp1
   jmp convert_end

reject:
   clr temp1
   rjmp convert_end

convert_end:
   //debug
   //ldi temp1, 0b01010101
   out PORTC, temp1
   rjmp main
