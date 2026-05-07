# Pascal Subset Analysis: `examples/lists/`

## Overview
Two linked-list and tree manipulation programs demonstrate **records**, **typed pointers**, **heap allocation**, **recursion**, and **by-reference parameters**.

---

## Programs Analyzed

| File | Size | Purpose |
|------|------|---------|
| `nested_s_expression_list.pas` | 152 lines | Parses nested S-expressions into a tree structure with `child` and `next` pointers |
| `string_to_linked_list.pas` | 75 lines | Reads characters and builds a singly-linked list |

---

## Pascal Subset Enumeration

### Data Types

| Type | Usage | Examples |
|------|-------|----------|
| `integer` | Loop counters, array indices, state tracking | `count`, `pos`, `depth`, `i` |
| `char` | Character data storage | `value: char`, `ch: char`, `input: array[1..64] of char` |
| `boolean` | Flag variables | `done: boolean` |
| **`record`** | Structured data with typed fields | `node = record kind: char; value: char; child: ^node; next: ^node; end` |
| **`^TypeName` (pointer)** | Typed pointer declarations | `^node`, `node_ptr = ^node` |
| **`array[..] of char`** | Fixed-size character buffers | `array[1..64] of char`, `array[1..32] of char` |
| **Type aliases** | Named type synonyms | `node_ptr = ^node` |

---

### Control Structures

| Structure | Usage | Count |
|-----------|-------|-------|
| `if ... then ... else ...` | Conditional branching | 12 (nested_s_expression_list), 3 (string_to_linked_list) |
| `while ... do` | Loops with exit conditions | 8 (nested_s_expression_list), 3 (string_to_linked_list) |
| `begin ... end` | Compound statements | Used throughout |
| Nested conditionals | `if ... then begin ... end else begin ... end` | Multiple |

**Not used in these programs:** `for`, `case`, `repeat`

---

### Procedures & Functions

| Feature | Usage | Examples |
|---------|-------|----------|
| **Procedures** | Named blocks of code | `append_node`, `parse_list`, `print_nodes`, `dispose_nodes` |
| **Parameters (by value)** | Default parameter passing | `item: node_ptr` |
| **`var` parameters (by reference)** | Modify caller's variables | `var head: node_ptr`, `var tail: node_ptr`, `var result: node_ptr` |
| **Parameterless procedures** | No parameters | Main program body (implicit) |
| **Recursive procedures** | Procedures calling themselves | `parse_list` (calls itself), `dispose_nodes` (calls itself) |
| **Local variables** | Variables declared within procedures | `var tail: node_ptr; item: node_ptr; current: char;` in `parse_list` |
| **Variable shadowing** | Local vars shadow globals | `ch`, `curr` used both globally and locally |

**Not used:** Functions (with return values)

---

### Input/Output

| Operation | Usage | Examples |
|-----------|-------|----------|
| `readln` | Read single character from stdin | `readln(ch)` |
| `write` | Output expressions (multi-argument) | `write('[', curr^.value, ']')`, `write('list: ')` |
| `writeln` | Output with newline | `writeln('')`, `writeln('nil')` |

**Features demonstrated:**
- Multi-argument `write` mixing string literals and expressions
- Chained output for linked list traversal

---

### Advanced Features

| Feature | Usage | Examples |
|---------|-------|----------|
| **Records** | Structured data types with named fields | `node = record kind: char; value: char; child: ^node; next: ^node; end` |
| **Typed Pointers** | Pointers to specific record types | `^node`, `node_ptr = ^node` |
| **`nil`** | Null pointer constant | `head := nil`, `if head = nil`, `item^.child := nil` |
| **`new`** | Heap allocation | `new(item)` |
| **`dispose`** | Heap deallocation | `dispose(curr)`, `dispose(item)` |
| **Pointer dereference** | Access through pointer | `item^.value`, `item^.kind`, `item^.child`, `item^.next` |
| **Field access through pointer** | `pointer^.field` syntax | `curr^.value`, `curr^.next`, `tail^.next` |
| **Recursion** | Procedures calling themselves | `parse_list(item^.child)`, `dispose_nodes(curr^.child)` |
| **By-reference parameters** | `var` parameters for in-out modification | `var head: node_ptr`, `var tail: node_ptr`, `var result: node_ptr` |
| **Type aliases** | Named type synonyms | `node_ptr = ^node` |
| **Global variables** | Variables declared in `var` section | `input`, `count`, `pos`, `depth`, `done`, `ch`, `root`, `head`, `tail` |
| **Local variables** | Variables in procedure scope | Declared in `parse_list`, `print_nodes`, `dispose_nodes`, etc. |
| **Array indexing** | Access array elements | `input[pos]`, `input[count]`, `input[i]` |
| **Array bounds** | Fixed array sizes | `array[1..64]`, `array[1..32]` |
| **Character comparison** | `=`, `<>`, `<`, `>` on chars | `input[pos] = '('`, `ch <> ')'` |
| **Boolean logic** | `and`, `not` operators | `while (pos <= count) and (input[pos] <> ')')`, `while not done` |
| **Assignment** | Simple and compound | `head := item`, `pos := pos + 1`, `depth := depth + 1` |
| **Increment/decrement** | Arithmetic on counters | `count := count + 1`, `depth := depth - 1`, `i := i + 1` |

---

### Operators

| Category | Operators Used |
|----------|----------------|
| Arithmetic | `+`, `-` (unary and binary) |
| Comparison | `=`, `<>`, `<`, `<=`, `>`, `>=` |
| Boolean | `and`, `not` |
| Assignment | `:=` |

**Not used:** `*`, `/`, `mod`, `or`, `div`

---

## Feature Matrix by Program

| Feature | nested_s_expression_list.pas | string_to_linked_list.pas |
|---------|--------------------------------|----------------------------|
| Records | ✅ (4-field node) | ✅ (2-field node) |
| Typed pointers | ✅ (`^node`, `node_ptr`) | ✅ (`^node`, `node_ptr`) |
| Type aliases | ✅ (`node_ptr = ^node`) | ✅ (`node_ptr = ^node`) |
| `new` / `dispose` | ✅ (both) | ✅ (both) |
| `nil` | ✅ | ✅ |
| Recursion | ✅ (`parse_list`, `dispose_nodes`) | ❌ |
| `var` parameters | ✅ (`append_node`, `parse_list`, `dispose_nodes`) | ❌ |
| Multi-arg `write` | ✅ | ✅ |
| Local variables in procedures | ✅ | ❌ |
| Nested records | ✅ (child points to node) | ❌ |
| S-expression parsing | ✅ | ❌ |
| Array of char | ✅ (`[1..64]`) | ✅ (`[1..32]`) |
| Boolean variables | ✅ (`done`) | ❌ |
| Nested `if/else` | ✅ | ✅ |

---

## Summary

The `examples/lists/` directory showcases **advanced Pascal features** including:

1. **Dynamic data structures**: Linked lists and trees using records and typed pointers
2. **Memory management**: Manual heap allocation/deallocation with `new`/`dispose`
3. **Recursive parsing**: Tree construction from nested S-expression input
4. **By-reference parameters**: Enabling procedures to modify caller's pointer variables
5. **Multi-argument I/O**: Complex output formatting with `write` and `writeln`

**Notable absence**: No arithmetic operators (`+`, `-` only for integer increments), no `for` loops, no `case` statements, no functions with return values, no array bounds checking code (handled by runtime).

---
Report generated at: Thu May  7 10:07:20 UTC 2026
Commit SHA: b8b29668bb09ddb4aea39216bd616555dc2b4752
