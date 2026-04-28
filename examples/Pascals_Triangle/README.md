# Pascal's Triangle Demo (Standalone)

This directory contains a self-contained demonstration of Pascal's Triangle using the Pascal programming language. You can explore this demo independently of the main project.

**Standalone Directory**: `examples/Pascals_Triangle/`

## Files

- `full_binomial.pas` - Pascal program that calculates binomial coefficients recursively
- `Blaise_Pascal.md` - Comprehensive information about Blaise Pascal, the Pascal language, and Pascal's Triangle

## Program Description

The `full_binomial.pas` program demonstrates:

1. **Recursive function implementation** of binomial coefficient calculation
2. **Base case handling** for Pascal's Triangle edges (always 1)
3. **Recursive decomposition** following the triangle's mathematical structure
4. **Pascal language features**: functions, conditionals, recursion, nested `for` loops, and mixed `write`/`writeln` output

## How to Run (Standalone Instructions)

These instructions assume you're working from the `examples/Pascals_Triangle` directory or want to run this specific demo:

```bash
# From the main project directory:
cd /path/to/pascal-prolog-compiler

# Build the Pascal's Triangle program
swipl -q -s pascal_compiler.pl -- build-asm examples/Pascals_Triangle/full_binomial.pas pascals_triangle_demo

# Run the program
./pascals_triangle_demo
```

### Alternative: Quick Test

```bash
# Parse only (check syntax)
swipl -q -s pascal_compiler.pl -- parse examples/Pascals_Triangle/full_binomial.pas

# Semantic check only
swipl -q -s pascal_compiler.pl -- check examples/Pascals_Triangle/full_binomial.pas

# Generate assembly code
swipl -q -s pascal_compiler.pl -- asm examples/Pascals_Triangle/full_binomial.pas pascals_triangle.s
```

## Expected Output

```
1
1 1
1 2 1
1 3 3 1
1 4 6 4 1
1 5 10 10 5 1
1 6 15 20 15 6 1
```

This prints rows 0 through 6 of Pascal's Triangle.

### Understanding the Output

The program calculates each binomial coefficient C(row,col) using the recursive function and prints each row:

```
Row 0: 1
Row 1: 1 1
Row 2: 1 2 1
Row 3: 1 3 3 1
Row 4: 1 4 6 4 1
Row 5: 1 5 10 10 5 1
Row 6: 1 6 15 20 15 6 1
```

### Extending the Program

To generate more of Pascal's Triangle, you could modify the program to:
1. Increase the upper bound in `for row := 0 to 6 do`
2. Create a procedure to print more formatted triangle output
3. Implement memoization to optimize the recursive calculations

The current implementation intentionally keeps the recursive algorithm visible rather than optimizing it away.

## Mathematical Background

The program calculates binomial coefficients using the recursive formula:

C(n,k) = C(n-1,k-1) + C(n-1,k)

Where:
- C(n,k) is the binomial coefficient "n choose k"
- C(n,0) = C(n,n) = 1 (base cases)
- This formula directly implements the structure of Pascal's Triangle

## Educational Value

This example demonstrates:
- Recursion in programming
- Mathematical functions in code
- The connection between mathematics and computer science
- Historical continuity from 17th century mathematics to modern programming

## Exploring Further

### Within This Directory
- [Blaise_Pascal.md](Blaise_Pascal.md) - Comprehensive historical and mathematical context
- [full_binomial.pas](full_binomial.pas) - The Pascal source code

### Main Project Resources
If you want to explore the full Pascal-to-x86-64 compiler project:
- Main project: [../../README.md](../../README.md)
- Compiler source: [../../src/](../../src/)
- More examples: [../](../)

### External Resources
- [Pascal Programming Language](https://en.wikipedia.org/wiki/Pascal_(programming_language))
- [Pascal's Triangle](https://en.wikipedia.org/wiki/Pascal%27s_triangle)
- [Blaise Pascal Biography](https://en.wikipedia.org/wiki/Blaise_Pascal)

## Project Context

This Pascal's Triangle demo is part of a larger educational compiler project that:
- Compiles Pascal subset to x86-64 assembly
- Demonstrates compiler construction concepts
- Uses Prolog for implementation
- Supports functions, recursion, loops, and basic I/O

The demo showcases how fundamental mathematical concepts can be implemented in code and compiled to native executables.
