; ============================================================
; Secure x86-64 Assembly Implementation
; Converted from 68k with Security Fixes
; ============================================================
; Author: Oyindamola Olaosun
; Date: 29th April 2026
;
; Program Description:
;   - Loops 3 times, reading two numbers per iteration
;   - Validates input using ATOI function
;   - Adds two numbers with overflow detection
;   - Maintains a running sum across all iterations
;   - Displays iteration results and final accumulated sum
;
; Key Features:
;   * Input validation (bounds checking: -1000 to 1000)
;   * Integer overflow detection using CPU flags
;   * Secure stack alignment
;   * Non-executable stack (GNU-stack standard)
; ============================================================


; ============================================================
; DATA SECTION - String Constants and Messages
; ============================================================

section .data
    ; User prompts
    PROMPT          db "Enter number: ", 0
    PROMPT_LEN      equ $-PROMPT

    ; Output messages
    RESULT          db "The sum is: ", 0
    RESULT_LEN      equ $-RESULT

    FINAL_RESULT    db "Final sum is: ", 0
    FINAL_LEN       equ $-FINAL_RESULT

    ; Error messages
    ERR_MSG         db "Invalid input", 10
    ERR_LEN         equ $-ERR_MSG

    OVERFLOW_MSG    db "Overflow detected", 10
    OVERFLOW_LEN    equ $-OVERFLOW_MSG

    ; Line feed character
    CRLF            db 10


; ============================================================
; BSS SECTION - Uninitialized Data (Runtime Buffers)
; ============================================================

section .bss
    input_buffer    resb 64         ; Buffer for reading user input
    output_buffer   resb 64         ; Buffer for converting numbers to strings


; ============================================================
; TEXT SECTION - Executable Code
; ============================================================

section .text
    global _start
    global ATOI_testable
    global ATOI_C_Wrapper
    global test_add_wrapper


; ============================================================
; MAIN PROGRAM ENTRY POINT
; ============================================================

_start:
    ; Initialize registers
    xor rbx, rbx                    ; RBX = running sum (accumulated across iterations)
    mov r8d, 3                      ; R8D = loop counter (3 iterations)


; ============================================================
; MAIN LOOP - Execute 3 times
; ============================================================

GAME_LOOP:
    ; ---- Iteration Setup ----
    mov byte [input_buffer], 0      ; Clear input buffer for first number


    ; ====== READ FIRST NUMBER ======

    ; Print prompt for first number
    mov rax, 1                      ; Syscall: write
    mov rdi, 1                      ; File descriptor: stdout
    mov rsi, PROMPT                 ; Address of prompt string
    mov rdx, PROMPT_LEN             ; Length of prompt
    syscall


    ; Read input from user (stdin)
    mov rax, 0                      ; Syscall: read
    mov rdi, 0                      ; File descriptor: stdin
    mov rsi, input_buffer           ; Address to store input
    mov rdx, 32                     ; Max bytes to read
    syscall
    mov r12, rax                    ; R12 = bytes read (for reference)


    ; Parse first number using ATOI function
    mov rsi, input_buffer           ; Load input buffer address
    call ATOI_testable              ; Convert ASCII to integer
    test rdi, rdi                   ; Check error flag (rdi: 0=success, 1=error)
    jnz INVALID_INPUT_HANDLER       ; If error, handle invalid input


    ; Validate first number is within acceptable range [-1000, 1000]
    cmp rax, -1000
    jl INVALID_INPUT_HANDLER        ; If less than -1000, error
    cmp rax, 1000
    jg INVALID_INPUT_HANDLER        ; If greater than 1000, error

    mov r9, rax                     ; R9 = first number (save for ADD_NUMBERS)


    ; ====== READ SECOND NUMBER ======

    ; Clear input buffer for second number
    mov byte [input_buffer], 0


    ; Print prompt for second number
    mov rax, 1                      ; Syscall: write
    mov rdi, 1                      ; File descriptor: stdout
    mov rsi, PROMPT                 ; Address of prompt string
    mov rdx, PROMPT_LEN             ; Length of prompt
    syscall


    ; Read second input from user
    mov rax, 0                      ; Syscall: read
    mov rdi, 0                      ; File descriptor: stdin
    mov rsi, input_buffer           ; Address to store input
    mov rdx, 32                     ; Max bytes to read
    syscall
    mov r12, rax                    ; R12 = bytes read


    ; Parse second number using ATOI function
    mov rsi, input_buffer           ; Load input buffer address
    call ATOI_testable              ; Convert ASCII to integer
    test rdi, rdi                   ; Check error flag
    jnz INVALID_INPUT_HANDLER       ; If error, handle invalid input


    ; Validate second number is within acceptable range
    cmp rax, -1000
    jl INVALID_INPUT_HANDLER
    cmp rax, 1000
    jg INVALID_INPUT_HANDLER

    mov r10, rax                    ; R10 = second number (save for ADD_NUMBERS)


    ; ====== ADD THE TWO NUMBERS ======

    mov rdi, r9                     ; RDI = first number (function parameter)
    mov rsi, r10                    ; RSI = second number (function parameter)
    call ADD_NUMBERS                ; Call addition with overflow detection
    jc OVERFLOW_HANDLER             ; Jump if carry flag set (overflow occurred)

    mov r13, rax                    ; R13 = sum of current iteration


    ; ====== DISPLAY ITERATION RESULT ======

    ; Print "The sum is: " message
    mov rsi, RESULT
    mov rdx, RESULT_LEN
    call PRINT_STRING


    ; Print the calculated sum
    mov rax, r13                    ; Load sum into RAX for printing
    call PRINT_NUMBER


    ; Print newline after result
    call NEW_LINE


    ; ====== ADD TO RUNNING TOTAL ====

    add rbx, r13                    ; RBX (running sum) += current iteration sum


    ; ====== LOOP CONTROL ====

    dec r8d                         ; Decrement loop counter
    jnz GAME_LOOP                   ; If counter != 0, repeat loop


    ; ============================================================
    ; POST-LOOP: DISPLAY FINAL RESULT
    ; ============================================================

    ; Print "Final sum is: " message
    mov rsi, FINAL_RESULT
    mov rdx, FINAL_LEN
    call PRINT_STRING


    ; Print the accumulated sum across all iterations
    mov rax, rbx                    ; Load running sum into RAX for printing
    call PRINT_NUMBER


    ; Print newline after final result
    call NEW_LINE


    ; ====== PROGRAM EXIT ====

    mov rax, 60                     ; Syscall: exit
    xor rdi, rdi                    ; Exit code: 0 (success)
    syscall


; ============================================================
; HELPER FUNCTIONS
; ============================================================


; ============================================================
; FUNCTION: PRINT_STRING
; ============================================================
; Purpose: Output a string to stdout using syscall
; Input:   RSI = pointer to string
;          RDX = length of string
; Output:  None
; Modifies: RAX, RDI, RSI, RDX (syscall clobbered)
; ============================================================

PRINT_STRING:
    mov rax, 1                      ; Syscall: write
    mov rdi, 1                      ; File descriptor: stdout
    syscall                         ; Execute syscall (RSI and RDX already set)
    ret


; ============================================================
; FUNCTION: NEW_LINE
; ============================================================
; Purpose: Output a single newline character
; Input:   None
; Output:  None
; Modifies: RAX, RDI, RSI, RDX (syscall clobbered)
; ============================================================

NEW_LINE:
    mov rax, 1                      ; Syscall: write
    mov rdi, 1                      ; File descriptor: stdout
    mov rsi, CRLF                   ; Address of newline character
    mov rdx, 1                      ; Write 1 byte
    syscall
    ret


; ============================================================
; FUNCTION: ATOI_testable
; ============================================================
; Purpose: Convert null-terminated ASCII string to integer
;
; Input:   RSI = pointer to input string
;
; Output:  RAX = converted integer value
;          RDI = error flag (0 = success, 1 = error)
;
; Behavior:
;   - Handles optional leading minus sign
;   - Stops parsing at newline, carriage return, or null terminator
;   - Validates all characters are digits
;   - Returns error if string is empty or contains non-digits
;
; Register Preservation: RBP (push/pop)
; Local Registers: R14 (sign flag: 0=positive, 1=negative)
; ============================================================

ATOI_testable:
    push rbp
    mov rbp, rsp
    push r14                        ; Save R14 for sign flag

    ; Initialize working registers
    xor rax, rax                    ; RAX = result (start at 0)
    xor rcx, rcx                    ; RCX = string index
    xor rdi, rdi                    ; RDI = error flag (0 = no error)
    xor r14, r14                    ; R14 = sign flag (0 = positive)


    ; ---- Check for leading minus sign ----

    mov dl, [rsi]                   ; Load first character
    cmp dl, '-'                     ; Is it a minus sign?
    jne .convert                    ; No, skip sign handling


    mov r14, 1                      ; Yes, set sign flag to negative
    inc rcx                         ; Move past the minus sign


    ; ---- Convert ASCII digits to integer ----

.convert:
    mov dl, [rsi + rcx]             ; Load current character

    ; Check for string terminators (newline, carriage return, space, null)
    cmp dl, 10                      ; Is it newline?
    je .done

    cmp dl, 13                      ; Is it carriage return?
    je .done

    cmp dl, 32                      ; Is it space?
    je .done

    test dl, dl                     ; Is it null terminator?
    jz .done


    ; ---- Validate character is a digit ----

    cmp dl, '0'                     ; Is character < '0'?
    jl .invalid

    cmp dl, '9'                     ; Is character > '9'?
    jg .invalid


    ; ---- Add digit to result ----

    sub dl, '0'                     ; Convert ASCII to digit value
    imul rax, rax, 10               ; Multiply result by 10
    movzx rdx, dl                   ; Zero-extend digit to 64-bit
    add rax, rdx                    ; Add digit to result
    inc rcx                         ; Move to next character
    jmp .convert                    ; Continue parsing


    ; ---- Error handling: invalid input ----

.invalid:
    mov rdi, 1                      ; Set error flag
    jmp .exit


    ; ---- Validation and sign application ----

.done:
    test rcx, rcx                   ; Was any character parsed?
    jz .invalid                     ; If not, it's an error

    cmp r14, 1                      ; Check sign flag
    jne .ok                         ; If positive, we're done

    neg rax                         ; If negative, negate the result


    ; ---- Success: return with no error ----

.ok:
    xor rdi, rdi                    ; Clear error flag


    ; ---- Exit function ----

.exit:
    pop r14                         ; Restore R14
    pop rbp                         ; Restore RBP
    ret


; ============================================================
; FUNCTION: PRINT_NUMBER
; ============================================================
; Purpose: Convert integer in RAX to decimal ASCII and print
;
; Input:   RAX = integer to print (can be negative)
;
; Output:  None (prints to stdout)
;
; Algorithm:
;   1. Handle special case: zero
;   2. Handle sign separately (print minus, work with absolute value)
;   3. Extract digits using repeated division by 10
;   4. Reverse digit sequence and print
;
; Register Preservation: Most registers (push/pop)
; Working Registers: RCX (digit counter), RDX (remainder from division)
;                    RBX (reverse counter), R14 (digit count)
; ============================================================

PRINT_NUMBER:
    push r15                        ; Dummy push for 16-byte stack alignment
    push rbx
    push rcx
    push rdx
    push rsi
    push rbp
    push r14                        ; R14 stores digit count
    push rax                        ; Save original number


    ; ---- Clear output buffer ----

    xor rax, rax
    mov rcx, 8                      ; Clear 8 qwords (64 bytes)
    lea rdi, [output_buffer]
    rep stosq                       ; Fill with zeros


    ; ---- Check for zero ----

    mov rax, [rsp]                  ; Retrieve saved number
    xor rcx, rcx                    ; RCX = digit counter
    test rax, rax                   ; Is the number zero?
    jnz .check_sign                 ; No, check for negative


    ; Special case: zero
    mov byte [output_buffer], '0'   ; Place '0' in buffer
    mov rsi, output_buffer
    mov rdx, 1                      ; Write 1 byte
    jmp .do_syscall


    ; ---- Check if negative ----

.check_sign:
    jns .convert                    ; If positive, skip to conversion


    ; Handle negative number
    push rcx                        ; Save digit counter
    mov byte [output_buffer + 63], '-'  ; Place minus sign
    mov rax, 1                      ; Syscall: write
    mov rdi, 1                      ; File descriptor: stdout
    lea rsi, [output_buffer + 63]   ; Address of minus sign
    mov rdx, 1                      ; Write 1 byte
    syscall                         ; Print minus sign

    pop rcx                         ; Restore digit counter
    mov rax, [rsp]                  ; Retrieve number again
    neg rax                         ; Make positive for digit extraction


    ; ---- Extract digits from right to left ----

.convert:
    mov rdi, 10                     ; Divisor = 10


.next:
    xor rdx, rdx                    ; Clear RDX (for division)
    div rdi                         ; RAX / 10 -> quotient in RAX, remainder in RDX
    add dl, '0'                     ; Convert remainder to ASCII digit
    mov [output_buffer + rcx], dl   ; Store digit in buffer
    inc rcx                         ; Increment digit counter
    test rax, rax                   ; Is quotient zero? (all digits extracted?)
    jnz .next                       ; No, continue extracting


    ; ---- Reverse digits (they were stored backwards) ----

    mov r14, rcx                    ; R14 = total digit count
    xor rbx, rbx                    ; RBX = output position (starts at 0)


.reverse_loop:
    dec rcx                         ; Move backwards through extracted digits
    mov al, [output_buffer + rcx]   ; Load digit
    mov [output_buffer + rbx + 32], al  ; Store in reverse position (buffer offset 32)
    inc rbx                         ; Move forward in output
    test rcx, rcx                   ; Have we reversed all digits?
    jnz .reverse_loop               ; No, continue reversing


    ; ---- Prepare to print reversed digits ----

    lea rsi, [output_buffer + 32]   ; Address of reversed digits
    mov rdx, r14                    ; RDX = number of digits


    ; ---- Print the number ----

.do_syscall:
    mov rax, 1                      ; Syscall: write
    mov rdi, 1                      ; File descriptor: stdout
    syscall


    ; ---- Clean up and return ----

.full_exit:
    pop rax                         ; Clean up saved RAX
    pop r14
    pop rbp
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop r15                         ; Remove dummy alignment push
    ret


; ============================================================
; FUNCTION: ADD_NUMBERS
; ============================================================
; Purpose: Add two integers with overflow detection
;
; Input:   RDI = first number
;          RSI = second number
;
; Output:  RAX = sum (if no overflow)
;          Carry Flag = set if overflow occurred, clear if success
;
; Algorithm:
;   - Perform addition: RAX = RDI + RSI
;   - Check overflow flag (OF) set by the add operation
;   - Set carry flag if overflow detected (for error signaling)
;
; Note: x86-64 'add' sets overflow flag when signed overflow occurs
; ============================================================

ADD_NUMBERS:
    push rbp
    mov rbp, rsp

    ; Perform addition and check for overflow
    mov rax, rdi                    ; RAX = first number
    add rax, rsi                    ; RAX += second number
    jo .overflow_detected           ; Jump if overflow flag set


    ; ---- No overflow: return success ----

    clc                             ; Clear carry flag (0 = success)
    jmp .done


    ; ---- Overflow detected: signal error ----

.overflow_detected:
    stc                             ; Set carry flag (1 = error)


    ; ---- Exit function ----

.done:
    pop rbp
    ret


; ============================================================
; ERROR HANDLERS
; ============================================================


; ============================================================
; HANDLER: INVALID_INPUT_HANDLER
; ============================================================
; Purpose: Handle invalid user input
; Action:  Print error message and return to main loop
; ============================================================

INVALID_INPUT_HANDLER:
    mov rsi, ERR_MSG                ; Error message address
    mov rdx, ERR_LEN                ; Error message length
    call PRINT_STRING               ; Print error
    jmp GAME_LOOP                   ; Return to main loop for retry


; ============================================================
; HANDLER: OVERFLOW_HANDLER
; ============================================================
; Purpose: Handle integer overflow detected during addition
; Action:  Print overflow message and exit program with error code
; ============================================================

OVERFLOW_HANDLER:
    mov rsi, OVERFLOW_MSG           ; Overflow message address
    mov rdx, OVERFLOW_LEN           ; Overflow message length
    call PRINT_STRING               ; Print error message

    ; Exit with error code
    mov rax, 60                     ; Syscall: exit
    mov rdi, 1                      ; Exit code: 1 (error)
    syscall


; ============================================================
; C WRAPPER FUNCTIONS
; ============================================================
; These functions allow the assembly code to be called from C
; They adapt C's calling convention to our assembly conventions


; ============================================================
; FUNCTION: ATOI_C_Wrapper
; ============================================================
; Purpose: C-compatible wrapper for ATOI_testable
;
; C Calling Convention:
;   Input:  RDI = string pointer (from C)
;   Output: RAX = result (returned to C)
;
; Conversion:
;   C passes first arg in RDI, but ATOI expects it in RSI
;   So we move RDI -> RSI before calling ATOI_testable
; ============================================================

ATOI_C_Wrapper:
    mov rsi, rdi                    ; Move C's first arg (RDI) to our convention (RSI)
    call ATOI_testable              ; Call ATOI function
    ; RAX already contains result for C to read
    ret


; ============================================================
; FUNCTION: test_add_wrapper
; ============================================================
; Purpose: C-compatible wrapper for ADD_NUMBERS
;
; C Calling Convention:
;   Input:  RDI = first number, RSI = second number
;   Output: RAX = sum (if success), -999 (if overflow)
;
; Note: C's convention already passes args in RDI, RSI
;       so we just need to check carry flag and convert to error code
; ============================================================

test_add_wrapper:
    mov rdi, rdi                    ; First arg (C passes in RDI) - already in place
    mov rsi, rsi                    ; Second arg (C passes in RSI) - already in place
    call ADD_NUMBERS                ; Call addition function
    jc .err                         ; Jump if carry flag set (error)

    ; Success: RAX already contains sum
    ret


    ; Error case: return special error code
.err:
    mov rax, -999                   ; Return -999 to signal error to C
    ret


; ============================================================
; LINKER DIRECTIVES & SECURITY SETTINGS
; ============================================================

; This section tells the linker that the stack should NOT be executable
; This is a standard security practice that prevents stack-based code execution attacks
section .note.GNU-stack noalloc noexec nowrite progbits
