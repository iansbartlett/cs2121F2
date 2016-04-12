//Lab 02 Part C
//Ian Bartlett z3419581 and Aaron Schneider z502001

.include "m2560def.inc"


.def nextAddressL = r18
.def nextAddressH = r19
.def valueL = r20
.def valueH = r21


.set NEXT_INT = 0x0000
.macro defint; str
	.set T = PC ;save current position in program memory
	.dw NEXT_INT << 1 ;write out address of next list node
	.set NEXT_INT = T;update NEXT_STRING to point to this node
	
	.dw @0
.endmacro

.cseg

rjmp start

defint 0x01
defint 0x00
defint -255
defint 15000

start:

ldi ZL, low(NEXT_INT<<1)
ldi ZH, high(NEXT_INT<<1)

//Initialize stack pointer
ldi r17, low(RAMEND)
out SPL, r17
ldi r17, high(RAMEND)
out SPH, r17

rcall recMinMax

end:
rjmp end


//FUNCTIONS

//***************************
//Function: recMinMax
//Recursively finds longest string in linked list
//Arguments: next address, stored in Z
//Returns: 
// -current best guess for highest value, stored in strLength(r16)
// -current best guess for string location, stored in Z
//***************************

recMinMax:

cpi ZL, 0x0
breq return

lpm nextAddressL, Z+
lpm nextAddressH, Z+

storeLength:
lpm valueL, Z+
push valueL
lpm valueH, Z+
push valueH

//MAY BE A PROBLEM- DOES NOT CHECK IF HIGH BYTE NONZERO

cpi nextAddressL, 0x0
breq firstReturn

//Call again
nextAddrs:
mov ZL, nextAddressL
mov ZH, nextAddressH
rcall recMinMax

rjmp returnSequence

firstReturn:
mov XL, valueL
mov XH, valueH

mov YL, valueL
mov YH, valueH

returnSequence:

pop valueH
pop valueL

cp valueH,XH
breq checkXL
brge biggerX
brlt checkY

checkXL:

cp XL,valueL
brsh checkY

biggerX:

mov XL, valueL
mov XH, valueH

checkY:

cp YH, valueH
breq checkYL
brge smallerY
brlt return

checkYL:

cp valueL,YL
brge return

smallerY:
mov YL, valueL
mov YH, valueH

rjmp return

return_unchanged:

//Move stack pointer down over unused values
in YL, SPL
in YH, SPH
adiw Y, 2
out SPL, YL
out SPH, YH

rjmp return

return: ret
