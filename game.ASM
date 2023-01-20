
;**********************************************************************
;                                                                     *
;    Filename:        game.asm                                        *
;    Date: 12/8/22                                                    *
;								      *
;    Author: Ceci                                                     *
;								      *
;**********************************************************************
;                                                                     *
;    Files required: P16F84A.INC                                      *
;                                                                     *
;**********************************************************************


    list      p=16F84A             ; list directive to define processor
    #include <p16F84a.inc>         ; processor specific variable definitions

    __CONFIG   _CP_OFF & _WDT_OFF & _PWRTE_ON & _RC_OSC

;***** VARIABLE DEFINITIONS********************************************
w_temp        EQU     0x0C         
status_temp   EQU     0x0D        
win_checker   EQU     0x0E
DOUTER	      EQU     0x0F 	
DINNER	      EQU     0x10
;**********************************************************************
RESET_VECTOR      CODE    0x0000  ; processor reset vector
        goto    start             ; go to beginning of program

ISR               CODE    0x0004  ; interrupt vector location

Interrupt:

        movwf  w_temp             ; save off current W register contents
        movf   STATUS,w           ; move status register into W register
        movwf  status_temp        ; save off contents of STATUS register

        movf   status_temp,w      ; retrieve copy of STATUS register
        movwf  STATUS             ; restore pre-isr STATUS register contents
        swapf  w_temp,f
        swapf  w_temp,w           ; restore pre-isr W register contents
        retfie                    ; return from interrupt
	  
MAIN_PROGRAM    CODE
    
start 
;configuring PORTA for inputs and PORTB for outputs (DONE)
    bsf STATUS, RP0 
    movlw 0x0f
    movwf TRISA
    
    movlw 0xc0
    movwf TRISB
    bcf STATUS, RP0
    
;clearing 'c' bit in STATUS to ensure RLF works properly (DONE)
    bcf STATUS, C
    
;setup PORTB light pattern & set wreg to 0x01 (DONE)
    movlw 0x01   
    movwf PORTB
 
mloop:
    call delay 
mloop2:    bcf STATUS, C

    ;reset important register values (DONE)
    bcf STATUS, C
    movlw 0x01
    
    ;test if light needs to be sent back to lsb 
    btfsc PORTB, 3
	goto rset
	
    ;Chasing sequence (DONE)
      rlf PORTB, F
    goto mloop
   
;sets PORTB back to 0x01, creating loop (DONE)
rset:
    movwf PORTB
    goto mloop
    
    
;delays program for ~1 sec and checks for input while
;game is running (not when button has been pressed)
delay
    ;if there is input, goes to STOP (DONE)
    movlw 0x0D
    movwf DOUTER
delay0
    movlw 0xF0
    movwf DINNER
delay1
    movlw 0xFF
    addwf PORTA, W
    movwf w_temp
    btfsc STATUS, C
	goto stop
    
    decfsz DINNER
	goto delay1
    
    decfsz DOUTER
	goto delay0
    return

;delays switching by ~1 sec
delayb
    movlw 0x23
    movwf DOUTER
delayb0
    movlw 0xED
    movwf DINNER
delayb1    
    decfsz DINNER
	goto delayb1
    
    decfsz DOUTER
	goto delayb0
    return    
;when a button is pressed
stop:
    bcf STATUS, 0
    clrw
    movf PORTA, W
    subwf PORTB, W
    btfsc STATUS, Z
	goto win
	
;lose condition; lights up corresponding LED and returns to guessing after delay
    movlw 0x10
    addwf PORTB, f
    call delayb
    movlw 0x10
    subwf PORTB, f
    goto mloop2
       
;win condition; lights up corresponding LED and returns to guessing after delay
win:
    movlw 0x20
    addwf PORTB, f
    call delayb
    movlw 0x20
    subwf PORTB, f
    goto mloop2
    
fin:
    goto fin
    

        END                      
