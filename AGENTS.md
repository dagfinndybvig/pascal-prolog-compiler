# AGENTS.md - Pascal-Prolog Compiler

> Guidelines for AI agents working on this Pascal-to-x86-64 compiler project.

## Project Overview

This is a **Pascal compiler written in SWI-Prolog** that compiles a subset of Pascal to native x86-64 assembly. It's an educational compiler focused on core compiler construction concepts.

**Key characteristics:**
- Integer-only arithmetic (32-bit signed)
- Operators: `+`, `-`, `*`, `/`, `mod`, comparisons (`=`, `<>`, `<`, `<=`, `>`, `>=`)
- Compiles to x86-64 assembly via GCC
- Uses Prolog DCGs for parsing
- **Functions supported**: Integer functions with up to 6 parameters, recursion
- Prime number algorithms are the primary test cases

**Version**: 1.4.4 (2026-04-23) - Fixed function semantic checking and local variable codegen bugs
**Previous**: 1.4.3 (2026-04-22) - Added `mod` operator, fixed uninitialized function return values

## Quick Start

### Build a Pascal Program

```bash
# Compile Pascal source to native executable
swipl -q -s pascal_compiler.pl -- build-asm examples/comprehensive_test.pas comprehensive_test

# Run it
./comprehensive_test
```

### Available CLI Commands

```bash
swipl -q -s pascal_compiler.pl -- parse <source.pas>           # Parse only, output AST
swipl -q -s pascal_compiler.pl -- check <source.pas>          # Semantic check only
swipl -q -s pascal_compiler.pl -- asm <source.pas> <out.s>    # Generate assembly file
swipl -q -s pascal_compiler.pl -- build-asm <source.pas> <out_binary>  # Full build
```

### Run Tests

```bash
# Build and run the comprehensive test
swipl -q -s pascal_compiler.pl -- build-asm examples/comprehensive_test.pas comprehensive_test
./comprehensive_test

# Run verification suite
python3 scripts/verify_math.py
```

## Architecture

```
Pascal Source → Lexer → Parser → AST → Semantic Checker → IR → x86-64 Assembly → Executable
```

| Stage | File | Purpose |
|-------|------|---------|
| Lexer | `src/lexer.pl` | Tokenizes source code |
| Parser | `src/parser.pl` | DCG-based parser, produces AST |
| Semantics | `src/semantics.pl` | Variable declaration & scope checking |
| IR | `src/ir.pl` | Lowers AST to intermediate representation with name mangling for locals |
| Codegen | `src/codegen_asm_x86_64.pl` | Generates x86-64 assembly with register allocation |
| Runtime | `runtime/runtime.c` | C runtime for I/O operations |

## Common Agent Tasks

### Adding a New Language Feature

1. **Lexer** (`src/lexer.pl`): Add token recognition in `keyword_or_ident/2` or `consume_symbol/4`
2. **Parser** (`src/parser.pl`): Add DCG rules following existing patterns
3. **Semantics** (`src/semantics.pl`): Add validation in `check_stmt/2` or `check_expr/2`
4. **IR** (`src/ir.pl`): Add lowering rules in `lower_stmt/6` or `lower_expr/3`
5. **Codegen** (`src/codegen_asm_x86_64.pl`): Add assembly generation in `generate_asm_text/2` or `asm_expr/2`
6. **Test**: Add test case to `examples/comprehensive_test.pas` or create new test file

### Debugging Compilation Issues

```bash
# Check if parsing works
swipl -q -s pascal_compiler.pl -- parse examples/test.pas

# Check semantics
swipl -q -s pascal_compiler.pl -- check examples/test.pas

# Generate assembly to inspect
swipl -q -s pascal_compiler.pl -- asm examples/test.pas test.s
cat test.s
```

### Adding New Test Cases

1. Create `.pas` file in `examples/` or appropriate subdirectory
2. Build and verify output manually
3. If it's a prime algorithm variant, place in `examples/primes/` hierarchy:
   - `examples/primes/basic/` - Simple implementations
   - `examples/primes/optimized/` - Optimized versions
   - `examples/primes/special/` - Special constraint versions (division-free, etc.)

## Code Conventions

### Prolog Style
- Use snake_case for predicates and variables
- Module exports are explicit in `module/2` directive
- Use DCGs for parsing (`phrase/2`)
- Cut (`!`) used sparingly in parser for efficiency

### IR Naming Convention
- Local variables are mangled as `local(Counter, OriginalName)` to avoid collisions
- Global variables keep their original names
- This is handled in `src/ir.pl` `allocate_locals/5`

### Register Allocation
- Uses callee-saved registers: `%rbx`, `%r12-%r15` (System V ABI)
- `%rax` for results, `%rcx` as preferred temp register
- Register state tracked dynamically via `available_registers/1`

### Assembly Output
- Stack frame: 16 + 8*N bytes (16-byte aligned)
- Variables stored at negative offsets from `%rbp`
- Runtime error handlers included: `division_by_zero`
- Generated calls use ABI-safe `%rsp` alignment wrappers

## Testing Procedures

Always verify changes with:

1. **Comprehensive test**: Build and run `examples/comprehensive_test.pas`
2. **Prime examples**: Build at least one prime algorithm variant
3. **Verification script**: Run `python3 scripts/verify_math.py` if math-related changes

### Expected Comprehensive Test Output

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
Enter a number: {input 5}
You entered: 5
Double of your input: 10
Test completed successfully!
```

## Important Limitations

**Never forget these constraints:**

1. **Integer-only**: No floating-point. Division truncates toward zero (`7/2 = 3`, `-7/2 = -3`)
2. **No arrays or records** - only simple variables and control flow
3. **No procedures** - functions only, must return integer
4. **String literals are output-only** - no string variables or operations
5. **32-bit signed integers** - overflow behavior is undefined
6. **Maximum 6 function parameters** - x86-64 calling convention limit

## File Organization

```
├── pascal_compiler.pl          # Main entry point
├── src/
│   ├── lexer.pl                # Lexical analysis
│   ├── parser.pl               # Parser (DCG)
│   ├── semantics.pl            # Semantic analysis
│   ├── ir.pl                   # IR generation
│   └── codegen_asm_x86_64.pl   # Assembly code generation
├── runtime/
│   ├── runtime.c               # C runtime library
│   └── runtime.h               # Runtime headers
├── examples/
│   ├── comprehensive_test.pas  # Main test suite
│   └── primes/                 # Prime algorithm examples
│       ├── basic/
│       ├── optimized/
│       └── special/
├── scripts/
│   └── verify_math.py          # Mathematical verification suite
└── docs/                       # Documentation
```

## Dependencies

- SWI-Prolog 8.4.2+
- GCC 11.4.0+
- Python 3 (for verification scripts)

## Version History

- **v1.4.4** (2026-04-23): Fixed function semantic checking bug - `collect_func_sigs/2` now correctly handles `func/4` AST terms; fixed IR generation to properly merge function locals with block locals; fixed codegen to handle mangled local variable names
- **v1.4.3** (2026-04-22): Added `mod` operator support, fixed uninitialized function return values (now default to 0)
- **v1.4.2** (2026-04-22): Fixed nested call argument clobbering, function-local variable codegen support, and call-site stack alignment
- **v1.4.1** (2026-04-22): Fixed function semantic checking bug - separated signature collection from body checking to enable mutual recursion
- **v1.4.0** (2026-04-22): Added function support - integer functions with up to 6 parameters, recursion, proper callee-saved register handling
- **v1.3** (2026-04-17): Post-audit hardening, fixed division-by-zero handling, register allocation fixes

---

**When in doubt**: Build `examples/comprehensive_test.pas` and verify output matches expected. If adding features, follow the existing pipeline pattern (Lexer → Parser → Semantics → IR → Codegen).
