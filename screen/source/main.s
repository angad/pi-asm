/* The Raspberry Pi has 7 mailbox channels for
* communication with the graphics processor,
* only the first of which is useful to us,
* as it is for negotiating the frame buffer.
*/


/*
* Address	 Size/Bytes		Name	 		Description	 				Read / Write
* 2000B880	 4	 			Read	 		Receiving mail.	 				R
* 2000B890	 4	 			Poll	 		Receive without retrieving.	 	R
* 2000B894	 4	 			Sender	 		Sender information.			 	R
* 2000B898	 4	 			Status	 		Information.					R
* 2000B89C	 4	 			Configuration	Settings.	 					RW
* 2000B8A0	 4	 			Write	 		Sending mail.	 				W
*/

/*
In order to send a message to a particular mailbox:
- The sender waits until the Status field has a 0 in the top bit.
- The sender writes to Write such that the lowest 4 bits are the mailbox to write to,
  and the upper 28 bits are the message to write.

In order to read a message:
- The receiver waits until the Status field has a 0 in the 30th bit.
- The receiver reads from Read.
- The receiver confirms the message is for the correct mailbox, and tries again if not.
*/


.section .init
.globl _start
_start:

b main

.section .text

main:

mov sp,#0x8000      /* set the stack pointer to 0x8000 */

mov r0,#1024
mov r1,#768
mov r2,#16				/* bit depth 16 */
bl InitialiseFrameBuffer

teq r0,#0 				/* check if the result is 0 */
bne noError$			/* if not equal, then no error */

mov r0,#16 				/* error, turn on the 16th GPIO pin */
mov r1,#1
bl SetGpioFunction
mov r0,#16
mov r1,#0
bl SetGpio

error$:					/* and stay there */
b error$

noError$:
fbInfoAddr .req r4
mov fbInfoAddr,r0

render$:
	fbAddr .req r3
	ldr fbAddr,[fbInfoAddr,#32]  /* get the frame buffer address */

	colour .req r0
	y .req r1
	mov y,#768
	drawRow$:
		x .req r2
		mov x,#1024
		drawPixel$:
			strh colour,[fbAddr]
			add fbAddr,#2
			sub x,#1
			teq x,#0
			bne drawPixel$

	sub y,#1
	add colour,#1
	teq y,#0
	bne drawRow$

	push {r0, r1, r2, r3}

	waitTime .req r0
	ldr waitTime,=0xF4240 /* 50Hz */
	bl Wait
	.unreq waitTime
	pop {r0, r1, r2, r3}

	b render$

	.unreq fbAddr

.unreq fbInfoAddr
