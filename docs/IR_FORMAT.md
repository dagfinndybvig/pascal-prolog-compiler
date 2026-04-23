# IR (Intermediate Representation) Format

This document describes the Intermediate Representation (IR) format used by the Pascal-Prolog compiler.

## Overview

The IR is a simplified, typed representation of the Pascal source code that serves as input to the code generator. It eliminates high-level language constructs and prepares the program for efficient x86-64 assembly generation.

## IR Structure

### Top-level Program Structure

```prolog
ir_program(Name, Functions, Variables, Statements)
```

- `Name`: Program name (atom)
- `Functions`: List of `ir_func/4` structures
- `Variables`: List of global variable names
- `Statements`: List of IR statements for the main program

### Function Representation

```prolog
ir_func(Name, Parameters, LocalVariables, Statements)
```

- `Name`: Function name (atom)
- `Parameters`: List of parameter names
- `LocalVariables`: List of local variable names (mangled as `local(Counter, OriginalName)`)
- `Statements`: List of IR statements for the function body

**Note on Function Local Variables**: During IR generation, function-level local variables (declared in `var` section before `begin`) are merged with the function body's block-level local variables. This ensures proper name mangling and allocation for all local variables in function scope.

### Variable Naming Convention

Local variables are name-mangled to avoid collisions:
- Global variables: keep their original names
- Local variables: `local(Counter, OriginalName)` where Counter is a unique integer
- Function return values: use the function name as the variable name

## IR Statement Types

### Assignment

```prolog
ir_assign(VariableName, Expression)
```

Assigns the result of evaluating Expression to VariableName.

### Conditional

```prolog
ir_if(Condition, ThenStatement, ElseStatement)
```

Evaluates Condition and executes either ThenStatement or ElseStatement.

### Loop

```prolog
ir_while(Condition, BodyStatement)
```

Executes BodyStatement repeatedly while Condition evaluates to true.

### Block

```prolog
ir_block(Statements)
```

Groups multiple statements into a single block with its own scope.

### I/O Operations

```prolog
ir_writeln_int(Expression)      % Write integer with newline
ir_writeln_str(String)          % Write string literal with newline
ir_write_int(Expression)         % Write integer without newline
ir_write_str(String)            % Write string literal without newline
ir_readln(VariableName)         % Read integer from input
```

## IR Expression Types

### Integer Literal

```prolog
ir_int(Value)
```

Represents a 32-bit signed integer constant.

### Variable Reference

```prolog
ir_var(VariableName)
```

References a variable (global, local, or parameter).

### Function Call

```prolog
ir_call(FunctionName, Arguments)
```

Calls a function with the given arguments.

### Unary Operation

```prolog
ir_unary(Operator, Expression)
```

Supported operators: `'-'` (negation)

### Binary Operation

```prolog
ir_bin(Operator, LeftExpression, RightExpression)
```

Supported operators: `'+'`, `'-'`, `'*'`, `'/'`, `'='`, `'<>'`, `'<'`, `'<='`, `'>'`, `'>='`

## Example IR

Consider this Pascal code:

```pascal
program test;
var x, y: integer;
begin
  x := 10;
  y := x + 5;
  writeln(y)
end.
```

The corresponding IR might look like:

```prolog
ir_program(test, [], [x, y], [
  ir_assign(x, ir_int(10)),
  ir_assign(y, ir_bin('+', ir_var(x), ir_int(5))),
  ir_writeln_int(ir_var(y))
])
```

## IR Generation Process

1. **Variable Environment Setup**: Create mappings from original variable names to mangled names
2. **Local Variable Allocation**: Assign unique counters to local variables
3. **Statement Lowering**: Convert AST statements to IR statements
4. **Expression Lowering**: Convert AST expressions to IR expressions

The IR generation preserves the control flow structure while simplifying expressions and ensuring proper variable scoping.

## IR to Assembly Translation

The code generator processes IR statements and expressions to produce x86-64 assembly:

- IR statements become sequences of assembly instructions
- IR expressions are evaluated into registers using the x86-64 calling convention
- Variable references are translated to memory accesses using stack offsets
- Function calls follow the System V AMD64 ABI

The IR format is designed to make this translation straightforward while maintaining the semantic meaning of the original Pascal program.