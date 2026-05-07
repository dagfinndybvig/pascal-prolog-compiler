# Set Examples

This folder contains runnable examples for the Pascal `set` feature in this compiler.

## What Sets Are (Quick Overview)

A set is a collection of distinct values from a fixed domain.

In Pascal-style syntax used here:

- Declare a set type with a bounded integer range, for example `set of 0..31`.
- Build set values with literals: `[]`, `[1,3,5]`, `[1..5, 8, 10..12]`.
- Test membership with `in`, for example `if 7 in s then ...`.
- Combine sets with:
  - union: `+`
  - difference: `-`
  - intersection: `*`
- Compare sets with `=`, `<>`, subset `<=`, and superset `>=`.

## How Sets Are Implemented Here

This project currently implements sets as a compact bitset representation.

- v1 set domain is bounded to integer ranges within `0..63`.
- A set value is stored in one 64-bit slot.
- Set algebra (`+`, `-`, `*`) lowers to fast bitwise operations.
- Membership (`in`) is lowered to range-check + bit test.
- Equality and inequality are simple value comparisons of the bitset.

Practical effect: sets are fast and predictable for the supported subset.

## What Is Missing for Full Pascal Coverage

This compiler intentionally implements a Pascal subset, not full ISO Pascal.

Set-related gaps versus broader/full Pascal dialect coverage include:

- Set base types are intentionally narrow in this project version (bounded integer subranges in the supported range model).
- No direct set printing/parsing via runtime I/O (examples use boolean-style checks and explanatory text instead).
- Some dialect-specific Pascal set features and edge semantics outside this subset are not implemented.

So the set feature is solid for this compiler's target scope, but not a complete all-dialects Pascal set implementation.

## Example Programs In This Folder

- `set_basic_ops.pas`
  - Minimal demo of union, intersection, difference, and membership.
  - Output style: `1`/`0` for true/false checks.

- `set_ranges_and_empty.pas`
  - Shows empty set literal, range literals, mixed literals, and membership.
  - Output style: `1`/`0` checks.

- `set_equality.pas`
  - Demonstrates equality/inequality and algebraic transformation to equal sets.
  - Output style: `1`/`0` checks.

- `set_subset_relations.pas`
  - Demonstrates subset (`<=`) and superset (`>=`) relations, including empty-set relations.
  - Output style: `1`/`0` checks.

- `set_feature_showcase.pas`
  - Rich walkthrough with labeled `PASS`/`FAIL` messages.
  - Covers literals, ranges, algebra, equality, subset/superset, and variable membership.

- `set_boundary_showcase.pas`
  - Rich boundary-focused walkthrough.
  - Verifies behavior around endpoints `0` and `31` and full range `0..31`.

## Build And Run From This Folder

If you are reading only this folder, run from repository root:

```bash
swipl -q -s pascal_compiler.pl -- build-asm examples/sets/set_feature_showcase.pas set_feature_showcase
./set_feature_showcase
```

Boundary-focused demo:

```bash
swipl -q -s pascal_compiler.pl -- build-asm examples/sets/set_boundary_showcase.pas set_boundary_showcase
./set_boundary_showcase
```

Run any set example with the same pattern:

```bash
swipl -q -s pascal_compiler.pl -- build-asm examples/sets/<program>.pas <program>
./<program>
```

If you are inside `examples/sets`, use:

```bash
cd ../..
swipl -q -s pascal_compiler.pl -- build-asm examples/sets/set_basic_ops.pas set_basic_ops
./set_basic_ops
```