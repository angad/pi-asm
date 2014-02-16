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


/* NEW
* Use our new SetGpio function to set GPIO 16 to low, causing the LED to turn 
* on.
*/
loop$:
pinNum .req r0
pinVal .req r1
mov pinNum,#16
mov pinVal,#0
bl SetGpio
.unreq pinNum
.unreq pinVal

waitTime .req r0
ldr waitTime,=0xF4240 /* 1 second */
bl Wait
.unreq waitTime

/* NEW
* Use our new SetGpio function to set GPIO 16 to high, causing the LED to turn 
* on.
*/
pinNum .req r0
pinVal .req r1
mov pinNum,#16
mov pinVal,#1
bl SetGpio
.unreq pinNum
.unreq pinVal

waitTime .req r0
ldr waitTime,=0xF4240 /* 1 second */
bl Wait
.unreq waitTime

/*
* Loop over this process forevermore
*/
b loop$
