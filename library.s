	AREA	lib, CODE, READWRITE
	
	EXPORT pin_connect_block_setup
	EXPORT timer_interrupt_init
	EXPORT start_timer
	EXPORT illuminate_rgb_led
	EXPORT illuminate_leds
	EXPORT display_digit

digits_SET	
		DCD 0x00001F80  ; 0
 		DCD 0x00000300  ; 1
		DCD 0x00002D80	; 2
		DCD 0x00002780  ; 3
		DCD 0x00003300  ; 4
		DCD 0x00003680	; 5
		DCD 0x00003E80	; 6
		DCD 0x00000380	; 7
		DCD 0x00003F80	; 8
		DCD 0x00003380	; 9
		DCD 0x00003B80	; A
		DCD 0x00003F80	; B
		DCD 0x00001C80	; C
		DCD 0x00001F80  ; D
		DCD 0x00003C80	; E		
		DCD 0x00003880  ; F

	ALIGN

; this shortened library created by Keith Carolus
; ------------------------------------------------------------------------

; Keith Carolus and Simran Singh
pin_connect_block_setup
	STMFD sp!, {r0-r3, lr}
		
	; port 1 - hardwired LEDs and pushbuttons
	; no need to configure PINSEL

	; 7 segment port 0 pins 7-13
	; RGB LED port 0 pins 17,18,21

	; push buttons port 1 pins 20-23
	; LEDs port 1 pins 16-19

	; PIN CONFIGURATION

	LDR r0, =0xE002C000	 ; PINSEL0 pins 0-15 on port 0
	LDR r1, =0xE002C004  ; PINSEL1 pins 16-31 on port 0		

	; configure pins 0-15
	LDR r2, [r0]
	LDR r3, =0xFFFC000 ; loads constant
	BIC r4, r2, r3
	STR r4, [r0]

	; configure pins 16-31
	LDR r2, [r1]
	LDR r3, =0xC3C 	   ; loads constant
	BIC r4, r2, r3
	STR r4, [r1]

	; DIRECTION SETTING

	LDR r0, =0xE0028008	; IO0DIR - direction for port 0
	LDR r1, =0xE0028018	; IO1DIR - direction for port 1

	; PORT 0 DIRECTIONS	(r0)

	LDR r2, [r0]
	LDR r3, =0x263F80 ; directions for 7 segment display and RGB LED
	ORR r4, r3, r2  ; set up output directions for port 0
	
	STR r4, [r0]	  ; write out directions for port 0

	; PORT 1 DIRECTIONS	(r1)

	LDR r2, [r1]
	MOV r3, #0xF0000  ; direction for LEDs
	ORR r4, r3, r2  ; set up output directions for port 1
	
	MOV r3, #0xF00000 ; direction for pushbuttons
	BIC r4, r4, r3    ; set up input directions on port 1
	
	STR r4, [r1]	  ; write out directions for port 1

	; turn off 7 segment display on port 0

	LDR r0, =0xE002800C	; IO0CLR

	LDR r1, =0x3F80  ; clear 7 seg
	LDR r2, [r0]
	ORR r3, r2, r1
	
	STR r3, [r0]	  ; write out clear

	; turn off the RGB LED on port 0

	LDR r0, =0xE0028004	; IO0SET

	LDR r1, =0x260000  ; turn RGB LED off (high)
	LDR r2, [r0]
	ORR r3, r2, r1
	
	STR r3, [r0]	  ; write out RGB LED clear

	; Turn off LEDs on port 1

	LDR r0, =0xE0028014	; IO1SET

	MOV r1, #0xF0000  ; turn all LEDs off (high)
	LDR r2, [r0]
	ORR r3, r2, r1
	
	STR r3, [r0]	  ; write out LED clear

	; make the middle horizontal of 7 segment (g) red

	LDR r0, =0xE0028004

	MOV r1, #0x2000
	LDR r2, [r0]
	ORR r3, r2, r1

	STR r3, [r0]

	; RGB LED white

	LDR r0, =0xE002800C ; IO0CLR

	LDR r1, =0x260000
	LDR r2, [r0]
	ORR r3, r2, r1

	STR r3, [r0]

	; LEDs on

	LDR r0, =0xE002801C	; IO1CLR

	MOV r1, #0xF0000  ; turn all LEDs on (low)
	LDR r2, [r0]
	ORR r3, r2, r1
	
	STR r3, [r0]	  ; write out LED on

	LDMFD sp!, {r0-r3, lr}
	BX lr

; ------------------------------------------------------------------------

; Keith Carolus and Simran Singh
timer_interrupt_init
	STMFD SP!, {r0-r1, lr}

	; classify as FIQ
	LDR r0, =0xFFFFF00C
	LDR r1, [r0]
	ORR r1, r1, #0x10 ; timer 0 (bit 4 -> 1 for FIQ)
	STR r1, [r0]

	; interrupt enable register
	LDR r0, =0xFFFFF010
	LDR r1, [r0]
	ORR r1, r1, #0x10 ; enable timer 0 (bit 4 -> 1)
	STR r1, [r0]

	; match control register
	LDR r0, = 0xE0004014 ; T0MCR
	LDR r1, [r0]
	ORR r1, r1, #0x18	 ; bits 3, 4 -> 1
	BIC r1, r1, #0x20    ; bit 5 -> 0
	STR r1, [r0]	; REMEMBER TO STORE

	LDMFD SP!, {r0-r1, lr} ; Restore registers
	BX lr

; ------------------------------------------------------------------------

; Keith Carolus and Simran Singh
start_timer
	STMFD SP!, {r0-r2, lr}

	; set timer timeout period (with MR1)
	; start timer (with TCR)

	LDR r0, =0xE000401C ; MR1
	LDR r1, =0x8CA000	; timeout period = (18.432 MHz)(0.5) = 9.216 MHz -> 0x8CA000
	STR r1, [r0]		; REMEMBER TO STORE

	LDR r0, =0xE0004004 ; TCR
	LDR r1, [r0]
	ORR r2, r1, #0x1	; enable timer 0
	STR r2, [r0]

	LDMFD SP!, {r0-r2, lr} ; Restore registers
	BX lr

; ------------------------------------------------------------------------

; Keith Carolus
illuminate_rgb_led
	STMFD SP!,{r1-r4,lr}
	
	; r0 has input character r, g, b, p, y, or w corresponding to color

	; first clear/turn off RGB LED

	LDR r1, =0xE0028004	; IO0SET

	LDR r2, =0x260000  ; turn RGB LED off (high)
	LDR r3, [r1]
	ORR r4, r3, r2
	
	STR r4, [r1]	  ; write out RGB LED clear

	; decimal values used throughout

red
	cmp r0, #114 ; r red
	BNE green
	LDR r1, =0x20000
	B set_color
green
	cmp r0, #103 ; g green
	BNE blue
	LDR r1, =0x200000
	B set_color
blue
	cmp r0, #98	 ; b blue
	BNE purple
	LDR r1, =0x40000
	B set_color
purple
	cmp r0, #112 ; p purple
	BNE yellow
	LDR r1, =0x60000
	B set_color
yellow
	cmp r0, #121 ; y yellow
	BNE white
    LDR r1, =0x220000
	B set_color
white
	cmp r0, #119 ; w white
	LDR r1, =0x260000

set_color

	LDR r0, =0xE002800C ; IO0CLR
	; r1 set above with the color from the first character of the string
	LDR r2, [r0]
	ORR r3, r2, r1

	STR r3, [r0] 

	LDMFD SP!, {r1-r4,lr}	; Restore register lr from stack	
	BX LR

; ------------------------------------------------------------------------

; Keith Carolus
illuminate_leds
	STMFD SP!,{r1-r3, lr}
	
	; r0 has the pattern
	
	; 0001 1
	; 0010 2
	; 0011 3
	; 0100 4
	; 0101 5
	; 0110 6
	; 0111 7
	; 1000 8
	; 1001 9
	; 1010 A
	; 1011 B
	; 1100 C
	; 1101 D
	; 1110 E
	; 1111 F
	
	; LEDs port 1 pins 16-19
	
	; Turn off LEDs on port 1

	LDR r1, =0xE0028014	; IO1SET

	MOV r2, #0xF0000  ; turn all LEDs off (high)
	LDR r3, [r1]
	ORR r4, r3, r2
	
	STR r4, [r1]	  ; write out LED clear
	
	; NOW TURN DESIRED LEDS ON
	 
	; move r0 over into position
	LSL r0, #16
	LDR r1, =0xE002801C	; IO1CLR

	; turn LEDs on (low)
	LDR r2, [r1]
	ORR r3, r2, r0
	STR r3, [r1]	  ; write out LED on
	
	LDMFD SP!, {r1-r3, lr}
	BX LR

; ------------------------------------------------------------------------

; Simran Singh
display_digit
	STMFD sp!, {lr, r1-r4} ; r0 will be passed as an input
	
	MOV r1, #0x2F	; compare this value with the value passed into r0
	MOV r2, #-4		; offset in digits_SET

seven_seg_loop
	;  break out of loop if it is equal to what was inputted
	ADD r1, r1, #1
	ADD r2, r2, #4
	CMP r0, r1		
	BNE seven_seg_loop

print_on_seven_seg
	LDR r0, =0xE002800C	; IO0CLR

	LDR r1, =0x3F80  ; clear 7 seg
	LDR r4, [r0]
	ORR r3, r4, r1
	
	STR r3, [r0]	  ; write out clear

	LDR r0, =0xE0028004

	LDR r1, =digits_SET
	ADD r1, r1, r2		; look at byte in digits_SET at offset
	LDR r1, [r1]
	LDR r4, [r0]
	ORR r3, r4, r1

	STR r3, [r0]      

	LDMFD sp!, {lr, r1-r4}
	BX lr

; ------------------------------------------------------------------------

	END