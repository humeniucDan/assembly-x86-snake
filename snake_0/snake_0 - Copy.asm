.586
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern printf: proc
extern rand: proc
extern srand: proc
extern time: proc
extern free: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
decimal_format DB "%d", 0ah, 0 
four dd 4

window_title DB "SNAKE",0
area_width EQU 800
area_height EQU 600
area DD 0

playarea_width EQU 500
playarea_height EQU 500
playare_leftoffset equ 50
playarea_start EQU area_width * playare_leftoffset + playare_leftoffset

snake_width EQU 25
snake_size EQU snake_width
head_start EQU playarea_start ;playarea_start + playarea_height/2*area_width + playarea_width/2
snake_sideoffset equ snake_width
snake_vertoffset equ snake_width*area_width

playmat_width equ playarea_width / snake_width
playmat_height equ playarea_height / snake_width

snake_posx dd 0;9
snake_posy dd 2;10

snakeline_start dd 0
snakeline_finish dd snake_width
snake_speed dd 4
snake_step dd 0
snake_direction dd 1
snake_lastpos dd 0
snake_len dd 4
snake_dead dd 0
snake_orientation dd 1
snake_tailpos dd 0
snake_h dd 0
n dd 0

but_width equ 50

butleft_pos equ ((area_height-but_width)/2)*area_width - but_width*2 - 1
butup_pos equ ((area_height-but_width)/2-but_width)*area_width - but_width*3 - 1
butdown_pos equ ((area_height-but_width)/2+but_width)*area_width - but_width*3 - 1
butright_pos equ ((area_height-but_width)/2)*area_width - but_width*4 - 1

butup_top equ butup_pos / area_width
butup_right equ butup_pos-(area_width * butup_top)
butup_bot equ butup_top+but_width
butup_left equ butup_right+but_width

butleft_top equ butleft_pos / area_width
butleft_right equ butleft_pos - (area_width * butleft_top)
butleft_bot equ butleft_top+but_width
butleft_left equ butleft_right+but_width

butdown_top equ butdown_pos / area_width
butdown_right equ butdown_pos - (area_width * butdown_top)
butdown_bot equ butdown_top+but_width
butdown_left equ butdown_right+but_width

butright_top equ butright_pos / area_width
butright_right equ butright_pos - (area_width * butright_top)
butright_bot equ butright_top+but_width
butright_left equ butright_right+but_width

apple_pos dd head_start + snake_size;playarea_start + (playarea_height/2)*area_width + playarea_width / 2
apple_bound dd 0
apple_type dd 0
apple_y dd 0
apple_x dd 0

col_red equ 0ff0000h
col_gold equ 0FFD700h
col_green equ 0ff00h
col_brown equ 442200h
col_gray equ 0c0c0c0h

counter DD 1 ; numara evenimentele de tip timer
score dd 0

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc	
include snake_gfx.inc

.code

insert proc
	push ebp
	mov ebp, esp
	pusha
	
	mov ecx, [ebp+12]
	mov edx, [ecx+8]
	
	pusha
	mov eax, 12
	push eax
	call malloc
	add esp, 4
	mov n, eax
	popa
	
	mov eax, n
	mov ebx, [ebp+8]
	mov dword ptr[eax], ebx
	
	mov [edx+4], eax
	mov [ecx+8], eax
	mov [eax+4], ecx
	mov [eax+8], edx
	
	popa
	mov esp, ebp
	pop ebp
	ret
insert endp
insert_m macro head, val
	push head
	push val
	call insert
	add esp, 8
endm

init macro head, val
	mov eax, 12
	push eax
	call malloc
	add esp, 4
	mov head, eax
	
	mov ebx, eax
	mov dword ptr[ebx], val
	mov [ebx+4], ebx
	mov [ebx+8], ebx
endm

del proc
	push ebp
	mov ebp, esp
	pusha
	
	mov ebx, [ebp+8]
	mov edx, [ebx+8]
	mov ecx, [edx+8]
	
	mov [ebx+8], ecx
	mov [ecx+4], ebx
	
	push edx
	call free
	add esp, 4
	
	popa
	mov esp, ebp
	pop ebp
	ret
del endp
del_m macro head
	push head
	call del
	add esp, 4
endm

; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

;----------------------------------------------------------------------------------------------------
make_text1 proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	sub eax, '0'
	lea esi, snake_gfx
	
draw_text1:
	mov ebx, snake_size
	mul ebx
	mov ebx, snake_size
	mul ebx
	mul four
	add esi, eax
	mov ecx, snake_size
bucla_simbol_linii1:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4]
	shl eax, 2
	add edi, eax
	;mov eax, [ebp+arg4] ; pointer la coord y
	;add eax, snake_size
	mov eax, snake_size
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	;add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, snake_size
	;add edi, [ebp+arg4]
bucla_simbol_coloane1:
	
	push eax
	mov eax, dword ptr[esi]
	mov dword ptr[edi], eax
	pop eax
	
simbol_pixel_next1:
	add esi, 4
	add edi, 4
	loop bucla_simbol_coloane1
	pop ecx
	loop bucla_simbol_linii1
	popa
	mov esp, ebp
	pop ebp
	ret
make_text1 endp

make_text_macro1 macro symbol, drawArea, x, y ;un macro ca sa apelam mai usor desenarea simbolului
	push y
	push x
	push drawArea
	push symbol
	call make_text1
	add esp, 16
endm
;----------------------------------------------------------------------------------------------------

	r PROC
     push ebx                 ; Save callee saved (non-volatile) registers that we use.
                             ;EBX, EBP, ESI, EDI, ESP are non-volatile. For each
                             ;one we clobber we must save it and restore it before
                             ;returning from `main`

    push 0
    call time                ; EAX=time(0)
    add esp, 4
    push eax                 ; Use time as seed	
    call srand               ; srand(time(0))
    add esp, 4

    
    call rand                ; Get a random number between 0 and 32767 into EAX

	mov ecx, playmat_height
	div ecx
	
	mov eax, edx
	mov apple_y, eax
	
    push eax
    push offset decimal_format
    call printf              ; Print the random number
    add esp,8
	
	call rand  
	; Get a random number between 0 and 32767 into EAX
	mov ecx, playmat_height
	div ecx
	
	mov eax, edx
	mov apple_x, eax
	
    push eax
    push offset decimal_format
    call printf              ; Print the random number
    add esp,8
	
	call rand  
	; Get a random number between 0 and 32767 into EAX
	mov ecx, 4
	div ecx
	
	mov eax, edx
	;mov eax, 3
	mov apple_type, eax
	
    push eax
    push offset decimal_format
    call printf              ; Print the random number
    add esp,8

    pop ebx                  ; Restore callee saved registers
    xor eax, eax             ; Return 0 from our program
    ret
r ENDP

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	
	;mai jos e codul care intializeaza fereastra cu pixeli gri
	init snake_h, head_start + snake_width * area_width*2 
	insert_m snake_h, head_start + snake_width * area_width 
	insert_m snake_h, head_start
	
	mov ebx, area_width * area_height - 1
	mov ecx, 0
	mov eax, area
make_gray:
	mov dword ptr[eax+ecx*4], col_gray
	inc ecx
	cmp ecx, ebx
	jnz make_gray
	
	
	;butoane
	mov ebx, 0
	mov ecx, 0
	mov eax, area	
	make_butleft_square:
		mov ecx, 0
		make_butleft_line:
			mov dword ptr[eax + ecx*4 + butleft_pos*4], 1
		inc ecx
		cmp ecx, but_width
		jnz make_butleft_line
			
		add eax, area_width*4
	inc ebx
	cmp ebx, but_width
		jnz make_butleft_square
	
	mov ebx, 0
	mov ecx, 0
	mov eax, area	
	make_butup_square:
		mov ecx, 0
		make_butup_line:
			mov dword ptr[eax + ecx*4 + butup_pos*4], 1
		inc ecx
		cmp ecx, but_width
		jnz make_butup_line
			
		add eax, area_width*4
	inc ebx
	cmp ebx, but_width
	jnz make_butup_square
	
	mov ebx, 0
	mov ecx, 0
	mov eax, area	
	make_butdown_square:
		mov ecx, 0
		make_butdown_line:
			mov dword ptr[eax + ecx*4 + butdown_pos*4], 1
		inc ecx
		cmp ecx, but_width
		jnz make_butdown_line
			
		add eax, area_width*4
	inc ebx
	cmp ebx, but_width
	jnz make_butdown_square
	
	mov ebx, 0
	mov ecx, 0
	mov eax, area	
	make_butright_square:
		mov ecx, 0
		make_butright_line:
			mov dword ptr[eax + ecx*4 + butright_pos*4], 1
		inc ecx
		cmp ecx, but_width
		jnz make_butright_line
			
		add eax, area_width*4
	inc ebx
	cmp ebx, but_width
	jnz make_butright_square
	
	jmp afisare_litere
	
evt_click:
	; mov edi, area
	; mov ecx, area_height
	; mov ebx, [ebp+arg3]
	; and ebx, 7
	; inc ebx
chk_butup:
	mov ebx, [ebp+arg2]
	cmp ebx, butup_right
	jl chk_butdown
	cmp ebx, butup_left
	jg chk_butdown
	mov ebx, [ebp+arg3]
	cmp ebx, butup_top
	jl chk_butdown
	cmp ebx, butup_bot
	jg chk_butdown
	mov snake_direction, 3
	jmp evt_timer
chk_butdown:
	mov ebx, [ebp+arg2]
	cmp ebx, butdown_right
	jl chk_butleft
	cmp ebx, butdown_left
	jg chk_butleft
	mov ebx, [ebp+arg3]
	cmp ebx, butdown_top
	jl chk_butleft
	cmp ebx, butdown_bot
	jg chk_butleft
	mov snake_direction, 1
	jmp evt_timer
chk_butleft:
	mov ebx, [ebp+arg2]
	cmp ebx, butleft_right
	jl chk_butright
	cmp ebx, butleft_left
	jg chk_butright
	mov ebx, [ebp+arg3]
	cmp ebx, butleft_top
	jl chk_butright
	cmp ebx, butleft_bot
	jg chk_butright
	mov snake_direction, 2
	jmp evt_timer
chk_butright:
	mov ebx, [ebp+arg2]
	cmp ebx, butright_right
	jl evt_timer
	cmp ebx, butright_left
	jg evt_timer
	mov ebx, [ebp+arg3]
	cmp ebx, butright_top
	jl evt_timer
	cmp ebx, butright_bot
	jg evt_timer
	mov snake_direction, 4
	
evt_timer:

cmp snake_dead, 1
je final_draw

	mov ebx, 0
	mov ecx, 0
	mov eax, area	
	make_brown_square:
		mov ecx, 0
		make_brown_line:
			mov dword ptr[eax + ecx*4 + playarea_start*4], col_brown
		inc ecx
		cmp ecx, playarea_width
		jnz make_brown_line
			
		add eax, area_width*4
	inc ebx
	cmp ebx, playarea_height
	jnz make_brown_square	
	
	
move_snake:
	; mov eax, counter
	; and eax, snake_speed
	; cmp eax, snake_speed
	push edx
	mov edx, 0
	mov eax, counter
	div snake_speed
	mov eax, edx
	pop edx
	cmp eax, 0
	jne inc_snakepos
		
		
		cmp snake_direction, 1
		je go_down
		cmp snake_direction, 2
		je go_left
		cmp snake_direction, 3
		je go_up
		cmp snake_direction, 4
		je go_right
		
		go_up: 
		dec snake_posy
		mov ebx, area_width*snake_width*-1
		jmp chng_snakepos 
		go_down: 
		inc snake_posy
		mov ebx, area_width*snake_width
		jmp chng_snakepos
		go_left: 
		inc snake_posx
		mov ebx, snake_width
		jmp chng_snakepos
		go_right:
		dec snake_posx
		mov ebx, snake_width*-1
		
	chng_snakepos:
	
		mov eax, snake_h
		mov ecx, [eax+8]
		push [ecx]
		pop snake_tailpos
		mov edx, [eax]
		add edx, ebx
		mov [ecx], edx
		mov snake_h, ecx
		push snake_direction
		pop snake_orientation
		
		
		mov eax, snake_h
		mov ebx, [eax+4]
	chk_body_colision:
			mov eax, [eax] 
			cmp [ebx], eax
			je death_text
			mov eax, snake_h
		mov ebx, [ebx+4]
		cmp ebx, snake_h
		jne chk_body_colision
		
	inc_snakepos:
	
	mov ebx, snake_posx
	cmp ebx, 0
	jl death_text
	cmp ebx, playmat_width
	jge death_text
	mov ebx, snake_posy
	cmp ebx, 0
	jl death_text
	cmp ebx, playmat_height
	jge death_text
	
	
	mov eax, snake_h
	mov ebx, snake_orientation
	add ebx, '0'
	
	make_text_macro1 ebx, area, 0, [eax]
	mov eax, [eax+4]
	
draw_snake:
	
	make_text_macro1 '0', area, 0, [eax]
	mov eax, [eax+4]
	
	cmp eax, snake_h
	jne draw_snake
	
	
chk_apple_colision:
	mov eax, apple_pos
	mov ebx, snake_h
	cmp [ebx], eax
	je gen_applepos
	jmp draw_apple
	
gen_applepos:

	mov eax, apple_type
	cmp eax, 0
	je n_apple
	cmp eax, 1
	je g_apple
	cmp eax, 2
	je s_apple
	cmp eax, 3
	je h_apple
	
	n_apple:
	inc score
	insert_m snake_h, snake_tailpos
	jmp compute_applepos
	
	g_apple:
	add score, 5
	insert_m snake_h, snake_tailpos
	jmp compute_applepos
	
	s_apple:
	del_m snake_h
	jmp compute_applepos
	
	h_apple:
	inc score
	cmp snake_speed, 1
	je skip_increase
	dec snake_speed
	skip_increase:
	insert_m snake_h, snake_tailpos
	jmp compute_applepos
	
compute_applepos:
	call r
	mov eax, area_width
	mov ecx, snake_size
	mul ecx
	mul apple_y
	mov ecx, eax
	mov eax, snake_size
	mul apple_x
	add eax, ecx
	add eax, playarea_start
	
	mov ebx, snake_h
chk_apple_pos:
		cmp [ebx], eax
		je compute_applepos
		mov ebx, [ebx+4]
	cmp ebx, snake_h
	jne chk_apple_pos
	
	mov apple_pos, eax
	
	
draw_apple:
	
	mov eax, apple_pos
	mov ebx, apple_type
	add ebx, '5'
	make_text_macro1 ebx, area, 0, eax

make_gs:
	
	inc counter
	
afisare_litere:
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, score
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, area_width-symbol_width*1, 10
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, area_width-symbol_width*2, 10
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, area_width-symbol_width*3, 10
	
	;scriem un mesaj
cmp snake_dead, 1
jne final_draw
death_text:
	mov snake_dead, 1
	make_text_macro 'A', area, 360, area_height/2
	make_text_macro 'I', area, 370, area_height/2
	make_text_macro ' ', area, 380, area_height/2
	make_text_macro 'M', area, 390, area_height/2
	make_text_macro 'U', area, 400, area_height/2
	make_text_macro 'R', area, 410, area_height/2
	make_text_macro 'I', area, 420, area_height/2
	make_text_macro 'T', area, 430, area_height/2

final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	
	;push ebx                 ; Save callee saved (non-volatile) registers that we use.
                             ; EBX, EBP, ESI, EDI, ESP are non-volatile. For each
                             ; one we clobber we must save it and restore it before
                             ; returning from `main`
	; push 0
    ; call time                ; EAX=time(0)
    ; add esp, 2
    ; push eax                 ; Use time as seed
    ; call srand               ; srand(time(0))
    ; add esp, 2
	
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
