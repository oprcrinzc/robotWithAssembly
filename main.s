.include "m328pdef.inc"
.org 0x0000
	rjmp	INIT
	
	; Register to use
	; r16 = ultrasonic A Value [cm]
	; r17 = ultrasonic B Value [cm]
	; r18 = ultrasonic C Value [cm]
	; r19 = flagA
	; + === flagA === +
	; | first_run 	  |
	; | go_none_stop  |
	; | in_out_maze   | ; now
	; | prev_in_out   | ; before 
	; + ============= +
	; + = PIN ===================== +
	; | PB4 TRIG (out)		|
	; | PB3 echo A (in)		|
	; | PB2 echo B (in)		|
	; | PB1 echo C (in)		|
	; | PB0 motor A direction (1/0)		|
	; | PD7 motor A direction (0/1)	|
	; | PD6 motor A pwm		|
	; | PD5 motor B pwm		|
	; | PD4 motor B direction (0/1)	|
	; | PD3 motor B direction (1/0)		|
	; | PD2 LED 1 (out)		|
	; | PB5 LED 3 (out)		|
	; + =========================== +

INIT: 	ldi 	r20,	0b11111100	; PD
	out	DDRD,	r20
	ldi	r20,	0b00110000	; PB
	out 	DDRB,	r20

	; init timer for delay
	
	ldi 	r20, 	(1 << CS02) | (1 << CS00)
	out	TCCR0B,	r20
	
	sbi	PORTB,	PB0
	cbi	PORTD,	PD7
	
	sbi	PORTD,	PD3
	cbi	PORTD,	PD4

LOOP:	sbi	PORTB,	PB5
	rcall	DELAY1S
	cbi	PORTB,	PB5
	rcall	DELAY1S
	
	

	rjmp	LOOP

DELAY1S:
	ldi	r21,	30
DELAY1SLOOP:
DELAY1SWAIT:	
	in	r20,	TIFR0
	sbrs	r20,	TOV0
	rjmp	DELAY1SWAIT
	ldi	r20, 	(1<<TOV0)
	out	TIFR0,	r20
	dec	r21
	brne	DELAY1SLOOP
	ret
