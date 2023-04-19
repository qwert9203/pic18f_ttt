	LIST P=18F4520
	#include <P18F4520.INC>
	CONFIG OSC = XT
	CONFIG WDT = OFF
	CONFIG LVP = OFF

PLAYER1 EQU 0x01
PLAYER2 EQU 0x04

PLAYER1WIN EQU 0x03
PLAYER2WIN EQU 0x0C

i EQU 0x10 ; iterator
j EQU 0x11 ; iterator
k EQU 0x12 ; iterator

cursor EQU 0x40
target_index EQU 0x41
old_display_reg EQU 0x42


	cblock 0x100
		board:9
		display:32
		lines:3
		DELAY_H
		DELAY_L
		gameover
	endc
current_shape EQU 0x20
check_result EQU 0x21
current_player EQU 0x22 ; 0 or 1, starting with 0
current_index EQU 0x23
	ORG 0x0000
	GOTO Main

	ORG 0x0100
Main:


	CLRF TRISB
	CLRF TRISC
	CLRF TRISD
	SETF TRISA
	CLRF current_index

	MOVLW 0x0F
	MOVWF ADCON1

	MOVLW 0x09
	MOVWF i
	LFSR 0, board
loop_0_for_i:
	CLRF POSTINC0
	DECF i, F
	BNZ loop_0_for_i

	call clear_display
	
	;current_player = 0
	MOVLW PLAYER1
	MOVWF current_player





	GOTO Loop
	

Loop: ; no interrupts tyvm
	BTFSC PORTA, 0
	BRA check_1
	call delay10
wait_0_up:
	BTFSS PORTA, 0
	BRA wait_0_up
	call delay10
	MOVLW 0x00
	CPFSEQ current_index
	DECF current_index, F
check_1
	BTFSC PORTA, 1
	BRA check_2
	call delay10
wait_1_up:
	BTFSS PORTA, 1
	BRA wait_1_up
	call delay10
	MOVLW 0x08
	CPFSEQ current_index
	INCF current_index
check_2
	BTFSC PORTA, 2
	BRA refresh_display
	call delay10
wait_2_up:
	BTFSS PORTA, 2
	BRA wait_2_up
	call delay10
	LFSR 0, board
	MOVF current_index, W
	MOVFF PLUSW0, target_index
	MOVLW 0x00
	CPFSEQ target_index
	GOTO refresh_display ; trying to place on occupied tile
	MOVF current_index, W
	MOVFF current_player, PLUSW0
	call update_display
	call Check_win
	; check if win and stuff
	MOVLW 0x01
	CPFSEQ gameover
	GOTO refresh_display
	GOTO done
refresh_display:
	LFSR 0, display
	MOVLW 0x1A
	MOVFF current_index, PLUSW0 
	call Display
	GOTO Loop


; goes to win, draw or continue
Check_win:
	;table_pointer = &Checks
	MOVLW low Checks
	MOVWF TBLPTRL
	MOVLW high Checks
	MOVWF TBLPTRH
	MOVLW upper Checks
	MOVWF TBLPTRU
	CLRF gameover

	; k = 0
	; for i = 8; i > 0; i--:
	; 	for j = 3; j > 0; j--:
	; 		check_result += board[Checks[k++]]
	;   if check_result == 3 or check_result == 12:
	;   	win()
	;		
	;i, j = 8, 3;

	MOVLW 0x09;
	MOVWF i;

loop_1_for_i:
	MOVLW 0x03;
	MOVWF j;
	CLRF check_result

loop_1_for_j:
	
	; w = Checks[k++]
	TBLRD*+; post increment
	MOVFF TABLAT, WREG
	LFSR 0, board;
	; w = board[w]
	MOVFF PLUSW0, WREG
	; check_result += w
	ADDWF check_result, F
	; j--
	DECF j, F;
	BNZ loop_1_for_j;
	
	; if player1 win
	MOVLW PLAYER1WIN
	CPFSEQ check_result
	goto player1_no_win
	goto end_game ; player 1 wins
player1_no_win:
	MOVLW PLAYER2WIN
	CPFSEQ check_result
	goto no_win
	goto end_game ; player 2 wins
no_win:
	; i--
	DECF i, F;
	BNZ loop_1_for_i
	
	; check for 0s
	; for i = 9; i > 0; i--:
	; 	
	MOVLW 0x09
	MOVWF i;
	LFSR 0, board;
	MOVLW 0
loop_2_for_i:
	CPFSEQ POSTINC0; if its 0, break
	GOTO continue_check
	GOTO no_draw; == 0, break
continue_check:
	; i--
	DECF i, F
	BNZ loop_2_for_i

	MOVLW 0xFF
	MOVWF 0x70
	LFSR 0, display
	MOVLW 0x1C
	MOVFF 0x70, PLUSW0 
	goto end_game ; draw
	

no_draw:
	; change player
	MOVLW PLAYER1
	CPFSEQ current_player
	BRA set_to_p1
	BRA set_to_p2
set_to_p1:
	MOVLW PLAYER1
	MOVWF current_player
	BRA finish_set

set_to_p2:
	MOVLW PLAYER2
	MOVWF current_player
	BRA finish_set

finish_set:
	MOVLW 0x00
	MOVWF gameover
	return


end_game:
	MOVLW 0xF0
	MOVWF 0x70
	LFSR 0, display
	MOVLW 0x1F
	MOVFF 0x70, PLUSW0 
	MOVLW 0x01
	MOVWF gameover
	return

clear_display:
	MOVLW 0x20
	MOVWF i
	LFSR 0, display
loop_5_for_i:
	CLRF POSTINC0
	DECF i, F
	BNZ loop_5_for_i
	return


update_display:
	call clear_display
	MOVLW low cursor_points
	MOVWF TBLPTRL
	MOVLW high cursor_points
	MOVWF TBLPTRH
	MOVLW upper cursor_points
	MOVWF TBLPTRU
	MOVLW 0x09
	MOVWF i
	LFSR 1, board
	clrf cursor
loop_4_for_i:
	LFSR 0, lines
	MOVFF POSTINC1, current_shape
	MOVLW 0x00
	CPFSEQ current_shape
	bra shape_not_null
	bra render_null
shape_not_null:
	MOVLW 0x01
	CPFSEQ current_shape
	bra render_o
	bra render_x
render_o:
	clrf POSTINC0
	MOVLW b'00000111'
	MOVWF POSTINC0
	MOVLW b'00000101'
	MOVWF POSTINC0
	MOVLW b'00000111'
	MOVWF POSTINC0
	BRA render
render_x:
	clrf POSTINC0
	MOVLW b'00000101'
	MOVWF POSTINC0
	MOVLW b'00000010'
	MOVWF POSTINC0
	MOVLW b'00000101'
	MOVWF POSTINC0
	BRA render
render_null:
	clrf POSTINC0
	clrf POSTINC0
	clrf POSTINC0
	clrf POSTINC0
	BRA render
render:
	LFSR 0, lines
	LFSR 2, display
	MOVLW 0x04
	MOVWF j
	; moves starting address of cursor to fsr2
	TBLRD*+
	MOVFF TABLAT, cursor
loop_4_for_j:
	; move old line to old_display_reg
	MOVF cursor, W
	MOVFF PLUSW2, old_display_reg
	; w = current line
	MOVF POSTINC0, W
	; add them together
	ADDWF old_display_reg, F
	; swap nibbles if needed
	MOVLW 0x06
	CPFSGT i
	BRA check_lt
	BRA swap

swap:
	SWAPF old_display_reg, F
	BRA after_swap


check_lt:
	MOVLW 0x04
	CPFSLT i
	BRA after_swap
	BRA swap

after_swap:
	
	; move line back to display
	MOVF cursor, W
	MOVFF old_display_reg, PLUSW2

	MOVLW 0x02
	ADDWF cursor, F
	DECF j, F
	BNZ loop_4_for_j

	DECF i, F
	BNZ loop_4_for_i
	return
	

Display:
	MOVLW low columns
	MOVWF TBLPTRL
	MOVLW high columns
	MOVWF TBLPTRH
	MOVLW upper columns
	MOVWF TBLPTRU
	; i = 16
	MOVLW 0x00
	MOVWF i
	LFSR 0, display
loop_3_for_i:
	TBLRD*+
	MOVFF TABLAT, PORTC
	MOVFF POSTINC0, PORTB
	MOVFF POSTINC0, PORTD
	call delay
	INCF i, F
	MOVLW 0x10
	CPFSEQ i
	BRA loop_3_for_i
	return


delay:
	MOVLW 0x3F
	MOVWF k
loop_delay:
	NOP
	NOP
	NOP
	NOP	
	NOP
	NOP
	NOP
	DECF k
	BNZ loop_delay
	RETURN

delay10: MOVLW 0x7f
	MOVWF DELAY_H
LOP_1: 
	MOVLW 0
LOP_2: DECF DELAY_L, F
	BNZ LOP_2
	DECF DELAY_H, F
	BNZ LOP_1
	return

Checks
	db 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07
	db 0x08, 0x00, 0x03, 0x06, 0x01, 0x04, 0x07, 0x02
	db 0x05, 0x08, 0x02, 0x04, 0x06, 0x00, 0x04, 0x08

columns
	db 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17
	db 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F

cursor_points
	db 0x00, 0x08, 0x10, 0x00, 0x08, 0x10, 0x01, 0x09, 0x11


done:
	call Display
	bra done
	END
