.include "m328pdef.inc"
.org 0x0000
	rjmp	INIT
	
	; Register to use
	; r16 = ultrasonic A Value [cm] high r26 low
	; r17 = ultrasonic B Value [cm] high r27 low 
	; r18 = ultrasonic C Value [cm] high r28 low
	; r19 = flagA
	; r20 = for carry number
	; r21 = delay parameter
	; r22 = motor state 0b0000[0000] for AaBb [cancled]
	; r23, 24, 25 = for save timer
	; 
	; + === flagA === +
	; | first_run 	  |
	; | go_none_stop  |
	; | in_out_maze   | ; now
	; | prev_in_out   | ; before 
	; + ============= +
	; + = PIN ============================= +
	; | PB4 TRIG (out)			|
	; | PB3 echo A (in)			|
	; | PB2 echo B (in)			|
	; | PB1 echo C (in)			|
	; | PB0 motor A direction (1/0)	A	|
	; | PD7 motor A direction (0/1)	a	|
	; | PD6 motor A pwm			|
	; | PD5 motor B pwm			|
	; | PD4 motor B direction (0/1)	b 	|
	; | PD3 motor B direction (1/0)	B 	|
	; | PD2 LED 1 (out)			|
	; | PB5 LED 3 (out)			|
	; + =================================== +

INIT: 	ldi 	r20,	0b11111100	; PD
	out	DDRD,	r20
	ldi	r20,	0b00110000	; PB
	out 	DDRB,	r20	
	
	rcall	FORWARD

LOOP:
;	ldi	r21,	40
;	rcall	DELAYMS
	
	sbi	PORTB,	PB5
	mov	r21,	r16
	rcall	DELAYMS
	cbi	PORTB,	PB5
	mov	r21,	r16
	rcall	DELAYMS	
	ldi	r16,	0
	rcall 	READULTRASONIC
	
	ldi	r20,	low(580)
	ldi	r22,	high(580)
	cp	r26,	r20
	cpc	r16,	r22
	brlt	DOA0
	rjmp	DOA1
DOA0:
	rcall	STOP
	rjmp	EDA
DOA1:	
	cpi	r22,	0b1010
	breq	LOOP
;	
	rcall	FORWARD
EDA:
	rjmp	LOOP


FORWARD:
	sbi	PORTB,	PB0
	cbi	PORTD,	PD7
	
	sbi	PORTD,	PD3
	cbi	PORTD,	PD4
	ldi	r22,	0b1010
	ret

BACKWARD:
	cbi	PORTB,	PB0
	sbi	PORTD,	PD7
	
	cbi	PORTD,	PD3
	sbi	PORTD,	PD4
	ldi	r22,	0b0101
	ret

STOP:	
	cbi	PORTB,	PB0
	cbi	PORTD,	PD7
	
	cbi	PORTD,	PD3
	cbi	PORTD,	PD4
	ldi	r22,	0b0000
	ret

READULTRASONIC:
	cbi	PORTB,	PB4 ; clear trig
	ldi	r21,	2
	rcall	DELAYUS
	sbi	PORTB,	PB4 ; high trig
	ldi	r21,	5
	rcall	DELAYUS
	cbi	PORTB,	PB4 ; close trig
	
	; save prev timer
	in	r23,	TCCR0A
	in	r24,	TCCR0B
	in	r25,	OCR0A
	; set timer
	ldi	r20, 	0
	out	TCNT0,	r20
	ldi	r20,	(1<<WGM01)
	out	TCCR0A,	r20
	ldi	r20,	(1<<CS01) ; prescaler 8
	out	TCCR0B,	r20
	ldi	r20,	2	; 2 = 1us
	out	OCR0A,	r20 
WAITECHOHIGH:
	sbis	PINB,	PB2
	rjmp	WAITECHOHIGH
WAITECHOLOW:
	ldi	r20,	0
	out	TCNT0,	r20
WAITECHOLOWWAIT:
	in	r20,	TIFR0
	sbrs	r20,	OCF0A
	rjmp	WAITECHOLOWWAIT
	ldi	r20,	(1<<OCF0A)
	out	TIFR0,	r20
	; use r16 as high r26 as low

	inc	r26
	tst	r26
	brne	SILA
ALIS:
	sbic	PINB,	PB2
	rjmp	WAITECHOLOW
	ldi	r21,	100
	rcall	DELAYMS
	out	TCCR0A,	r23
	out	TCCR0B,	r24
	out	OCR0A,	r25
	ret

SILA:	
	inc	 r16
	rjmp	ALIS

DELAY1S:
	ldi 	r20, 	(1 << CS02) | (1 << CS00)
	out	TCCR0B,	r20
	
	ldi	r21,	61
DELAY1SLOOP:
	ldi	r20, 	0
	out	TCNT0,	r20
DELAY1SWAIT:	
	in	r20,	TIFR0
	sbrs	r20,	TOV0
	rjmp	DELAY1SWAIT
	ldi	r20, 	(1<<TOV0)
	out	TIFR0,	r20
	dec	r21
	brne	DELAY1SLOOP
	ret

DELAYMS:
	ldi	r20,	(1<<WGM01)
	out	TCCR0A,	r20
	ldi	r20,	(1<<CS01) | (1<<CS00)
	out	TCCR0B,	r20
	ldi	r20,	250
	out	OCR0A,	r20
	
;	ldi	r21,	20
DELAYMSLOOP:
	ldi	r20, 	0
	out	TCNT0,	r20
DELAYMSWAIT:
	in	r20,	TIFR0
	sbrs	r20,	OCF0A
	rjmp	DELAYMSWAIT
	ldi	r20,	(1<<OCF0A)
	out	TIFR0,	r20
	dec	r21
	brne	DELAYMSLOOP
	ret

DELAYUS:
	ldi	r20,	(1<<WGM01)
	out	TCCR0A,	r20
	ldi	r20,	(1<<CS01) ; prescaler 8
	out	TCCR0B,	r20
	ldi	r20,	2	; 2 = 1us
	out	OCR0A,	r20 
DELAYUSLOOP:
	ldi	r20, 	0
	out	TCNT0,	r20

DELAYUSWAIT:
	in	r20,	TIFR0
	sbrs	r20,	OCF0A
	rjmp	DELAYUSWAIT
	ldi	r20,	(1<<OCF0A)
	out	TIFR0,	r20
	dec	r21
	brne	DELAYUSLOOP ; to loop if r21 not 0
	ret
