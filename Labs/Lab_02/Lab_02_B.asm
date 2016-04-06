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
defstring "Aaron"
defstring "Schneider"
defstring "and"
defstring "Ian"
defstring "Bartlett"

ldi ZL, low(NEXT_STRING<<1)
ldi ZH, high(NEXT_STRING<<1)

//Initialize stack pointer
ldi r17, low(RAMEND)
out SPL, r17
ldi r17, high(RAMEND)
out SPH, r17

ldi strLength,0 

rcall RecSearch

recSearch:

//Where am I?
push ZH
push ZL

lpm nextAddressL, Z+
lpm nextAddressH, Z+

ldi lenCount, 0

countingLoop:

lpm currChar, Z+
cpi currChar, 0x0
breq storeLen
inc lenCount
rjmp countingLoop

//How long was my string?
push lenCount

storeLen:
cp lenCount, strLength 
brlt nextAddrs
mov strLength, lenCount

cpi nextAddressL, 0x0
breq returnSequence

cpi nextAddressH, 0x0
breq returnSequence

nextAddrs:
mov ZL, nextAddressL
mov ZH, nextAddressH
//save the next address into registers
//cycle through string and count
//change Z using address saved into registers
//breq blah

rcall recSearch//call again

returnSequence:
//Pop lenCount from this iteration
pop strLength
//Compare it to the return length from the function above
cp strLength, lenCount
brlt return 
//If popped value is greater than return, overwrite:
//Overwrite return length w/ popped length
mov lenCount, strLength
//Overwrite Z register with popped location
pop ZL
pop ZH

return: ret

end:
rjmp end
