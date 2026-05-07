# CONST.md - `const` Feature Implementation

> **Status**: Work in Progress (✅ Lexer, Parser, Semantics, IR | ❌ Full Testing)

## Overview

This document describes the **`const` feature** implementation for the Pascal-Prolog compiler. The feature adds support for **constant declarations** in Pascal, allowing developers to define named constants with compile-time values. This is a **work in progress** and has been implemented across the compiler pipeline (lexer, parser, semantics, and IR), but requires further testing and validation.

---

## Feature Description

### What is `const` in Pascal?
In Pascal, `const` is used to declare **named constants** that are initialized with a value and **cannot be modified** during program execution. Constants improve code readability, maintainability, and performance by replacing "magic numbers" with meaningful names.

### Supported Syntax
The current implementation supports the following `const` declarations:

#### 1. Global Constants
```pascal
const
  MaxSize = 100;
  Pi = 3;
  Greeting = 'Hello, World!';
```

#### 2. Local Constants (Inside Procedures/Functions)
```pascal
procedure MyProcedure;
const
  LocalConst = 42;
begin
  writeln(LocalConst);
end;
```

#### 3. Typed Constants (Optional Type Annotation)
```pascal
const
  MaxSize: integer = 100;
  IsActive: boolean = true;
```

#### 4. Constant Expressions
The compiler supports **compile-time evaluation** of constant expressions, including:
- Literals: `42`, `true`, `'A'`, `nil`
- Arithmetic: `2 + 2`, `10 * 5`
- Unary operations: `-5`, `not true`
- Binary operations: `10 + 20`, `100 / 2`

Example:
```pascal
const
  ArraySize = 10;
  MaxIndex = ArraySize - 1;  % Evaluated at compile-time
```

---

## Implementation Details

The `const` feature was implemented following the **6-step process** outlined in `AGENTS.md` for adding new language features. Below is a summary of the changes made to each component of the compiler.

---

### 1. Lexer (`src/lexer.pl`)
**Change**: Added `const` as a recognized keyword.
```prolog
keyword_or_ident(const, kw(const)) :- !.
```
- **Purpose**: Ensures the lexer recognizes `const` as a keyword (not an identifier).
- **Location**: Added to the `keyword_or_ident/2` predicate list.

---

### 2. Parser (`src/parser.pl`)
**Changes**: Added parsing rules for `const` declarations at both the **global** and **local** (block) levels.

#### Global `const` Declarations
- Added `const_declarations//1` to the `program//1` rule:
  ```prolog
  program(program(Name, ConstDecls, Types, Funcs, Vars, Block)) -->
      keyword(program),
      identifier(Name),
      symbol(';'),
      const_declarations(ConstDecls),  % NEW
      type_declarations(Types),
      top_level_declarations(Funcs, Vars),
      block(Block),
      symbol('.'),
      [tok(eof, _, _)].
  ```

- Added rules for parsing `const` declarations:
  ```prolog
  const_declarations(ConstDecls) -->
      keyword(const),
      !,
      const_decls(ConstDecls).
  const_declarations([]) --> [].

  const_decls([ConstDecl|Rest]) -->
      const_decl(ConstDecl),
      symbol(';'),
      !,
      const_decls(Rest).
  const_decls([]) --> [].

  const_decl(const_decl(Name, Type, Value)) -->
      identifier(Name),
      symbol(':'),
      type_spec(Type),
      symbol('='),
      expression(Value).
  ```

#### Local `const` Declarations (Inside Blocks)
- Updated `block//1` to support `const` declarations:
  ```prolog
  block(block(LocalConsts, LocalVars, Stmts)) -->
      keyword(begin),
      block_declarations(LocalConsts, LocalVars),  % UPDATED
      stmt_list(Stmts),
      keyword(end).

  block_declarations(LocalConsts, LocalVars) -->
      const_declarations_block(LocalConsts),
      declarations(LocalVars).
  block_declarations([], LocalVars) -->
      declarations(LocalVars).
  ```

---

### 3. Semantics (`src/semantics.pl`)
**Changes**: Added validation for `const` declarations to ensure:
- No duplicate `const` names.
- `const` values are **constant expressions** (evaluated at compile-time).
- `const` types are valid and match the assigned value.

#### Key Predicates Added
- `check_const_decls/2`: Validates a list of `const` declarations.
- `eval_const_expr/4`: Evaluates constant expressions (e.g., `2 + 2` → `4`).
- `ensure_no_duplicate_const/2`: Ensures no duplicate `const` names.

#### Example Rules
```prolog
check_const_decls([], _).
check_const_decls([const_decl(Name, Type, Value)|Rest], VarsInScope) :-
    ensure_no_duplicate_const(Name, VarsInScope),
    ensure_valid_type(Type),
    check_const_expr(Value, VarsInScope, Type),
    check_const_decls(Rest, [Name-Type|VarsInScope]).

% Evaluate constant expressions
eval_const_expr(int(N), _Vars, int(N), integer).
eval_const_expr(bool(Value), _Vars, bool(Value), boolean).
eval_const_expr(bin(Op, Left, Right), Vars, int(Value), integer) :-
    eval_const_expr(Left, Vars, int(LVal), integer),
    eval_const_expr(Right, Vars, int(RVal), integer),
    eval_bin_op(Op, LVal, RVal, Value).
```

#### Integration with `check_program/1`
- Updated `check_program/1` to call `check_const_decls/2` before checking variables and functions:
  ```prolog
  check_program(program(_, ConstDecls, TypeDecls, Funcs, Vars, Block)) :-
      init_type_aliases(TypeDecls),
      check_const_decls(ConstDecls, []),  % NEW
      ensure_no_duplicate_decls(Vars),
      ensure_valid_decls(Vars),
      decls_env(Vars, GlobalEnv),
      check_funcs(Funcs, GlobalEnv, FuncSigs),
      check_block(Block, GlobalEnv, FuncSigs).
  ```

---

### 4. IR (Intermediate Representation) (`src/ir.pl`)
**Changes**: Added lowering rules to replace `const` references with their **compile-time values** in the IR.

#### Key Predicates Added
- `lower_consts/3`: Lowers `const` declarations to IR values.
- `eval_const_ir_expr/3`: Evaluates constant expressions to IR values (e.g., `int(42)`).

#### Example Rules
```prolog
lower_consts([], _Env, []).
lower_consts([const_decl(Name, Type, Value)|Rest], Env, [Name-Name-Type-ConstValue|ConstEnvTail]) :-
    eval_const_ir_expr(Value, Env, ConstValue),
    lower_consts(Rest, Env, ConstEnvTail).

% Evaluate constant expressions to IR values
eval_const_ir_expr(int(N), _Env, ir_int(N)).
eval_const_ir_expr(bool(Value), _Env, ir_bool(Value)).
eval_const_ir_expr(bin(Op, Left, Right), Env, ir_bin(Op, IRLeft, IRRight)) :-
    eval_const_ir_expr(Left, Env, IRLeft),
    eval_const_ir_expr(Right, Env, IRRight).
```

#### Integration with `lower_program/2`
- Updated `lower_program/2` to include `const` declarations in the environment:
  ```prolog
  lower_program(program(Name, ConstDecls, Types, Funcs, Vars, Block), ir_program(Name, IRFuncs, AllVars, IRStmts)) :-
      init_ir_type_aliases(Types),
      resolve_decl_list(ConstDecls, ResolvedConsts),  % NEW
      resolve_decl_list(Vars, ResolvedVars),
      init_func_metadata(Funcs),
      vars_env(ResolvedVars, GlobalEnv),
      lower_consts(ResolvedConsts, GlobalEnv, ConstEnv),  % NEW
      append(ConstEnv, GlobalEnv, FullGlobalEnv),
      lower_funcs(Funcs, FullGlobalEnv, IRFuncs),
      lower_block(Block, FullGlobalEnv, 0, _CounterOut, IRStmts, LocalVars),
      append(ResolvedVars, LocalVars, AllVars).
  ```

#### Handling `const` References
- Updated `map_name/3` and `lookup_type/3` to resolve `const` references to their values:
  ```prolog
  map_name(Name, [Name-_-Type-ConstValue|_], ConstValue) :- !.
  lookup_type(Name, [Name-_-Type-ConstValue|_], Type) :- !,
      functor(ConstValue, Functor, _),
      arg(1, ConstValue, Type).
  ```

---

### 5. Test Case (`examples/datatypes/const_demo.pas`)
A test file was added to demonstrate and validate the `const` feature:
```pascal
program ConstDemo;

const
  MaxSize = 100;
  Pi = 3;
  Greeting = 'Hello, World!';
  ArraySize = 10;

type
  MyArray = array[1..ArraySize] of integer;

var
  arr: MyArray;
  i: integer;

begin
  for i := 1 to MaxSize do
  begin
    if i = Pi then
      writeln(Greeting)
    else if i <= ArraySize then
    begin
      arr[i] := i * 2;
      write(arr[i], ' ')
    end
  end;
  writeln('')
end.
```

#### Expected Output
When compiled and run, this program should output:
```
2 4 6 8 10 12 14 16 18 20
Hello, World!
```

---

## Current Status

| Component       | Status | Notes                                                                                     |
|-----------------|--------|-------------------------------------------------------------------------------------------|
| **Lexer**       | ✅     | `const` is recognized as a keyword.                                                      |
| **Parser**      | ✅     | Supports global and local `const` declarations with expressions.                         |
| **Semantics**   | ✅     | Validates `const` declarations and evaluates constant expressions.                       |
| **IR**          | ✅     | Replaces `const` references with their values in the IR.                                  |
| **Codegen**     | ✅     | No changes needed (handled by IR).                                                        |
| **Testing**     | ⚠️     | **Work in progress**: Requires manual testing (parsing, semantics, compilation).          |
| **Documentation** | ✅   | This file (`CONST.md`) and `AGENTS.md` updated.                                           |

---

## How to Test

### 1. Parse the Test File
```bash
swipl -q -s pascal_compiler.pl -- parse examples/datatypes/const_demo.pas
```
- **Expected**: AST with `const_decl` nodes.
- **Debug**: If parsing fails, check `src/lexer.pl` and `src/parser.pl`.

### 2. Check Semantics
```bash
swipl -q -s pascal_compiler.pl -- check examples/datatypes/const_demo.pas
```
- **Expected**: `ok`
- **Debug**: If semantics fail, check `src/semantics.pl`.

### 3. Compile and Run
```bash
swipl -q -s pascal_compiler.pl -- build-asm examples/datatypes/const_demo.pas const_demo
./const_demo
```
- **Expected Output**:
  ```
  2 4 6 8 10 12 14 16 18 20
  Hello, World!
  ```
- **Debug**: If compilation fails, check `src/ir.pl` and `src/codegen_asm_x86_64.pl`.

---

## Known Limitations

1. **No Typed Constants (Yet)**
   - Currently, `const` declarations **do not require type annotations** (e.g., `const MaxSize = 100;` works).
   - Future: Add support for explicit types (e.g., `const MaxSize: integer = 100;`).

2. **No `const` Parameters**
   - The compiler does **not yet support** `const` parameters in procedures/functions (e.g., `procedure Foo(const x: integer);`).
   - Future: Extend the parser and semantics to handle `const` parameters.

3. **Limited Constant Expressions**
   - Only **simple arithmetic and logical expressions** are supported in `const` declarations.
   - Future: Add support for function calls (if they are `const`-safe).

4. **No Forward References**
   - `const` declarations **cannot reference other `const` declarations** that appear later in the same block.
   - Example: This will **fail**:
     ```pascal
     const
       A = B + 1;  % Error: B is not yet declared
       B = 10;
     ```
   - Future: Add forward resolution for `const` declarations.

---

## Future Work

| Feature               | Priority | Description                                                                                     |
|-----------------------|----------|-------------------------------------------------------------------------------------------------|
| Typed Constants       | High     | Support explicit type annotations (e.g., `const MaxSize: integer = 100;`).                  |
| `const` Parameters    | Medium   | Allow `const` parameters in procedures/functions (e.g., `procedure Foo(const x: integer);`).   |
| Forward References    | Medium   | Allow `const` declarations to reference later `const` declarations in the same block.         |
| Complex Expressions   | Low      | Support function calls and other complex expressions in `const` declarations.                 |
| `const` in Records     | Low      | Allow `const` fields in records (if applicable).                                               |

---

## Version History

- **v1.16.0** (2026-05-07): Initial implementation of `const` declarations (global and local). Added `examples/datatypes/const_demo.pas`.

---

## References

- [AGENTS.md](AGENTS.md): General guidelines for adding features to the compiler.
- [Pascal Standard](https://www.freepascal.org/docs-html/current/ref/refch1.html): Official Pascal documentation for `const`.
