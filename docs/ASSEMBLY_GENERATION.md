# Assembly Generation

This document describes how the Pascal-Prolog compiler generates x86-64 assembly code from the Intermediate Representation (IR).

## Overview

The assembly generator translates IR statements and expressions into x86-64 assembly code following the System V AMD64 ABI. The generated code uses a combination of register-based operations and stack-based memory accesses.

## Register Allocation Strategy

### Available Registers

The compiler uses the following x86-64 registers:

- `%rax`: Result register (always used for expression results)
- `%rbx`, `%r12-%r15`: Callee-saved registers for temporary values
- `%rdi`, `%rsi`, `%rdx`, `%rcx`, `%r8`, `%r9`: Parameter registers (System V ABI)
- `%r10`, `%r11`: Temporary registers for complex operations
- `%rbp`: Base pointer for stack frame
- `%rsp`: Stack pointer

### Register Allocation Algorithm

1. **Initialization**: Mark callee-saved registers as available
2. **Allocation**: When a temporary register is needed, prefer registers in this order: `%r12`, `%r13`, `%r14`, `%r15`, `%rbx`
3. **Fallback**: If no registers are available, use stack-based operations with `%r10`
4. **Release**: Free registers when they're no longer needed

### Register Usage Rules

- `%rax` is always used for expression results
- Callee-saved registers are saved/restored in function prologues/epilogues
- Parameter registers are used for function calls following System V ABI
- Temporary registers are used for intermediate calculations

## Stack Frame Layout

### Main Program Stack Frame

```
High Addresses
+----------------+  
|    ...         |  
+----------------+  
|  Local Var N   | - (16 + 8*N)
+----------------+  
|    ...         |  
+----------------+  
|  Local Var 1   | - 24
+----------------+  
|  Local Var 0   | - 16
+----------------+  
|    %rbp        | - 8 (saved base pointer)
+----------------+  
|    %rip        |  0 (return address)
+----------------+  
|    ...         |  
Low Addresses
```

### Function Stack Frame

```
High Addresses
+----------------+  
|    ...         |  
+----------------+  
|  Local Var N   | - (48 + 8*(ParamCount + LocalCount + N))
+----------------+  
|    ...         |  
+----------------+  
|  Local Var 1   | - (48 + 8*(ParamCount + LocalCount + 1))
+----------------+  
|  Local Var 0   | - (48 + 8*(ParamCount + LocalCount))
+----------------+  
|  Param N       | - (48 + 8*(ParamCount + N))
+----------------+  
|    ...         |  
+----------------+  
|  Param 1       | - 56
+----------------+  
|  Return Value  | - 48 (function name variable)
+----------------+  
|    %r15        | - 40 (saved callee-saved)
+----------------+  
|    %r14        | - 32
+----------------+  
|    %r13        | - 24
+----------------+  
|    %r12        | - 16
+----------------+  
|    %rbx        | - 8
+----------------+  
|    %rbp        |  0 (saved base pointer)
+----------------+  
|    %rip        |  8 (return address)
+----------------+  
|    ...         |  
Low Addresses
```

## Assembly Generation Patterns

### Variable Access

```assembly
; Load variable at offset N from %rbp into %rax
movq -N(%rbp), %rax

; Store %rax into variable at offset N from %rbp
movq %rax, -N(%rbp)
```

### Arithmetic Operations

```assembly
; Addition with register
movq %rax, %r12    ; Save left operand
; ... evaluate right operand ...
addq %r12, %rax    ; Add saved value to result

; Addition with stack fallback
pushq %rax         ; Save left operand
; ... evaluate right operand ...
popq %r10          ; Restore left operand
addq %r10, %rax     ; Add to result
```

### Function Calls

```assembly
; Save current stack pointer
movq %rsp, %r11
; Align stack to 16 bytes
andq $-16, %rsp
; Allocate shadow space
subq $16, %rsp
; Save original stack pointer
movq %r11, 8(%rsp)
; Call function
call function_name
; Restore stack pointer
movq 8(%rsp), %rsp
```

### Comparison Operations

```assembly
; Compare two values
movq %rax, %r12    ; Save left operand
; ... evaluate right operand ...
cmpq %rax, %r12    ; Compare
sete %al           ; Set %al based on comparison
movzbq %al, %rax   ; Zero-extend to %rax
```

## Error Handling

### Stack Overflow

The compiler includes stack overflow protection:

```assembly
stack_overflow:
    movq $1, %rdi
    leaq overflow_msg(%rip), %rsi
    call rt_error
```

### Division by Zero

Division operations include zero checks:

```assembly
movq %rax, %r11
cmpq $0, %r11
je division_by_zero
; ... perform division ...
```

## Assembly Structure

### Generated Assembly Sections

1. **Data Section**: String literals and constants
2. **Text Section**: Executable code
3. **Main Function**: Program entry point
4. **Generated Functions**: User-defined functions
5. **Error Handlers**: Stack overflow and division by zero handlers

### Assembly Generation Process

1. **Header Generation**: Set up data and text sections
2. **Data Generation**: Emit string literals and constants
3. **Main Stack Frame**: Set up stack frame for main program
4. **Statement Translation**: Convert IR statements to assembly
5. **Function Generation**: Generate assembly for each function
6. **Error Handlers**: Add runtime error handlers

## ABI Compliance

The generated code follows the System V AMD64 ABI:

- **Calling Convention**: First 6 parameters in registers, rest on stack
- **Stack Alignment**: 16-byte alignment before function calls
- **Register Preservation**: Callee-saved registers preserved across calls
- **Return Values**: Integer results in `%rax`

## Optimization Notes

The current implementation focuses on correctness over optimization:

- Register allocation is simple but effective
- Common subexpression elimination is not performed
- Instruction scheduling is basic
- No peephole optimizations are applied

Future optimizations could include:
- More sophisticated register allocation
- Constant folding and propagation
- Dead code elimination
- Loop optimizations