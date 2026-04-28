; ============================================================
; Secure x86-64 Assembly Implementation
; Converted from 68k with Security Fixes
; ============================================================
; Author: Oyindamola Olaosun
; Date: 29th April 2026
; Description: 
;   - Loops 3 times asking for two numbers each iteration
;   - Adds numbers with proper input validation
;   - Detects integer overflow
;   - Keeps a running sum and displays final result
; ============================================================

; ============================================================
; x86_64 VERSION (ALIGNED WITH 68k STRUCTURE)
; ============================================================

global ATOI_testable

section .data
    PROMPT db "Enter number: ", 0
    PROMPT_LEN equ $-PROMPT

    RESULT db "The sum is: ", 0
    RESULT_LEN equ $-RESULT

    FINAL_RESULT db "Final sum is: ", 0
    FINAL_LEN equ $-FINAL_RESULT

    ERR_MSG db "Invalid input", 10
    ERR_LEN equ $-ERR_MSG

    OVERFLOW_MSG db "Overflow detected", 10
    OVERFLOW_LEN equ $-OVERFLOW_MSG

    CRLF db 10

section .bss
    input_buffer resb 64   ; for reading user input (ATOI)
    output_buffer resb 64  ; for printing numbers (PRINT_NUMBER)

section .text
    global _start
    ;global asm_main 

;asm_main:
_start:
    xor rbx, rbx        ; running sum = 0
    mov r8d, 3          ; loop counter

GAME_LOOP:
    ; ---- CLEAR INPUT BUFFER ----
    mov byte [input_buffer], 0

    ; ---- PRINT PROMPT ----
    mov rax, 1
    mov rdi, 1
    mov rsi, PROMPT
    mov rdx, PROMPT_LEN
    syscall

    ; ---- READ FIRST NUMBER ----
    mov rax, 0
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 32
    syscall
    mov r12, rax        ; SAVE byte count in r12

    ; Parse first number
    mov rsi, input_buffer
    call ATOI_testable
    test rdi, rdi ; Better way to check error flag
    jnz INVALID_INPUT_HANDLER

    ; Bounds check
    cmp rax, -1000
    jl INVALID_INPUT_HANDLER
    cmp rax, 1000
    jg INVALID_INPUT_HANDLER

    mov r9, rax         ; SAVE FIRST NUMBER IN r9

    ; ---- CLEAR INPUT BUFFER ----
    mov byte [input_buffer], 0

    ; ---- PRINT PROMPT ----
    mov rax, 1
    mov rdi, 1
    mov rsi, PROMPT
    mov rdx, PROMPT_LEN
    syscall

    ; ---- READ SECOND NUMBER ----
    mov rax, 0
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 32
    syscall
    mov r12, rax        ; SAVE byte count

    mov rsi, input_buffer
    call ATOI_testable
    test rdi, rdi
    jnz INVALID_INPUT_HANDLER ; Jump to the handler if rdi != 0

    cmp rax, -1000
    jl INVALID_INPUT_HANDLER
    cmp rax, 1000
    jg INVALID_INPUT_HANDLER

    mov r10, rax        ; SAVE SECOND NUMBER IN r10

    ; ---- ADD THEM ----
    mov rdi, r9         ; First number
    mov rsi, r10        ; Second number
    call ADD_NUMBERS
    jc OVERFLOW_HANDLER ;Jump if Carry flag is set (our error signal)

    mov r13, rax  ;Use r13 (preserved across syscalls)

    ; ---- PRINT RESULT ----
    mov rsi, RESULT
    mov rdx, RESULT_LEN
    call PRINT_STRING

    mov rax, r13       ; Load sum for printing
    call PRINT_NUMBER
    call NEW_LINE

    ; ---- ADD TO RUNNING SUM ----
    add rbx, r13        ; rbx += current iteration sum

    ; ---- LOOP CONTROL ----
    dec r8d             ; Decrement loop counter
    jnz GAME_LOOP

    ; ---- FINAL RESULT ----
    mov rsi, FINAL_RESULT
    mov rdx, FINAL_LEN
    call PRINT_STRING

    mov rax, rbx        ; Load running sum
    call PRINT_NUMBER
    call NEW_LINE

    ; Exit
    mov rax, 60
    xor rdi, rdi
    syscall

; =========================
; HELPER FUNCTIONS
; =========================

PRINT_STRING:
    mov rax, 1
    mov rdi, 1
    syscall
    ret

NEW_LINE:
    mov rax, 1
    mov rdi, 1
    mov rsi, CRLF
    mov rdx, 1
    syscall
    ret

; ATOI - Parse string in buffer to integer
; Input: rsi = input_buffer
; Output: rax = number, rdi = error flag (0=success, 1=error)
ATOI_testable:
    push rbp
    mov rbp, rsp
    push r14        ; Use R14 as our sign flag instead of RBP
    xor rax, rax
    xor rcx, rcx
    xor rdi, rdi
    xor r14, r14    ; 0 = positive

    mov dl, [rsi]
    cmp dl, '-'
    jne .convert
    mov r14, 1      ; Mark as negative
    inc rcx

.convert:
    mov dl, [rsi + rcx]
    cmp dl, 10
    je .done
    cmp dl, 13
    je .done
    cmp dl, 32
    je .done
    test dl, dl     ; Null terminator check
    jz .done

    cmp dl, '0'
    jl .invalid
    cmp dl, '9'
    jg .invalid

    sub dl, '0'
    imul rax, rax, 10
    movzx rdx, dl
    add rax, rdx
    inc rcx
    jmp .convert

.invalid:
    mov rdi, 1      ; Set error flag
    jmp .exit

.done:
    test rcx, rcx
    jz .invalid
    cmp r14, 1      ; Check our sign flag
    jne .ok
    neg rax
.ok:
    xor rdi, rdi    ; success
.exit:
    pop r14         ; Restore r14
    pop rbp         ; Restore rbp
    ret

; PRINT_NUMBER - Print number in rax
; Uses output_buffer exclusively

PRINT_NUMBER:
    push r15   ;Dummy push for 16-byte alignment
    push rbx
    push rcx
    push rdx
    push rsi
    push rbp
    push r14        ; Use R14 for length instead of RBP
    push rax        ; Store the number to print (7 pushes + 1 for alignment later)

    ; 1. Clear output_buffer
    xor rax, rax
    mov rcx, 8
    lea rdi, [output_buffer]
    rep stosq

    mov rax, [rsp]  ; Peek at the saved RAX
    xor rcx, rcx
    test rax, rax
    jnz .check_sign

    mov byte [output_buffer], '0'
    mov rsi, output_buffer
    mov rdx, 1
    jmp .do_syscall

.check_sign:
    jns .convert    ; If positive, jump straight to convert
    
    push rcx    ;Save your digit counter
    mov byte [output_buffer + 63], '-'
    mov rax, 1
    mov rdi, 1
    lea rsi, [output_buffer + 63]
    mov rdx, 1
    syscall         ; Print '-'
    pop rcx  ;restore your digit counter

    mov rax, [rsp]
    neg rax         ; Make positive for conversion

.convert:
    mov rdi, 10
.next:
    xor rdx, rdx
    div rdi
    add dl, '0'
    mov [output_buffer + rcx], dl
    inc rcx
    test rax, rax
    jnz .next

    mov r14, rcx    ; SAVE length in R14 (NOT RBP!)
    xor rbx, rbx

.reverse_loop:
    dec rcx
    mov al, [output_buffer + rcx]
    mov [output_buffer + rbx + 32], al
    inc rbx
    test rcx, rcx
    jnz .reverse_loop

    lea rsi, [output_buffer + 32]
    mov rdx, r14    ; Use saved length

.do_syscall:
    mov rax, 1
    mov rdi, 1
    syscall

.full_exit:
    pop rax         ; Clean up the saved rax
    pop r14
    pop rbp
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop r15 ;Added Dummy pop 
    ret

;ADD_NUMBERS -Adds two numbers and checks for overflow
;Input: rdi = First Number, rsi =Second number
;Output: rax = Sum, r8 (or a flag) = Status
ADD_NUMBERS:
    push rbp
    mov rbp, rsp

    mov rax, rdi
    add rax, rsi
    jo .overflow_detected

    clc  ;Clear Carry/Error (Success)
    jmp .done

.overflow_detected:
    stc  ;Set Carry Flag (Error)

.done:
    pop rbp
    ret

INVALID_INPUT:
    mov rsi, ERR_MSG
    mov rdx, ERR_LEN
    call PRINT_STRING
    ; Clear the stack if necessary, or just ensure r8d is still valid 
    jmp GAME_LOOP

OVERFLOW_HANDLER:
    mov rsi, OVERFLOW_MSG
    mov rdx, OVERFLOW_LEN
    call PRINT_STRING
    mov rax, 60
    mov rdi, 1
    syscall

INVALID_INPUT_HANDLER:
    mov rsi, ERR_MSG
    mov rdx, ERR_LEN
    call PRINT_STRING
    jmp GAME_LOOP

global ATOI_C_Wrapper
ATOI_C_Wrapper:
    mov rsi, rdi  ;Move C's 1st arg (rdi) to your 1st arg (rsi)
    call ATOI_testable
    ; RAX already conatins the result for C to read 
    ret

global test_add_wrapper
test_add_wrapper:
    mov rdi, rdi ;1st arg (C passes in rdi)
    mov rsi, rsi ;2nd arg (C passes in rsi)
    call ADD_NUMBERS
    jc .err 
    ;rax already has the sum 
    ret 

.err:
    mov rax, -999 ;Special error code for C to catch
    ret

;This tells the linker that your stack should not be executable (standard security practice)
section .note.GNU-stack noalloc noexec nowrite progbits