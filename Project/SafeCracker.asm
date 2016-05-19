//Safe Cracker Game
//COMP2121 Final Project
//Ian Bartlett z3419581 and Aaron Schneider z502001

//Register usage guidelines
//**************************
//r16: LCD/I/O loading/general temp register
//r17: low(Pot target)
//r18: high(Pot target)
//r18: Temporary storage for keypad number
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

.dseg

   final_code: .byte 3
  
.cseg

//Interrupts

//RESET

//Main
main:
   


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

//LCD Backlight Dim

//LCD Backlight Undim

//Pot ADC driver

//Keypad sweep routine

//Speaker function





