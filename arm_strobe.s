	AREA interrupts, CODE, READWRITE
	
	EXPORT arm_strobe
	
	IMPORT pin_connect_block_setup
	IMPORT timer_interrupt_init
	IMPORT start_timer
	IMPORT illuminate_rgb_led
	IMPORT illuminate_leds

colors = "rgbpyw",0
	ALIGN
initial_led_pattern = 0x7
	ALIGN

; ------------------------------------------------------------------------

arm_strobe
	STMFD sp!, {lr}

	BL pin_connect_block_setup
	BL timer_interrupt_init
	BL start_timer

main_loop
	B main_loop

	LDMFD sp!,{lr}
	BX lr

; ------------------------------------------------------------------------

FIQ_Handler ; fast interrupt handler
	STMFD SP!, {r0-r12, lr}

timer ; check for TIMER0 interrupt

	LDR r0, =0xE0004000	 ; interrupt register
	LDR r1, [r0]
	AND r2, r1, #0x2     ; isolate bit 1
	CMP r2, #0x2	     ; if bit 1 is 1, pending timer interrupt
	BNE FIQ_Exit			 

	; do nothing yet

	LDR r0, =0xE0004000	 ; interrupt register
	LDR r1, [r0]
	ORR r2, r1, #0x2		 ; set bit 1 to 1 to reset interrupt
	STR r2, [r0]	; REMEMBER TO STORE
FIQ_Exit
	LDMFD SP!, {r0-r12, lr}
	SUBS pc, lr, #4

; ------------------------------------------------------------------------

	END