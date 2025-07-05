.include "m328pdef.inc"
.org 0x0000
rjmp RESET

RESET:
    ; Set PB5 as output
    ldi r16, (1 << PB5)
    out DDRB, r16

    ; Configure Timer0: normal mode, prescaler 1024
    ldi r16, (1 << CS02) | (1 << CS00) ; clk/1024
    out TCCR0B, r16

Loop:
    sbi PORTB, PB5
    rcall Delay1s
    cbi PORTB, PB5
    rcall Delay1s
    rjmp Loop

Delay1s:
    ldi r18, 61          ; 61 overflows ≈ 1 second at 16MHz
DelayLoop:
    ; Wait for overflow
WaitTOV:
    in r19, TIFR0
    sbrs r19, TOV0
    rjmp WaitTOV

    ; Clear overflow flag by writing 1
    ldi r19, (1 << TOV0)
    out TIFR0, r19

    dec r18
    brne DelayLoop
    ret
