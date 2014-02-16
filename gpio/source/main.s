/*
* .globl is a directive to our assembler, that tells it to export this symbol
* to the elf file. Convention dictates that the symbol _start is used for the 
* entry point, so this all has the net effect of setting the entry point here.
* Ultimately, this is useless as the elf itself is not used in the final 
* result, and so the entry point really does not matter, but it aids clarity,
* allows simulators to run the elf, and also stops us getting a linker warning
* about having no entry point.
*/

.section .init
.globl _start
_start:

b main

.section .text

/* NEW
* main is what we shall call our main operating system method. It never 
* returns, and takes no parameters.
* C++ Signature: void main(void)
*/
main:

mov sp,#0x8000      /* set the stack pointer to 0x8000 */

/* NEW
* Use our new SetGpioFunction function to set the function of GPIO port 16 (OK 
* LED) to 001 (binary)
*/
pinNum .req r0
pinFunc .req r1
mov pinNum,#16
mov pinFunc,#1
bl SetGpioFunction
.unreq pinNum
.unreq pinFunc


ptrn .req r4
ldr ptrn,=pattern
ldr ptrn,[ptrn]
seq .req r5
mov seq,#0

/* NEW
* Use our new SetGpio function to set GPIO 16 based on the current bit in
* the pattern.
*/
loop$:
mov r0,#16
mov r1,#1
lsl r1,seq
and r1,ptrn
bl SetGpio

waitTime .req r0
ldr waitTime,=0xF4240 /* 1 second */
bl Wait
.unreq waitTime

add seq,#1
and seq,#0b11111
b loop$

.section .data
/*
*.align num ensures the address of the next line is a multiple of 2num .
*/
.align 2
pattern:
.int 0b11111111101010100010001000101010


