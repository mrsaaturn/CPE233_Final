;----------------------
;-- Port Constants
;---------------------
.EQU SWITCHES 	= 0x20
.EQU XPOT_PORT 	= 0x10	; Port designation for X potentiometer
.EQU YPOT_PORT	= 0x11	; Port designation for Y potentiometer

.EQU VGA_HADD 	= 0x90
.EQU VGA_LADD 	= 0x91
.EQU VGA_COLOR	= 0x92

.EQU BG_COLOR 	= 0x30
;----------------------
;-- Register Aliases
;----------------------
.DEF COLOR	= r0	; Color Hold
.DEF XPOT	= r1	; ADC'd value from X potentiometer
.DEF YPOT	= r2	; ADC'd value from Y potentiometer
.DEF StartX	= r8
.DEF StartY = r7
.DEF MAP_CDTN	= r20	; Condition for Mapping
.DEF MAPCONST 	= r21
.DEF MAPMAX		= r22
.DEF POTVAL		= r23
.DEF MAPVAL 	= r24
.CSEG
.ORG 0x01
; Read Values from Switches & Potentiometers

INIT:
			MOV COLOR, 0xBB

MAIN:		IN 	r0,  SWITCHES
			;IN  r25, BG_COLOR
			;CALL draw_background
			IN	r1, XPOT_PORT
			; Move values for MAPPING subroutine
			MOV MAP_CDTN, 0x03
			MOV MAPMAX,	  0xED
			MOV POTVAL, XPOT
			CALL MAPPING
			MOV StartX, MAPVAL
			
			IN r2, YPOT_PORT
			MOV MAP_CDTN, 0x04
			MOV MAPMAX,	  0xEC
			MOV POTVAL, YPOT
			CALL MAPPING
			MOV StartY, MAPVAL
			CALL draw_dot
			BRN MAIN 			; Infinite loop
			
;------------------------------------------
; Subroutine: Generic mapping function
;
; Parameters:
; Map_CDTN & MAPCONST - MUST BE SAME! 255/MAPMAX rounded
; MAPMAX - Highest value in range
; MAPVAL - Mapped Value
; POTVAL - Value from potentiometer
MAPPING:	MOV MAPCONST, MAP_CDTN
			MOV MAPVAL, 0x00
LOOPMAP:	CMP MAP_CDTN, POTVAL
			BRCC MAPDONE
			ADD MAP_CDTN, MAPCONST
			ADD MAPVAL, 0x01
			CMP MAPVAL, MAPMAX
			BREQ MAPDONE
			BRN LOOPMAP
MAPDONE:	MOV MAPCONST, 0x00
			RET
;---------------------------------------------------------------------
;- Subrountine: draw_dot
;- 
;- This subroutine draws a dot on the display the given coordinates: 
;- 
;- (X,Y) = (r8,r7)  with a color stored in r6  
;- 
;- Tweaked registers: r4,r5
;---------------------------------------------------------------------
draw_dot: 
           MOV   r10,r7         ; copy Y coordinate
           MOV   r11,r8         ; copy X coordinate

           AND   r11,0x7F       ; make sure top 1 bits cleared
           AND   r10,0x3F       ; make sure top 2 bits cleared
           LSR   r10             ; need to get the bottom bit of r4 into sA
           BRCS  dd_add80

dd_out:    OUT   r11,VGA_LADD   ; write bot 8 address bits to register
           OUT   r10,VGA_HADD   ; write top 5 address bits to register
           OUT   r0,VGA_COLOR  ; write color data to frame buffer
           RET           

dd_add80:  OR    r11,0x80       ; set bit if needed
           BRN   dd_out
; --------------------------------------------------------------------
