# Prime Number Algorithm Progression

This document summarizes the evolutionary path of prime number algorithms in this project, from least to most efficient.

## The Progression

### 1. Basic Division Approaches
**Files**: `examples/primes/basic/primes_less_than_200_simple.pas`, `examples/primes/basic/primes_less_than_200.pas`

**Characteristics**:
- Use integer division to test divisibility
- Test all potential divisors
- Simple and straightforward
- Complexity: O(n) per number

**Key Insight**: `remainder = i - (i/j)*j` tells us if j divides i

### 2. Division-Free Approaches
**Files**: `examples/primes/special/primes_no_division.pas`, `examples/primes/special/primes_mult_sub.pas`

**Characteristics**:
- Use only addition/subtraction (no division operations)
- Mathematically equivalent but computationally expensive
- Complexity: O(i/j) per divisor test
- Useful in environments where division is unavailable/expensive

**Key Insight**: Divisibility can be tested by repeated subtraction

**Variants**:
- `examples/primes/special/primes_no_division.pas`: Simple subtraction-based testing
- `examples/primes/special/primes_mult_sub.pas`: Multiplication+subtraction hybrid approach

### 3. Square Root Optimized Approaches
**Files**: `examples/primes/optimized/primes_sqrt_optimized.pas`, `examples/primes/special/primes_sqrt_no_div.pas`

**Characteristics**:
- Test only up to √n (mathematical optimization)
- Skip even numbers after testing 2
- Complexity: O(√n) per number
- 10-100× faster than naive approaches

**Key Insight**: If n is composite, it has a factor ≤ √n

**Variants**:
- `examples/primes/optimized/primes_sqrt_optimized.pas`: Square root optimization with division
- `examples/primes/special/primes_sqrt_no_div.pas`: Square root optimization with subtraction-based testing

### 4. Final Presentation Version
**File**: `examples/primes/optimized/primes_with_summary.pas`

**Characteristics**:
- Screen-filling output format
- Clean presentation with summary
- Uses optimized algorithms
- Perfect for demonstration

## Performance Comparison

| Approach | Complexity | Relative Speed | Use Case |
|----------|------------|----------------|----------|
| Naive division | O(n) | 1× | Baseline |
| Optimized division | O(n) | 2× | Simple improvement |
| Subtraction-based | O(i/j) | 0.1× | Division-free environments |
| Square root + division | O(√n) | 10-30× | Production use |
| Square root + subtraction | O(√n × i/j) | 5-15× | Constrained environments |

## Mathematical Foundations

### Prime Definition
A prime number is a natural number > 1 with exactly two distinct positive divisors: 1 and itself.

### Divisibility Testing
All algorithms test: Does j divide i?
- Division: `i % j == 0`
- Subtraction: Repeated subtraction until 0 or negative
- Multiplication: Build multiples until matching i
- Hybrid: Combine multiplication and subtraction for efficiency

### Optimization Principles
1. **Square root limit**: Test only up to √n
2. **Skip evens**: After testing 2, skip all even numbers
3. **Early termination**: Stop at first divisor found
4. **Algorithm selection**: Choose based on constraints

## Key Takeaways

1. **Multiple approaches exist** for the same problem
2. **Constraints drive algorithm choice** (division vs no-division)
3. **Mathematical insights enable optimization** (square root limit)
4. **Performance differences can be dramatic** (10-100× speedups)
5. **All approaches are mathematically equivalent** (same results)

## Verification and Hardening Status

The progression results are now covered by an expanded verification workflow in `scripts/verify_math.py`.

In addition to mathematical output verification, the suite now includes backend regressions that protect algorithm execution correctness under:
- Deep nested arithmetic expressions
- Signed integer division edge cases
- Nested control flow with block shadowing
- Runtime division-by-zero handling

Current status: baseline algorithm checks and added hardening regressions are passing.

## How to Explore

Run each program to see the progression:

```bash
# Build and run each version
swipl -q -s pascal_compiler.pl -- build-asm examples/primes/special/primes_no_division.pas primes_slow
swipl -q -s pascal_compiler.pl -- build-asm examples/primes/optimized/primes_sqrt_optimized.pas primes_fast

# Compare execution times
./primes_slow   # Noticeable delay
./primes_fast   # Nearly instantaneous
```

See `PERFORMANCE_COMPARISON.md` for detailed benchmarking information.