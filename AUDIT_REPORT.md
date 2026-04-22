# Pascal-Prolog Compiler Audit Report

**Date:** 2026-04-22  
**Version:** 1.4.3  
**Auditor:** Code Review

---

## Executive Summary

This educational Pascal-to-x86-64 compiler is well-structured with a clean pipeline architecture (Lexer → Parser → Semantics → IR → Codegen). The codebase shows good separation of concerns and follows Prolog conventions. Most features work correctly including arithmetic, control flow, functions with up to 6 parameters, recursion, and proper register allocation.

**Overall Status:** ✅ **All critical issues resolved**

**Fixes Applied:**
- ✅ Function return values now default to 0 (was returning garbage)
- ✅ Added `mod` operator support

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
| `src/semantics.pl` | Scope/type checking | ⚠️ See issues |
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

**Fix Applied:** Added initialization of return value slot to 0 in `codegen_asm_x86_64.pl`, line 508:
```prolog
format(Stream, "\tmovq $0, -48(%rbp)\n", [])
```

**Impact:** Functions now safely return 0 if no explicit assignment made.

---

### 🟡 MEDIUM: No Global Variable Access from Functions

**Issue:** Functions cannot access global variables due to grammar ordering.

**Root Cause:** Grammar requires `func_declarations` before `declarations`, so global variables aren't in scope when functions are parsed.

**Workaround:** Pass all needed data as parameters.

**Recommendation:** Document this as an architectural limitation or restructure grammar to allow global access.

---

### 🟡 MEDIUM: Error Message Inconsistency

**Issue:** Error messages have inconsistent formatting and sometimes expose internal details.

**Examples:**
```
Unknown error term: undeclared_variable(b) (Variable not declared in current scope)
Unknown error term: duplicate_declaration(a) (Variable or parameter declared multiple times)
Unknown error term: too_many_arguments(foo,7)
```

**Root Cause:** Custom error terms aren't uniformly handled by the top-level error printer.

**Recommendation:** Standardize error handling with a `format_error/2` predicate.

---

### 🟢 LOW: Parameter Shadowing Not Detected at Parse Time

**Issue:** Shadowing a parameter with a local variable fails with generic syntax error instead of clear message.

**Test Case:**
```pascal
function foo(x: integer): integer;
var x: integer;  { Shadows parameter }
begin
  foo := x + 1
end;
```

**Result:** Generic "Syntax error: invalid_pascal_program"

**Note:** This IS caught by `ensure_no_duplicates/1` but the error handling obscures it.

---

### 🟢 LOW: Missing Features (By Design)

The following are documented limitations:

| Feature | Status | Notes |
|---------|--------|-------|
| `mod` operator | ✅ **Supported** | Added in v1.4.3 |
| `and`/`or`/`not` | ❌ Not supported | Boolean operators |
| Arrays | ❌ Not supported | Significant work required |
| Records | ❌ Not supported | Significant work required |
| Forward declarations | ❌ Not supported | Needed for mutual recursion |
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
   - 24 example programs covering various cases
   - Prime number algorithms as realistic test cases

### ⚠️ Areas for Improvement

1. **Documentation:**
   - More inline comments in `codegen_asm_x86_64.pl`
   - Assembly generation logic is complex and could use explanation

2. **Error handling:**
   - Standardize error term format
   - Add user-friendly error messages with line numbers

3. **Code duplication:**
   - `asm_expr/2` and `asm_expr_func/6` share similar logic
   - Could potentially be unified with proper context passing

---

## 4. Security Assessment

### ✅ Safe Practices

1. **No buffer overflows:** String handling uses proper escaping
2. **No format string vulnerabilities:** Assembly uses `format/3` with controlled atoms
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
Build Tests:    24/24 passed ✅
Prime Tests:    All match expected output ✅
Math Tests:     All pass ✅
Division Signs: Correct (-7/2 = -3) ✅
Scope Tests:    Correct (1221 output) ✅
Functions:      Recursion works ✅
```

---

## 6. Recommendations

### ✅ Completed Fixes

1. **✅ Fixed uninitialized function returns:**
   - Added `format(Stream, "\tmovq $0, -48(%rbp)\n", [])` in function prologue
   - Functions now safely return 0 if no explicit assignment made

2. **✅ Added `mod` operator:**
   - Added `mod` keyword to lexer and parser
   - Added code generation using `%rdx` remainder after `idivq`
   - Works in both main program and function contexts

### Remaining Recommendations

3. **Improve error messages:**
   ```prolog
   format_error(undeclared_variable(Name), Msg) :-
       format(string(Msg), "Error: Variable '~w' not declared", [Name]).
   ```

4. **Document limitations:**
   - Add explicit "Not Supported" section to AGENTS.md
   - Better error messages for unsupported features

### Long Term (Low Priority)

5. **Support global variable access from functions:**
   - Restructure grammar or add second pass for global binding

6. **Add boolean operators:**
   - `and`, `or`, `not`

7. **Forward declarations:**
   - Enable mutual recursion patterns

---

## 7. Conclusion

The Pascal-Prolog compiler is a **well-crafted educational compiler** that successfully compiles a meaningful subset of Pascal to x86-64 assembly. The architecture is sound, the code is maintainable, and the test coverage is good.

**Grade: A- (Good, critical issues resolved)**

All critical issues identified in the audit have been resolved:
- ✅ Function return values now default to 0
- ✅ `mod` operator support added

The compiler is now more robust and feature-complete for its intended educational purpose.

---

*Report generated by code audit on 2026-04-22*  
*Updated after fixes applied on 2026-04-22*
