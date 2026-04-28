# Comprehensive Test Documentation

> [!WARNING]
> This project implements only a **fragment of Pascal**. It supports integer arithmetic, typed booleans and chars, static arrays, and a focused feature subset that is just enough to do interesting work with prime-number programs.
>
> It is primarily a **Computer Science experiment** in language design, compiler construction, and algorithm exploration, not a full Pascal implementation.

This document describes the comprehensive test program that demonstrates the compiler's core arithmetic, control-flow, scoped-variable, I/O, and string-output behavior. Additional examples and generated regressions cover functions, procedures, `var` parameters (scalar and array), `for` loops, multi-argument `write`/`writeln`, `case` statements, `mod`, boolean operators, chars, arrays, semantic errors, declaration order, and global access from subprograms.

## Test Program: `comprehensive_test.pas`

The comprehensive test program exercises core Pascal subset features:

### Features Tested:

1. **Variable Declarations**: Multiple integer variables
2. **Basic Arithmetic**: Addition, multiplication, division
3. **Complex Expressions**: Nested arithmetic operations with proper precedence
4. **Unary Operations**: Negative numbers and nested unary operations
5. **Relational Operators**: `<`, `=`, `>=` comparisons
6. **Conditional Statements**: `if-then-else` constructs
7. **Nested Blocks**: Variable scoping with inner blocks
8. **While Loops**: Looping construct with counter
9. **String Output**: String literal output
10. **Input Operations**: `readln` for integer input
11. **Multiple Writeln**: Various output operations

### Program Structure:

```pascal
program comprehensive_test;

var
  a, b, c, result, temp, user_input: integer;

begin
  { Test basic arithmetic }
  a := 10;
  b := 20;
  c := a + b;
  writeln(c);  { Output: 30 }
  
  { Test more arithmetic operations }
  result := a * b;
  writeln(result);  { Output: 200 }
  
  result := b / a;
  writeln(result);  { Output: 2 }
  
  { Test complex expression }
  result := ((a + b) * 2) / 3;
  writeln(result);  { Output: 20 }
  
  { Test unary operations }
  temp := -a;
  writeln(temp);  { Output: -10 }
  
  temp := -(-b);
  writeln(temp);  { Output: 20 }
  
  { Test relational operators }
  if a < b then
    writeln(1)  { Output: 1 }
  else
    writeln(0);
  
  if a = 10 then
    writeln(1)  { Output: 1 }
  else
    writeln(0);
  
  if b >= a then
    writeln(1)  { Output: 1 }
  else
    writeln(0);
  
  { Test nested blocks }
  begin
    var inner: integer;
    inner := a + b;
    writeln(inner)  { Output: 30 }
  end;
  
  { Test while loop }
  temp := 0;
  c := 1;
  while c <= 5 do
  begin
    temp := temp + c;
    c := c + 1
  end;
  writeln(temp);  { Output: 15 }
  
  { Test input operations }
  write('Enter a number: ');
  readln(user_input);
  write('You entered: ');
  writeln(user_input);
  
  { Use input in calculation }
  result := user_input * 2;
  write('Double of your input: ');
  writeln(result);
  
  { Test string output }
  writeln('Test completed successfully!')
end.
```

## Important Note

**This release includes the Pascal front-end and the assembly backend.** You can compile Pascal source (`.pas`) directly to a native executable with `build-asm`.

### Example Workflow:
```bash
# Compile Pascal source to native executable
swipl -q -s pascal_compiler.pl -- build-asm comprehensive_test.pas comprehensive_test

# Run the compiled program
./comprehensive_test
```

### Expected Output:
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

## Verification

The test program has been successfully compiled and executed using the assembly backend, demonstrating that all implemented features work correctly:

- ✅ Variable declarations and assignments
- ✅ Basic arithmetic operations (+, *, /)
- ✅ Complex nested expressions
- ✅ Unary minus operations
- ✅ Relational operators (<, =, >=)
- ✅ Conditional statements (if-then-else)
- ✅ Nested blocks with local variables
- ✅ While loops with compound statements
- ✅ String literal output
- ✅ Input operations (readln)
- ✅ Multiple writeln statements

## Additional Hardening Coverage

`comprehensive_test.pas` remains the primary feature demonstration program. Complementary backend hardening checks are now also executed by `scripts/verify_math.py` using generated regression programs.

These additional checks validate:
- Division-by-zero runtime error path behavior
- Scoped name handling under collision-like identifier patterns
- Deep expression correctness
- Signed division semantics
- Nested control-flow and shadowing correctness

This means validation now combines:
1. Feature coverage via `comprehensive_test.pas`
2. Algorithm correctness via prime program verification
3. Backend robustness via targeted regressions

## Test Coverage Analysis

This comprehensive test covers the core features exercised by `examples/comprehensive_test.pas`:

| Feature | Tested | Working |
|---------|--------|---------|
| Variable declarations | ✅ | ✅ |
| Integer arithmetic | ✅ | ✅ |
| Complex expressions | ✅ | ✅ |
| Unary operations | ✅ | ✅ |
| Relational operators | ✅ | ✅ |
| Conditional statements | ✅ | ✅ |
| Nested blocks | ✅ | ✅ |
| While loops | ✅ | ✅ |
| String output | ✅ | ✅ |
| Input operations | ✅ | ✅ |
| Writeln statements | ✅ | ✅ |

Together with the generated regressions and example programs run by `scripts/verify_math.py`, this test demonstrates that the assembly backend produces correct results for the supported Pascal subset.
