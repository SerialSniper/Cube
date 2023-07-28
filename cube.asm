[org 0x7c00]

xor ax, ax
mov ds, ax
mov es, ax

%define FBWIDTH   320
%define FBHEIGHT  200

%define cubeDataPtr 600
%define cubeDataTransformedPtr 800
%define rotationPtr 512

mov [rotationPtr], word 0

; 320x200
mov ah, 0
mov al, 13h
int 10h

genCube:
    push bp
    mov bp, sp
    sub sp, 6
    
    mov bx, cubeDataPtr
    mov ax, -1
    xor dx, dx
    genCube_loop2:
        mov [bp - 6], ax
        mov [bp - 4], ax
        mov [bp - 2], ax
        
        cmp dx, 0
            je genCube_loop2_first
            sub bp, dx
            neg word [bp]
            add bp, dx
        genCube_loop2_first:

        mov cx, 6
        genCube_loop:
            call putVertexAndNegBpCx
            call putVertexAndNegBpCx
            dec cx
            loop genCube_loop
        
        mov ax, 1
        inc dx
        inc dx
        cmp dx, 8
            jl genCube_loop2
    
    mov sp, bp
    pop bp

loop:
    mov cx, word FBWIDTH * FBHEIGHT
    mov dx, cx
    cls_loop:
        push es
            mov bx, 0xA000
            mov es, bx

            mov di, dx
            sub di, cx
            mov [es:di], byte 0
        pop es

        ; dec cx
        loop cls_loop

    push word 12
    push word cubeDataPtr
    call drawLines

    xor cx, cx
    mov dx, 0x2710 ; 10ms
    mov ah, 86h
    int 15h
    
    mov ax, [rotationPtr]
    inc ax
    cmp ax, 360
        jl wrap_end
        sub ax, 360
    wrap_end:
    mov [rotationPtr], ax

    jmp loop

; 4      6
; data*, len
drawLines:
    push bp
    mov bp, sp

    mov ax, [bp + 6]
    mov dx, 12
    mul dx
    mov [bp + 6], ax

    push ax
    push word cubeDataTransformedPtr
    push word [bp + 4]
    call memcpy

    mov cx, 0
    drawLines_lineLoop:
        mov bx, cubeDataTransformedPtr
        add bx, cx
        call transformVertex
        add bx, 6
        call transformVertex
        
        push dword [bx - 0]
        push dword [bx - 6]
        call drawLine

        add cx, 12
        cmp cx, word [bp + 6]
            jl drawLines_lineLoop

    mov sp, bp
    pop bp
    ret 4

; 4    6    8
; src, dst, len
memcpy:
    push bp
    mov bp, sp

    xor bx, bx
    memcpy_loop:
        mov si, [bp + 4]
        mov di, [bp + 6]
        mov ax, [si + bx]
        mov [di + bx], ax
        
        inc bx
        inc bx
        cmp bx, [bp + 8]
            jl memcpy_loop

    mov sp, bp
    pop bp
    ret 6

; bx = vertexPtr
transformVertex:
    fninit

    fild word [rotationPtr]
    push 180
    fidiv word [esp]
    pop ax
    fldpi
    fmul
    fsincos
    
    fild word [bx]      ; x
    fmul st0, st2       ; x * sin
    fild word [bx + 4]  ; z
    fmul st0, st2       ; z * cos
    fadd
    fchs

    fild word [bx]      ; x
    fmul st0, st2       ; x * cos
    fild word [bx + 4]  ; z
    fmul st0, st4
    fchs                ; z * -sin
    fadd
    
    push 3
    fild word [esp]
    pop ax
    faddp st2, st0

    fimul word [fbWidth2]
    fdiv st0, st1
    fimul word [fbHeight2]
    fidiv word [fbWidth2]
    fiadd word [fbWidth2]
    fistp word [bx]

    fild word [bx + 2]
    fimul word [fbHeight2]
    fdiv st0, st1
    fchs
    fiadd word [fbHeight2]
    fistp word [bx + 2]
    ret

putVertexAndNegBpCx:
    push bx
        push word 6
        push bx
        mov ax, bp
        sub ax, 6
        push ax
        call memcpy
    pop bx
    add bx, 6
    
    mov si, cx
    neg si
    neg word [bp + si]
    ret

; 4   6   8   10
; x0, y0, x1, y1
drawLine:
    push bp
    mov bp, sp
    sub sp, 8

    fninit
    
    mov ax, [bp + 10]
    sub ax, [bp + 6]
    call abs_
    mov dx, ax
    
    mov ax, [bp + 8]
    sub ax, [bp + 4]
    call abs_

    xor si, si
    cmp dx, ax
        jle drawLine_slopeCheck_end  ; if dy > dx then
        mov si, 2                    ; x and y will invert
    drawLine_slopeCheck_end:

    mov dx, [bp + 8 + si]
    cmp dx, [bp + 4 + si]
        jge drawLine_adjust_end
        mov dx, [bp + 8]
        xchg dx, [bp + 4]
        mov [bp + 8], dx
        mov dx, [bp + 10]
        xchg dx, [bp + 6]
        mov [bp + 10], dx
    drawLine_adjust_end:

    mov di, 2
    drawLine_loopTwoTimes:
        mov ax, [bp + 8 + di]
        sub ax, [bp + 4 + di]
        mov [bp - 4 + di], ax           ; dx, dy
        
        mov ax, [bp + 4 + di]
        mov [bp - 8 + di], ax           ; x, y

        sub di, 2
        jge drawLine_loopTwoTimes

    drawLineLow_loop:
        fild word [bp - 8 + si]
        fisub word [bp + 4 + si]
        fidiv word [bp - 4 + si]
        neg si
        fimul word [bp - 2 + si]
        fiadd word [bp + 6 + si]
        fistp word [bp - 6 + si]
        neg si

        ; drawPixel
        mov ax, [bp - 6]
        mov dx, FBWIDTH
        mul dx

        push es
            mov bx, 0xA000
            mov es, bx
            
            add ax, [bp - 8]
            mov bx, ax
            mov [es:bx], byte 0x0F
        pop es
        ; drawPixel end

        inc word [bp - 8 + si]
        mov ax, [bp - 8 + si]
        cmp ax, [bp + 8 + si]
            jl drawLineLow_loop

    mov sp, bp
    pop bp
    ret 8

; 4
; n
abs_:
    mov bx, ax
    sar bx, 15
    xor ax, bx
    sub ax, bx
    ret

fbWidth2  dw 160
fbHeight2 dw 100

times 510-($-$$) db 0
dw 0xAA55