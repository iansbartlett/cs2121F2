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

defstring "Aaron"
defstring "Schneider"
defstring "Bartlett"
defstring "and"
defstring "Ian"
defstring "Testing"


start:

ldi ZL, low(NEXT_STRING<<1)
ldi ZH, high(NEXT_STRING<<1)

//Initialize stack pointer
ldi r17, low(RAMEND)
out SPL, r17
ldi r17, high(RAMEND)
out SPH, r17

ldi strLength,0 

rcall recSearch

end:
rjmp end


//FUNCTIONS

//***************************
//Function: recSearch
//Recursively finds longest string in linked list
//Arguments: next address, stored in Z
//Returns: 
// -current best guess for highest value, stored in strLength(r16)
// -current best guess for string location, stored in Z
//***************************

recSearch:

ldi lenCount, 0

cpi ZL, 0x0
breq return

//Where am I?
push ZH
push ZL

lpm nextAddressL, Z+
lpm nextAddressH, Z+



countingLoop:

lpm currChar, Z+
cpi currChar, 0x0
breq storeLength
inc lenCount
rjmp countingLoop

//How long was my string?

storeLength:
push lenCount

//MAY BE A PROBLEM- DOES NOT CHECK IF HIGH BYTE NONZERO

cpi nextAddressL, 0x0
breq returnSequence

//Call again
nextAddrs:
mov ZL, nextAddressL
mov ZH, nextAddressH
rcall recSearch

returnSequence:
//Pop lenCount from this iteration
pop lenCount
//Compare it to the return length from the function above
cp lenCount, strLength
brlt return_unchanged 
//If popped value is greater than return, overwrite:
//Overwrite return length w/ popped length
mov strLength, lenCount
//Overwrite Z register with popped location
pop ZL
pop ZH

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
