# Pointers v1 Plan (Typed, List-Oriented)

This document defines a concrete v1 pointer feature set for the Pascal compiler, aimed at enabling linked records (singly linked lists) while minimizing regression risk.

> Status: Implemented in v1.13.0 (2026-05-05). This file is retained as the design/rollout record.

## Goals

- Enable linked data structures based on records.
- Keep pointer support strictly typed.
- Avoid pointer arithmetic in v1.
- Preserve existing behavior for non-pointer programs.

## Non-Goals (v1)

- Untyped pointers.
- Pointer arithmetic (+, -, indexing via pointers).
- Generic memory reinterpretation/casts.
- Full Pascal object/variant features.

## Design Principles

- Typed only: every pointer has a target type.
- Fail fast in semantic checking.
- Keep IR and codegen changes explicit and local.
- Add runtime guards for null dereference.

## v1 Language Surface

### New syntax and keywords

- Type declarations section (`type`) to support named and recursive types.
- Pointer type constructor (`^TypeName`).
- Address-of (`@var_or_lvalue`).
- Dereference (`p^`).
- Nil literal (`nil`).
- Heap management statements:
  - `new(p)`
  - `dispose(p)`

### Linked-list-enabling example target

```pascal
program list_demo;

type
  NodePtr = ^Node;
  Node = record
    value: integer;
    next: NodePtr;
  end;

var
  head, n: NodePtr;

begin
  head := nil;
  new(n);
  n^.value := 10;
  n^.next := head;
  head := n;
end.
```

## Parser Plan (src/parser.pl)

### Grammar extensions

- Program declaration order becomes:
  - `program ...;`
  - optional `type` declarations
  - existing top-level var and function/procedure declarations
  - main block

- Type declarations:
  - `type Name = type_spec ;`

- Type specs extended with:
  - named type reference: `type_name(Name)`
  - pointer type: `ptr(TypeName)` (or equivalent internal form)

- Expression/primary extensions:
  - `nil`
  - address-of: `addr_of(LValue)`
  - dereference: `deref(Expr)`

- Lvalue-capable forms extended to include:
  - dereferenced pointer fields, e.g. `n^.value`

- Statements extended with:
  - `new(LValue)`
  - `dispose(LValue)`

### Predicate touchpoints

- Extend `program//1` and declaration collectors.
- Add `type_declarations//1` and `type_decl//1`.
- Extend `type_spec//1`.
- Extend `primary//1` and assignment target parsing.
- Extend `statement//1` for `new`/`dispose`.

## Semantics Plan (src/semantics.pl)

### Environment model

- Add type environment for named type declarations.
- Resolve named types (including recursive references through names).

### Type rules

- `nil` type-checks as pointer-compatible only.
- `new(x)` requires `x` to be pointer lvalue.
- `dispose(x)` requires `x` to be pointer lvalue.
- Dereference requires pointer operand.
- Assignment supports pointer-to-same-target type and `nil` assignment to pointers.
- Comparisons for pointers in v1:
  - allow `=` and `<>`
  - disallow `< <= > >=`

### Safety rules

- Keep strict exact-type compatibility otherwise.
- Reject pointer arithmetic operators.
- Keep var-arg checks lvalue-aware for pointer/deref/field chains.

### Predicate touchpoints

- `check_program/1`: initialize and pass type env.
- `ensure_valid_type/1`: support pointers and named type resolution.
- `check_expr/4` and `bin_expr_type/4`: pointer and nil typing.
- `ensure_assignable/2`: pointer rules + nil compatibility.
- `ensure_var_ref_arg/4`: pointer-aware lvalue acceptance.
- `check_stmt/3`: `new` and `dispose` checks.

## IR Plan (src/ir.pl)

### New IR forms (proposed)

- `ir_null`
- `ir_addr_of(...)` (reuse existing where possible)
- `ir_load_ptr(Base)` / `ir_store_ptr(Base, Value)` or equivalent generic load/store-through-address
- `ir_new(TargetAddr, ByteSize)`
- `ir_dispose(PtrExpr)`
- `ir_null_check(PtrExpr)` before dereference-sensitive operations

### Lowering strategy

- Lower pointer lvalues to address expressions.
- Lower dereference read/write via explicit load/store through computed address.
- Lower `new(p)` to runtime allocation call and store returned address into `p`.
- Lower `dispose(p)` to runtime free call.

### Predicate touchpoints

- `lower_stmt/6`: add `new` and `dispose`, pointer assigns.
- `lower_expr/4`: add `nil`, address-of, dereference.
- Lvalue address lowering helper (new predicate) to centralize var/field/deref addressing.

## Codegen Plan (src/codegen_asm_x86_64.pl)

### Core requirements

- Represent pointers as 64-bit addresses in registers/stack slots.
- Emit null checks before dereference loads/stores (branch to runtime error handler).
- Emit runtime calls for allocation/free with ABI-safe stack alignment wrappers (reuse existing call wrappers).

### Proposed runtime-facing codegen ops

- `rt_alloc(size)` -> pointer in `%rax`
- `rt_free(ptr)`
- `null_deref_error` handler label/message similar to existing error handlers.

### Predicate touchpoints

- `asm_expr/2` and `asm_expr_func/5`: nil/address/deref.
- assignment helpers for pointer stores.
- handler/message emitters alongside division and bounds handlers.

## Runtime Plan (runtime/runtime.c, runtime/runtime.h)

### Add functions

- `int64_t rt_alloc(int64_t size)`
- `void rt_free(int64_t ptr)`

### Error handling

- Add runtime error code/message for null dereference.
- Keep behavior consistent with current runtime error paths.

## Layout and Size Rules

- Pointer occupies 1 slot (8 bytes).
- Record field slot computation includes pointer fields as 1 slot.
- `new` allocation size for `^RecordType` uses resolved record slot count * 8.

## Testing Plan

### New positive tests

- Basic pointer assignment and nil checks.
- `new` + field write/read through `^`.
- Singly linked list push/traverse for small fixed count.
- `dispose` on allocated nodes.

### New negative tests

- Dereference non-pointer.
- `new` on non-pointer lvalue.
- `dispose` on non-pointer expression.
- Pointer arithmetic attempt.
- Pointer relational compare with `< <= > >=`.

### Regression

- Re-run comprehensive and math verification suites unchanged.

## Milestones

1. M1: Type declarations and named type resolution.
2. M2: Pointer types + nil + basic assignment/comparison.
3. M3: Dereference + field-through-pointer lvalues.
4. M4: new/dispose runtime integration and null guards.
5. M5: Linked list examples + docs + regression signoff.

## Risk Controls

- Feature branch only.
- Land in small commits per milestone.
- Keep parser and semantic errors explicit and deterministic.
- Maintain existing test suite as merge gate.

## Implementation Outcomes

- Pointer type spelling is `^TypeName`; dereference forms include `p^` and `p^.field`.
- Heap allocation is exposed via `new(p)` and deallocation via `dispose(p)`.
- Runtime includes null-pointer error handling for dereference-sensitive operations.
- Pointer arithmetic remains intentionally unsupported.
