# Challenging Test Programs

This directory contains test programs designed to stress-test specific aspects of the Pascal compiler beyond simple prime number calculations.

## Test Programs

### Mathematical Algorithms

| File | Description | What It Tests |
|------|-------------|---------------|
| `isqrt_newton.pas` | Integer square root via Newton's method | Division, comparison, loop convergence |
| `gcd_euclidean.pas` | Greatest common divisor (Euclidean algorithm) | Modulo via subtraction, loop termination |
| `int_power.pas` | Integer exponentiation | Accumulating multiplication, verification loop |
| `collatz.pas` | 3n+1 sequence | Complex conditional logic, odd/even detection |
| `palindrome.pas` | Palindrome number check | Digit extraction, number reconstruction |
| `factorial_overflow.pas` | Factorial with overflow detection | Overflow detection via division verification |

### Compiler Stress Tests

| File | Description | What It Tests |
|------|-------------|---------------|
| `scope_shadowing.pas` | Deeply nested variable shadowing | Name mangling, scope isolation |
| `expr_register_stress.pas` | Complex nested expressions | Register allocation, spilling |

## Build and Run

```bash
# Build a specific test
swipl -q -s pascal_compiler.pl -- build-asm examples/challenging/isqrt_newton.pas isqrt_newton

# Run it
./isqrt_newton
```

## Expected Outputs

### isqrt_newton.pas
```
4
16
4
16
25
```

### gcd_euclidean.pas
```
1
21
```

### int_power.pas
```
1024
10
```

### collatz.pas
```
111
9232
```

### palindrome.pas
```
12321
1
54321
0
```

### scope_shadowing.pas
```
1221
```

### expr_register_stress.pas
```
-36
21
```

### factorial_overflow.pas
```
1
2
6
24
120
720
5040
40320
362880
3628800
39916800
479001600
1932053504
1278945280
2004310016
```
(Note: 13! and beyond overflow 32-bit signed integers)

## Notes

- All numbers are kept small (< 50000) to avoid 32-bit integer overflow
- Programs use only integer arithmetic (no floating-point)
- `mod` operation is simulated via: `a - (a / b) * b`
- Division uses truncation toward zero semantics
