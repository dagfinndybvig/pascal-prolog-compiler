# IR (Intermediate Representation) Format

This document describes the Intermediate Representation (IR) format used by the Pascal-Prolog compiler.

## Overview

The IR is a simplified, typed representation of the Pascal source code that serves as input to the x86-64 code generator. It eliminates high-level syntax while preserving types, control flow, storage layout, and l-value/address information needed by the backend.

## IR Structure

### Top-level Program Structure

```prolog
ir_program(Name, Functions, Variables, Statements)
```

- `Name`: Program name (atom)
- `Functions`: List of `ir_func/5` structures
- `Variables`: List of typed global declarations, e.g. `decl(Name, Type)`
- `Statements`: List of IR statements for the main program

Named Pascal `type` declarations are resolved before and during IR lowering. IR declarations carry concrete types such as `integer`, `boolean`, `char`, `array(Low, High, ElementType)`, `record(Fields)`, and `ptr(TargetType)`. Recursive record references are preserved through pointer indirection with `type_ref(Name)` where needed.

### Function Representation

```prolog
ir_func(Name, Parameters, ReturnType, LocalVariables, Statements)
```

- `Name`: Function or procedure name (atom)
- `Parameters`: List of typed parameters, e.g. `param(Name, Type)` or `param_var(Name, Type)`
- `ReturnType`: Scalar function return type, or `void` for procedures
- `LocalVariables`: List of typed local declarations, with local names mangled as `decl(local(Counter, OriginalName), Type)`
- `Statements`: List of IR statements for the subprogram body

Function-level local variables declared before `begin` are merged with block-level local declarations so every local has a unique storage name and stack slot.

### Variable Naming Convention

Local variables are name-mangled to avoid collisions:

- Global variables: keep their original names
- Local variables: `local(Counter, OriginalName)` where `Counter` is a unique integer
- Function return values: use the function name as the variable name

Functions and procedures can reference global variables by their original names. Parameter and local mappings take precedence, so parameters and locals shadow globals.

## IR Statement Types

### Assignment

```prolog
ir_assign(VariableName, Expression)
```

Assigns the result of evaluating `Expression` to a scalar variable or pointer variable.

### Array Assignment

```prolog
ir_array_store(VariableName, LowBound, HighBound, IndexExpression, ValueExpression)
```

Stores a scalar value in a statically bounded array element. Bounds are carried in the IR so the backend can emit runtime checks.

### Record and Pointer Assignment

```prolog
ir_record_field_store(VariableName, SlotOffset, ValueExpression)
ir_ptr_field_store(PointerVariableName, SlotOffset, ValueExpression)
ir_ptr_deref_store(PointerVariableName, ValueExpression)
```

- `ir_record_field_store/3` stores into a field of a stack-allocated record. `SlotOffset` is the zero-based field slot offset computed from the record layout.
- `ir_ptr_field_store/3` stores through a pointer to a record (`p^.field`) after the backend emits a null-pointer guard.
- `ir_ptr_deref_store/2` stores through a scalar pointer (`p^`) after the backend emits a null-pointer guard.

Record values are not copied as aggregate expressions; source Pascal accesses records through fields. Pointer variables are scalar address values.

### Conditional

```prolog
ir_if(Condition, ThenStatement, ElseStatement)
```

Evaluates `Condition` and executes either `ThenStatement` or `ElseStatement`.

### Loop

```prolog
ir_while(Condition, BodyStatement)
```

Executes `BodyStatement` repeatedly while `Condition` evaluates to true.

`for` loops are lowered to initialization plus an `ir_while/2` loop. The end-bound expression is re-evaluated each iteration.

### Case Statement Lowering

Pascal `case` statements do not have a distinct IR node. They are lowered to chained `ir_if` statements that compare the selector expression against each label in order. The selector is re-evaluated for each label comparison, so avoid side-effecting selector expressions.

### Block

```prolog
ir_block(Statements)
```

Groups multiple statements into a single block.

### I/O Operations

```prolog
ir_writeln_int(Expression)          % Write integer/boolean with newline
ir_writeln_char(Expression)         % Write char with newline
ir_writeln_char_array(Name, Low, High)
ir_writeln_str(String)              % Write string literal with newline
ir_write_int(Expression)            % Write integer/boolean without newline
ir_write_char(Expression)           % Write char without newline
ir_write_char_array(Name, Low, High)
ir_write_str(String)                % Write string literal without newline
ir_readln(VariableName)             % Read integer from input
ir_readln_char(VariableName)        % Read char from input
ir_record_field_readln(VariableName, SlotOffset)
ir_record_field_readln_char(VariableName, SlotOffset)
```

Multi-argument `write` and `writeln` statements are lowered to `ir_block/1` sequences of these primitive typed write operations. Boolean output uses the integer write primitive and prints `0` or `1`; char output uses the char primitive. Legacy helper IR nodes such as `ir_write_int_str/2`, `ir_write_str_int/2`, and `ir_write_int_str_int/3` may still be accepted by the backend, but they are not the normal lowering path for Pascal source.

Record-field input nodes read directly into integer or char fields. Aggregate records and pointer values are not readable/writable as whole values.

### Heap Operations

```prolog
ir_new(AddressExpression, ByteSize)
ir_dispose(PointerExpression)
```

- `ir_new/2` allocates `ByteSize` bytes and stores the resulting heap pointer into the l-value address represented by `AddressExpression`.
- `ir_dispose/1` evaluates a pointer expression and frees it through the runtime.

The l-value address expression may be a variable address, record-field address, pointer-dereference address, or pointer-field address depending on the Pascal source.

### Procedure Calls

```prolog
ir_proc_call(Name, Arguments)
```

Calls a procedure. `var` arguments are lowered to address expressions, while value arguments are lowered as normal expressions.

## IR Expression Types

### Integer Literal

```prolog
ir_int(Value)
```

Represents a 32-bit signed integer constant. The Pascal literal `nil` is lowered to `ir_int(0)` when used as a pointer value.

### Boolean and Char Literals

```prolog
ir_bool(Value)   % 0 or 1
ir_char(Code)    % character code
```

### Variable Reference

```prolog
ir_var(VariableName)
```

References a variable (global, local, parameter, or function return slot).

### Array Load

```prolog
ir_array_load(VariableName, LowBound, HighBound, IndexExpression)
```

Loads a scalar element from a statically bounded array. The generated assembly checks the index before accessing memory.

### Record and Pointer Loads

```prolog
ir_record_field_load(VariableName, SlotOffset)
ir_ptr_field_load(PointerVariableName, SlotOffset)
ir_ptr_deref_load(PointerVariableName)
```

- `ir_record_field_load/2` loads a field from a stack-allocated record.
- `ir_ptr_field_load/2` loads a record field through a pointer after a null-pointer check.
- `ir_ptr_deref_load/1` loads a scalar value through a pointer after a null-pointer check.

### Address Expressions

```prolog
ir_addr_of(VariableName)
ir_record_field_addr(VariableName, SlotOffset)
ir_ptr_deref_addr(PointerVariableName)
ir_ptr_field_addr(PointerVariableName, SlotOffset)
```

These expressions produce addresses for Pascal address-of (`@`) operations, `var` parameters, and heap allocation destinations. Pointer-derived address expressions include null-pointer checks in generated code.

### Function Call

```prolog
ir_call(FunctionName, Arguments)
```

Calls a scalar-returning function with the given arguments. `var` arguments are represented as address expressions in `Arguments`.

### Unary Operation

```prolog
ir_unary(Operator, Expression)
```

Supported operators: `'-'` (integer negation), `not` (boolean negation).

### Binary Operation

```prolog
ir_bin(Operator, LeftExpression, RightExpression)
```

Supported operators: `'+'`, `'-'`, `'*'`, `'/'`, `mod`, `and`, `or`, `'='`, `'<>'`, `'<'`, `'<='`, `'>'`, `'>='`. Arithmetic operators require integers; boolean operators require booleans; comparisons produce booleans. Pointer equality and inequality compare pointer values, including `nil` as zero.

## Storage Layout

- Scalars and pointers occupy one 8-byte slot in generated storage.
- Static arrays reserve one 8-byte slot per element.
- Records reserve one or more 8-byte slots, equal to the sum of their field slot counts.
- Nested record fields are flattened by slot count; pointer fields still occupy one slot.
- Record field offsets are zero-based slot offsets from the record base.

## Example IR

Consider this Pascal code:

```pascal
program test;
var
  x, y: integer;
  text: array[1..2] of char;
begin
  x := 10;
  y := x + 5;
  text[1] := 'O';
  text[2] := 'K';
  writeln(y);
  writeln(text)
end.
```

The corresponding IR might look like:

```prolog
ir_program(test, [], [decl(x, integer), decl(y, integer), decl(text, array(1, 2, char))], [
  ir_assign(x, ir_int(10)),
  ir_assign(y, ir_bin('+', ir_var(x), ir_int(5))),
  ir_array_store(text, 1, 2, ir_int(1), ir_char(79)),
  ir_array_store(text, 1, 2, ir_int(2), ir_char(75)),
  ir_writeln_int(ir_var(y)),
  ir_writeln_char_array(text, 1, 2)
])
```

Pointer-enabled Pascal such as `p^.key := 7` lowers to a pointer-field store with a field slot offset:

```prolog
ir_ptr_field_store(p, 0, ir_int(7))
```

The backend turns that into a null-checked load of pointer variable `p`, then stores into slot `0` of the pointed-to record.

## IR Generation Process

1. **Type environment setup**: Resolve named types and preserve recursive pointer references where necessary.
2. **Variable environment setup**: Create mappings from original variable names to mangled names and typed storage declarations.
3. **Local variable allocation**: Assign unique counters to local variables.
4. **Statement lowering**: Convert AST statements to IR statements.
5. **Expression lowering**: Convert AST expressions to IR expressions.
6. **L-value lowering**: Convert `var` arguments, address-of expressions, and heap-operation targets to address expressions.

The IR generation preserves control flow while simplifying expressions and making storage addressing explicit.

## IR to Assembly Translation

The code generator processes IR statements and expressions to produce x86-64 assembly:

- IR statements become sequences of assembly instructions.
- IR expressions are evaluated into registers using the x86-64 calling convention.
- Variable references are translated to memory accesses using stack offsets.
- Records reserve one 8-byte slot per scalar field, with nested records flattened by slot count.
- Pointer loads/stores are address-sized scalar operations and are null-checked before dereference.
- Function and procedure calls follow the System V AMD64 ABI.

The IR format is designed to make this translation straightforward while maintaining the semantic meaning of the original Pascal program.
