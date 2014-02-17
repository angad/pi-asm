/*
When working with devices using DMA,
alignment constraints become very important.
The GPU expects the message to be 16 byte aligned.
*/

.section .data
.align 4
.globl FrameBufferInfo
FrameBufferInfo:
	.int 1024 /* #0 Physical Width */
	.int 768 /* #4 Physical Height */
	.int 1024 /* #8 Virtual Width */
	.int 768 /* #12 Virtual Height */
	.int 0 /* #16 GPU - Pitch */
	.int 16 /* #20 Bit Depth */
	.int 0 /* #24 X */
	.int 0 /* #28 Y */
	.int 0 /* #32 GPU - Pointer */
	.int 0 /* #36 GPU - Size */


/*
- Write the address of FrameBufferInfo + 0x40000000 to mailbox 1.
- Read the result from mailbox 1. If it is not zero, we did not ask
for a proper frame buffer.
- Copy our images to the pointer, and they will appear on screen!

(By adding 0x40000000, we tell the GPU not to use its cache for
	these writes, which ensures we will be able to see the change.)
*/


.section .text

.globl InitialiseFrameBuffer
InitialiseFrameBuffer:
	width .req r0
	height .req r1
	bitDepth .req r2
	cmp width,#4096		/* width should be less than 4096 */
	cmpls height,#4096	/* height should be less than 4096 */
	cmpls bitDepth,#32  /* bit depth should be less than 32 bits */
	result .req r0
	movhi result,#0
	movhi pc,lr

	fbInfoAddr .req r4
	push {r4,lr}
	ldr fbInfoAddr,=FrameBufferInfo	/* load framebufferinfo to r4 */
	str width,[r4,#0]
	str height,[r4,#4]
	str width,[r4,#8]
	str height,[r4,#12]
	str bitDepth,[r4,#20]
	.unreq width
	.unreq height
	.unreq bitDepth

	mov r0,fbInfoAddr
	add r0,#0x40000000
	mov r1,#1
	bl MailboxWrite

	mov r0,#1
	bl MailboxRead

	teq result,#0 			/* check if result is equal to 0 */
	movne result,#0
	popne {r4,pc}

	mov result,fbInfoAddr
	pop {r4,pc}
	.unreq result
	.unreq fbInfoAddr
