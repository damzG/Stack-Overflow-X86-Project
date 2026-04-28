# Project II - Convert 68000 Assembly Code to x86_64

# Description
Demonstrates passing parameters using registers and stack, performing arithmetic operations and running a loop to keep
a running sum.

# 68K Source Code
This program:
Runs a loop 3 times
Each time:
  Prompts the user for two numbers
  Adds them using a subroutine (REGISTER_ADDER)
  Adds the result to a running total
After the loop, prints the final sum

# Vulnerability 1
If the string at PROMPT, RESULT, FINAL_RESULT, CRLF, ERR_MSG is not properly terminated, the TRAP will continue reading past the intended data.
Fix: Creating a VALIDATE_A1 to check if the address register has been tampered with.

# Vulnerability 2
No input Validation
It accepts anything. No check for: Overflow, negative numbers, non-numeric input
Fix: Setting a range between 0 - 1000 (bounds)

# Vulnerability 3
Arithmetic Overflow
No overflow detection and could wrap around silently
Fix: BVS checks for signed overflow, the 'branches' to a overflow handler

# x86_64
Mapping to x86_64
D1  ----> RAX/RDI/RSI
D2  ---->  RBX/RDX
D3  ---->  RCX
A1  ----> RDI

68k 
BSR FUNC:
RTS

x86_64
call func
ret
Return address is pushed to stack
RTS Pops it


# Tools & Resources
WSL
nasm 
gdb (debugger)
68000 assembly source code

# Errors/Challenges
1. Register Corruption: I saved the first number in rdx, but then the syscall read instruction overwrote rdx with 32. I fixed this by using r9 and r10 for the input numbers.
2. Loop Counter Corruption: I used rcx as the loop counter, but PRINT_NUMBER also used rcx. This corrupted the loop count. I moved the loop counter to r8d instead.
3. Missing Register Preservation: Functions that use registers borrowed from the caller should save and restore them using push/pop. I added proper push/pop pairs to PRINT_NUMBER.
4. Destroyed by Syscalls: rax (holds return value), rcx, r11
5. Stack Imbalance: segmentation fault is occurring becuase of how the stack is handled in the PRINT_NUMBER function.
6. Issue where I tested, 10 + 9, it gave 91
7. Issue where I tested -10 + 5, segfault occurred

# Solution
Corrected the PRINT_NUMBER routine
Pushed and popped the  registers in corresponding order
used other general purposes registers like r8, r13 because of syscalls

# Test Plan
| Category | Test Case | Input | Expected Output |
| -------- | --------- | ----- | --------------- |
| Basic    | Simple Addition | "5, 5" | The sum is: 10 |
| Boundary | Maximum Limit | "1000, 1000" | The sum is: 2000 |
| Negative | Negative Addition | "-100, -50" | The sum is: -150 |
| Security | Integer Overflow | "9223372036854775807, 1", | Overflow detected |
| Security | Buffer Overflow | 100+ characters | Invalid input |
| Input | Non-numeric | "abc, 12e4" | Invalid input |

# To run test file (ATOI, add)
Step 1: Assemble
nasm -f elf64 project2.asm -o project2.o

Step 2: Compile & Link with C
gcc -no-pie test_suite.c project2.o -o test_runner
gcc -no-pie test_add.c project2.o -o add_tester

Step 3: Run
./test_runner
./add_tester
