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
- Callee-saved registers are saved/restored in function prologues/epilogues and in generated `main`
- Parameter registers are used for function calls following System V ABI
- Temporary registers are used for intermediate calculations

## Stack Frame Layout

### Main Program Stack Frame

```
High Addresses
+----------------+  
|    ...         |  
+----------------+  
|  Var/Array Slot N | - (48 + 8*N)
+----------------+  
|    ...         |  
+----------------+  
|  Var/Array Slot 1 | - 56
+----------------+  
|  Var/Array Slot 0 | - 48
+----------------+  
|    %r15        | - 40
+----------------+
|    %r14        | - 32
+----------------+
|    %r13        | - 24
+----------------+
|    %r12        | - 16
+----------------+
|    %rbx        | - 8
+----------------+
| saved %rbp     |  0
+----------------+  
| return address |  8
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
|  Local/Array Slot N | - (48 + 8*(ParamCount + N))
+----------------+  
|    ...         |  
+----------------+  
|  Local/Array Slot 1 | - (48 + 8*(ParamCount + 2))
+----------------+  
|  Local/Array Slot 0 | - (48 + 8*(ParamCount + 1))
+----------------+  
|  Param N       | - (48 + 8*N)
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

Function access to globals uses the recorded `main` frame pointer:

```assembly
movq main_frame_ptr(%rip), %r11
movq -N(%r11), %rax      ; load global
movq %rax, -N(%r11)      ; store global
```

Static arrays reserve one 8-byte slot per element. The first element is stored at the variable's base offset, and element `Index` is addressed as:

```assembly
; after checking Low <= Index <= High
subq $Low, %rax       ; zero-base the index
imulq $8, %rax        ; scale to slot size
movq %rbp, %r11       ; or main_frame_ptr(%rip) for globals from functions
subq $BaseOffset, %r11
subq %rax, %r11
movq (%r11), %rax     ; load element
```

Out-of-range indexes branch to `array_bounds_error`, which calls `rt_error` with runtime error code 3.

Records use the same slot model as arrays: each scalar or pointer field occupies one 8-byte slot, and nested record fields contribute their own slot counts. Field access is compiled as a fixed slot offset from the record base:

```assembly
; Load field at slot offset K from a record whose base offset is BaseOffset
movq -BaseOffset(%rbp), %rax          ; K = 0
movq -(BaseOffset + 8*K)(%rbp), %rax  ; K > 0

; Store field at slot offset K
movq %rax, -(BaseOffset + 8*K)(%rbp)
```

Pointer variables are 8-byte address values. Address-of expressions compute the address of a stack slot or record-field slot. Pointer dereference and pointer-field operations first load the pointer value, check it for `nil`, then access the target storage:

```assembly
; Load p^.field where field slot offset is K
movq -PointerOffset(%rbp), %r11
cmpq $0, %r11
je null_pointer_error
movq 8*K(%r11), %rax
```

The same null-pointer guard pattern is used for pointer-derived l-value addresses, scalar dereference (`p^`), pointer-field load/store (`p^.field`), and `var` arguments that pass `p^` or `p^.field`.

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

### Boolean Operations

Boolean values are represented as normalized integers: `0` for false and `1` for true. Generated `and` and `or` expressions normalize both operands before applying byte-level boolean operations, and `not` compares against zero before producing a normalized result.

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

### Null Pointer Dereference

Pointer dereference-sensitive operations branch to `null_pointer_error` when the pointer value is zero:

```assembly
cmpq $0, %r11
je null_pointer_error
```

The handler calls `rt_error` with runtime error code 4. This protects `p^`, `p^.field`, pointer-derived `var` arguments, and pointer-derived allocation targets.

### Heap Allocation and Free

Pascal `new(p)` and `dispose(p)` are lowered to runtime calls:

```assembly
; new(p): allocate target size in bytes and store returned pointer in p
movq $ByteSize, %rdi
call rt_alloc
movq %rax, -PointerOffset(%rbp)

; dispose(p): free pointer value
movq -PointerOffset(%rbp), %rdi
call rt_free
```

Record allocation sizes are computed from the target type's slot count multiplied by 8 bytes.

## Assembly Structure

### Generated Assembly Sections

1. **Data Section**: String literals and `main_frame_ptr`, which lets functions access globals stored in `main`'s frame
2. **Text Section**: Executable code
3. **Main Function**: Program entry point
4. **Generated Functions**: User-defined functions
5. **Error Handlers**: Stack overflow, division by zero, array-bounds, and null-pointer handlers

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
- **Register Preservation**: Callee-saved registers are preserved in generated functions and generated `main`
- **Return Values**: Scalar results in `%rax`
- **Global Access**: Generated `main` records `%rbp` in `main_frame_ptr`; functions use it to read and write global variables
- **Aggregate Layout**: Static arrays and records are represented as contiguous 8-byte stack slots
- **Pointer Safety**: Typed pointer dereferences check for `nil` before accessing memory

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
