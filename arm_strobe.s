	AREA interrupts, CODE, READWRITE
	
	EXPORT arm_strobe
	EXPORT FIQ_Handler	

	IMPORT pin_connect_block_setup
	IMPORT timer_interrupt_init
	IMPORT start_timer
	IMPORT illuminate_rgb_led
	IMPORT illuminate_leds
	IMPORT display_digit

; each character represents an RGB LED color
colors         = "rgbpyw",0
	ALIGN
; index in colors
colors_pointer = 0x0
	ALIGN

led_pattern    = 0x7
	ALIGN
; digit displayed on 7 segment display
digit		   = 0x30
	ALIGN

; this assembly program by Keith Carolus
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

timer 
	; check for TIMER0 interrupt
	LDR r0, =0xE0004000	 ; interrupt register
	LDR r1, [r0]
	AND r2, r1, #0x2     ; isolate bit 1
	CMP r2, #0x2	     ; if bit 1 is 1, pending timer interrupt
	BNE FIQ_Exit			 

	; rgb led

	LDR r0, =colors_pointer
	LDR r1, [r0]
	CMP r1, #5				; if we have reached index five
	BNE increment1			; wrap otherwise just increment
wrap1
	MOV r1, #0
	B color
increment1
	ADD r1, r1, #1
color
	STRB r1, [r0]			; store index
	
	LDR r2, =colors
	LDRB r0, [r2, r1]		; load character at index
	BL illuminate_rgb_led	; light with corresponding color

	; leds

	LDR r0, =led_pattern
	LDR r1, [r0]
	ROR r1, #1				; rotate right 1 place
	MOV r2, r1				; copy into r2
	BIC r2, r2, #0xF		; isolate sign bit
	CMP r2, #0x80000000
	BEQ rotate_byte			; if rotate yields 1 at bit 31
	B store_led_pattern		
rotate_byte
	ADD r1, r1, #8			; bit 3 -> 1
store_led_pattern	
	STRB r1, [r0]
	
	LDR r1, =led_pattern	; load new bit pattern
	LDR r0, [r1]
	BL illuminate_leds		; output

	; 7 segment display

	LDR r0, =digit
	LDRB r1, [r0]
	CMP r1, #0x39			; if ascii 9 -> ascii 0
	BEQ	wrap2
	B increment2
wrap2
	MOV r1, #0x30
	B display
increment2
	ADD r1, r1, #1			; otherwise increment
display
	STRB r1, [r0]
	MOV r0, r1
	BL display_digit

	; reset TIMER0 interrupt
	LDR r0, =0xE0004000	 ; interrupt register
	LDR r1, [r0]
	ORR r2, r1, #0x2		 ; set bit 1 to 1 to reset interrupt
	STR r2, [r0]	; REMEMBER TO STORE

FIQ_Exit
	LDMFD SP!, {r0-r12, lr}
	SUBS pc, lr, #4

; ------------------------------------------------------------------------

	END