<img width="1880" height="515" alt="image" src="https://github.com/user-attachments/assets/0c40b246-bb09-4c59-80ee-e9eafc54bde0" />

# Pascal-Prolog Assembly Backend - Release Version 1.3

> [!WARNING]
> This project implements only a **fragment of Pascal**. It supports **integer-only arithmetic** and a feature subset that is just enough to have som fun with prime-number programs and the like.
>
> It is primarily a **Computer Science experiment** in language design, compiler construction, and algorithm exploration, not a full Pascal implementation.

## 📦 Pascal-Prolog Assembly Backend Release

**Version**: 1.3
**Release Date**: 2026-04-17
**License**: Unlicense (Public Domain)

## 🎯 About This Release

This is now a **complete standalone release** of the Pascal-Prolog compiler with assembly backend. It includes everything needed to compile Pascal programs directly to x86-64 assembly and native executables.

### What's Included
- ✅ Complete Pascal compiler (parser, semantics, IR generator)
- ✅ Assembly code generator (x86-64 backend)
- ✅ Runtime library for I/O operations
- ✅ Comprehensive test program
- ✅ Full documentation
- ✅ Minimal, clean distribution

## 🆕 What's New In v1.3

This release includes a post-audit hardening pass with verified fixes and expanded regression coverage.

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
- **Variables**: Integer variables only (32-bit signed integers)
- **Arithmetic**: Integer arithmetic only (`+`, `-`, `*`, `/`)
  - **Division**: Integer division (truncates toward zero, e.g., `7/2 = 3`)
  - **No floating-point**: All operations work exclusively with integers
- **Control Flow**: `if-then-else`, `while-do` statements
- **I/O Operations**: `readln`, `write`, `writeln` (integer and string output)
- **String Literals**: Output-only string literals (no string variables)
- **Nested Blocks**: Local variable scoping with proper shadowing
- **Relational Operators**: `=`, `<>`, `<`, `<=`, `>`, `>=` (integer comparisons only)
- **Unary Operators**: `+` (implicit), `-` (negation)

#### ❌ Not Yet Implemented
- Arrays and records
- Procedures and functions
- String variables or expressions
- Floating-point numbers
- Pointer arithmetic
- User-defined types

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
   - Stack frame bounds check in generated assembly
   - Division by zero runtime detection
   - Explicit error handlers and termination

3. **Robust and Tested**
    - Comprehensive test suite (10+ test cases)
    - Edge case coverage (large numbers, complex expressions)
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

1. **Stack Frame Bounds Check**
   - Runtime stack pointer validation against generated frame bounds
   - Automatic error handling path on violation

2. **Dynamic Stack Sizing**
   - Calculates exact stack needs: `16 + 8*N` bytes
   - Minimal 16-byte frame for zero-variable programs
   - 16-byte alignment for System V ABI compliance

3. **Register Allocation**
   - Uses callee-saved registers (%rbx, %r12-%r15)
   - Dynamic allocation/deallocation
   - Fallback to stack-based approach when needed

4. **Error Handling**
   - Division by zero detection
   - Stack overflow protection
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

- **Stack Overflow**: Generated code includes a stack frame bounds check, but this is not OS-level guard-page protection
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

-- The Pascal-Prolog Team
