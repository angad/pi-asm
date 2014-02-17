
.globl GetMailboxBase
GetMailboxBase:
	ldr r0,=0x2000B880
	mov pc,lr

/* tst reg,#val computes and reg,#val and compares the result with 0. */

.globl MailboxWrite
MailboxWrite:
	/* r0 - what to write
	* r1 - which mailbox to write to
	*/
	tst r0,#0b1111		/* checks if lowest 4 bits of r0 are all 0, by and-ing with 1111 */
	movne pc,lr 		/* if the result of above is not 0, then return */
	cmp r1,#15 			/* compare r1 and 15 */
	movhi pc,lr 		/* if r1 is greater than 15, then return */

	channel .req r1
	value .req r2
	mov value,r0		/* copy r0 to r2 */
	push {lr}
	bl GetMailboxBase
	mailbox .req r0

	wait1$:
		status .req r3
		ldr status,[mailbox,#0x18]		/* loads the current status */

	tst status,#0x80000000 		/* check if the top bit of status is 0 */
	.unreq status
	bne wait1$					/* if not, then loop back, wait */

	add value,channel 			/* add value to channel */
	.unreq channel

	str value,[mailbox,#0x20]	/* store value in mailbox + 0x20 */
	.unreq value
	.unreq mailbox
	pop {pc}

.globl MailboxRead
MailboxRead:
	/* r0 - which mailbox to read from
	*/
	cmp r0,#15			/* mailbox should be less than 15 */
	movhi pc,lr 		/* else return */

	channel .req r1
	mov channel,r0
	push {lr}
	bl GetMailboxBase
	mailbox .req r0

	/* r0 - address of the mailbox
	* r1 - channel
	*/

	rightmail$:
		wait2$:
			status .req r2
			ldr status,[mailbox,#0x18]		/* store status from mailbox + 0x18 */

	tst status,#0x40000000 			/* check if the 30th bit is 0 */
	.unreq status
	bne wait2$						/* if not equal then loop */

	mail .req r2
	ldr mail,[mailbox,#0]			/* get mail from mailbox */

	inchan .req r3
	and inchan,mail,#0b1111			/* store the and of mail and 1111 in r3 */
	teq inchan,channel 				/* check if inchan is equal to channel */
	.unreq inchan
	bne rightmail$ 					/* if not, then we have the wrong mail. loop. */
	.unreq mailbox
	.unreq channel

	and r0,mail,#0xfffffff0			/* store top 28 bits of mail to r0 */
	.unreq mail
	pop {pc}
