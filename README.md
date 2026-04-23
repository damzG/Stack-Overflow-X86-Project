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
