# Pascal Subset Report: `examples/lists/` Directory

## Files Analyzed (4 total)
- `count_list.pas` — Linked list creation, counting, and disposal
- `nested_s_expression_list.pas` — Nested S-expression parsing and tree construction
- `string_to_linked_list.pas` — String-to-linked-list conversion
- `tree_sort_wirth.pas` — Binary search tree implementation (Wirth's tree sort)

---

## Pascal Subset Enumeration

### Data Types

| Type | Usage | Files |
|------|-------|-------|
| `integer` | Numeric values, loop counters, list sizes | All 4 |
| `char` | Character data, S-expression tokens | `nested_s_expression_list.pas`, `string_to_linked_list.pas` |
| `boolean` | Flags, loop control | `nested_s_expression_list.pas`, `tree_sort_wirth.pas` |
| `record` | Structured data with typed fields | All 4 |
| Typed pointers (`^TypeName`) | Heap-allocated nodes, references | All 4 |
| Named type aliases (`type` ... `=`) | `node = record...`, `node_ptr = ^node` | All 4 |
| Static arrays | `array[1..N] of char` input buffers | `nested_s_expression_list.pas`, `string_to_linked_list.pas` |

### Control Structures

| Structure | Usage | Files |
|-----------|-------|-------|
| `while ... do` | Iteration, list traversal, input reading | All 4 |
| `if ... then ... else` | Conditional branching | All 4 |
| Recursion | Tree traversal, nested list disposal | `nested_s_expression_list.pas`, `tree_sort_wirth.pas` |

### Subprograms

| Feature | Details | Files |
|---------|---------|-------|
| **Procedures** | Void subprograms | All 4 |
| **Functions** | Integer-returning subprograms | `count_list.pas` |
| **Parameters** | Up to 6 parameters | All 4 |
| **`var` parameters** | By-reference (scalar and pointer) | All 4 |
| **Local variables** | Declared within subprograms | All 4 |
| **Recursion** | Self-referential calls | `nested_s_expression_list.pas`, `tree_sort_wirth.pas` |

### I/O Operations

| Operation | Usage | Files |
|-----------|-------|-------|
| `readln` | Read single char from stdin | `nested_s_expression_list.pas`, `string_to_linked_list.pas` |
| `write` | Output without newline, multi-argument | All 4 |
| `writeln` | Output with newline, multi-argument | All 4 |

### Advanced Features

| Feature | Usage | Files |
|---------|-------|-------|
| `nil` | Null pointer constant | All 4 |
| `new` | Heap allocation | All 4 |
| `dispose` | Heap deallocation | All 4 |
| Pointer dereference (`p^`) | Access pointer target | All 4 |
| Field-through-pointer (`p^.field`) | Access record fields via pointer | All 4 |
| Pointer assignment | `head := item`, `t := nil` | All 4 |
| Nested record fields | Multi-field records with pointer fields | All 4 |
| Comments | `{ ... }` style | `tree_sort_wirth.pas` |
| Multi-argument `write`/`writeln` | Mix of literals and expressions | All 4 |
| Type aliases | Named types for readability | All 4 |
| Global variables | Declared in main scope | All 4 |
| Shadowing | Parameters shadow globals | All 4 |

---

## Feature Summary by Category

### Data Structures
- **Linked lists**: Singly-linked (`next: ^node`) in 3 files
- **Binary trees**: Left/right child pointers in `tree_sort_wirth.pas`
- **Nested structures**: S-expression tree with `child` and `next` pointers in `nested_s_expression_list.pas`
- **Static arrays**: Character buffers for input in 2 files

### Memory Management
All programs demonstrate complete memory lifecycle:
- Allocation via `new`
- Traversal via pointer chasing
- Deallocation via `dispose`
- Null checks via `= nil` or `<> nil`

### Algorithm Patterns
- **List construction**: Head/tail pattern with conditional first-insertion logic
- **List traversal**: `while curr <> nil do` pattern
- **Tree insertion**: Recursive BST insertion
- **Tree traversal**: In-order recursive traversal
- **Input parsing**: Character-by-character with sentinel detection

---

## Not Used in `examples/lists/`

The following Pascal features **from the compiler's supported subset** are *not* used:
- `for ... to/downto ... do` loops
- `case ... of ... end` statements
- `mod` operator
- Arithmetic operators other than `+`, `-`, `<`, `>`, `<=`
- `and`, `or`, `not` boolean operators
- Division (`/`) and multiplication (`*`)
- Global `var` sections before/after functions
- Functions returning values other than integer
- Two-dimensional or non-char arrays

---
Report generated at: Thu May  7 10:33:15 UTC 2026
Commit SHA: bd03fc1c03512db4832fc75bf072892ca2c102a1
