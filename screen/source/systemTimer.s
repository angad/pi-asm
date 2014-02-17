/*
GPIO Timer - at address 0x20003000
20003000 - Control register 	- 	4 bytes
20003004 - Counter 				-	8 bytes
2000300C - Compare 0 			-	4 bytes
20003010 - Compare 1 			-	4 bytes
20003014 - Compare 2 			-	4 bytes
20003018 - Compare 3 			-	4 bytes
*/

/* ldrd regLow,regHigh,[src,#val]
* loads 8 bytes from the address given by the number in src plus val into regLow and regHigh 
* regHigh would contain the highest 4 bytes
*/

.globl GetTimerBaseAddress
GetTimerBaseAddress:
    ldr r0,=0x20003000
    mov pc, lr

.globl GetTimeStamp
GetTimeStamp:
	push {lr}
	bl GetTimerBaseAddress
	ldrd r0,r1,[r0, #4]
	pop {pc}

/* Wait function accepts only 4 bytes of time
*/
.globl Wait
Wait:
	waitTime .req r2
	mov waitTime, r0
	push {lr}
	bl GetTimeStamp
	startTime .req r3
	mov startTime, r0

	/* now
	* r1 contains waitTime
	* r2 contains startTime
	*/
	loop$:
		bl GetTimeStamp
		currentTime .req r0
		elapsedTime .req r1
		sub elapsedTime, currentTime, startTime /* elapsedTime = currentTime - startTime */
		cmp elapsedTime, waitTime
		.unreq currentTime
		.unreq elapsedTime
		bls loop$
	.unreq startTime
	.unreq waitTime
	pop {pc}
