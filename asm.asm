%include "tools.asm"

	global maze_init
	global maze_display
	global maze_generate

	DEFAULT REL

	section .text

; Calling convention:
; RDI, RSI, RDX, RCX, R8, R9
; (then stack)

; Initialize the maze to a starting condition:
; All left/top walls in place, except for the outer edges.
; right edge has left wall in place, bottom row has top wall.

maze_init:
	push rbx
	push rbp
	mov rbp, rsp

	mov [maze_height], rdi
	mov [maze_width], rsi
	mov [maze_ptr], rdx

; set all middle contents to default value

	mov rax, rdi		;set up our width/height in rax and rbx for multiply operation
	mov rbx, rsi
	mov rdi, rdx 		;get destination address of array into DI
	mul rbx
	mov rcx, rax		;height * width becomes number of bytes to set in array
	mov al, 0b01100000	;visited = 0, top wall = 1, left wall = 1
	cld
	rep stosb		;clear entire array to default values

; lower row

	mov rdi, [maze_ptr]	;restore pointer we were passed
	mov rbx, [maze_width]	;width into rbx
	mov rax, [maze_height]	;height into rax

	dec rax			;get the last row (height - 1)
	imul rbx		;make pointer to first item in last row: (height -1) * width
	add rdi, rax		;add our existing data pointer

	mov rcx, rbx		;set exactly WIDTH number of bytes - 1
	dec rcx
	mov al, 0b01000000	;visited = 0, top wall = 1, left wall = 0
	cld
	rep stosb

; right side wall

	mov rdi, [maze_ptr]	;get our pointer back
	mov rbx, [maze_width]	;width into rbx
	mov rcx, [maze_height]	;height into rcx
	dec rcx			;height -1
.0:
				;the following 2 instructions explained:
				;first time through loop: point rdi to last element of first row
				;subsequently, add 1 height next time(s) through loop
				; (dec rdi takes care of extraneous DI increment by stosb instruction)
	add rdi, rbx
	dec rdi

	mov al, 0b00100000	;visited = 0, top wall = 0, left wall = 1
	stosb			;automatically increments DI; but this is taken care of by dec rdi above
	dec rcx			;   the next time it goes through the loop!
	jne .0

; lower right side corner

	mov rdi, [maze_ptr]	;pointer
	mov rbx, [maze_width]	;width
	mov rax, [maze_height]	;height
	dec rax			;height-1 (point to last row)
	mul rbx			;rax = width * (height-1)
	add rax, rbx		;add height
	dec rax			;point it to last member
	add rdi, rax		;apply it to the pointer
	mov al, 0x0		;visited = 0, top wall = 0, left wall = 0
	mov [rdi], al

	pop rbp
	pop rbx

	ret

; helper functions

; maze_ptr2cell
; This routine takes cell hpos=r8 wpos=r9 and returns a pointer
; to the cell in rdx based on the value in maze_ptr.
; saves all registers

maze_ptr2cell:
	mov rax, r8
	mul qword [maze_width]
	add rax, r9
	add rax, [maze_ptr]
	mov rdx, rax
	mov al, [rdx]
	ret

; Pretty print the maze.
; hscale = number of character cells each maze cell should be tall,
; wscale = number of character cells each maze cell should be wide.
; maze_ptr is the pointer to the maze array.

maze_display:
	push rbx
	push rbp
	mov rbp, rsp

	mov [maze_height], rdi			;save all our arguments
	mov [maze_width], rsi
	mov [maze_ptr], rdx
	mov [maze_height_scale], rcx
	mov [maze_width_scale], r8

	xor r8, r8						;clear height loop counter
.icycle:
	xor r9, r9						;clear width loop counter for top wall
.jcycle1:
; display top wall of cell r8, r9
	call maze_ptr2cell
	and al, 0b01000000
	jz .notop
	mov al, '-'
	jmp .printtop
.notop:
	mov al, ' '
.printtop:
	mov rcx, [maze_width_scale]
.printtop1:
	push rcx
	push rax
	push r8
	push r9
	call print_char
	pop r9
	pop r8
	pop rax
	pop rcx
	loop .printtop1
.jrecycle1:
	inc r9
	cmp r9, [maze_width]
	jb .jcycle1

	push r8
	push r9
	call print_cr
	pop r9
	pop r8

; loop [maze_height_scale] number of times to render the left side walls

	xor r10, r10
.kcycle:
	xor r9, r9
.jcycle2:

; print "|   " or "    " depending on left wall flag in cell
	call maze_ptr2cell
	push rax				;save, so we can check visited status
	and al, 0b00100000
	jz .noside
	mov al, '|'
	jmp .printside
.noside:
	mov al, ' '
.printside:

; print left-size character as set above
	push r8
	push r9
	push r10
	call print_char
	pop r10
	pop r9
	pop r8

; restore rax and check for visited status
	pop rax
	and al, 0b10000000
	jz .novis
	mov al, ' '
	or r10, r10
	jne .printvis
;	mov al, '#'
	mov al, ' '						; print a space no matter what (visiting debug off)
	jmp .printvis
.novis:
	mov al, ' '
.printvis:
	push r8
	push r9
	push r10
	call print_char
	pop r10
	pop r9
	pop r8

; print n number of spaces to pad the cell
	mov rcx, [maze_width_scale]
	sub rcx, 2						;rcx = maze_width_scale - 2, because we already printed first character + vis
.sidepad:
	mov al, ' '
	push rcx
	push r8
	push r9
	push r10
	call print_char
	pop r10
	pop r9
	pop r8
	pop rcx
	loop .sidepad

.jrecycle2:
	inc r9
	cmp r9, [maze_width]
	jb .jcycle2
.krecycle:
	push r8
	push r9
	push r10
	call print_cr
	pop r10
	pop r9
	pop r8
	inc r10
	cmp r10, [maze_height_scale]
	jb .kcycle

; recycle outer (i) loop
	inc r8
	cmp r8, [maze_height]
	jb .icycle

	pop rbp
	pop rbx

	ret

; Actually generate the maze
; maze_generate carves a unique path through the maze from any point to any other point.
;
; helper functions:
; maze_traverse starts at the traverse points and carves a random path
; through the maze until it reaches a dead end, indicated by there
; being no unvisited neighbors, which is when it returns to the caller.
;
; maze_get_unvis_ptr takes the index of the unvis_neighs array and returns a pointer
; in RSI to the actual data (offset_h and offset_w pair).

maze_get_unvis_ptr:
	push rbx
	mov rbx, 16
	mul rbx
	pop rbx
	add rax, unvis_neighs
	mov rsi, rax						;SI = index into unvis_neighs array
	ret

maze_traverse:
	xor rax, rax
	mov [num_unvis_neighs], rax			;clear our unvisited neighbors counter
; get r8, r9 set up with current cell
	mov r8, [maze_traverse_h]
	mov r9, [maze_traverse_w]
; check upwards neighbor
	or r8, r8							;traverse_h is zero?
	je .checkleft
	dec r8
	call maze_ptr2cell
	and al, 0b10000000					;check visited bit of upwards neighbor
	jne .checkleft
	mov rax, [num_unvis_neighs]
	call maze_get_unvis_ptr
	mov rax, -1
	mov [rsi], rax
	xor rax, rax
	mov [rsi+8], rax					;offset_h=-1, offset_w=0
	inc qword [num_unvis_neighs]		;num_unvis_neighs++
; check left neighbor
.checkleft:
	mov r8, [maze_traverse_h]
	mov r9, [maze_traverse_w]
	or r9, r9							;traverse_w is zero?
	je .checkright
	dec r9
	call maze_ptr2cell
	and al, 0b10000000					;check visited bit of leftwards neighbor
	jne .checkright
	mov rax, [num_unvis_neighs]
	call maze_get_unvis_ptr
	xor rax, rax
	mov [rsi], rax
	mov rax, -1
	mov [rsi+8], rax					;offset_h=0, offset_w=-1
	inc qword [num_unvis_neighs]		;num_unvis_neighs++
; check right neighbor
.checkright:
	mov r8, [maze_traverse_h]
	mov r9, [maze_traverse_w]
	mov r10, [maze_width]
	sub r10, 2							;maze_width - 2
	cmp r9, r10
	jae .checkdown
	inc r9
	call maze_ptr2cell
	and al, 0b10000000					;check visited bit of rightwards neighbor
	jne .checkdown
	mov rax, [num_unvis_neighs]
	call maze_get_unvis_ptr
	xor rax, rax
	mov [rsi], rax
	mov rax, 1
	mov [rsi+8], rax					;offset_h=0, offset_w=1
	inc qword [num_unvis_neighs]		;num_unvis_neighs++
; check down neighbor
.checkdown:
	mov r8, [maze_traverse_h]
	mov r9, [maze_traverse_w]
	mov r10, [maze_height]
	sub r10, 2							;maze_height - 2
	cmp r8, r10
	jae .checknumunvis
	inc r8
	call maze_ptr2cell
	and al, 0b10000000					;check visited bit of down neighbor
	jne .checknumunvis
	mov rax, [num_unvis_neighs]
	call maze_get_unvis_ptr
	mov rax, 1
	mov [rsi], rax
	xor rax, rax
	mov [rsi+8], rax					;offset_h=1, offset_w=0
	inc qword [num_unvis_neighs]		;num_unvis_neighs++

.checknumunvis:
	mov rax, [num_unvis_neighs]
	or rax, rax
	jne .chooserand
	mov r8, [maze_traverse_h]
	mov r9, [maze_traverse_w]
	call maze_ptr2cell
	or al, 0b10000000
	mov [rdx], al						;mark ourselves as visited
	ret									;no unvisited neighbors, so return!

.chooserand:
	mov rax, [num_unvis_neighs]
	call random_mod
;	push rax
	call maze_get_unvis_ptr
;	pop rax
;	push rsi
;	call print_uint64
;	call print_space
;	call print_space
;	mov rax, [num_unvis_neighs]
;	call print_uint64
;	call print_cr
;	pop rsi
	mov r10, [rsi]						;r10 = random neighbor's offset_h
	mov r11, [rsi+8]					;r11 = random neighbor's offset_w
	mov r8, [maze_traverse_h]
	mov r9, [maze_traverse_w]			;restore our traverse pointers

; check which direction we are going
	cmp r10, -1
	jne .checkdirleft
	call maze_ptr2cell
	and al, 0b10111111					;tear down top wall
	mov [rdx], al
	jmp .markvis
.checkdirleft:
	cmp r11, -1
	jne .checkdirright
	call maze_ptr2cell
	and al, 0b11011111					;tear down left wall
	mov [rdx], al
	jmp .markvis
.checkdirright:
	cmp r11, 1
	jne .checkdirdown
	inc r9
	call maze_ptr2cell
	and al, 0b11011111					;tear down left wall or righthand neighbor
	mov [rdx], al
	jmp .markvis
.checkdirdown:
; not any of the others, must be down
	inc r8
	call maze_ptr2cell
	and al, 0b10111111					;tear down top wall of downstairs neighbor
	mov [rdx], al

.markvis:
	mov r8, [maze_traverse_h]
	mov r9, [maze_traverse_w]
	call maze_ptr2cell
	or al, 0b10000000
	mov [rdx], al						;mark ourselves as visited

	add r8, r10
	mov [maze_traverse_h], r8
	add r9, r11							;do traversal
	mov [maze_traverse_w], r9

;	mov rax, r8
;	call print_uint64
;	call print_space
;	mov rax, [maze_traverse_w]
;	call print_uint64
;	call print_cr

;	mov rdi, [maze_height]
;	mov rsi, [maze_width]
;	mov rdx, [maze_ptr]
;	mov rcx, 2
;	mov r8, 5
;	call maze_display

	jmp maze_traverse					;and recycle for another go at it

maze_hunt_check:
	mov r8, [maze_traverse_h]
	mov r9, [maze_traverse_w]
	call maze_ptr2cell
	mov r12, rdx						;save pointer to our cell
	and al, 0b10000000					;we're interested in unvisited cells only
	jnz .notfound						;high bit set == already visited cell
; check up neighbor
	or r8, r8							;in zeroeth row?
	jz .checkleft						;yes, so there is no upwards neighbor
	dec r8
	call maze_ptr2cell
	and al, 0b10000000					;is our upwards neighbor visited?
	jz .checkleft						;no, not visited, so move on to check left neighbor
	mov al, [r12]
	or al, 0b10000000					;visit ourselves
	and al, 0b10111111					;tear down top wall
	mov [r12], al						;and put it back
	jmp .found
.checkleft:
	mov r8, [maze_traverse_h]
	mov r9, [maze_traverse_w]
	or r9, r9							;in zeroeth column?
	jz .checkright						;yes, so there is no leftside neighbor.
	dec r9
	call maze_ptr2cell
	and al, 0b10000000
	jz .checkright
	mov al, [r12]
	or al, 0b10000000
	and al, 0b11011111					;tear down our left side wall
	mov [r12], al
	jmp .found
.checkright:
	mov r8, [maze_traverse_h]
	mov r9, [maze_traverse_w]
	mov r10, [maze_width]
	sub r10, 2							;maze_width - 2
	cmp r9, r10
	jae .checkdown
	inc r9
	call maze_ptr2cell
	and al, 0b10000000
	jz .checkdown
	mov al, [rdx]						;get back our neighbor
	or al, 0b10000000					;visit him
	and al, 0b11011111					;tear down his left side wall
	mov [rdx], al						;put it back
	jmp .found
.checkdown:
	mov r8, [maze_traverse_h]
	mov r9, [maze_traverse_w]
	mov r10, [maze_height]
	sub r10, 2							;maze_height - 2
	cmp r8, r10
	jae .notfound
	inc r8
	call maze_ptr2cell
	and al, 0b10000000
	jns .notfound
	mov al, [rdx]
	or al, 0b10000000					;visit downwards neighbor
	and al, 0b10111111					;tear down his top wall
	mov [rdx], al						;put it back and fall through to .found

.found:
	mov rax, 1
	ret
.notfound:
	mov rax, 0
	ret

maze_hunt:
	mov rax, [maze_height]				;pick a random starting spot for the hunt
	dec rax
	call random_mod
	mov [maze_hunt_start_h], rax
	mov [maze_traverse_h], rax			;and set the traverse pointers
	mov rax, [maze_width]
	dec rax
	call random_mod
	mov [maze_hunt_start_w], rax
	mov [maze_traverse_w], rax
%ifdef DEBUG
	call print_embedded_cstring
	db "maze_hunt: chose random hunt starting point h=", 0x00
	mov rax, [maze_hunt_start_h]
	call print_uint64
	call print_embedded_cstring
	db " w=", 0x00
	mov rax, [maze_hunt_start_w]
	call print_uint64
	call print_cr
%endif

maze_check_loop:
%ifdef DEBUG
	call print_embedded_cstring
	db "maze_hunt: checking h=", 0x00
	mov rax, [maze_traverse_h]
	call print_uint64
	call print_embedded_cstring
	db " w=", 0x00
	mov rax, [maze_traverse_w]
	call print_uint64
	call print_cr
%endif
	call maze_hunt_check
	or rax, rax
	jnz maze_hunt_found					;if maze_hunt_check returns nonzero, we found a new starting cell

	mov r8, [maze_height]
	dec r8
	mov r9, [maze_width]
	dec r9
	inc qword [maze_traverse_w]
	mov rax, [maze_traverse_w]
	cmp rax, r9
	jb maze_check_back_to_start			;increment traverse_w, loop if we haven't reached the guard column yet
	xor rax, rax
	mov [maze_traverse_w], rax			;zero traverse_w so we can start on the next row
	inc qword [maze_traverse_h]
	mov rax, [maze_traverse_h]
	cmp rax, r8
	jb maze_check_back_to_start			;increment traverse_h, loop if we haven't reached guard row yet
	xor rax, rax
	mov [maze_traverse_h], rax			;zero traverse_h so we can start again from the top

maze_check_back_to_start:
	mov rax, [maze_traverse_w]
	cmp rax, [maze_hunt_start_w]
	jne maze_check_loop
	mov rax, [maze_traverse_h]
	cmp rax, [maze_hunt_start_h]
	jne maze_check_loop
%ifdef DEBUG
	call print_embedded_cstring
	db "maze_hunt: found no more unvisited cells!", 0x0a, 0x00
%endif
	mov rax, 0							;made it back to our starting point without finding a cell
	ret

maze_hunt_found:
%ifdef DEBUG
	call print_embedded_cstring
	db "maze_hunt: found unvisited cell with visited neighbor at: h=", 0x00
	mov rax, [maze_traverse_h]
	call print_uint64
	call print_embedded_cstring
	db " w=", 0x00
	mov rax, [maze_traverse_w]
	call print_uint64
	call print_cr
%endif
	mov rax, 1
	ret

maze_generate:
	push rbx
	push rbp
	mov rbp, rsp

	mov [maze_height], rdi
	mov [maze_width], rsi
	mov [maze_ptr], rdx

; generate random starting points for traverse
	mov rax, [maze_height]
	dec rax
	call random_mod
	mov [maze_traverse_h], rax
	mov rax, [maze_width]
	dec rax
	call random_mod
	mov [maze_traverse_w], rax
%ifdef DEBUG
	call print_embedded_cstring
	db "maze_generate: chose random traverse starting point h=", 0x00
	mov rax, [maze_traverse_h]
	call print_uint64
	call print_embedded_cstring
	db " w=", 0x00
	mov rax, [maze_traverse_w]
	call print_uint64
	call print_cr
%endif

; traversal loop: traverse then hunt until hunt returns finding no unvisited cells.

maze_generate_trav_loop:
	call maze_traverse
%ifdef DEBUG
	mov rdi, [maze_height]
	mov rsi, [maze_width]
	mov rdx, [maze_ptr]
	mov rcx, 2
	mov r8, 5
	call maze_display
%endif
	call maze_hunt
	or rax, rax
	jnz maze_generate_trav_loop	;loop until rax == zero

	pop rbp
	pop rbx
	ret

	section .data

	align 32

maze_height:
	dq 0						;The height in cells of our maze (bottom row is a padding row)
maze_width:
	dq 0						;The width of our maze (right side column is a padding column)
maze_ptr:
	dq 0
maze_height_scale:
	dq 0
maze_width_scale:
	dq 0
maze_traverse_h:
	dq 0
maze_traverse_w:
	dq 0
num_unvis_neighs:
	dq 0
maze_hunt_start_h:
	dq 0
maze_hunt_start_w:
	dq 0

	section .bss

unvis_neighs:
	resb 16 * 4					;unvis_neighs array. offset_h, offset_w * [4]

