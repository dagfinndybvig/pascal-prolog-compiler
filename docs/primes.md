# Prime Number Algorithms: From Basic to Optimized

> [!WARNING]
> This project implements only a **fragment of Pascal**. It supports **integer-only arithmetic** and a focused feature subset that is just enough to do interesting work with prime-number programs.
>
> It is primarily a **Computer Science experiment** in language design, compiler construction, and algorithm exploration, not a full Pascal implementation.

This document explores various approaches to prime number generation, from the most basic to highly optimized, all implemented within the constraints of our integer-only Pascal compiler.

## Table of Contents

1. [Basic Division Approaches](#basic-division-approaches)
2. [Division-Free Approaches](#division-free-approaches)
3. [Square Root Optimized Approaches](#square-root-optimized-approaches)
4. [Final Presentation Version](#final-presentation-version)
5. [Building and Running the Programs](#building-and-running-the-programs)
6. [Mathematical Foundations](#mathematical-foundations)

## Basic Division Approaches

### 1. Simple Division Method (`examples/primes/basic/primes_less_than_200_simple.pas`)

**Mathematical Approach:**
```
To test if n is prime, check divisibility by all numbers from 2 to n-1
If any number divides n exactly, n is not prime
```

**Programmatic Implementation:**
```pascal
quotient := i / j;
product := quotient * j;
if product = i then { j divides i }
```

**Constraints Handled:**
- Uses only integer division (no floating-point)
- Works within 32-bit signed integer limits
- Simple and easy to understand

**Complexity:** O(n) per number tested

**Example:** Testing if 15 is prime:
- 15 ÷ 2 = 7, 2×7=14 ≠ 15
- 15 ÷ 3 = 5, 3×5=15 = 15 ✓ (not prime)

### 2. Optimized Division Method (`examples/primes/basic/primes_less_than_200.pas`)

**Mathematical Improvement:**
```
Instead of checking i = quotient × divisor
Check remainder = i - (i/j) × j
If remainder = 0, then divisor divides i
```

**Programmatic Implementation:**
```pascal
remainder := i - (i / j) * j;
if remainder = 0 then { j divides i }
```

**Advantages:**
- Fewer arithmetic operations per test
- Same mathematical correctness
- More efficient computation

**Complexity:** O(n) per number (but faster constant factor)

## Division-Free Approaches

### 3. Subtraction-Based Method (`examples/primes/special/primes_no_division.pas`)

**Mathematical Approach:**
```
Test divisibility by repeated subtraction:
While temp ≥ j: temp = temp - j
If temp = 0 at any point, j divides i
```

**Programmatic Implementation:**
```pascal
is_divisible := 0;
temp := i;
while temp >= j do
begin
  temp := temp - j;
  if temp = 0 then is_divisible := 1;
end;
```

**Constraints Handled:**
- **No division operations** used
- Works in environments where division is expensive/unavailable
- Uses only addition and subtraction

**Complexity:** O(i/j) per divisor test

**Trade-off:** Slower but more universally compatible

### 4. Multiplication+Subtraction Method (`examples/primes/special/primes_mult_sub.pas`)

**Mathematical Approach:**
```
Build multiples of j and subtract from i:
multiple = j, 2j, 3j, ... until multiple > i
If i - multiple = 0 for any multiple, j divides i
```

**Programmatic Implementation:**
```pascal
multiple := j;
difference := i - multiple;
while difference > 0 do
begin
  multiple := multiple + j;
  difference := i - multiple;
end;
if difference = 0 then { j divides i }
```

**Advantages:**
- No division operations
- Clear mathematical intuition
- Same complexity as subtraction-only

**Example:** Testing if 12 is divisible by 3:
- multiple = 3, difference = 9
- multiple = 6, difference = 6
- multiple = 9, difference = 3
- multiple = 12, difference = 0 ✓ (divisible)

## Square Root Optimized Approaches

### 5. Division with Square Root Optimization (`examples/primes/optimized/primes_sqrt_optimized.pas`)

**Mathematical Foundation:**
```
If n is composite (n = a × b), then at least one factor a ≤ √n
Therefore, only need to test divisors up to √n
```

**Programmatic Implementation:**
```pascal
{ Calculate square root approximation }
sqrt_approx := 1;
while sqrt_approx * sqrt_approx <= i do
  sqrt_approx := sqrt_approx + 1;
sqrt_approx := sqrt_approx - 1;

{ Test only up to sqrt_approx }
j := 3;
while j <= sqrt_approx do
begin
  { ... divisibility test ... }
  j := j + 2;
end;
```

**Complexity Improvement:**
- From O(n) to O(√n) per number
- For n=10,000: 100× fewer iterations

**Constraints Handled:**
- Square root calculated via integer arithmetic
- No floating-point operations
- Avoids overflow by stopping before √MAX_INT

### 6. Division-Free with Square Root Optimization (`examples/primes/special/primes_sqrt_no_div.pas`)

**Combines Both Optimizations:**
- Square root limit (O(√n) complexity)
- Subtraction-based testing (no division)
- Skip even numbers (50% fewer tests)

**Programmatic Implementation:**
```pascal
{ Calculate sqrt limit }
sqrt_approx := 1;
while sqrt_approx * sqrt_approx <= i do
  sqrt_approx := sqrt_approx + 1;
sqrt_approx := sqrt_approx - 1;

{ Test only odd divisors up to sqrt }
j := 3;
while j <= sqrt_approx do
begin
  { Subtraction-based divisibility test }
  temp := i;
  while temp >= j do
  begin
    temp := temp - j;
    if temp = 0 then { divisible }
  end;
  j := j + 2; { skip evens }
end;
```

**This is the most efficient division-free approach**

## Final Presentation Version

### 7. Screen-Filling Display with Summary (`examples/primes/optimized/primes_with_summary.pas`)

**Features:**
- Uses optimized square root approach
- Continuous output with single spaces: `2 3 5 7 11 ...`
- Fills terminal screen with primes
- Summary at end: "Found these primes between 2 and 46000"

**Programmatic Implementation:**
```pascal
{ Main loop }
write('2 ');
i := 3;
while i <= 46000 do
begin
  { ... prime testing ... }
  if is_prime = 1 then
  begin
    write(i);
    write(' ');
  end;
  i := i + 2;
end;

{ Summary }
writeln('');
writeln('');
writeln('Found these primes between 2 and 46000');
```

**Perfect for demonstration and visualization**

## Building and Running the Programs

All programs can be built and run using the same commands:

```bash
# Build the program
swipl -q -s pascal_compiler.pl -- build-asm program_name.pas output_name

# Run the program
./output_name
```

**Specific Examples:**

```bash
# Build and run the simple version
swipl -q -s pascal_compiler.pl -- build-asm examples/primes/basic/primes_less_than_200_simple.pas primes_simple
./primes_simple

# Build and run the final presentation version
swipl -q -s pascal_compiler.pl -- build-asm examples/primes/optimized/primes_with_summary.pas primes_display
./primes_display
```

## Mathematical Foundations

### Prime Number Definition
A prime number is a natural number greater than 1 that has no positive divisors other than 1 and itself.

### Fundamental Theorem of Arithmetic
Every integer greater than 1 either is prime itself or is the product of prime numbers.

### Divisibility Rules
- **Division approach**: `i % j == 0` (using remainder)
- **Subtraction approach**: Repeated subtraction until 0 or negative
- **Multiplication approach**: Building multiples until matching i

### Complexity Analysis (per candidate number n)

| Approach | Complexity | Operations | Notes |
|----------|------------|------------|-------|
| Naive division | O(n) | n-2 tests | Simple but slow |
| Optimized division | O(n) | n/2 tests | Skips evens |
| Square root + division | O(√n) | √n/2 tests | Best balance |
| Subtraction-based | O(i/j) | i/j subtractions | No division |
| Mult+Sub | O(i/j) | i/j operations | Clear logic |
| Square root + subtraction | O(√n × i/j) | Best division-free | Most efficient |

### Integer Overflow Considerations

Our implementation handles 32-bit signed integers (-2,147,483,648 to 2,147,483,647):

- **Largest safe integer square root**: 46,340
- **Largest square that fits in 32-bit signed int**: 46,340² = 2,147,395,600
- **First overflowing square**: 46,341² = 2,147,488,281 (> 2,147,483,647)

The square root calculation uses integer arithmetic to avoid floating-point operations while staying within safe bounds.

## Summary

This collection demonstrates:

1. **Mathematical progression**: From basic to sophisticated algorithms
2. **Constraint handling**: Working within integer-only, no floating-point environment
3. **Performance optimization**: Reducing complexity from O(n) to O(√n)
4. **Algorithm diversity**: Multiple approaches to the same problem

Each program represents a step in the evolution of prime number algorithms, showing how mathematical insights can lead to increasingly efficient solutions while respecting computational constraints.

## Verification and Hardening Update

The prime programs continue to be mathematically verified against independent references via `scripts/verify_math.py`.

The verification workflow now also includes backend hardening regressions to ensure the compiler/runtime execution model used by these prime programs remains correct under edge conditions. Added checks include:
- `division_by_zero_guard`
- `mangling_collision_scope`
- `expression_stress`
- `division_sign_semantics`
- `nested_control_flow_scope`

Current status: prime correctness checks and all added hardening checks are passing.
