//Safe Cracker Game
//COMP2121 Final Project
//Ian Bartlett z3419581 and Aaron Schneider z502001

//Register usage guidelines
//**************************
//r5: countdown length for difficulty level
//r6: system mode
//r16: LCD/I/O loading/general temp register
//r17: low(Pot target)
//r18: high(Pot target)
//r19: Temporary storage for keypad number
//r21: Rounds played
//r10: Seconds remaining in countdown
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

#define ASCII_OFFSET 48

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

///**************MACROS************************8
.macro do_lcd_command
	ldi r16, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro

.macro do_lcd_data
	ldi r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

; The macro clears a word (2 bytes) in a memory
; the parameter @0 is the memory address for that word
.macro clear
   ldi YL, low(@0)
   ldi YH, high(@0)     
   clr r16
   st Y+, r16
   st Y, r16                
.endmacro

.dseg

   final_code: .byte 3
   TempCounter: .byte 2
   TempCounterHalf: .byte 2
  
.cseg

.org 0x0000
    jmp RESET

.org INT0addr
    jmp PB0_Interrupt

.org INT1addr
    jmp PB1_Interrupt

.org OVF0addr
    jmp mainClockInterrupt

.org ADCCaddr
    jmp ADC_interrupt
	
RESET:

    ser r16
	out DDRF, r16
	out DDRA, r16
    out DDRC, r16
    out DDRB, r16

	clr r16
	out PORTF, r16
	out PORTA, r16


	ldi r16, 0b00000000
	out TCCR0A, r16
	ldi r16, 0b00000010
	out TCCR0B, r16
	ldi r16, 1<<TOIE0
	sts TIMSK0, r16
	sei

    ldi r16, low(RAMEND)
	out SPL, r16
	ldi r16, high(RAMEND)
	out SPH, r16

    ldi r16, PORTADIR
    sts DDRL, r16

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

    //Initialize difficulty levels
    ldi r16, 40
	mov r5, r16

    //Initialize mode
	ldi r16, START_SCREEN_MODE
	mov r6, r16

main:

    ldi r16, START_SCREEN_MODE
    cp r6, r16
	brne check_start_countdown
	    rcall start_screen
	
	check_start_countdown:
	ldi r16, START_COUNTDOWN_MODE
	cp r6, r16
	brne check_reset_pot
	    rcall start_countdown 

    check_reset_pot:
	ldi r16, RESET_POT_MODE
	cp r6, r16
    brne check_find_pot
	    rcall reset_POT

	check_find_pot:
	ldi r16, FIND_POT_MODE
	cp r6, r16
	brne no_mode
	    rcall find_POT

	no_mode:

rjmp main

//Mode functions

//Start screen - mode 0
//Displays welcome message
//Argument: most recent keypad button pressed
//Returns: writes to COUNTDOWN, sets mode to START_COUNTDOWN_MODE
//Incorperates dimming
start_screen:
	
	//Set up for next mode
    
    rcall init_start_countdown
	ret

//Initialize Start Countdown Mode
init_start_countdown:

    do_lcd_command 0b00000001 

    ldi r16, 3
	mov r10, r16

    ldi r16, START_COUNTDOWN_MODE
	mov r6, r16 

	do_lcd_data '2'
	do_lcd_data '1'
	do_lcd_data '2'
	do_lcd_data '1'
	do_lcd_data ' '	
	do_lcd_data '1'
	do_lcd_data '6'
	do_lcd_data 's'
	do_lcd_data '1'

	do_lcd_command 0b11000000

    do_lcd_data 'S'
	do_lcd_data 't'
	do_lcd_data 'a'
	do_lcd_data 'r'
	do_lcd_data 't'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'g'
	do_lcd_data ' '
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data '.'
	do_lcd_data '.'
	do_lcd_data '.'
	do_lcd_data ' '
 
    mov r20, r10
	rcall displayNumber

	ret
    
//Start Countdown - mode 1
//Displays game start countdown from 3
//Arguments: none
//Returns: sets mode to RESET_POT_MODE
start_countdown:
   
	clr r16
    cp r10, r16
    brne continueCountdown
       
         mov r10, r5

	    //Serious hax- PLEASE find a better way to fix timing issues
		rcall sleep_5ms
	    rcall sleep_5ms
		rcall sleep_5ms
		rcall sleep_5ms
		rcall sleep_5ms
		rcall sleep_5ms
		rcall sleep_5ms
		rcall sleep_5ms
		rcall sleep_5ms
		rcall sleep_5ms
		rcall sleep_5ms
		rcall sleep_5ms
		rcall sleep_5ms
       
	    rcall init_reset_pot     
	
	continueCountdown:    
	ret

//Initialize reset potentiometer mode
init_reset_pot:

    do_lcd_command 0b00000001 

	do_lcd_data 'R'
	do_lcd_data 'e'
	do_lcd_data 's'
	do_lcd_data 'e'
	do_lcd_data 't'
	do_lcd_data ' '
	do_lcd_data 'P'
	do_lcd_data 'O'
	do_lcd_data 'T'
	do_lcd_data ' '
	do_lcd_data 't'
	do_lcd_data 'o'
	do_lcd_data ' '
	do_lcd_data '0'

	do_lcd_command 0b11000000

	do_lcd_data 'R'
	do_lcd_data 'e'
	do_lcd_data 'm'
	do_lcd_data 'a'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'g'
	do_lcd_data ':'
	do_lcd_data ' '
 
    

    mov r20, r10
	rcall displayNumber

    ldi r16, RESET_POT_MODE
    mov r6, r16

    ret


//Reset potentiometer - mode 2
//Compares pot value to 0
//Displays countdown from COUNTDOWN
//Arguments: none
//Returns: sets mode to FIND_POT_MODE if successful, TIMEOUT_MODE if not.
reset_POT:

    //out PORTC, r12 

    clr r16
	cp r13, r16
	cp r12, r16
	brne pot_not_reset
        rcall init_find_POT

    pot_not_reset:
	clr r16
    cp r10, r16
    brge continueReset
        rcall init_timeout     
	
	continueReset:
     
    ret

init_find_POT:

    ldi r16, FIND_POT_MODE
	mov r6, r16
    
    do_lcd_command 0b00000001 

	do_lcd_data 'F'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'd'
	do_lcd_data ' '
	do_lcd_data 'P'
	do_lcd_data 'O'
	do_lcd_data 'T'

	do_lcd_command 0b11000000

	do_lcd_data 'R'
	do_lcd_data 'e'
	do_lcd_data 'm'
	do_lcd_data 'a'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'g'
	do_lcd_data ':'
	do_lcd_data ' '

    mov r20, r10
	rcall displayNumber

    //**********TEST INITIALIZATION**********
	//Replace with randomizer code
	ldi r16, 0x01
	mov r15, r16
	ldi r16, 0xE2
	mov r14, r16
    //*****************************

    ldi r16, FIND_POT_MODE
    mov r6, r16

    ret

//Find potentiometer - mode 3
//Generates a random pot value
//Compares pot value to random value
//Displays countdown from final countdown value of reset_POT
//Provides feedback via LED bank
//Arguments: none
//Returns: sets mode to FIND_CODE_MODE if successful, TIMEOUT_MODE if not
find_POT:  
    
    clr r16
	out PORTC, r16
	out PORTB, r16

    cp r14, r12
    cpc r15, r13
	brcc pot_not_overshot
        rcall init_reset_pot
		rjmp continueFind
   
    pot_not_overshot:
    cp r15, r13
	brne pot_not_found

	ser r16
 	out PORTC, r16

    //Final steps of LED logic not working

    mov r16, r17
    sub r16, r12
	cpi r16, 32 
	brpl pot_not_found

    in r16, PORTB
	ori r16, 0b00000100
	out PORTB, r16
    
    mov r16, r17
    sub r16, r12
	cpi r16, 16 
	brpl pot_not_found

	cpi r17, 16
	in r16, PORTB
	ori r16, 0b00001000
	out PORTB, r16

    pot_not_found:   
    clr r16
    cp r10, r16
	brge continueFind
        rcall init_timeout     
	
	continueFind:    
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
    mov r17, row
    lsl r17
    add r17, row
    add r17, col
    inc r17
  
    push r17
    jmp convert_end

symbols: 
   cpi col, 1
   breq zero
   jmp reject

resetReadFlag:
   clr readFlag
   rjmp return_from_find_code

zero:
   clr r16
   jmp convert_end

reject:
   clr r16
   rjmp return_from_find_code

convert_end:
   ldi r22, ASCII_OFFSET
   add r16, r22

   cp r16, r19
   breq right_number
   rjmp return_from_find_code

right_number:
   //turn on motor
   //if held for less than 1 sec 
   rjmp return_from_find_code
   //if held for more than 1 sec

	inc r21
	cpi r21, 3
	brlo next_round

    inc r25
	rjmp return_from_find_code

next_round:
	rcall init_reset_POT

return_from_find_code:
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

//Initialize timeout
init_timeout:
    ldi r16, TIMEOUT_MODE
	mov r6, r16
  
    do_lcd_command 0b00000001 
   
    do_lcd_data 'T'
	do_lcd_data 'i'
	do_lcd_data 'm'
	do_lcd_data 'e'
	do_lcd_data 'o'
	do_lcd_data 'u'
	do_lcd_data 't' 

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
PB0_Interrupt:
   reti

//PB1
PB1_Interrupt:
   reti

ADC_Interrupt:
   push r16
   in r16, SREG
   push r16

   lds r16, ADCL
   mov r12, r16
   lds r16, ADCH
   mov r13, r16

   pop r16
   out SREG, r16
   pop r16

   reti

//Timer

mainClockInterrupt:

//Prologue
   push r16
   in r16, SREG
   push r16
   push YH
   push YL
   push r25
   push r24

//500 ms routine

halfSecondRoutine:

   lds r24, TempCounterHalf
   lds r25, TempCounterHalf+1
   adiw r25:r24, 1
   cpi r24, low(3406)
   ldi r16, high(3406)
   cpc r25, r16
   brne NotHalfSecond

   //Stuff to do on the half second
   rcall refreshLCD

   ldi r16, (3 << REFS0) | (0 << ADLAR) | (0 << MUX0)
   sts ADMUX, r16
   ldi r16, (1 << MUX5)
   sts ADCSRB, r16
   ldi r16, (1 << ADEN) | (1 << ADSC) | (1 << ADIE) | (5 << ADPS0)
   sts ADCSRA, r16

   clear TempCounterHalf
   rjmp secondRoutine
   
NotHalfSecond:
   sts TempCounterHalf, r24
   sts TempCounterHalf+1, r25

secondRoutine:

   lds r24, TempCounter
   lds r25, TempCounter+1
   adiw r25:r24, 1
   cpi r24, low(7812)
   ldi r16, high(7812)
   cpc r25, r16
   brne NotSecond

   //Stuff to do on the second
   dec r10
   
   clear TempCounter
   rjmp EndIF
   
NotSecond:
   sts TempCounter, r24
   sts TempCounter+1, r25

//Epilogue

EndIF:

   pop r24
   pop r25
   pop YL
   pop YH
   pop r16
   out SREG, r16
   pop r16

reti

//Auxillary functions

//Displays the value of the r20 register by converting to BCD and outputting digits
//Does not move cursor
displayNumber:

cpi r20, 100
brlo checkTensPlace

countHundreds:

	cpi r20, 100
	brlo printHundreds
	//brvs printHundreds

    subi r20, 100
	inc r21
	rjmp countHundreds

printHundreds:
    
    //cpi temp2, 0
	//breq countTens

	ldi r16, ASCII_OFFSET
	add r16, r21
	
	rcall lcd_data
	rcall lcd_wait

	//mov temp3, temp2
    clr r21

checkTensPlace:
cpi r20, 10
brlo printOnes
    

countTens:

    cpi r20,10
	brlo printTens

    subi r20, 10
	inc r21
	rjmp countTens

printTens:
    
    //tst temp3
    //NEED AN AND CONDITION HERE
	//cpi temp2, 0
	//breq printOnes

	ldi r16, ASCII_OFFSET
	add r16, r21
	
	rcall lcd_data
	rcall lcd_wait
    clr r21

printOnes:

    //Only thing left should be the ones place
    ldi r16, ASCII_OFFSET
	//debug
	//ldi temp1, 9
    add r16, r20
    rcall lcd_data 
    rcall lcd_wait

    ret


//Random number generation

//LCD CODE BLOCK

.equ LCD_RS = 7
.equ LCD_E = 6
.equ LCD_RW = 5
.equ LCD_BE = 4

.macro lcd_set
	sbi PORTA, @0
.endmacro
.macro lcd_clr
	cbi PORTA, @0
.endmacro

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

//Keypad sweep routine
//Function prologue
push r17
push r18

//Body

keypad_sweep:
   ldi cmask, INITCOLMASK
   clr col
     
colloop: 
   cpi  col, 4
   brne noReadFlagReset
       rjmp resetReadFlag
   noReadFlagReset:
   sts PORTL, cmask

   ldi r17, 0xFF
delay: 
   dec r17
   brne delay    //wait for the decrement to hit a zero flag
    
   lds r17, PINL
   andi r17, ROWMASK 
   cpi r17, 0xF
   breq nextcol

   ldi rmask, INITROWMASK
   clr row

rowloop:
   cpi row, 4
   breq nextcol
   mov r18, r17
   and r18, rmask

   //I think this should have been convert_end
   brne continueConvert
      rjmp convert_end
   continueConvert:
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

//Epilogue
   pop r18
   pop r17

   ret

//Speaker function

//Refresh LCD

refreshLCD:   

    //out PORTC, r10

    start_countdown_LCD:
    ldi r16, START_COUNTDOWN_MODE
    cp r6, r16
	breq update_start_countdown_LCD
	   rjmp reset_POT_LCD

    update_start_countdown_LCD:
    do_lcd_command 0b00010000
	mov r20, r10
	rcall displayNumber

    reset_pot_LCD:
    ldi r16, RESET_POT_MODE
	cp r6, r16
    breq update_reset_pot_LCD
        rjmp find_pot_LCD

    update_reset_pot_LCD:
	do_lcd_command 0b00010000
	do_lcd_command 0b00010000
    
	ldi r16, 10
	cp r10, r16
	brge doubleDigitReset
         do_lcd_data ' '

    doubleDigitReset:
	mov r20, r10
	rcall displayNumber   
    

    find_pot_LCD:
    ldi r16, FIND_POT_MODE
	cp r6, r16
    breq update_find_pot_LCD
        rjmp exit_refresh_LCD

    update_find_pot_LCD:
    
	do_lcd_command 0b00010000
	do_lcd_command 0b00010000

    ldi r16, 10
	cp r10, r16
	brge doubleDigit
         do_lcd_data ' '

    doubleDigit:
    mov r20, r10
	rcall displayNumber   
    
    exit_refresh_LCD:

	ret
