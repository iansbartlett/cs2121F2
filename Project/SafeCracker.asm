//Safe Cracker Game
//COMP2121 Final Project
//Ian Bartlett z3419581 and Aaron Schneider z502001

//Register usage guidelines
//**************************
//r16: LCD/I/O loading/general temp register
//r17: low(Pot target)
//r18: high(Pot target)
//r19: Temporary storage for keypad number
//r21: Rounds played
//r22: Seconds remaining in countdown
//r25: current system mode
//**************************




.include "m2560def.inc"

#define START_SCREEN_MODE 0
#define START_COUNTDOWN_MODE 1
#define RESET_POT_MODE 2
#define FIND_POT_MODE 3
#define FIND_CODE_MODE 4
#define ENTER_CODE_MODE 5
#define GAME_COMPLETE_MODE 6
#define TIMEOUT_MODE 7


//Keypad things
//*********************
.def row = r20
.def col = r23
.def rmask = r24
.def cmask = r26
.def readFlag = r27

.equ PORTADIR = 0xF0
.equ INITCOLMASK = 0xEF
.equ INITROWMASK = 0x01
.equ ROWMASK = 0x0F
//*********************

.dseg

   final_code: .byte 3
  
.cseg

//Interrupts

//RESET

//Main
main:
   
    ldi r16, low(RAMEND)
	out SPL, r16
	ldi r16, high(RAMEND)
	out SPH, r16

    ldi temp1, PORTADIR
    sts DDRL, temp1

	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000 ; 2x5x7
  	rcall sleep_1ms
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001000 ; display off?
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001100 ; Cursor on, bar, no blink


rjmp main

//Mode functions


//Start screen - mode 0
//Displays welcome message
//Argument: most recent keypad button pressed
//Returns: writes to COUNTDOWN, sets mode to START_COUNTDOWN_MODE
//Incorperates dimming
start_screen:
    ret

//Start Countdown - mode 1
//Displays game start countdown from 3
//Arguments: none
//Returns: sets mode to RESET_POT_MODE
start_countdown:
    ret

//Reset potentiometer - mode 2
//Compares pot value to 0
//Displays countdown from COUNTDOWN
//Arguments: none
//Returns: sets mode to FIND_POT_MODE if successful, TIMEOUT_MODE if not.
reset_POT:
    ret

//Find potentiometer - mode 3
//Generates a random pot value
//Compares pot value to random value
//Displays countdown from final countdown value of reset_POT
//Provides feedback via LED bank
//Arguments: none
//Returns: sets mode to FIND_CODE_MODE if successful, TIMEOUT_MODE if not
find_POT:
    ret

//Find code - mode 4
//Generates a random keypad key
//Compares keypad input to random key
//Spins motor if correct key pressed
//Arguments: none
//Returns: sets mode to ENTER_CODE_MODE, stores random key in final_code
find_code:
    do_lcd_data 'P'
	do_lcd_data 'o'
	do_lcd_data 's'
	do_lcd_data 'i'
	do_lcd_data 't'	
	do_lcd_data 'i'
	do_lcd_data 'o'
	do_lcd_data 'n'

	do_lcd_data ' '

	do_lcd_data 'f'
	do_lcd_data 'o'
	do_lcd_data 'u'
	do_lcd_data 'n'	
	do_lcd_data 'd'
	do_lcd_data '!'

	do_lcd_command 0b11000000


	do_lcd_data 'S'
	do_lcd_data 'c'
	do_lcd_data 'a'
	do_lcd_data 'n'

	do_lcd_data ' '	

	do_lcd_data 'f'
	do_lcd_data 'o'
	do_lcd_data 'r'

	do_lcd_data ' '	

	do_lcd_data 'n'
	do_lcd_data 'u'
	do_lcd_data 'm'
	do_lcd_data 'b'
	do_lcd_data 'e'
	do_lcd_data 'r'	    

    rcall keypad_sweep

	push r16
    clr r16

    cpi col, 3
    breq reject
   
    cpi row, 3
    breq symbols
   
    inc r16
    mov temp1, row
    lsl temp1
    add temp1, row
    add temp1, col
    inc temp1
    //subi temp1, -'1'
    push temp1
    jmp convert_end

symbols: 
   cpi col, 1
   breq zero
   jmp reject

resetReadFlag:
   clr readFlag
   rjmp find_code

zero:
   clr r16
   jmp convert_end


reject:
   clr r16
   rjmp find_code

convert_end:
   ldi r22, ASCII_OFFSET
   add r16, r22

   cp r16, r19
   breq right_number
   rjmp find_code

right_number:
   //turn on motor
   //if held for less than 1 sec 
   rjmp find_code
   //if held for more than 1 sec


	inc r21
	cpi r21, 3
	brlo next_round

    inc r25
	rjmp return_from_find_code

next_round;
	ldi r25, RESET_POT

return_from_find_code
    ret

//Enter code - mode 5
//Accepts keypad input and compares with stored values
//Displays a "*" when correct key pressed, otherwise resets
//Arguments: final_code
//Returns: sets mode to GAME_COMPLETE_MODE
enter_code:
    ret

//Game complete - mode 6
//Displays "You win!" message
//Arguments: none
//Returns: sets mode to START_SCREEN_MODE
//Incorperates dimming
game_complete:
    ret

//Game timeout - mode 7
//Displays "You lose!" message
//Arguments: none
//Returns: sets mode to START_SCREEN_MODE
//Incorperates dimming

timeout:
    ret

//Interrupt functions

//PB0

//PB1

//Timer

//Auxillary functions

//Random number generation

//LCD CODE BLOCK
lcd_command:
    out PORTF, r16
    rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
    rcall sleep_1ms
	ret

lcd_data:
	out PORTF, r16
	lcd_set LCD_RS
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	lcd_clr LCD_RS
	ret

lcd_wait:
	push r16
    clr r16
    out DDRF, r16
	out PORTF, r16
	lcd_set LCD_RW

lcd_wait_loop:
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	in r16, PINF
	lcd_clr LCD_E
	sbrc r16, 7
	rjmp lcd_wait_loop
	lcd_clr LCD_RW
	ser r16
	out DDRF, r16
	pop r16
	ret

.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4
; 4 cycles per iteration - setup/call-return overhead

sleep_1ms:
    push r24
    push r25
    ldi r25, high(DELAY_1MS)
    ldi r24, low(DELAY_1MS)

delayloop_1ms:
    sbiw r25:r24, 1
    brne delayloop_1ms
    pop r25
    pop r24
    ret

sleep_5ms:
    rcall sleep_1ms
    rcall sleep_1ms
    rcall sleep_1ms
    rcall sleep_1ms
    rcall sleep_1ms
    ret

//LCD Backlight Dim

//LCD Backlight Undim

//Pot ADC driver

//Keypad sweep routine
keypad_sweep:
   ldi cmask, INITCOLMASK
   clr col
     
colloop: 
   cpi  col, 4
   breq resetReadFlag
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

sweep_end:
   //temp1 IS r16
   // hax hax hax
   cpi readFlag, 1
   breq keypad_sweep
   ret

//Speaker function
