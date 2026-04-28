# Pascal-Prolog Compiler Audit Report

**Date:** 2026-04-28
**Version:** 1.5.0
**Auditor:** Code Review

---

## Executive Summary

This educational Pascal-to-x86-64 compiler is well-structured with a clean pipeline architecture (Lexer → Parser → Semantics → IR → Codegen). The codebase shows good separation of concerns and follows Prolog conventions. Most features work correctly including arithmetic, control flow, functions with up to 6 parameters, recursion, and proper register allocation.

**Overall Status:** ✅ **Current audit findings addressed**

**Fixes Applied:**
- ✅ Function return values now default to 0 (was returning garbage)
- ✅ Added `mod` operator support
- ✅ Duplicate function declarations are rejected before code generation
- ✅ Function declarations are limited to the supported 6 parameters
- ✅ Function parameter/local duplicate declarations are rejected
- ✅ Generated `main` now preserves callee-saved registers
- ✅ Functions can now read and write global variables
- ✅ Boolean operators (`and`, `or`, `not`) are supported
- ✅ Typed booleans, chars, static arrays, and array bounds checks are supported
- ✅ Global `var` sections can appear before functions or after functions
- ✅ Top-level compiler errors use explicit user-facing messages
- ✅ Unsafe printf-style runtime formatting entry point removed

---

## 1. Architecture Review

### Strengths
- **Clean modular design**: Each compiler phase is isolated in its own module
- **Proper use of Prolog DCGs** for parsing
- **Name mangling for locals** prevents scope collisions
- **Callee-saved register usage** follows System V ABI conventions
- **Stack alignment handling** for external calls

### Components
| File | Purpose | Status |
|------|---------|--------|
| `pascal_compiler.pl` | CLI entry point | ✅ Good |
| `src/lexer.pl` | Tokenization | ✅ Good |
| `src/parser.pl` | DCG-based parsing | ✅ Good |
| `src/semantics.pl` | Scope/type checking | ✅ Good |
| `src/ir.pl` | IR generation with name mangling | ✅ Good |
| `src/codegen_asm_x86_64.pl` | x86-64 assembly generation | ✅ Good |
| `runtime/runtime.c` | C runtime library | ✅ Good |

---

## 2. Issues Found

### 🔴 HIGH: Function Return Value Not Initialized (Semantic Gap) ✅ FIXED

**Issue:** Functions that don't assign to their name return uninitialized garbage.

**Test Case:**
```pascal
function foo(x: integer): integer;
begin
  writeln(x)  { Missing: foo := something }
end;
```

**Result:** ~~Returns garbage value (`-1617551296`)~~ Now returns `0` ✅

**Root Cause:** The semantic checker (`semantics.pl`) doesn't verify that functions assign to their name. The codegen allocates stack space for the return value but never initializes it.

**Fix Applied:** Added initialization of the return-value stack slot in the function prologue:
```prolog
format(Stream, "\tmovq $0, -48(%rbp)\n", [])
```

**Impact:** Functions now safely return 0 if no explicit assignment made.

---

### 🟡 MEDIUM: No Global Variable Access from Functions ✅ FIXED

**Issue:** Functions could not access global variables.

**Root Cause:** Function semantic checking and function code generation scoped functions to their return slot, parameters, and locals.

**Prior Workaround:** Pass all needed data as parameters.

**Fix Applied:** Function semantic checking now includes globals after function-local names, so parameters and locals still shadow globals. Code generation records `main`'s frame pointer and uses it for function reads/writes of true global variables.

---

### 🟡 MEDIUM: Error Message Inconsistency ✅ FIXED

**Issue:** Error messages have inconsistent formatting and sometimes expose internal details.

**Examples:**
```
undeclared variable: b (Variable not declared in current scope)
duplicate declaration: a (Variable or parameter declared multiple times)
too many arguments for function foo: 7 (maximum 6)
```

**Root Cause:** Custom error terms aren't uniformly handled by the top-level error printer.

**Fix Applied:** Added `prolog:message//1` handlers in `pascal_compiler.pl` for known compiler error terms.

---

### 🟢 LOW: Parameter Shadowing Not Detected Clearly ✅ FIXED

**Issue:** Shadowing a parameter with a local variable fails with generic syntax error instead of clear message.

**Test Case:**
```pascal
function foo(x: integer): integer;
var x: integer;  { Shadows parameter }
begin
  foo := x + 1
end;
```

**Result:** Clear duplicate-declaration error.

**Fix Applied:** Function semantic checking now validates the combined function name + parameters + local variable scope.

---

### 🟢 LOW: Missing Features (By Design)

The following are documented limitations:

| Feature | Status | Notes |
|---------|--------|-------|
| `mod` operator | ✅ **Supported** | Added in v1.4.3 |
| `and`/`or`/`not` | ✅ **Supported** | Boolean operators added in v1.5.0 |
| Static arrays | ✅ **Supported** | Fixed bounds with runtime bounds checks |
| Records | ❌ Not supported | Significant work required |
| Separate forward declarations | ❌ Not supported | Mutual recursion works between fully defined functions |
| Procedures (void) | ❌ Not supported | Functions only |
| Real/float | ❌ Not supported | Integer only |

---

## 3. Code Quality Assessment

### ✅ Strengths

1. **Good use of Prolog idioms:**
   - DCGs for parsing
   - `memberchk/2` for lookups
   - `append/3` for list building
   - Proper use of cuts (`!`) for efficiency

2. **Register allocation:**
   - Dynamic register tracking
   - Fallback to stack when registers exhausted
   - Proper save/restore of callee-saved registers

3. **Runtime safety:**
   - Division by zero checks
   - Stack overflow protection (reserved space)
   - Error handlers with proper messages

4. **Testing:**
   - Comprehensive test suite (`verify_math.py`)
   - 45 example programs covering various cases
   - Prime number algorithms as realistic test cases

### ⚠️ Areas for Improvement

1. **Documentation:**
   - More inline comments in `codegen_asm_x86_64.pl`
   - Assembly generation logic is complex and could use explanation

2. **Diagnostics:**
    - User-friendly messages now exist for known compiler errors
    - Future improvement: add source line/column reporting to semantic errors

3. **Code duplication:**
   - `asm_expr/2` and `asm_expr_func/6` share similar logic
   - Could potentially be unified with proper context passing

---

## 4. Security Assessment

### ✅ Safe Practices

1. **No buffer overflows:** String handling uses proper escaping
2. **No format string vulnerabilities:** Assembly uses `format/3` with controlled atoms; the unsafe `rt_write_format` runtime helper has been removed
3. **Input validation:** Scanner rejects unexpected characters
4. **Division by zero:** Runtime check before `idivq`

### ⚠️ Potential Concerns

1. **Integer overflow:**
   - Pascal integers are 32-bit signed but stored in 64-bit registers
   - Overflow behavior is undefined (as documented)
   - No runtime overflow detection

2. **Stack overflow:**
   - Protected with reserved guard space
   - Runtime handler exists but uses `int $3` which is a breakpoint

---

## 5. Test Results Summary

```
Build Tests:    45/45 passed ✅
Prime Tests:    All match expected output ✅
Math Tests:     All pass ✅
Division Signs: Correct (-7/2 = -3) ✅
Scope Tests:    Correct (1221 output) ✅
Functions:      Recursion works ✅
Semantics:      Duplicate functions, excessive parameters, and param/local collisions rejected ✅
Globals:        Function read/write and shadowing behavior verified ✅
Datatypes:      Boolean operators, chars, static arrays, and bounds checks verified ✅
Decl Order:     Global vars before functions and after functions verified ✅
```

---

## 6. Recommendations

### ✅ Completed Fixes

1. **✅ Fixed uninitialized function returns:**
   - Added initialization of the function return-value slot in the function prologue
   - Functions now safely return 0 if no explicit assignment made

2. **✅ Added `mod` operator:**
   - Added `mod` keyword to lexer and parser
   - Added code generation using `%rdx` remainder after `idivq`
   - Works in both main program and function contexts

### Completed Hardening

3. **✅ Improved error messages:**
    - Added user-facing messages for semantic, arity, GCC, and unsupported-format errors.

4. **✅ Implemented global access from functions:**
    - Functions can read and write global variables.
    - Parameters and locals continue to shadow globals.

5. **✅ Added typed scalar and array support:**
   - Booleans, chars, static arrays, boolean operators, and array bounds checks are implemented.

6. **✅ Relaxed top-level declaration order:**
   - Global `var` sections may appear before functions or after functions.

### Long Term (Low Priority)

7. **Separate forward declarations:**
   - Add prototype-only declarations if the compiler grows toward a larger Pascal subset.

---

## 7. Conclusion

The Pascal-Prolog compiler is a **well-crafted educational compiler** that successfully compiles a meaningful subset of Pascal to x86-64 assembly. The architecture is sound, the code is maintainable, and the test coverage is good.

**Grade: A- (Good, critical issues resolved)**

All critical issues identified in the audit have been resolved:
- ✅ Function return values now default to 0
- ✅ `mod` operator support added
- ✅ Function/global access works
- ✅ Boolean operators, chars, static arrays, and declaration-order improvements work
- ✅ Semantic edge cases fail early with clear diagnostics
- ✅ Generated `main` preserves callee-saved registers

The compiler is now more robust and feature-complete for its intended educational purpose.

---

*Report generated by code audit on 2026-04-28*
*Updated after fixes applied on 2026-04-28*
