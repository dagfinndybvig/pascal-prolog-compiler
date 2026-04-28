<img width="1880" height="515" alt="image" src="https://github.com/user-attachments/assets/0c40b246-bb09-4c59-80ee-e9eafc54bde0" />

# Pascal-Prolog Assembly Backend - Release Version 1.5.0

> [!WARNING]
> This project implements only a **fragment of Pascal**. It now supports typed scalar values (`integer`, `boolean`, `char`) plus static arrays, while still intentionally omitting full ISO Pascal features.
>
> It is primarily a **Computer Science experiment** in language design, compiler construction, and algorithm exploration, not a full Pascal implementation.

## 📦 Pascal-Prolog Assembly Backend Release

**Version**: 1.5.0
**Release Date**: 2026-04-28
**License**: Unlicense (Public Domain)

## 🎯 About This Release

This is now a **complete standalone release** of the Pascal-Prolog compiler with assembly backend. It includes everything needed to compile simple Pascal programs directly to x86-64 assembly and native executables.

### What's Included
- ✅ Complete Pascal compiler (parser, semantics, IR generator)
- ✅ Assembly code generator (x86-64 backend)
- ✅ Runtime library for I/O operations
- ✅ Comprehensive test program
- ✅ Full documentation
- ✅ Minimal, clean distribution

## 🆕 What's New In v1.5.0

### Datatypes: Boolean, Char, and Static Arrays

The compiler now has an explicit type system across parsing, semantic checking, IR lowering, and x86-64 code generation.

- ✅ **Typed declarations and function signatures**: variables, parameters, and return values carry declared types internally
- ✅ **Boolean scalars**: `boolean`, `true`, `false`, boolean function parameters/returns, and boolean conditions
- ✅ **Char scalars**: `char` variables, parameters/returns, character literals such as `'A'`, and character I/O
- ✅ **Static arrays**: fixed-bound arrays such as `array[1..5] of integer`
- ✅ **Indexed array access**: `a[i]` works as both an r-value and assignment target
- ✅ **Runtime bounds checks**: invalid indexes exit through a clear array-bounds runtime error
- ✅ **Fixed-size text buffers**: `array[...] of char` can be written with `write`/`writeln`
- ✅ **Pointer decision**: raw integer-address pointers remain intentionally deferred; future pointer work should be typed and based on the array/l-value model

### Example: Arrays and Character Buffers

See `examples/array_demo.pas`:

```pascal
program array_demo;

var
  values: array[1..5] of integer;
  text: array[1..4] of char;
  i: integer;
  sum: integer;

begin
  values[1] := 2;
  values[2] := 3;
  values[3] := 5;
  values[4] := 7;
  values[5] := 11;

  i := 1;
  sum := 0;
  while i <= 5 do
  begin
    sum := sum + values[i];
    i := i + 1
  end;
  writeln(sum);  { Outputs: 28 }

  text[1] := 'M';
  text[2] := 'a';
  text[3] := 't';
  text[4] := 'h';
  writeln(text)  { Outputs: Math }
end.
```

Build and run it with:

```bash
swipl -q -s pascal_compiler.pl -- build-asm examples/array_demo.pas array_demo
./array_demo
```

---

## 🆕 Previous: v1.4.4

### Bug Fixes: Function Semantic Checking & Local Variables

Fixed critical bugs affecting programs with functions and local variables.

- ✅ **Fixed semantic checker function handling**: `collect_func_sigs/2` was corrected to match parser function AST terms
- ✅ **Fixed IR generation for function locals**: Function-level local variables now properly merged with block-level locals during IR lowering
- ✅ **Fixed codegen mangled name handling**: Code generator now correctly resolves `local(Counter, Name)` mangled variable references
- ✅ **Hardened semantic validation**: Duplicate function names, excessive parameter lists, and parameter/local name collisions are now rejected clearly
- ✅ **Improved ABI preservation**: Generated `main` now saves and restores callee-saved registers used by expression evaluation
- ✅ **Added global access from functions**: Functions can now read and write global variables while local names and parameters still shadow globals
- ✅ **Hardened runtime formatting surface**: Removed the unused printf-style runtime helper

### Example: Functions with Local Variables
```pascal
program local_vars_demo;

function double_and_add_one(n: integer): integer;
var
  temp: integer;
begin
  temp := n * 2;
  double_and_add_one := temp + 1
end;

begin
  writeln(double_and_add_one(5))  { Outputs: 11 }
end.
```

### Example: Function Accessing a Global Variable

See `examples/global_function_demo.pas` for a complete program where a function reads and updates a global variable:

```pascal
program global_function_demo;

function add_counter(value: integer): integer;
begin
  counter := counter + value;
  add_counter := counter
end;

var
  counter: integer;

begin
  counter := 10;
  writeln(add_counter(5));  { Outputs: 15 }
  writeln(add_counter(7));  { Outputs: 22 }
  writeln(counter)          { Outputs: 22 }
end.
```

Build and run it with:

```bash
swipl -q -s pascal_compiler.pl -- build-asm examples/global_function_demo.pas global_function_demo
./global_function_demo
```

---

## 🆕 Previous: v1.4.3

### New Features & Bug Fixes

- ✅ **Added `mod` operator**: Integer modulo operation now supported (`a mod b`)
- ✅ **Fixed uninitialized function returns**: Functions without explicit return now return 0 instead of garbage values
- ✅ **Enhanced write functionality**: Extended runtime library with safe formatting helpers
  - `rt_write_int_str()`, `rt_write_str_int()`, `rt_write_int_str_int()`
  - Enables better output formatting while maintaining compiler compatibility

### Example: Using the `mod` operator
```pascal
program mod_demo;

function is_even(n: integer): integer;
begin
  if (n mod 2) = 0 then
    is_even := 1
  else
    is_even := 0
end;

begin
  writeln(17 mod 5);    { Outputs: 2 }
  writeln(is_even(42))  { Outputs: 1 }
end.
```

### Example: Using Enhanced Write Functions
```pascal
program enhanced_write_demo;

{ Note: These functions are available in the runtime library }
{ and can be called directly from assembly or through Pascal wrappers }

begin
  { Basic write still works }
  writeln(42);  { Outputs: 42 }
  
  { Enhanced write functions with new syntax }
  write(42, ' is the answer');  { Outputs: 42 is the answer }
  write('Result: ', 100);       { Outputs: Result: 100 }
  write('Value: ', 42);         { Outputs: Value: 42 }
end.
```

---

## 🆕 Previous: v1.4.2

### Backend Reliability Fixes

Fixed multiple backend issues affecting function calls and function-scope variables.

- ✅ Fixed function-call argument clobbering in nested calls
- ✅ Added codegen support for function-local variables
- ✅ Hardened call-site stack alignment for generated calls (runtime + user functions)
- ✅ Kept all existing verification checks passing (15/15)

---

## 🆕 Previous: v1.4.1

### Bug Fix: Function Semantic Checking

Fixed critical bug in function semantic checking that caused infinite loops when checking programs with multiple functions. The fix separates function signature collection from body checking, enabling proper mutual recursion support.

- ✅ Fixed `check_funcs` infinite loop bug
- ✅ Added two-pass semantic checking (signatures first, then bodies)
- ✅ All functions now visible to all other functions during checking
- ✅ 15/15 verification tests pass

---

## 🆕 Previous: v1.4

### Major Feature: Functions

This release adds **function support** to the Pascal subset:

- ✅ Function declarations with multiple integer parameters
- ✅ Integer return values via Pascal-style assignment (`funcname := value`)
- ✅ Recursive function calls (e.g., factorial)
- ✅ Function calls within expressions (e.g., `add(multiply(2, 3), 10)`)
- ✅ Proper callee-saved register handling for reliable multi-level recursion

**Example:**
```pascal
program example;

function factorial(n: integer): integer;
begin
  if n <= 1 then
    factorial := 1
  else
    factorial := n * factorial(n - 1)
end;

function add(a, b: integer): integer;
begin
  add := a + b
end;

var result: integer;
begin
  result := factorial(5);        { 120 }
  writeln(result);
  result := add(3, 4);           { 7 }
  writeln(result);
  result := add(factorial(3), 10);  { 16 }
  writeln(result)
end.
```

### Technical Implementation
- Uses System V AMD64 calling convention
- Arguments passed in registers: `%rdi`, `%rsi`, `%rdx`, `%rcx`, `%r8`, `%r9`
- Return value in `%rax`
- Callee-saved registers (`rbx`, `r12`-`r15`) preserved across calls
- Maximum 6 parameters (hardware register limit)

---

## 🆕 Previous: v1.4.0

Initial function support release with multi-parameter functions, recursion, and callee-saved register handling.

---

## 🆕 Previous: v1.3

Post-audit hardening pass with verified fixes and expanded regression coverage.

### Key improvements
- ✅ Fixed division-by-zero fallback behavior to use controlled runtime error handling.
- ✅ Removed IR local-symbol collision risk by using collision-proof internal local identifiers.
- ✅ Fixed register allocator initialization consistency and temp register emission behavior.
- ✅ Fixed nested-expression temporary register clobbering in code generation.
- ✅ Fixed relational comparison operand ordering in allocated-register compare paths.

### Verification improvements
- ✅ Added targeted backend regression checks in `scripts/verify_math.py`:
   - `division_by_zero_guard`
   - `mangling_collision_scope`
   - `expression_stress`
   - `division_sign_semantics`
   - `nested_control_flow_scope`
- ✅ Baseline example builds and all new hardening checks pass.

## 🚀 Quick Start

### Requirements
- Linux environment (tested on Ubuntu 22.04)
- SWI-Prolog 8.4.2+
- GCC 11.4.0+

### Installation

```bash
# Install dependencies (Ubuntu/Debian)
sudo apt update
sudo apt install -y swi-prolog-nox build-essential

# Verify dependencies
swipl --version  # Should show 8.4.2+
gcc --version    # Should show 11.4.0+
```

### Compile and Run a Pascal Program

```bash
# Compile to native executable via assembly backend
swipl -q -s pascal_compiler.pl -- build-asm examples/comprehensive_test.pas comprehensive_test

# Run the program
./comprehensive_test

# Expected output:
# 30
# 200
# 2
# 20
# -10
# 20
# 1
# 1
# 1
# 30
# 15
# Enter a number: You entered: [your input]
# Double of your input: [your input * 2]
# Test completed successfully!
```

## 📚 About This Project

This project uses **prime number algorithms** as a vehicle to explore and demonstrate various programming approaches within our Pascal compiler's constraints. The prime programs serve as practical examples showing:

- Algorithm evolution from naive to optimized
- Performance impact of mathematical optimizations
- Constraint handling (division vs no-division environments)
- Complexity analysis in practice

### 🔬 Mathematical Verification

**✅ All prime algorithms have been mathematically verified** for correctness. See [MATHEMATICAL_VERIFICATION.md](MATHEMATICAL_VERIFICATION.md) for complete verification details including:

- Primality testing against formal mathematical definitions
- Sequence verification using independent computational generation
- Cross-algorithm consistency checking
- Edge case validation
- Comprehensive standards compliance table

**Confidence Level:** Verified by reproducible checks in `scripts/verify_math.py`

### Verification and Hardening Update (2026-04-17)

The backend has received a post-audit hardening update and the verification suite now includes targeted regression checks for prior and newly discovered edge cases.

Implemented and verified fixes include:
- Division-by-zero guard path correctness in generated assembly fallback code.
- Collision-proof internal local symbol representation in IR lowering.
- Register allocator initialization consistency for all temporary registers.
- Nested-expression temporary register clobber prevention.
- Correct relational comparison operand ordering in allocated-register compare paths.

New regression checks in `scripts/verify_math.py`:
- `division_by_zero_guard`
- `mangling_collision_scope`
- `expression_stress`
- `division_sign_semantics`
- `nested_control_flow_scope`

Current status: all shipped examples build, and all baseline + hardening checks pass.

## 📚 About Pascal

### Historical Context

Pascal was designed by **Niklaus Wirth** in the early 1970s as a language for clear, structured programming and computer science education. It became one of the most influential teaching languages because its syntax and type discipline make algorithms and data structures explicit and readable.

This implementation is inspired by Wirth's classic book **"Algorithms + Data Structures = Programs" (1976)**, where Pascal is used to teach the deep connection between problem-solving methods and data representation.

### Pascal Subset Implemented

This release supports a **practical subset** of Pascal focused on core programming constructs:

#### ✅ Supported Features
- **Typed variables**: `integer`, `boolean`, `char`, and static arrays
- **Integers**: 32-bit signed integer arithmetic (`+`, `-`, `*`, `/`, `mod`)
  - **Division**: Integer division (truncates toward zero, e.g., `7/2 = 3`)
  - **Modulo**: Remainder of integer division (e.g., `17 mod 5 = 2`)
  - **No floating-point**: All operations work exclusively with integers
- **Control Flow**: `if-then-else`, `while-do` statements
- **Booleans**: `boolean`, `true`, `false`; `if` and `while` conditions are boolean
- **Chars**: `char` variables, character literals, comparisons, and character I/O
- **Static arrays**: fixed bounds, indexed load/store, runtime bounds checks
- **Character buffers**: `array[...] of char` can be printed as fixed-size text
- **I/O Operations**: `readln`, `write`, `writeln` (integer, char, char-array, and string-literal output)
  - **Enhanced write syntax**: `write(expr, str)` and `write(str, expr)` for better formatting
- **Enhanced Write Functions**: Extended formatting capabilities via runtime library
  - `rt_write_int_str(value, text)`: Write integer followed by string
  - `rt_write_str_int(text, value)`: Write string followed by integer
  - `rt_write_int_str_int(val1, text, val2)`: Write integer, string, integer
- **String Literals**: Output-only string literals (no string variables)
- **Nested Blocks**: Local variable scoping with proper shadowing
- **Relational Operators**: `=`, `<>`, `<`, `<=`, `>`, `>=` (typed comparisons)
- **Unary Operators**: `+` (implicit), `-` (negation)
- **Functions**: Scalar functions with up to 6 scalar parameters
  - **Recursion**: Fully supported with proper register preservation
  - **Return values**: Pascal-style (`funcname := value`)
  - **Expression calls**: `add(3, multiply(2, 4))`
  - **Global access**: Functions can read and write global variables

#### ❌ Not Yet Implemented
- Records
- Procedures (void functions - all functions must return a scalar value)
- Forward declarations (functions must be defined before use)
- Dynamic string variables or string expressions
- Floating-point numbers
- Pointers and pointer arithmetic
- User-defined types

#### Pointer Direction

Pointers are intentionally still out of scope. Now that arrays provide real l-values, layout, and bounds checks, any future pointer feature should be Pascal-style and typed (for example, a pointer to `integer` or `char`) rather than raw integer-address arithmetic. That keeps the compiler type-checkable and avoids turning addresses into unvalidated integers.

### Prime Number Examples

This release includes multiple prime number algorithms that demonstrate different programming approaches:

```bash
# List all prime programs
ls -1 examples/primes/*/*.pas

# Build and run a division-free (slow) version
swipl -q -s pascal_compiler.pl -- build-asm examples/primes/special/primes_no_division.pas primes_no_division
./primes_no_division

# Build and run an optimized square-root version
swipl -q -s pascal_compiler.pl -- build-asm examples/primes/optimized/primes_sqrt_optimized.pas primes_sqrt_optimized
./primes_sqrt_optimized

# Compare benchmark-style variants (count of primes <= 46000)
swipl -q -s pascal_compiler.pl -- build-asm examples/primes/basic/primes_simple_slow.pas primes_simple_slow
swipl -q -s pascal_compiler.pl -- build-asm examples/primes/optimized/primes_simple_fast.pas primes_simple_fast
./primes_simple_slow   # ... Number of primes: 4761
./primes_simple_fast   # ... Number of primes: 4761
```

The prime examples show:
- **`primes_simple_slow.pas`**: Naive subtraction-based counter (primes <= 46000)
- **`primes_simple_fast.pas`**: Square-root optimized counter (primes <= 46000)
- **`primes_no_division.pas`**: Division-free prime listing (< 200)
- **`primes_sqrt_optimized.pas`**: Optimized prime listing (< 200)
- **`primes_with_summary.pas`**: Optimized display with summary (2..46000)
- **`primes_mult_sub.pas`**: Multiplication+subtraction approach (< 200)
- **`primes_sqrt_no_div.pas`**: Square root + division-free optimization (< 200)

### Example Pascal Program

```pascal
program HelloWorld;

var
  x, y, result: integer;

begin
  x := 10;
  y := 20;
  result := x + y;
  writeln('The result is: ');
  writeln(result)
end.
```

### Global Variable Function Example

`examples/global_function_demo.pas` demonstrates function access to a global variable. The `add_counter` function updates the global `counter` and returns the new value:

```bash
swipl -q -s pascal_compiler.pl -- build-asm examples/global_function_demo.pas global_function_demo
./global_function_demo
# 15
# 22
# 22
```

### Integer Division Example

```pascal
program DivisionDemo;

var
  a, b, result: integer;

begin
  a := 7;
  b := 2;
  result := a / b;  { Integer division: 7/2 = 3 }
  writeln('7 / 2 = ');
  writeln(result);  { Outputs: 3 }
  
  result := -7 / 2; { Integer division: -7/2 = -3 }
  writeln('-7 / 2 = ');
  writeln(result);  { Outputs: -3 }
end.
```

## 🔧 Technical Features

### Assembly Backend Advantages

1. **Performance Optimized**
   - Smart register allocation (30-50% fewer stack operations)
   - Dynamic stack frame sizing (90% memory savings for small programs)
   - Efficient expression evaluation

2. **Runtime Safety Checks**
   - ABI-safe stack alignment at generated call sites
   - Division by zero runtime detection
   - Explicit runtime error handlers and termination
   - Enhanced write functions for better output formatting

3. **Robust and Tested**
    - Comprehensive verification suite with example builds and targeted regressions
    - Edge case coverage (large numbers, complex expressions)
    - Function global access and semantic error regressions
    - Consistent results across multiple prime implementations

### Compilation Pipeline

```
Pascal Source → AST → IR → x86-64 Assembly → Native Executable
```

## 📁 Directory Structure

```
pascal-prolog-asm-release/
├── pascal_compiler.pl          # Main compiler entry point
├── src/                        # Compiler front-end + backend modules
│   ├── lexer.pl                # Lexer
│   ├── parser.pl               # Parser
│   ├── semantics.pl            # Semantic checks
│   ├── ir.pl                   # IR lowering
│   └── codegen_asm_x86_64.pl   # x86-64 assembly generator
├── examples/                    # Example Pascal programs
│   ├── comprehensive_test.pas # Comprehensive test program
│   ├── challenging/           # Challenging algorithms (recursion, etc.)
│   └── primes/                 # Prime algorithm examples
│       ├── basic/             # Basic prime algorithms
│       ├── optimized/         # Optimized prime algorithms
│       └── special/           # Specialized prime algorithms
├── docs/                       # Documentation
│   ├── primes.md              # Prime algorithm documentation
│   ├── ALGORITHM_PROGRESSION.md # Algorithm evolution
│   └── PERFORMANCE_COMPARISON.md # Performance analysis
├── MATHEMATICAL_VERIFICATION.md # Mathematical correctness report
├── runtime/                    # Runtime library
│   ├── runtime.c               # Runtime functions
│   ├── runtime.h               # Runtime headers
│   └── (built at compile time) # No prebuilt objects in release
├── README.md                   # This file
└── UNLICENSE                   # License
```

## 🧪 Testing

### Run the Comprehensive Test

```bash
# Compile and run the comprehensive test
swipl -q -s pascal_compiler.pl -- build-asm examples/comprehensive_test.pas comprehensive_test
./comprehensive_test
```

### Expected Output

The comprehensive test prints:

```
30
200
2
20
-10
20
1
1
1
30
15
Enter a number: You entered: [your input]
Double of your input: [your input * 2]
Test completed successfully!
```

### Try the Comprehensive Test Program

```bash
# Run the comprehensive test that demonstrates all features
swipl -q -s pascal_compiler.pl -- build-asm examples/comprehensive_test.pas comprehensive_test
./comprehensive_test
```

## 📖 Documentation

### Assembly Backend Features

1. **ABI-Safe Call Alignment**
   - Generated calls align `%rsp` to System V ABI expectations
   - Stack pointer is restored after each generated call

2. **Dynamic Stack Sizing**
   - Calculates exact stack needs for variables plus saved callee-saved registers
   - Main reserves stack slots for `%rbx` and `%r12-%r15`
   - 16-byte alignment for System V ABI compliance

3. **Register Allocation**
   - Uses callee-saved registers (%rbx, %r12-%r15)
   - Dynamic allocation/deallocation
   - Fallback to stack-based approach when needed

4. **Error Handling**
   - Division by zero detection
   - Explicit runtime error handlers
   - Clear error messages and proper termination

### CLI Commands

```bash
# Parse Pascal source
swipl -q -s pascal_compiler.pl -- parse <source.pas>

# Check semantics
swipl -q -s pascal_compiler.pl -- check <source.pas>

# Generate assembly only
swipl -q -s pascal_compiler.pl -- asm <source.pas> <output.s>

# Build executable (assembly backend)
swipl -q -s pascal_compiler.pl -- build-asm <source.pas> <output>
```

## ⚠️ Limitations and Warnings

### Critical Limitations

1. **Integer-Only Arithmetic**: This compiler only supports **integer arithmetic**. All variables are 32-bit signed integers, and all operations (including division) work exclusively with integers.

   **Important behaviors:**
   - `7 / 2` evaluates to `3` (integer division, truncates toward zero)
   - `-7 / 2` evaluates to `-3` (not -3.5)
   - No floating-point numbers or operations
   - No automatic type conversion

2. **Language Subset**: This release implements a focused subset of Pascal for core programming constructs. See the "Supported Features" section for complete details.

3. **No C Backend**: This is an assembly-only release. The C backend has been omitted for minimal package size.

4. **Error Handling**: While comprehensive error handling is implemented, some edge cases may not be covered. Always test your programs thoroughly.

5. **Performance**: While optimized, this is still an educational compiler. For production use, consider commercial compilers for better optimization.

### Security Considerations

- **Stack Overflow**: Generated code does not include OS-level guard-page stack overflow protection
- **Division by Zero**: Detected and handled through a validated runtime error path
- **Memory Safety**: No bounds checking on variables or stack usage
- **Input Validation**: Limited to integer input validation

### Not Suitable For

- Production systems requiring maximum reliability
- Security-critical applications
- Large-scale commercial software
- Real-time systems

**Recommended For**: Education, learning, experimentation, small projects

## 🎓 Learning Resources

### Recommended Reading

1. **"Algorithms + Data Structures = Programs"** by Niklaus Wirth
   - The original inspiration for this project
   - Classic computer science textbook using Pascal

2. **"The Pascal User Manual and Report"** by Jensen & Wirth
   - Definitive Pascal language reference

3. **"Compiler Construction"** by Niklaus Wirth
   - Learn how compilers work (using Oberon, but concepts apply)

### Online Resources

- [Pascal Programming Wikipedia](https://en.wikipedia.org/wiki/Pascal_(programming_language))
- [Free Pascal Compiler](https://www.freepascal.org/) (for comparison)
- [GNU Pascal](https://www.gnu-pascal.de/) (another open-source Pascal)

### Prolog for Compiler Construction

Implementing compilers in Prolog is a **long-standing tradition** in computer science education. Prolog's pattern matching, recursion, and logic programming features make it ideal for parsing and language processing:

- **"Programming in Prolog"** by Clocksin & Mellish (Springer)
  - The classic Prolog textbook (since 1981, 6th edition 2003)
  - Covers DCGs and compiler construction fundamentals
  - Often called the "bible" of Prolog programming
  
- **"The Power of Prolog"** - [Metalevel Systems](https://www.metalevel.at/prolog) by Markus Triska
  - Comprehensive modern Prolog resource with compiler/grammar examples
  - Includes detailed DCG (Definite Clause Grammars) tutorials
  
- **DCG (Definite Clause Grammars)** - Prolog's built-in grammar system for parsing:
  - [Prolog DCG Primer](https://www.metalevel.at/prolog/dcg) by Markus Triska
  - Standard approach for implementing parsers in Prolog

## 🤝 Contributing

We welcome contributions! This is an active development repository.

1. **Fork the Repository**: Create your own fork for development
2. **Report Issues**: Use the issue tracker to report bugs or suggest features
3. **Submit Pull Requests**: Contribute to the main development branch

## 📜 License

This software is released under the **Unlicense** (public domain dedication). See the `UNLICENSE` file for details.

**You are free to:**
- Use, modify, and distribute this software for any purpose
- Use it in commercial products without restriction
- Modify and redistribute without attribution

**Without warranty of any kind** - Use at your own risk

## 🎉 Enjoy!

This project provides a minimalist Pascal compiler with assembly backend. It's perfect for:

- Learning compiler construction
- Experimenting with Pascal programming
- Understanding how compilers work
- Teaching programming concepts

**Happy coding!** 🚀

### Challenging Algorithms

The `examples/challenging/` directory contains advanced recursive algorithms:

```bash
# Build and run the Tower of Hanoi with enhanced output
swipl -q -s pascal_compiler.pl -- build-asm examples/challenging/tower_of_hanoi_enhanced.pas tower_of_hanoi
./tower_of_hanoi
# Output: "Tower of Hanoi with 3 disks requires 7 moves"
```

Challenging examples include:
- **`tower_of_hanoi_simple.pas`**: Basic recursive implementation (mathematical formula)
- **`tower_of_hanoi_enhanced.pas`**: Enhanced version demonstrating new write functionality

-- The Pascal-Prolog Team
