The markdown report has been generated at `examples/lists/pascal-subset-report.md`.
in the `examples/lists/` directory.*

## Files Analyzed (7 programs)

| File | Description | Lines |
|------|-------------|-------|
| `case_bucket_lists.pas` | Distributes numbers 1-40 into 4 linked lists by mod 4 | 133 |
| `count_list.pas` | Creates, counts, and frees a linked list | 101 |
| `for_count_list.pas` | Linked list operations using `for` loops | 106 |
| `nested_s_expression_list.pas` | Parses nested S-expressions into tree structure | 152 |
| `primes_under_1000_list.pas` | Finds primes under 1000, stores in linked list | 129 |
| `string_to_linked_list.pas` | Reads string input, builds char-linked list | 75 |
| `tree_sort_wirth.pas` | Binary search tree insertion and in-order traversal | 83 |

---

## Pascal Subset Enumeration

### 📦 Data Types

| Category | Types Used | Examples |
|----------|-----------|----------|
| **Scalar** | `integer` | loop counters, node values, prime numbers |
| **Scalar** | `boolean` | flags, loop conditions, `is_prime` return |
| **Scalar** | `char` | S-expression parsing, string input |
| **Composite** | `record` | `node`, `tree_node` with typed fields |
| **Pointer** | Typed pointers (`^TypeName`) | `^node`, `^node_ptr`, `^tree_node`, `^tree_ptr` |
| **Array** | Static arrays | `array[1..64] of char`, `array[1..32] of char` |
| **Alias** | Named type aliases | `type node = record...`, `node_ptr = ^node` |

**Field Types in Records:**
- `integer` (value, key)
- `char` (value, kind)
- Pointer fields (`next: ^node`, `left: ^tree_node`, `right: ^tree_node`, `child: ^node`)

---

### 🔄 Control Structures

| Structure | Usage | Files |
|-----------|-------|-------|
| `if...then...else` | Conditional execution | All 7 |
| `while...do` | Pre-test loops | 6/7 (all except tree_sort_wirth uses only for) |
| `for...to...do` | Counted loops | case_bucket_lists, for_count_list, primes_under_1000_list |
| `case...of...else...end` | Multi-way branching | case_bucket_lists |

**Loop Patterns:**
- List traversal: `while curr <> nil do`
- Counted iteration: `for i := 1 to size do`
- Bounded iteration: `for n := 2 to limit - 1 do`
- Input reading: `while not done do` / `while ch <> ')' do`
- Recursive tree traversal: `print_in_order(t^.left, first)`

---

### 🎯 Procedures and Functions

#### Function Types
| Return Type | Usage | Files |
|-------------|-------|-------|
| `integer` | `make_list`, `count_nodes`, `append_node`, `build_prime_list`, `print_list`, `free_list` | count_list, for_count_list, case_bucket_lists, primes_under_1000_list |
| `boolean` | `is_prime` | primes_under_1000_list |
| `void` (procedure) | `append_node`, `parse_list`, `print_nodes`, `dispose_nodes`, `insert_tree`, `print_in_order`, `dispose_tree` | nested_s_expression_list, tree_sort_wirth, count_list |

#### Parameter Modes
| Mode | Syntax | Usage | Files |
|------|--------|-------|-------|
| By-value | `param: type` | `value: integer`, `size: integer`, `limit: integer`, `n: integer` | All |
| By-reference | `var param: type` | `var head: node_ptr`, `var tail: node_ptr`, `var t: tree_ptr` | All 7 |

#### Parameter Count
- 0 parameters: None (all functions/procedures have at least 1 parameter)
- 1 parameter: `is_prime(n: integer)`
- 2 parameters: `insert_tree(var t: tree_ptr; value: integer)`, `print_in_order(t: tree_ptr; var first: boolean)`
- 3 parameters: `append_node(var head: node_ptr; var tail: node_ptr; item: node_ptr)`
- 4 parameters: `append_node(var head: node_ptr; var tail: node_ptr; value: integer)`

#### Recursion
| Function/Procedure | Recursive Pattern | Files |
|-------------------|-------------------|-------|
| `insert_tree` | Binary tree insertion (left/right subtree) | tree_sort_wirth |
| `print_in_order` | In-order tree traversal | tree_sort_wirth |
| `dispose_tree` | Post-order tree deletion | tree_sort_wirth |
| `parse_list` | Nested S-expression parsing | nested_s_expression_list |
| `dispose_nodes` | Recursive list with child trees | nested_s_expression_list |

---

### 🖨️ I/O Operations

| Operation | Usage | Files |
|-----------|-------|-------|
| `readln` | Read single char input | nested_s_expression_list, string_to_linked_list |
| `write` | Output values, strings, chars | All 7 |
| `writeln` | Output with newline | All 7 |

**I/O Patterns:**
- Single value: `write(curr^.value)`
- String literal: `write(' -> ')`
- Mixed arguments: `writeln('built: ', built)`
- Multi-value: `writeln('count0: ', count0, ', printed0: ', printed0)`
- Char output: `write('[', curr^.value, ']')`
- Boolean as string: `write(' -> nil')`

---

### 🔗 Pointer and Memory Operations

| Operation | Usage | Files |
|-----------|-------|-------|
| `^` | Pointer dereference | All 7 |
| `.` | Field access | All 7 |
| `^.` | Field-through-pointer | All 7 |
| `@` | Address-of | Not used |
| `nil` | Null pointer constant | All 7 |
| `new(p)` | Heap allocation | All 7 |
| `dispose(p)` | Heap deallocation | All 7 |

**Pointer Patterns:**
- List node creation: `new(item); item^.value := value; item^.next := nil`
- List traversal: `curr := curr^.next`
- Tree node creation: `new(t); t^.key := value; t^.left := nil; t^.right := nil`
- Recursive tree access: `insert_tree(t^.left, value)`
- Null checks: `if head = nil then`, `while curr <> nil do`

---

### ⚙️ Operators

| Category | Operators | Usage | Files |
|----------|-----------|-------|-------|
| **Arithmetic** | `+`, `-`, `*`, `/` | Increment, multiplication | case_bucket_lists, count_list, for_count_list, primes_under_1000_list |
| **Arithmetic** | `mod` | Modulo operation | case_bucket_lists, primes_under_1000_list |
| **Comparison** | `=`, `<>`, `<`, `<=`, `>`, `>=` | All comparison operators used | All 7 |
| **Boolean** | `and` | Boolean conjunction | primes_under_1000_list |
| **Boolean** | `not` | Boolean negation | nested_s_expression_list, string_to_linked_list |
| **Assignment** | `:=` | Variable assignment | All 7 |

---

### 🏗️ Advanced Features

| Feature | Description | Files |
|---------|-------------|-------|
| **Type Aliases** | `type name = definition` | All 7 |
| **Record Types** | Structured data with named fields | All 7 |
| **Typed Pointers** | Pointers to specific record types | All 7 |
| **Heap Management** | `new`/`dispose` with runtime null guards | All 7 |
| **Reference Parameters** | `var` parameters for in-place modification | All 7 |
| **Recursion** | Functions/procedures calling themselves | tree_sort_wirth, nested_s_expression_list |
| **Nested Data Structures** | Trees containing lists, records with pointer fields | nested_s_expression_list, tree_sort_wirth |
| **Multi-way Branching** | `case` statement with integer selector | case_bucket_lists |
| **Complex Boolean Logic** | `and` in loop conditions, `not` for flags | primes_under_1000_list, nested_s_expression_list |
| **Static Arrays** | Fixed-size char arrays for input buffering | nested_s_expression_list, string_to_linked_list |

---

### 📊 Feature Usage Summary

| Feature | Count |
|---------|-------|
| Files using `record` | 7 |
| Files using typed pointers (`^`) | 7 |
| Files using `new` | 7 |
| Files using `dispose` | 7 |
| Files using `while` loops | 6 |
| Files using `for` loops | 3 |
| Files using `if/else` | 7 |
| Files using `case` | 1 |
| Files using functions | 5 |
| Files using procedures | 6 |
| Files using recursion | 2 |
| Files using `var` parameters | 7 |
| Files using `readln` | 2 |
| Files using `write` | 7 |
| Files using `writeln` | 7 |
| Files using arrays | 2 |
| Files using `mod` | 2 |
| Files using `boolean` type | 4 |
| Files using `char` type | 3 |

---

### 🎯 Notable Patterns

1. **Linked List Pattern**: All 7 files implement linked lists using records with `value` and `next` fields, managed via `new`/`dispose`.

2. **Tree Structure**: `tree_sort_wirth.pas` and `nested_s_expression_list.pas` use binary tree and nested tree structures with left/right/child pointers.

3. **Input Parsing**: `nested_s_expression_list.pas` and `string_to_linked_list.pas` read character-by-character input with `readln` into char arrays.

4. **Prime Algorithm**: `primes_under_1000_list.pas` implements trial division with `mod` operator and `boolean` return type.

5. **Case-Based Distribution**: `case_bucket_lists.pas` uses `case n mod 4 of` to distribute 40 numbers into 4 separate linked lists.

6. **Recursive Tree Operations**: `tree_sort_wirth.pas` demonstrates all three tree operations: insertion, in-order traversal, and post-order disposal.

7. **Reference Semantics**: All files extensively use `var` parameters to modify pointer variables passed by reference, enabling list/tree head/tail updates.

---

### ❌ Features NOT Used

The following Pascal features from the compiler's supported subset are **not** used in any `examples/lists/` program:

- `@` (address-of operator)
- Forward declarations / prototypes
- Array bounds checking (explicitly tested)
- Division operator (`/`)
- `or` boolean operator
- `downto` in for loops
- Multiple var sections
- Global function access patterns
- Nested procedures/functions

---

*Report generated by analyzing all `.pas` files in `examples/lists/` directory.*

---
Report generated at: Thu May  7 11:03:45 UTC 2026
Commit SHA: a0fb2ab50ef682645e1c8b75ed318c1868090051
