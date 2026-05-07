# Pascal Subset Report: `examples/lists/`

## Overview

Analysis of all 6 Pascal programs in the `examples/lists/` directory, identifying the complete Pascal subset utilized across these linked-list and tree-based examples.

---

## File Index

| File | Description |
|------|-------------|
| `count_list.pas` | Basic linked list: creation, counting, freeing (5 nodes) |
| `for_count_list.pas` | Linked list using `for` loops instead of `while` |
| `nested_s_expression_list.pas` | S-expression parser building nested linked structures |
| `primes_under_1000_list.pas` | Prime number generator storing results in linked list |
| `string_to_linked_list.pas` | Character string converted to linked list |
| `tree_sort_wirth.pas` | Binary search tree implementation (Wirth's algorithm) |

---

## Pascal Subset Enumeration

### Data Types

| Type | Files | Notes |
|------|-------|-------|
| `integer` | All 6 | 32-bit signed |
| `char` | nested_s_expression_list, string_to_linked_list | Single character |
| `boolean` | nested_s_expression_list, tree_sort_wirth | `true`/`false` |
| `record` | All 6 | Structured type with fields |
| `^TypeName` | All 6 | Typed pointer declaration |
| `array[low..high] of char` | nested_s_expression_list (1..64), string_to_linked_list (1..32) | Static char arrays for input buffers |
| `type` aliases | All 6 | Named type declarations (`node = record...`, `node_ptr = ^node`) |

**Record field types:**
- `integer` fields: `value`, `key`, `count`, `pos`, `depth`
- Pointer fields: `next`, `child`, `left`, `right`
- `char` fields: `kind`, `value`, `input` (array)

---

### Control Structures

| Structure | Files | Count |
|-----------|-------|-------|
| `if...then...else` | All 6 | 28+ instances |
| `while...do` | count_list, nested_s_expression_list, primes_under_1000_list, string_to_linked_list | 8+ loops |
| `for i := a to b do` | for_count_list, primes_under_1000_list | 3 loops |
| `begin...end` blocks | All 6 | 30+ blocks |

**Not used:** `for...downto...do`, `case...of`, `repeat...until`

---

### Subprograms

#### Functions (Returning Values)

| Function | Return Type | Parameters | Files |
|----------|-------------|------------|-------|
| `make_list` | `integer` | `var head: node_ptr; size: integer` | count_list |
| `count_nodes` | `integer` | `var head: node_ptr` | count_list |
| `free_list` | `integer` | `var head: node_ptr` | count_list |
| `make_list_for` | `integer` | `var head: node_ptr; size: integer` | for_count_list |
| `count_nodes_for` | `integer` | `var head: node_ptr; size: integer` | for_count_list |
| `free_list_for` | `integer` | `var head: node_ptr; size: integer` | for_count_list |
| `is_prime` | `boolean` | `n: integer` | primes_under_1000_list |
| `append_prime` | `integer` | `var head: node_ptr; var tail: node_ptr; value: integer` | primes_under_1000_list |
| `build_prime_list` | `integer` | `var head: node_ptr; limit: integer` | primes_under_1000_list |
| `print_list` | `integer` | `var head: node_ptr` | primes_under_1000_list |

#### Procedures (Void)

| Procedure | Parameters | Files |
|-----------|------------|-------|
| `append_node` | `var head: node_ptr; var tail: node_ptr; item: node_ptr` | nested_s_expression_list |
| `parse_list` | `var result: node_ptr` | nested_s_expression_list |
| `print_nodes` | `nodes: node_ptr` | nested_s_expression_list |
| `dispose_nodes` | `var nodes: node_ptr` | nested_s_expression_list |
| `insert_tree` | `var t: tree_ptr; value: integer` | tree_sort_wirth |
| `print_in_order` | `t: tree_ptr; var first: boolean` | tree_sort_wirth |
| `dispose_tree` | `var t: tree_ptr` | tree_sort_wirth |

#### Parameter Modes

| Mode | Usage |
|------|-------|
| Value (default) | Scalar types: `integer`, `char`, `boolean` |
| `var` (by-reference) | Pointer types: `node_ptr`, `tree_ptr`; also `boolean` in `print_in_order` |

**Maximum parameters observed:** 3 (e.g., `append_node`, `append_prime`)

#### Recursion

| Recursive Subprogram | Files |
|---------------------|-------|
| `parse_list` | nested_s_expression_list |
| `print_nodes` | nested_s_expression_list |
| `dispose_nodes` | nested_s_expression_list |
| `insert_tree` | tree_sort_wirth |
| `print_in_order` | tree_sort_wirth |
| `dispose_tree` | tree_sort_wirth |

---

### Pointer Operations

| Operation | Files | Count |
|-----------|-------|-------|
| `^` (dereference) | All 6 | 40+ instances |
| `nil` | All 6 | 25+ instances |
| `new(pointer)` | All 6 | 10+ allocations |
| `dispose(pointer)` | count_list, nested_s_expression_list, primes_under_1000_list, string_to_linked_list, tree_sort_wirth | 15+ deallocations |
| `pointer^.field` | All 6 | Extensive field access |
| `pointer^` (full record dereference) | Not explicitly used | N/A |

**Not used:** `@` (address-of operator)

---

### I/O Operations

| Operation | Files | Usage Pattern |
|-----------|-------|----------------|
| `writeln` | count_list, for_count_list, primes_under_1000_list, string_to_linked_list, tree_sort_wirth | Output with newline |
| `write` | nested_s_expression_list, primes_under_1000_list, string_to_linked_list, tree_sort_wirth | Output without newline |
| `readln` | nested_s_expression_list, string_to_linked_list | Character input |

**Multi-argument writes:**
- `write('[', curr^.value, ']')` — mixed string literals and expressions
- `writeln('built: ', built)` — string + integer
- `write(' -> ')` — string literal
- `write(t^.key)` — single expression

---
---
### Operators

#### Arithmetic

| Operator | Files |
|----------|-------|
| `+` | count_list, nested_s_expression_list, primes_under_1000_list, string_to_linked_list |
| `-` | primes_under_1000_list |
| `*` | primes_under_1000_list |
| `mod` | primes_under_1000_list |

#### Comparison

| Operator | Files |
|----------|-------|
| `=` | All 6 |
| `<>` | All 6 |
| `<` | nested_s_expression_list, primes_under_1000_list, tree_sort_wirth |
| `<=` | count_list, nested_s_expression_list, primes_under_1000_list |
| `>` | primes_under_1000_list |
| `>=` | Not used |

#### Boolean

| Operator | Files |
|----------|-------|
| `and` | nested_s_expression_list, primes_under_1000_list |
| `or` | Not used |
| `not` | nested_s_expression_list |

#### Assignment

| Operator | Files |
|----------|-------|
| `:=` | All 6 |

---
---
### Variables

#### Global Variables

| File | Global Variables |
|------|------------------|
| count_list | `list: node_ptr; built: integer; counted: integer; freed: integer` |
| for_count_list | `list: node_ptr; built: integer; counted: integer; freed: integer` |
| nested_s_expression_list | `input: array[1..64] of char; count: integer; pos: integer; depth: integer; done: boolean; ch: char; root: node_ptr` |
| primes_under_1000_list | `list: node_ptr; built: integer; shown: integer; freed: integer` |
| string_to_linked_list | `input: array[1..32] of char; count: integer; i: integer; ch: char; head, tail, item, curr, next_item: node_ptr` |
| tree_sort_wirth | `root: tree_ptr; first_output: boolean` |

#### Local Variables

Used extensively in all subprograms. All files declare locals in `var` sections within subprograms.

---

### Advanced Features

| Feature | Files | Details |
|---------|-------|---------|
| **Named type aliases** | All 6 | `node = record...`, `node_ptr = ^node`, `tree_node = record...`, `tree_ptr = ^tree_node` |
| **Recursive data structures** | All 6 | `node` records containing `^node` fields; `tree_node` with `^tree_node` left/right |
| **Recursive subprograms** | nested_s_expression_list, tree_sort_wirth | Mutual recursion in tree operations |
| **Heap allocation** | All 6 | `new()` for node/tree creation |
| **Heap deallocation** | All 6 | `dispose()` with null-pointer guards |
| **By-reference parameters** | All 6 | `var` parameters for pointer modification |
| **Static arrays** | nested_s_expression_list, string_to_linked_list | Fixed-size char buffers for input |
| **Multi-statement blocks** | All 6 | `begin...end` with nested blocks |
| **Shadowing** | Not observed | Globals and locals have distinct names |

---
---
### Features NOT Used

The following Pascal features (supported by the compiler) are **not** used in any `examples/lists/` program:

- `for...downto...do` (countdown loops)
- `case...of...else...end` (switch statements)
- `@` (address-of operator)
- `char` literals (only `char` variables)
- `array` of types other than `char`
- Procedures/functions with 4-6 parameters
- Procedures/functions returning `char` or `boolean` (only `integer` returns observed)
- Global `var` sections declared after functions
- Division `/` operator
- Overflow handling

---

## Summary Statistics

| Category | Count |
|----------|-------|
| Total files | 6 |
| Total lines of Pascal | ~645 |
| Functions defined | 10 |
| Procedures defined | 7 |
| Recursive subprograms | 6 |
| Record types | 6 |
| Pointer types | 6 |
| Global variables | 23 |
| `new()` calls | 10+ |
| `dispose()` calls | 15+ |
| `while` loops | 8+ |
| `for` loops | 3 |
| `if` statements | 28+ |
| `write`/`writeln` calls | 20+ |

---
---
## Per-File Feature Matrix

| Feature | count_list | for_count_list | nested_s_expr | primes_1000 | string_to_ll | tree_sort |
|---------|------------|----------------|--------------|--------------|-------------|-----------|
| `record` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `^type` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `type` alias | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `integer` | ✓ | ✓ | ✓ | ✓ | | ✓ |
| `char` | | | ✓ | | ✓ | |
| `boolean` | | | ✓ | | | ✓ |
| `array` | | | ✓ | | ✓ | |
| `new()` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `dispose()` | ✓ | | ✓ | ✓ | ✓ | ✓ |
| `while` | ✓ | | ✓ | ✓ | ✓ | |
| `for...to` | | ✓ | | ✓ | | |
| `if/else` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Functions | ✓ | ✓ | | ✓ | | |
| Procedures | | | ✓ | | | ✓ |
| Recursion | | | ✓ | | | ✓ |
| `var` params | ✓ | ✓ | ✓ | ✓ | | ✓ |
| `writeln` | ✓ | ✓ | | ✓ | ✓ | ✓ |
| `write` | | | ✓ | ✓ | ✓ | ✓ |
| `readln` | | | ✓ | | ✓ | |
| Multi-arg write | | | ✓ | ✓ | ✓ | ✓ |

---
Report generated at: Thu May  7 10:54:27 UTC 2026
Commit SHA: 68c9ffb9f0cd5625c4e69ca22920b0be613b999e
