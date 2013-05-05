.include "m64def.inc"
.def temp =r16
.def row =r17
.def col =r18
.def mask =r19
.def temp2 =r20
.def hashcount = r21
.def numcount = r22
.def sum = r23
.def num = r24
.def count = r25
;.def ten = r
;.def tencount = r
.equ PORTDDIR = 0xF0
.equ INITCOLMASK = 0xEF
.equ INITROWMASK = 0x01
.equ ROWMASK = 0x0F

.cseg

.macro mul2 ; a * b, operation: (@4:@3) = (@1:@0)*(@2)
mul @0, @2 ; al * b
movw @4:@3, r1:r0
mul @1, @2 ; ah * b
add @4, r0
.endmacro

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
ldi hashcount,0
ldi numcount,0
ldi count,0
ldi sum,0
ldi num,0
ldi XL,10    ;ten
ldi XH,0     ;tencount


hash:
clr temp
jmp assembleNum


bintodec:
inc numcount
cpi temp,1
breq push1
cpi temp,2
breq push2
cpi temp,3
breq push3
cpi temp,4
breq push4
cpi temp,5
breq push5
cpi temp,6
breq push6
cpi temp,7
breq push7
cpi temp,8
breq push8
cpi temp,9
breq push9
cpi temp,0
breq push0
jmp convert_end

push1:
ldi temp,1
push temp
jmp convert_end

push2:
ldi temp,2
push temp
jmp convert_end

push3:
ldi temp,3
push temp
jmp convert_end

push4:
ldi temp,4
push temp
jmp convert_end

push5:
ldi temp,5
push temp
jmp convert_end

push6:
ldi temp,6
push temp
jmp convert_end

push7:
ldi temp,7
push temp
jmp convert_end

push8:
ldi temp,8
push temp
jmp convert_end

push9:
ldi temp,9
push temp
jmp convert_end

push0:
ldi temp,0
push temp
jmp convert_end

assembleNum:
;cpi temp,0xf
;brne convert_end;temporary redirection
inc hashcount
ldi count,0
jmp stackpop

stackpop:
clr temp 
cp numcount,count    ;check if stack is empty, i.e we have popped off = pushed on, or none to start with
breq mathsum         ;after we have popped off all digits and reassembled number, we do the maths
inc count            ;else, we  increment counter as each number is popped off
;clr num              ;clear num if there are new numbers for addition, else retain last value
in temp,SPL          ;load from stack last digit 
;pop SPL
pop temp             ;pop off after loading
ldi XH,1             ;reset power10 counter
ldi XL,10            ;reset power of 10 back to 1, i.e 10 itself
cpi count,0          ;if first digit, we dont scale with power 10
brne scalenum        ;scale other digits wrt power 10
mov num,temp         ;stores first popped number from temp into num
inc count 
jmp stackpop 

scalenum:
cp XH,count          ;check if digit place is at the correct decimal position yet, i,e tens in tens
breq lastscale       ;once correct decimal place is reached, we add it to the existing number
mul XL,XL            ;scales 10 to the correct decimal place required
inc XH               ;basically loops until correct power10 is reached
jmp scalenum

lastscale:
mul temp,XL          ;multiply the popped off value by correct decimal point
add num,temp         ;add to existing number
inc count 
jmp stackpop

mathsum:
;function to add two numbers
add sum,num          ;adds most recent assembled number to current sum total
clr count            ;clear number of digits to check on stack for next loop
clr numcount         ;clear number of digits on stack for next loop
mov temp,num
cpi temp,8
;breq revert
jmp convert_end
;rcall lcd

lcd:
;implement lcd
;lcd will load pointer of stored number
;print out number
;print out hascount
ret


convert_end:
ldi temp,0xf
jmp convert_end
