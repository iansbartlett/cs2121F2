//Lab 02 Part B
//Ian Bartlett z3419581 and Aaron Schneider z502001

.include "m2560def.inc"

.def strLength = r16
.def lenCount = r17
.def nextAddressL = r18
.def nextAddressH = r19
.def currChar = r20

.set NEXT_STRING = 0x0000
.macro defstring; str
	.set T = PC ;save current position in program memory
	.dw NEXT_STRING << 1 ;write out address of next list node
	.set NEXT_STRING = T;update NEXT_STRING to point to this node

	.if strlen(@0) & 1; odd length + null byte
		.db @0, 0
	.else; even length + null byte,add padding byte
		.db @0, 0, 0
	.endif
.endmacro

.cseg

rjmp start

start:
defstring "Ian"
defstring "Bartlett"
defstring "and"
defstring "Aaron"
defstring "Schneider"

ldi ZL, low(NEXT_STRING<<1)
ldi ZH, high(NEXT_STRING<<1)

ldi strLength,0 

rjmp RecSearch

recSearch:

lpm nextAddressL, Z+
lpm nextAddressH, Z+

ldi lenCount, 0

countingLoop:

lpm currChar, Z+
cpi currChar, 0x0
breq storeLen
inc lenCount
rjmp countingLoop

storeLen:
cp strLength, lenCount
brlt nextAddrs
mov strLength, lenCount

nextAddrs:

//save the next address into registers
//cycle through string and count
//change Z using address saved into registers
//breq blah
rjmp RecSearch//call again




