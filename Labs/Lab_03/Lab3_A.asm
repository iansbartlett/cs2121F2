//Lab 3 Part A
//Ian Bartlett z3419581 and Aaron Schneider z502001

.include "m2560def.inc"

.cseg

ldi r16, 0xE5
ser r17

out DDRC, r17
out PORTC, r16

end: rjmp end

