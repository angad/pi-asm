/*
* gpio.s contains the rountines for manipulation of the GPIO ports.
*/

/* there are 24 bytes in the GPIO controller
* 4 => 10 GPIO pins
* 54 GPIO pins, so 6 sets of 4 bytes => 24 bytes.
* within each 4 bytes, every 3 bits relate to one GPIO pin
* for 16th pin, 6th set of 3 bits (6 x 3 = 18)
* GPIO functions are stored in blocks of 10
* there are 54 GPIO pins
* each pin has 8 functions (0-7)
*/


/* pc - program counter - address of next instruction to be executed */
/* lr - address of instruction to be executed after a function returns */


/* CPSR - current program status register
*  The Current Program Status Register (CPSR) holds:
*  - the APSR flags
*  - the current processor mode
*  - interrupt disable flags
*  - current processor state (ARM, Thumb, ThumbEE, or Jazelle®)
*  - endianness state (on ARMv4T and later)
*  - execution state bits for the IT block (on ARMv6T2 and later).
*/


/* NEW
* According to the EABI, all method calls should use r0-r3 for passing
* parameters, should preserve registers r4-r8,r10-r11,sp between calls, and
* should return values in r0 (and r1 if needed).
* It does also stipulate many things about how methods should use the registers
* and stack during calls, but we are using hand coded assembly. All we need to
* do is obey the start and end conditions, and if all our methods do this, they
* would all work from C.
*/


/* NEW
* GetGpioAddress returns the base address of the GPIO region as a physical address
* in register r0.
* C++ Signature: void* GetGpioAddress()
*/
.globl GetGpioAddress
GetGpioAddress:
	ldr r0,=0x20200000		/* store the address of GPIO in r0 */
	mov pc,lr 				/* return */

.globl SetGpioFunction
SetGpioFunction:
    pinNum .req r0     /* alias */
    pinFunc .req r1    /* alias */
	cmp pinNum,#53     /*  check if r0 is <=53. if its greater then, it will run movhi instruction */
	cmpls pinFunc,#7   /*  cmpls - less or same. runs only if previous cmp is true */
	movhi pc,lr        /*  return */

	/*  get ready to call GetGpioAddress */
	push {lr}				/*  push lr to stack */
	mov r2,pinNum 			/*  copy r0 to r2 so it doesnt get overwritten */
	.unreq pinNum           /*  unalias */
	pinNum .req r2          /*  alias */
	bl GetGpioAddress       /*  call GetGpioAddress */
	gpioAddr .req r0        /*  alias r0 to gpioaddress */

	/*  at this stage r0 contains GPIO address, r1 contains function code, r2 contains GPIO pin number */

	/*  GPIO Controller Address + 4 × (GPIO Pin Number / 10) */
	functionLoop$:
		cmp r2,#9				/*  check if r2 <= 9 */
		subhi r2,#10			/*  if yes, subtract 10 from r2 */
		addhi r0,#4				/*  if yes, add 4 to r0 */
		bhi functionLoop$		/*  if yes, loop again */

	/* r2 now contains the pin number (0-9) in the block it is in, r0 contains the address of the pin function settings */

	/* r2 = r2 + r2 x 2 (multiply by 3) */
	add pinNum, pinNum,lsl #1       /* store result in r2, r2 - first operand, lsl #1 - flexible second operand */

	lsl pinFunc,pinNum				/* left shift r1 by r2 (to set the pin that correspond to our pin number) */

	mask .req r3
	mov mask,#7					/* r3 = 111 in binary */
	lsl mask,pinNum				/* r3 = 11100..00 where the 111 is in the same position as the function in r1 */
	.unreq pinNum

	mvn mask,mask				/* r3 = 11..1100011..11 where the 000 is in the same poisiont as the function in r1 */
	oldFunc .req r2
	ldr oldFunc,[gpioAddr]		/* r2 = existing code */
	and oldFunc,mask			/* r2 = existing code with bits for this pin all 0 */
	.unreq mask

	orr pinFunc,oldFunc			/* r1 = existing code with correct bits set */
	.unreq oldFunc

	str pinFunc,[gpioAddr]
	.unreq pinFunc
	.unreq gpioAddr
	pop {pc}


/* NEW
* SetGpio sets the GPIO pin addressed by register r0 high if r1 != 0 and low
* otherwise.
* C++ Signature: void SetGpio(u32 gpioRegister, u32 value)
*/
.globl SetGpio
SetGpio:
	pinNum .req r0			/* alias */
	pinVal .req r1

	cmp pinNum,#53			/* check if r0 is less than 53 */
	movhi pc,lr 			/* if no, then return */
	push {lr}               /* get ready to call GetGpioAddress save lr */
	mov r2,pinNum           /* copy pinnum to r2 */
	.unreq pinNum           /* unalias pinnum */
	pinNum .req r2          /* alias pinnum to r2 */
	bl GetGpioAddress       /*  call get GpioAddress */
	gpioAddr .req r0        /* alias r0 in gpioAddress */

	pinBank .req r3			/* alias pinbank to r3 */
	lsr pinBank,pinNum,#5   /* divide pinnumber by 32 to get the pinkbank number (there are 2 pin banks - 4 bytes each, 32 pins in first, 28 pins in second) */
	lsl pinBank,#2          /* multiply by 4 to get the pinbank (since each is 4 bytes) */
	add gpioAddr,pinBank    /* add pinbank to gpioaddress */
	.unreq pinBank          /* unalias */

	and pinNum,#31          /* get the pin number relative to the bank its in (e.g. 45th pin is 13th bit in 2nd bank) */
	setBit .req r3          /* r3 to setBit */
	mov setBit,#1           /* copy 1 to setBit */
	lsl setBit,pinNum       /* shift setbit number of times as the pinNum (because we want to set that bit) */
	.unreq pinNum           /* unalias */

	teq pinVal,#0          /* checks equality. checks if pinVal is 0 */
	.unreq pinVal          /* unalias */
	streq setBit,[gpioAddr,#40] /* store if equal to 0. 40 turns pin off */
	strne setBit,[gpioAddr,#28] /* store if not equal to 0. 28 turns pin on */
	.unreq setBit
	.unreq gpioAddr
	pop {pc}
