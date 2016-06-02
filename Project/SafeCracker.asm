//Safe Cracker Game
//COMP2121 Final Project
//Ian Bartlett z3419581 and Aaron Schneider z502001

//Register usage guidelines
//**************************
//r3: System state flags
//r5: countdown length for difficulty level
//r6: system mode
//r16: LCD/I/O loading/general temp register
//r17: low(Pot target)
//r18: high(Pot target)
//r19: Temporary storage for keypad number
//r21: Rounds played
//r10: Seconds remaining in countdown
//r9: backlight level
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

#define AUDIO_BIT_MASK 0b00000001

#define PB0_ACTIVE 0b00100000
#define PB1_ACTIVE 0b00010000

#define ACCEPT_CUTOFF_0 15
#define ACCEPT_CUTOFF_1 50
#define REJECT_CUTOFF_0 0
#define REJECT_CUTOFF_1 0

#define PB0_pin 0b00000001
#define PB1_pin 0b00000010

//Keypad things
//*********************

.def row = r20
.def col = r23
.def rmask = r24
.def cmask = r26
.def readFlag = r27

//Change later if we get a chance!
.def PB1Count = r28
.def PB0Count = r29

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
   TempCounterQuarter: .byte 2
   TempCounterAudio: .byte 2  
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
	out DDRG, r16
	out DDRE, r16
    sts DDRH, r16

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

    //Initialize backlight PWM

    ldi r16, 0xFF
	mov r9, r16

    sts OCR3BL, r9
	clr r16
	sts OCR3BH, r16
	//Use Fast PWM on Port E pin 3
	ldi r16, (1 << CS30)
	sts TCCR3B, r16
	ldi r16, (1 << WGM30)|(1 << WGM32 )|(1<<COM3B1)
	sts TCCR3A, r16

    ldi r16, (2 << ISC10)
	ori r16, (2 << ISC00)
	sts EICRA, r16

	in r16, EIMSK
	ori r16, (1<<INT0)
	ori r16, (1<<INT1)
	out EIMSK, r16

    //Initialize difficulty levels
    ldi r16, 40
	mov r5, r16

	clr r21

	//Initialize r3
	clr r16
	mov r3, r16

    rcall init_start_screen

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
	brne check_find_code
	    rcall find_POT

    check_find_code:
	ldi r16, FIND_CODE_MODE
	cp r6, r16
	brne check_enter_code
	    rcall find_code

    check_enter_code:
	ldi r16, ENTER_CODE_MODE
	cp r6, r16
	brne check_game_complete
	    rcall enter_code

    check_game_complete:
    ldi r16, GAME_COMPLETE_MODE
	cp r6, r16
	brne check_timeout
	    rcall game_complete

    check_timeout:
	ldi r16, TIMEOUT_MODE
	cp r6, r16
	brne repeat
	    rcall timeout
	
	repeat:
rjmp main

//Mode functions

init_start_screen:

	do_lcd_command 0b00000001 
	 
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
	do_lcd_data 'a'
	do_lcd_data 'f'
	do_lcd_data 'e'

	do_lcd_data ' '

	do_lcd_data 'C'
	do_lcd_data 'r'
	do_lcd_data 'a'
	do_lcd_data 'c'
	do_lcd_data 'k'
	do_lcd_data 'e'
	do_lcd_data 'r'

    ldi r16, START_SCREEN_MODE
	mov r6, r16

    ldi r16, 1
	out PORTC, r16

	ldi r16, 20
	mov r5, r16

    ldi ZL, low(final_code)
	ldi ZH, high(final_code)

ret


//Start screen - mode 0
//Displays welcome message
//Argument: most recent keypad button pressed
//Returns: writes to COUNTDOWN, sets mode to START_COUNTDOWN_MODE
//Incorperates dimming
start_screen:
    rcall keypad_sweep

    cpi readFlag, 0
	breq sameDifficulty	

	cpi r16, 0xA
	brne checkB
	    ldi readFlag, 2
        ldi r16, 20
		mov r5, r16
		ldi r16, 1
		out PORTC, r16

	checkB:
	cpi r16, 0xB
	brne checkC
	
	    ldi readFlag, 2
        ldi r16, 15
		mov r5, r16

		ldi r16, 3
		out PORTC, r16

    checkC:
    cpi r16, 0xC
	brne checkD

	    ldi readFlag, 2
        ldi r16, 10
		mov r5, r16

		ldi r16, 7
		out PORTC, r16
	
	checkD:
	cpi r16, 0xD
	brne sameDifficulty
		ldi readFlag, 2
        ldi r16, 6
		mov r5, r16

		ldi r16, 15
		out PORTC, r16

    sameDifficulty:
	//Set up for next mode  

	mov r16, r3
	andi r16, PB1_ACTIVE
	cpi r16, PB1_ACTIVE
	brne continue_start_screen
        
		andi r16, 0b11101111
		mov r3, r16
        rcall init_start_countdown
	
	continue_start_screen:
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

    //Reset rounds played
	clr r21
 
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
	//ldi r16, 0x01
	//mov r15, r16
	lds r16, TCNT3H
	andi r16, 0b00000011 //Truncate to ensure less than 0x3FF
	mov r15, r16
	//ldi r16, 0xE2
	//mov r14, r16
	lds r14, TCNT3L
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
    push XL
	push XH    

    clr r16
	out PORTC, r16
	//in  r16, PORTG
	//andi r16, 0b11111100
	out PORTG, r16

    cp r14, r12
    cpc r15, r13
	brcc pot_not_overshot
        rcall init_reset_pot
		rjmp continueFind
   
    pot_not_overshot: 

    mov XL, r12
	mov XH, r13

    adiw XL, 48

    cp r14, XL
    cpc r15, XH
	brcc pot_not_found

       ser r16
       out PORTC, r16
	
	sbiw XL, 16

    cp r14, XL
    cpc r15, XH
	brcc pot_not_found

    in r16, PORTG
	ldi r16, 0b00000100
	out PORTG, r16
    
	sbiw XL, 16

    cp r14, XL
    cpc r15, XH
	brcc pot_not_found
 
   	in r16, PORTG
	ldi r16, 0b00000010
	out PORTG, r16

    //Need a 1s wait time here. Right now responds instantly.
	rcall init_find_code

    pot_not_found:   
    clr r16
    cp r10, r16
	brge continueFind
	    clr r16
		out PORTC, r16
		out PORTG, r16
        rcall init_timeout     
	
	continueFind:    
    
	pop XH
	pop XL
	
	ret

init_find_code:
    
    clr r16
	out PORTC, r16
	out PORTG, r16

	do_lcd_command 0b00000001 
	
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

    //Initialize value
	//Fixed for now
	ldi r19, 3

    st Z+, r19

    ldi r16, FIND_CODE_MODE
	mov r6, r16

    ret

//Find code - mode 4
//Generates a random keypad key
//Compares keypad input to random key
//Spins motor if correct key pressed
//Arguments: none
//Returns: sets mode to ENTER_CODE_MODE, stores random key in final_code
find_code:	    

   rcall keypad_sweep

   cpi readFlag, 0
   breq not_pressed

   cpi readFlag, 2
   breq check_right_number
   ldi r16, 1
   mov r10, r16
   ldi readFlag, 2
   
   rjmp return_from_find_code

check_right_number:

   cp r16, r19
   brne not_pressed

   in r16, PORTG
   ori r16, 0b00000001
   out PORTG, r16

   mov r16, r4
   ori r16, 0b00000001
   mov r4, r16 
   
   ldi r16, 0
   cp r10, r16
   brge return_from_find_code

   inc r21
   
   out PORTC, r21

   cpi r21, 3
   brlo next_round

   rcall init_enter_code
   rjmp not_pressed

next_round:

    mov r10, r5
	rcall init_reset_POT

not_pressed:

    in r16, PORTG
	andi r16, 0b11111110
	out PORTG, r16

return_from_find_code:
    ret

init_enter_code:
   do_lcd_command 0b00000001 

   do_lcd_data 'E'
   do_lcd_data 'n'
   do_lcd_data 't'
   do_lcd_data 'e'
   do_lcd_data 'r'
   do_lcd_data ' '
   do_lcd_data 'C'
   do_lcd_data 'o'
   do_lcd_data 'd'
   do_lcd_data 'e'
 
   do_lcd_command 0b11000000

   ldi r16, ENTER_CODE_MODE
   mov r6, r16
   
   ldi ZL, low(final_code)
   ldi ZH, high(final_code)


ret

//Enter code - mode 5
//Accepts keypad inputv and compares with stored values
//Displays a "*" when correct key pressed, otherwise resets
//Arguments: final_code
//Returns: sets mode to GAME_COMPLETE_MODE
enter_code:

   rcall keypad_sweep

   ld r19, Z+

   out PORTC, r19

   cpi readFlag, 0
   breq enter_code_idle

   cpi readFlag, 2
   breq enter_code_idle
   ldi readFlag, 2

   cp r16, r19
   breq correct_key
       rcall init_enter_code
       rjmp enter_code_idle
    
    correct_key:
	dec r21
    do_lcd_data '*'
    cpi r21, 0
	breq init_game_complete

    enter_code_idle:
    ret

init_game_complete:
   ldi r16, GAME_COMPLETE_MODE
   mov r6, r16

    do_lcd_command 0b00000001 

    do_lcd_data 'G'
	do_lcd_data 'a'
	do_lcd_data 'm'
	do_lcd_data 'e'
	do_lcd_data ' '
	do_lcd_data 'C'
	do_lcd_data 'o'
	do_lcd_data 'm'
	do_lcd_data 'p'
	do_lcd_data 'l'
	do_lcd_data 'e'
	do_lcd_data 't'
	do_lcd_data 'e'

	do_lcd_command 0b11000000

    do_lcd_data 'Y'
	do_lcd_data 'o'
	do_lcd_data 'u'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data '!'

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
	do_lcd_data 'G'
	do_lcd_data 'a'
	do_lcd_data 'm'
	do_lcd_data 'e'
	do_lcd_data ' '
	do_lcd_data 'o'
	do_lcd_data 'v'
	do_lcd_data 'e'
	do_lcd_data 'r'
    
	do_lcd_command 0b11000000

    do_lcd_data 'Y'
	do_lcd_data 'o'
	do_lcd_data 'u'
	do_lcd_data ' '
	do_lcd_data 'l'
	do_lcd_data 'o'
	do_lcd_data 's'
	do_lcd_data 'e'
	do_lcd_data '!'

    ret

//Game timeout - mode 7
//Displays "You lose!" message
//Arguments: none
//Returns: sets mode to START_SCREEN_MODE
//Incorperates dimming

timeout:

	mov r16, r3
	andi r16, PB1_ACTIVE
	cpi r16, PB1_ACTIVE
	brne continue_timeout

        andi r16, 0b11101111
		mov r3, r16
        rcall init_start_screen
	
	continue_timeout:	
	mov r16, r3
	andi r16, PB0_ACTIVE
	cpi r16, PB0_ACTIVE
	brne continue_timeout_2

        andi r16, 0b11011111
		mov r3, r16
      //  rcall init_start_screen
	
    continue_timeout_2:
    ret

//Interrupt functions

//PB0
PB0_Interrupt:
   mov r16, r3
   ori r16, 0b10000000
   mov r3, r16
   reti

//PB1
PB1_Interrupt:
   
   mov r16, r3
   ori r16, 0b01000000   
   mov r3, r16  

   reti

//PB1 Debounce

debouncePB1:
   push r16

   in r16, PORTD
   andi r16, PB1_pin
   cpi r16, PB1_pin
   breq increasePB1Count
   dec PB1Count
   rjmp checkPB1Value

increasePB1Count:
   inc PB1Count

checkPB1Value:
   rjmp storePB1

   cpi PB1Count, ACCEPT_CUTOFF_1
   breq storePB1

   cpi PB1Count, REJECT_CUTOFF_1
   breq rejectButton
   
   rjmp exitDebouncePB1

storePB1:
   
   mov r16, r3
   andi r16, 0b00111111
   mov r3, r16
   ldi PB1Count, 10

   mov r16, r3
   ori r16, PB1_ACTIVE  
   mov r3, r16   

   rjmp exitDebouncePB1

rejectButton:
   mov r16, r3
   andi r16, 0b00111111
   mov r3, r16

   ldi PB0Count, 10
   ldi PB1Count, 10
   rjmp exitDebouncePB1

exitDebouncePB1:
   pop r16
ret

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
   push r17
   push YH
   push YL
   push r25
   push r24

// 523 Hz timer to generate audio tone
audioFrequencyRoutine:

   lds r24, TempCounterAudio
   lds r25, TempCounterAudio+1
   adiw r25:r24, 1
   cpi r24, low(7)
   ldi r16, high(7)
   cpc r25, r16
   brne NotAudioPeriod

   //Stuff to do on the half second
   mov r16, r3
   andi r16, AUDIO_BIT_MASK
   cpi 	r16, AUDIO_BIT_MASK
   brne noAudio 

   in r16, PORTB
   ldi r17, 0b00000001
   eor r16, r17
   out PORTB, r16

   noAudio:

   checkPB0:
   mov r16, r3
   andi r16, 0b10000000
   cpi r16, 0b10000000
   brne checkPB1
       //rcall debouncePB0

   checkPB1:
   mov r16, r3
   andi r16, 0b01000000
   cpi r16, 0b01000000
   brne exitAudioTimerRoutine
         
       rcall debouncePB1

   exitAudioTimerRoutine:
   clear TempCounterAudio
   rjmp quarterSecondRoutine
   
NotAudioPeriod:
   sts TempCounterAudio, r24
   sts TempCounterAudio+1, r25

quarterSecondRoutine:

   lds r24, TempCounterQuarter
   lds r25, TempCounterQuarter+1
   adiw r25:r24, 1
   cpi r24, low(1703)
   ldi r16, high(1703)
   cpc r25, r16
   brne NotQuarterSecond

   //Stuff to do on the quarter second
   //Shut off the audio flag
   mov r16, r3
   //Magic number: compliment of AUDIO_BIT_MASK
   andi r16, 0b11111110
   mov r3, r16   

   //May want to increase ADC sampling frequency
   ldi r16, (3 << REFS0) | (0 << ADLAR) | (0 << MUX0)
   sts ADMUX, r16
   ldi r16, (1 << MUX5)
   sts ADCSRB, r16
   ldi r16, (1 << ADEN) | (1 << ADSC) | (1 << ADIE) | (5 << ADPS0)
   sts ADCSRA, r16

   clear TempCounterQuarter
   rjmp halfSecondRoutine
   
NotQuarterSecond:
   sts TempCounterQuarter, r24
   sts TempCounterQuarter+1, r25

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
   //Count down on the timer
   dec r10

   //Begin the beep if mode is correct
 
   //TODO: MODE CHECK

   mov r16, r3
   ori r16, AUDIO_BIT_MASK
   mov r3, r16
   
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
   pop r17
   pop r16
   out SREG, r16
   pop r16

reti

//Auxillary functions

//Displays the value of the r20 register by converting to BCD and outputting digits
//Does not move cursor
displayNumber:
push r21


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


    pop r21
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

keypad_sweep:

 push r17
 push r21

 ldi cmask, INITCOLMASK
   clr col
     
colloop: 
   cpi  col, 4
   breq resetReadFlag
   sts PORTL, cmask

   ldi r16, 0xFF
delay: 
   dec r16
   brne delay    //wait for the decrement to hit a zero flag
    
   lds r16, PINL
   andi r16, ROWMASK 
   cpi r16, 0xF
   breq nextcol

   ldi rmask, INITROWMASK
   clr row

rowloop:
   cpi row, 4
   breq nextcol
   mov r17, r16
   and r17, rmask
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
   breq letters  

   cpi row, 3
   breq symbols
   
   inc r21
   mov r16, row
   lsl r16
   add r16, row
   add r16, col
   inc r16
   //subi temp1, -'1'
   jmp convert_end
   
symbols: 

   cpi col, 0
   breq star

   cpi col, 1
   breq zero

   cpi col, 2
   breq hash

   jmp reject

resetReadFlag:

   clr readFlag
   clr r16
   rjmp return_keypad_sweep

star:

   ldi r16, 0xE
   jmp convert_end

zero:
   clr r16
   jmp convert_end

hash:
   ldi r16, 0xF
   jmp convert_end

letters:

   cpi row, 0
   breq A_key

   cpi row, 1
   breq B_key

   cpi row, 2
   breq C_key
   
   cpi row, 3
   breq D_key

   rjmp reject

A_key:
   ldi r16, 0xA
   jmp convert_end

B_key:
   ldi r16, 0xB
   jmp convert_end

C_key:
   ldi r16, 0xC
   jmp convert_end

D_key:
   ldi r16, 0xD
   jmp convert_end

reject:
   clr r16
   rjmp convert_end


convert_end:

   cpi readFlag, 2
   breq return_keypad_sweep

   ldi readFlag, 1
   rjmp return_keypad_sweep

return_keypad_sweep:

   pop r21
   pop r17
   ret

//Refresh LCD

refreshLCD:   

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
