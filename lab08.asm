; It is assumed that the following connections on the board are made:
; LCD D0-D7 -> PB0-PB7
; LCD BE-RS -> PA0-PA3
; KEYPAD R0-C3 -> PD0-PD7
; KEYPAD (optional LEDs) LED0-LED7 -> PC0-PC7
; These ports can be changed if required by replacing all references to the ports with a
; different port. This means replacing occurences of DDRx, PORTx and PINx.

.include "m64def.inc"
.def temp =r16
.def data =r17
.def del_lo = r18
.def del_hi = r19

;keypad definitions
.def row =r21
.def col =r22
.def mask =r23
.def temp2 =r24
.equ PORTDDIR = 0xF0
.equ INITCOLMASK = 0xEF
.equ INITROWMASK = 0x01
.equ ROWMASK = 0x0F

;LCD protocol control bits
.equ LCD_RS = 3
.equ LCD_RW = 1
.equ LCD_E = 2
;LCD functions
.equ LCD_FUNC_SET = 0b00110000
.equ LCD_DISP_OFF = 0b00001000
.equ LCD_DISP_CLR = 0b00000001
.equ LCD_DISP_ON = 0b00001100
.equ LCD_ENTRY_SET = 0b00000100
.equ LCD_ADDR_SET = 0b10000000
;LCD function bits and constants
.equ LCD_BF = 7
.equ LCD_N = 3
.equ LCD_F = 2
.equ LCD_ID = 1
.equ LCD_S = 0
.equ LCD_C = 1
.equ LCD_B = 0
.equ LCD_LINE1 = 0
.equ LCD_LINE2 = 0x40
;Function lcd_write_com: Write a command to the LCD. The data reg stores the value to be written.

.cseg
jmp RESET

RESET:
		ldi temp, low(RAMEND)
		out SPL, temp
		ldi temp, high(RAMEND)
		out SPH, temp
		ldi temp, PORTDDIR ; columns are outputs, rows are inputs
		out DDRD, temp
		ser temp
		out DDRC, temp ; Make PORTC all outputs
		out PORTC, temp ; Turn on all the LEDs		
		rcall lcd_init	;clear and initialise lcd display
		; main keeps scanning the keypad to find which key is pressed.
		jmp keymain

lcd_write_com:
		out PORTB, data ; set the data port's value up
		clr temp
		out PORTA, temp ; RS = 0, RW = 0 for a command write
		nop ; delay to meet timing (Set up time)
		sbi PORTA, LCD_E ; turn on the enable pin
		nop ; delay to meet timing (Enable pulse width)
		nop
		nop
		cbi PORTA, LCD_E ; turn off the enable pin
		nop ; delay to meet timing (Enable cycle time)
		nop
		nop
		ret
;Function lcd_write_data: Write a character to the LCD. The data reg stores the value to be written.
lcd_write_data:
		out PORTB, data ; set the data port's value up
		ldi temp, 1 << LCD_RS
		out PORTA, temp ; RS = 1, RW = 0 for a data write
		nop ; delay to meet timing (Set up time)
		sbi PORTA, LCD_E ; turn on the enable pin
		nop ; delay to meet timing (Enable pulse width)
		nop
		nop
		cbi PORTA, LCD_E ; turn off the enable pin
		nop ; delay to meet timing (Enable cycle time)
		nop
		nop
		ret
;Function lcd_wait_busy: Read the LCD busy flag until it reads as not busy.
lcd_wait_busy:
		clr temp
		out DDRB, temp ; Make PORTB be an input port for now
		out PORTB, temp
		ldi temp, 1 << LCD_RW
		out PORTA, temp ; RS = 0, RW = 1 for a command port read
busy_loop:
		nop ; delay to meet timing (Set up time / Enable cycle time)
		sbi PORTA, LCD_E ; turn on the enable pin
		nop ; delay to meet timing (Data delay time)
		nop
		nop
		in temp, PINB ; read value from LCD
		cbi PORTA, LCD_E ; turn off the enable pin
		sbrc temp, LCD_BF ; if the busy flag is set
		rjmp busy_loop ; repeat command read
		clr temp ; else
		out PORTA, temp ; turn off read mode,
		ser temp
		out DDRB, temp ; make PORTB an output port again
		ret ; and return
		; Function delay: Pass a number in registers r18:r19 to indicate how many microseconds
		; must be delayed. Actual delay will be slightly greater (~1.08us*r18:r19).
		; r18:r19 are altered in this function.
		; Code is omitted
;Function lcd_init Initialisation function for LCD.
lcd_init:
		ser temp
		out DDRB, temp ; PORTB, the data port is usually all otuputs
		out DDRA, temp ; PORTA, the control port is always all outputs
		ldi del_lo, low(15000)
		ldi del_hi, high(15000)
		rcall delay ; delay for > 15ms

; Function set command with N = 1 and F = 0
		ldi data, LCD_FUNC_SET | (1 << LCD_N)
		rcall lcd_write_com ; 1st Function set command with 2 lines and 5*7 font
		ldi del_lo, low(4100)
		ldi del_hi, high(4100)
		rcall delay ; delay for > 4.1ms

		rcall lcd_write_com ; 2nd Function set command with 2 lines and 5*7 font
		ldi del_lo, low(100)
		ldi del_hi, high(100)
		rcall delay ; delay for > 100us

		rcall lcd_write_com ; 3rd Function set command with 2 lines and 5*7 font
		rcall lcd_write_com ; Final Function set command with 2 lines and 5*7 font
		rcall lcd_wait_busy ; Wait until the LCD is ready
		ldi data, LCD_DISP_OFF
		rcall lcd_write_com ; Turn Display off
		rcall lcd_wait_busy ; Wait until the LCD is ready
		ldi data, LCD_DISP_CLR
		rcall lcd_write_com ; Clear Display
		rcall lcd_wait_busy ; Wait until the LCD is ready
		; Entry set command with I/D = 1 and S = 0
		ldi data, LCD_ENTRY_SET | (1 << LCD_ID)
		rcall lcd_write_com ; Set Entry mode: Increment = yes and Shift = no
		rcall lcd_wait_busy ; Wait until the LCD is ready
		; Display on command with C = 0 and B = 1
		ldi data, LCD_DISP_ON | (1 << LCD_C)
		rcall lcd_write_com ; Trun Display on with a cursor that doesn't blink
		ret

delay:
		subi del_lo, 1
		sbci del_hi,0
		nop
		nop
		nop
		nop
		brne delay ;1 loop is 8 cycles or 1.08 us
		ret
;*****************************************************************************************
; Everything below here can be replaced.  This is some sample code to show it all working.
;*****************************************************************************************
     
      string: .db "Salut Johnny"
     .equ LENGTH = 12 
     .def count = r20       
         
; Function main: Test the LCD by writing some characters to the screen.  Desired output is:
; Hello World! 
; 123456789012 

keymain: 
        ;ldi temp,low(RAMEND)
		;out SPL, temp
		;ldi temp,high(RAMEND)
		;out SPH,temp
		
		ldi mask, INITCOLMASK ; initial column mask
		clr col ; initial column
		
		;rcall lcd_wait_busy
		;ldi data,LCD_DISP_OFF
        ;rcall lcd_write_data
		;rcall debounce2 ----------------
		jmp colloop

lcdmain:
		ldi ZL, low(string << 1)        ; point Y at the string
        ldi ZH, high(string << 1)       ; recall that we must multiply any Program code label address
                                        ; by 2 to get the correct location
        ldi count, 1;LENGTH               ; initialise counter 
		rcall lcd_init

main_loop: 
        ;lpm data, Z+  
		ldi count, 1;LENGTH                  ; read a character from the string 
        rcall lcd_wait_busy
        rcall lcd_write_data            ; write the character to the screen
        dec count						; decrement character counter
        brne main_loop                  ; loop again if there are more characters
 		;jmp keymain
        rcall lcd_wait_busy
        ldi data, LCD_ADDR_SET | LCD_LINE2
        rcall lcd_write_com                     ; move the insertion point to start of line 2
		;rcall debounce2--------------
		;rcall debounce2********
        ldi count, 1;LENGTH                       ; initialise counter 
        ldi data, '1'                           ; initialise character to '1' 

main_loop2: 
        rcall lcd_wait_busy
        rcall lcd_write_data            ; write the character to the screen 
        inc data                                        ; increment character
        cpi data, '9'+1                         ; compare with first character > '9'
        brlo skip                                       ; if character is now greater than '9'
        ldi data, '0' 
		;rcall debounce2---------------
		;rcall debounce2--------------
		;rcall debounce2--------------
		jmp keymain                          ; change it back to '0' 

skip:
        dec count                                       ; decrement character counter
        brne main_loop2                         ; loop again if there are more characters
		;rcall debounce2------------
		;rcall debounce2-----------
		;rcall debounce2--------------
		jmp keymain

end: 
        rjmp end                                        ; infinite loop
		

colloop:
		out PORTD, mask ; set column to mask value
						; (sets column 0 off)
		ldi temp, 0xFF ; implement a delay so the
						; hardware can stabilize
		jmp keydelay


nextcol:
		cpi col, 3 ; check if we’re on the last column
		breq keymain ; if so, no buttons were pushed,
		; so start again.
		
		sec ; else shift the column mask:
		; We must set the carry bit
		rol mask ; and then rotate left by a bit,
		; shifting the carry into
		; bit zero. We need this to make
		; sure all the rows have
		; pull-up resistors
		inc col ; increment column value
		jmp colloop ; and check the next column
		; convert function converts the row and column given to a
		; binary number and also outputs the value to PORTC.
		; Inputs come from registers row and col and output is in
		; temp.

keydelay:
		dec temp
		;rcall debounce
		brne keydelay
		in temp, PIND ; read PORTD
		andi temp, ROWMASK ; read only the row bits
		
		cpi temp, 0xF ; check if any rows are grounded
		breq nextcol ; if not go to the next column
		ldi mask, INITROWMASK ; initialise row check
		clr row ; initial row
		jmp rowloop

rowloop:
		mov temp2, temp
		and temp2, mask ; check masked bit
		brne skipconv ; if the result is non-zero,
						; we need to look again
	
		;rcall debounce2-----------
		;rcall debounce2-----------
		;rcall debounce2-----------
		;rcall debounce2----------
		;rcall debounce2---------
		rcall convert ; if bit is clear, convert the bitcode
		
		;rcall debounce


		jmp keymain ; and start again

skipconv:
		inc row ; else move to the next row
		lsl mask ; shift the mask to the next bit
		jmp rowloop


convert:
		cpi col, 3 ; if column is 3 we have a letter
		breq letters
		cpi row, 3 ; if row is 3 we have a symbol or 0
		breq symbols
		mov temp, row ; otherwise we have a number (1-9)
		lsl temp ; temp = row * 2
		add temp, row ; temp = row * 3
		add temp, col ; add the column address
		; to get the offset from 1
		inc temp ; add 1. Value of switch is
		; row*3 + col + 1.
		rjmp convert_end

letters:
		ldi temp, 0xA
		add temp, row ; increment from 0xA by the row value
		jmp convert_end

symbols:
		cpi col, 0 ; check if we have a star
		breq star
		cpi col, 1 ; or if we have zero
		breq zero
		ldi temp, 0xF ; we'll output 0xF for hash

		;we need to jump to our math function here

		rjmp convert_end

star:
		ldi temp, 0xE ; we'll output 0xE for star
		jmp convert_end

zero:
		clr temp ; set to zero
		jmp convert_end

convert_end:
		out PORTC, temp ; write value to PORTC
		cpi temp,8
		breq display8
		cpi temp,7
		breq display7
		ret ; return to caller

display8:
ldi temp,8 +'0'
mov r25,temp
rcall lcd_init
mov data,r25
;rcall debounce2
jmp main_loop

display7:
ldi temp,7 +'0'
mov r25,temp
rcall lcd_init
mov data,r25

jmp main_loop

		
debounce:
		
		ldi del_lo, low(15000)
		ldi del_hi, high(15000)
		rcall delay
		
		
		ret
debounce2:
rcall debounce
rcall debounce
rcall debounce
rcall debounce
rcall debounce
rcall debounce
rcall debounce
rcall debounce
rcall debounce
rcall debounce

ret
