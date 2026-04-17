# Mathematical Verification Report

## Status
**Result:** PASS  
**Date:** 2026-04-17  
**Version:** v1.3

This verification is reproducible from files in this release package.

## Reproducible Verification Procedure

Run:

```bash
python3 scripts/verify_math.py
```

The script:
1. Builds all `.pas` programs in `examples/`.
2. Runs the prime programs and compares outputs against independently generated reference primes.
3. Checks count-based variants up to 46000.
4. Runs the comprehensive feature test with fixed input.
5. Runs backend hardening regression programs generated at verification time.

## Verified Results

### 1. Build Integrity
- All shipped example programs build successfully with:
  - SWI-Prolog 8.4.2
  - GCC 11.4.0

### 2. Prime Sequence Correctness (< 200)
Verified programs output the exact prime sequence from 2 to 199:
- `examples/primes/basic/primes_less_than_200.pas`
- `examples/primes/basic/primes_less_than_200_simple.pas`
- `examples/primes/special/primes_no_division.pas`
- `examples/primes/special/primes_mult_sub.pas`
- `examples/primes/optimized/primes_sqrt_optimized.pas`
- `examples/primes/special/primes_sqrt_no_div.pas`

Reference sequence length: **46**

### 3. Prime Count Correctness (<= 46000)
Verified against an independent sieve implementation:
- `examples/primes/basic/primes_simple_slow.pas` reports **4761**
- `examples/primes/optimized/primes_simple_fast.pas` reports **4761**

Expected count of primes <= 46000: **4761**

### 4. Summary Variant Correctness
- `examples/primes/optimized/primes_with_summary.pas`
- Prime stream before summary matches independent reference for all primes <= 46000.

### 5. Comprehensive Program Behavior
- `examples/comprehensive_test.pas` executes correctly and produces expected arithmetic, control-flow, relational, I/O, and string-output behavior.

### 6. Backend Safety and Correctness Regressions
Verified additional regression checks in `scripts/verify_math.py`:

- `division_by_zero_guard`
  - Confirms division by zero exits through runtime error handling (no SIGFPE crash path).
- `mangling_collision_scope`
  - Confirms user identifiers cannot collide with lowered local symbol representation.
- `expression_stress`
  - Confirms deep arithmetic expression evaluation remains correct.
- `division_sign_semantics`
  - Confirms signed integer division truncation behavior is correct.
- `nested_control_flow_scope`
  - Confirms nested loop/branch evaluation and scoped shadowing behavior.

All listed checks currently pass.

## Complexity Notes

- Naive divisor checking over a range up to `N`: approximately `O(N^2)`
- Square-root bounded divisor checking over a range up to `N`: approximately `O(N*sqrt(N))`
- Division-free variants are mathematically equivalent but slower due to repeated subtraction.

## Conclusion

The prime-number examples are mathematically correct for their documented ranges, and the verification process is reproducible directly from this release. The verification suite now also includes backend safety and stress regressions that pass in the current workspace state.
