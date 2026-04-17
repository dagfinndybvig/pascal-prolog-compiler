# Performance Comparison: Slowest vs Fastest Prime Algorithms

## The Experiment

We compare two extreme approaches to prime number generation:

### 🐢 SLOWEST: `examples/primes/special/primes_no_division.pas`
- **Approach**: Naive subtraction-based divisibility testing
- **Complexity**: O(n²) - Tests all numbers from 2 to n-1 for each candidate
- **Operations**: Uses only addition/subtraction (no division)
- **Optimizations**: None

### 🚀 FASTEST: `examples/primes/optimized/primes_sqrt_optimized.pas`
- **Approach**: Square root optimization with division
- **Complexity**: O(n√n) - Tests only up to √n, skips even numbers
- **Operations**: Uses division for efficiency
- **Optimizations**: Square root limit, skip evens, early termination

## Expected Performance Difference

For finding primes up to N:

| N     | Slow Operations | Fast Operations | Ratio  |
|-------|----------------|----------------|--------|
| 100   | ~5,000         | ~700           | ~7×    |
| 500   | ~125,000       | ~8,000         | ~16×   |
| 1,000 | ~500,000       | ~15,000        | ~33×   |
| 5,000 | ~12.5M         | ~105,000       | ~120×  |

## How to Test

### Run the slow version:
```bash
swipl -q -s pascal_compiler.pl -- build-asm examples/primes/special/primes_no_division.pas primes_slow
./primes_slow
```

### Run the fast version:
```bash
swipl -q -s pascal_compiler.pl -- build-asm examples/primes/optimized/primes_sqrt_optimized.pas primes_fast
./primes_fast
```

## What You'll Observe

1. **Slow version**: Visible delay, especially for larger ranges
2. **Fast version**: Nearly instantaneous, even for larger ranges
3. **Same results**: Both find identical primes (mathematically equivalent)

## Mathematical Equivalence

Both algorithms implement the same prime test:
```
A number p is prime if it has no divisors other than 1 and p
```

**Slow version**: Checks every number from 2 to p-1
**Fast version**: Checks only odd numbers from 3 to √p

## Why the Difference Matters

This demonstrates:
- **Algorithm choice > Hardware**: Better algorithm beats faster CPU
- **Complexity matters**: O(n²) vs O(n√n) makes huge difference
- **Optimization pays off**: Simple mathematical insights yield massive speedups

## Real-World Impact

In production systems:
- Slow algorithm: Might take hours for large ranges
- Fast algorithm: Completes in seconds
- Difference becomes even more dramatic for larger N

## Conclusion

The fast algorithm isn't just "a bit better" - it's orders of magnitude faster while producing identical results. This is why algorithmic optimization is crucial in computer science!

## Verification and Backend Reliability Note

Performance comparisons in this document assume correct backend execution semantics. The project now includes additional regression checks in `scripts/verify_math.py` that validate critical backend correctness and safety paths, including:
- division-by-zero runtime error handling
- deep expression evaluation correctness
- signed division semantics
- nested control-flow and scope behavior

Current status: these hardening checks pass in addition to the prime-output checks used for performance-related examples.