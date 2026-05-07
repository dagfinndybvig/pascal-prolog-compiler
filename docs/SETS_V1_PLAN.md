# Sets v1 Plan (Bitset, Integer Subrange)

This document defines a concrete v1 `set` feature for the Pascal compiler with a narrow, low-risk scope that fits the current architecture.

## Goals

- Add first-class Pascal set values with predictable codegen.
- Keep semantics strict and explicit.
- Reuse existing compiler pipeline patterns (Lexer -> Parser -> Semantics -> IR -> ASM).
- Preserve behavior for non-set programs.

## Non-Goals (v1)

- Enumerated-base sets.
- Full char-range sets.
- Subset/superset relational operators (`<=`, `>=`) on sets.
- Set printing/parsing in runtime I/O.

## v1 Language Surface

### Type declarations

- New type form: `set of <base-range>`.
- v1 base-range is integer subrange only.

Example:

```pascal
type
  SmallSet = set of 0..31;
```

### Expressions and operators

- Set constructor literal: `[1, 2, 5]`
- Set constructor with ranges: `[1..5, 8, 10..12]`
- Empty set: `[]`
- Membership: `x in s`
- Set algebra:
  - union: `a + b`
  - difference: `a - b`
  - intersection: `a * b`
- Equality:
  - `a = b`
  - `a <> b`

### Example target

```pascal
program set_demo;

type
  SmallSet = set of 0..31;

var
  odds, primes, mix: SmallSet;
  x: integer;

begin
  odds := [1,3,5,7,9];
  primes := [2,3,5,7,11,13];
  mix := (odds + primes) - [1];
  x := 7;
  if x in mix then
    writeln(1)
  else
    writeln(0)
end.
```

## Representation Choice

Use a single 64-bit slot for v1 set values.

- Allowed base domain: integer subrange `Low..High` with `0 =< Low`, `High =< 63`.
- Bit mapping: value `V` maps to bit index `(V - Low)`.
- Storage size: one normal scalar slot (8 bytes), matching existing stack/global layout assumptions.

Reasoning:

- Fits existing scalar slot model.
- Enables fast operations via bitwise instructions.
- Avoids immediate runtime library changes.

## Parser Plan (src/parser.pl)

### AST extensions

- Type AST:
  - `set(subrange(Low, High))`
- Set literal AST:
  - `set_lit(Elements)`
- Set literal elements:
  - `set_elem_value(Expr)`
  - `set_elem_range(ExprLow, ExprHigh)`
- Membership expression:
  - `bin(in, ElemExpr, SetExpr)`

### Grammar updates

1. Extend `type_spec//1`:
   - parse `set of <int> .. <int>` into `set(subrange(Low, High))`.
2. Extend relational layer:
   - support `in` in `rel_op//1` with `rel_op(in) --> keyword(in).`
3. Extend `primary//1`:
   - parse `[` ... `]` as set literal in expression context.
4. Add new DCGs:
   - `set_literal//1`
   - `set_elem//1`
   - comma-tail helper for set element lists.

### Lexer updates (src/lexer.pl)

- Add keywords:
  - `set`
  - `in`

No symbol changes are required (`[`, `]`, and `..` already exist).

## Semantics Plan (src/semantics.pl)

### Type model

Add set type as a valid type:

- `set(subrange(Low, High))`

Validation rules:

- `Low` and `High` must be integers.
- `Low =< High`.
- `Low >= 0` and `High =< 63` for v1.

### Expression typing

Add `check_expr/4` support for:

- `set_lit(Elements)` -> infer a set type from context or literal bounds.
  - v1 rule: all explicit elements/ranges in one literal must be integer-typed constants.
  - if used in assignment/comparison, ensure assignable to target set base range.
- `bin(in, Elem, SetExpr)` -> `boolean`.
  - `Elem` must be `integer`.
  - `SetExpr` must be `set(subrange(_, _))`.

### Operator typing

Extend `bin_expr_type/4`:

- `+`, `-`, `*` on two compatible set types -> set type.
- `=`, `<>` on two compatible set types -> `boolean`.
- `in` for `integer` and set -> `boolean`.

Compatibility rule for v1:

- same resolved base range (`Low..High`) on both set operands.

### Assignment and parameter compatibility

Extend:

- `ensure_assignable/2`
- `types_compatible/2`

to treat sets as compatible only when base ranges match exactly.

### Writability/readability

No changes to I/O writability/readability in v1.

- `ensure_writable_type/1`: do not add set.
- `ensure_readable_type/1`: do not add set.

## IR Plan (src/ir.pl)

### New IR expression forms

- `ir_set_const(Mask)`
- `ir_set_bin(Op, Left, Right)` where `Op` in `[set_union, set_diff, set_inter]`
- `ir_set_in(ElemExpr, SetExpr, Low, High)`

### Lowering strategy

1. Set literals lower to `ir_set_const(Mask)` when all elements are compile-time constants.
2. Set operators lower to `ir_set_bin(...)`.
3. `in` lowers to `ir_set_in(...)` carrying base range for bounds guard logic.
4. Set assignment still uses existing `ir_assign/2` since set is scalar-sized.

### Semantic-to-IR contract

- IR assumes set operands are already type-checked and range-compatible.
- Any dynamic element for membership is allowed; codegen handles range check.

## Codegen Plan (src/codegen_asm_x86_64.pl)

### asm_expr support

Add clauses for:

- `asm_expr(ir_set_const(Mask), ...)` -> `movq $Mask, %rax`
- `asm_expr(ir_set_bin(set_union, L, R), ...)` -> bitwise `or`
- `asm_expr(ir_set_bin(set_diff, L, R), ...)` -> `and` with complement of right
- `asm_expr(ir_set_bin(set_inter, L, R), ...)` -> bitwise `and`
- `asm_expr(ir_set_in(Elem, Set, Low, High), ...)` -> boolean in `%rax`

### Membership code shape

Pseudo-flow:

1. Evaluate `Elem` -> `%rax`
2. Range check against `[Low, High]`
3. If out-of-range -> result `0`
4. Else compute bit index `Elem - Low`, test bit in set mask, return `0/1`

### Comparison reuse

No new comparison op needed if lowerer keeps set equality as `ir_bin('=', Left, Right)` and `ir_bin('<>', Left, Right)` on 64-bit values.

## Runtime Plan

No runtime C changes needed for v1.

- All operations are local bitwise arithmetic in generated assembly.

## Concrete Touchpoints

- Lexer:
  - `keyword_or_ident/2`
- Parser:
  - `type_spec//1`
  - `rel_op//1`
  - `primary//1`
  - new set literal DCGs
- Semantics:
  - `check_expr/4`
  - `bin_expr_type/4`
  - `ensure_assignable/2`
  - `types_compatible/2`
  - `ensure_valid_type/1`
- IR:
  - `lower_expr/4`
  - optional helper for literal mask folding
- Codegen:
  - `asm_expr/2`

## Test Plan

### Positive tests

1. Literal assignment:
   - `s := [];`
   - `s := [1,2,3];`
   - `s := [1..3, 10..12];`
2. Operators:
   - union/difference/intersection produce expected memberships.
3. Membership:
   - `if 5 in s then ...`
   - out-of-range membership returns false.
4. Equality:
   - same set compares equal; modified set compares unequal.
5. Type alias usage:
   - `type SmallSet = set of 0..31;`
   - pass/return as scalar function values if desired.

Suggested new example file:

- `examples/datatypes/set_demo.pas`

### Negative tests

1. Invalid base range:
   - `set of -1..31`
   - `set of 0..128`
2. Mixed-type literal elements.
3. Set ops with mismatched base ranges.
4. `in` with non-integer left operand.
5. Writing or reading whole sets through `write`/`readln` (should reject).

## Milestones

1. M1: Lexer + parser AST for set type and set literals.
2. M2: Semantics type validation and operator rules.
3. M3: IR lowering for set constants and set ops.
4. M4: Codegen for bitset ops and membership.
5. M5: New examples + regression run (`examples/comprehensive_test.pas`, `scripts/verify_math.py`).

## Risk Controls

- Keep v1 to one-word bitsets (`0..63`) only.
- Reject unsupported set domains early in semantics.
- Land in small commits by milestone.
- Preserve existing tests as merge gate.

## v2 Extension Path

- Multiword bitsets for larger integer/char domains.
- Char-set literals (for example `['a'..'z']`).
- Optional subset/superset operators.
- Optional runtime print helpers for debugging sets.