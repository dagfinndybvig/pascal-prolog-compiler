The markdown report has been successfully created at `examples/lists/pascal-subset-report.md` with 329 lines. The report comprehensively analyzes all 5 Pascal programs in the `examples/lists` directory, covering:

- **Overview** of all files analyzed
- **Data Types** with detailed tables showing usage across files
- **Control Structures** (if/then/else, while, for loops)
- **Subprograms** (functions, procedures, parameters, recursion)
- **Pointer and Memory Management** (new, dispose, nil, dereferencing)
- **I/O Operations** (readln, write, writeln)
- **Operators and Expressions**
- **Advanced Features** (global variables, local variables, shadowing, comments)
- **Feature Coverage Summary** categorized by universality
- **Program-Specific Highlights** for each of the 5 programs
- **Pascal Subset Not Used** section

The report uses markdown tables extensively for clear comparison across programs and includes code examples where helpful.
---------------|--------------|------------|-------|
| `integer` | ✓ | ✓ | ✓ | | ✓ | 4 |
| `char` | | | ✓ | ✓ | | 2 |
| `boolean` | | | ✓ | | ✓ | 2 |
| `record` | ✓ | ✓ | ✓ | ✓ | ✓ | 5 |
| Typed pointers (`^Type`) | ✓ | ✓ | ✓ | ✓ | ✓ | 5 |
| Named type aliases (`type`) | ✓ | ✓ | ✓ | ✓ | ✓ | 5 |
| Static arrays (`array[..] of char`) | | | ✓ | ✓ | | 2 |

### Type Declarations
All programs use named type aliases:
```pascal
// count_list.pas, for_count_list.pas, string_to_linked_list.pas
type
  node = record
    value: integer;  // or char in string_to_linked_list
    next: ^node;
  end;
  node_ptr = ^node;

// nested_s_expression_list.pas
type
  node = record
    kind: char;
    value: char;
    child: ^node;
    next: ^node;
  end;

// tree_sort_wirth.pas
type
  tree_node = record
    key: integer;
    left: ^tree_node;
    right: ^tree_node;
  end;
  tree_ptr = ^tree_node;
```

---

## Control Structures

| Feature | count_list | for_count_list | nested_s_expr | string_to_ll | tree_sort | Total |
|---------|------------|----------------|---------------|--------------|------------|-------|
| `if...then` | ✓ | ✓ | ✓ | ✓ | ✓ | 5 |
| `if...then...else` | ✓ | ✓ | ✓ | ✓ | ✓ | 5 |
| `while...do` | ✓ | | ✓ | ✓ | | 3 |
| `for...to...do` | | ✓ | | | | 1 |
| Nested conditionals | ✓ | ✓ | ✓ | ✓ | ✓ | 5 |
| Nested loops | | | ✓ | ✓ | | 2 |

### Loop Patterns
- **While loops**: Used for list construction (`i <= size`), traversal (`curr <> nil`), and input reading (`ch <> ')'`)
- **For loops**: `for i := 1 to size do` for bounded iteration (for_count_list.pas)
- **Loop re-evaluation**: For-loop bounds are re-evaluated each iteration (parameter passing)

---

## Subprograms

| Feature | count_list | for_count_list | nested_s_expr | string_to_ll | tree_sort | Total |
|---------|------------|----------------|---------------|--------------|------------|-------|
| Integer-returning functions | ✓ (3) | ✓ (3) | | | | 2 |
| Procedures (void) | | | ✓ (4) | | ✓ (3) | 2 |
| Value parameters | ✓ | ✓ | ✓ | | ✓ | 4 |
| `var` (by-reference) parameters | ✓ | ✓ | ✓ | | ✓ | 4 |
| Multiple parameters (2+) | ✓ | ✓ | ✓ | | ✓ | 4 |
| Recursive subprograms | | | ✓ | | ✓ | 2 |
| Mutual recursion | | | ✓ | | | 1 |

### Function Details

**count_list.pas:**
- `make_list(var head: node_ptr; size: integer): integer` - Builds list, returns size
- `count_nodes(var head: node_ptr): integer` - Counts nodes iteratively
- `free_list(var head: node_ptr): integer` - Disposes all nodes, returns count

**for_count_list.pas:**
- `make_list_for(var head: node_ptr; size: integer): integer` - Uses for-loop
- `count_nodes_for(var head: node_ptr; size: integer): integer` - Uses for-loop
- `free_list_for(var head: node_ptr; size: integer): integer` - Uses for-loop

**tree_sort_wirth.pas:**
- `insert_tree(var t: tree_ptr; value: integer)` - Recursively inserts into BST
- `print_in_order(t: tree_ptr; var first: boolean)` - In-order traversal (recursive)
- `dispose_tree(var t: tree_ptr)` - Recursively disposes tree

**nested_s_expression_list.pas:**
- `append_node(var head: node_ptr; var tail: node_ptr; item: node_ptr)` - Appends to list
- `parse_list(var result: node_ptr)` - Recursively parses S-expressions
- `print_nodes(nodes: node_ptr)` - Iterative printing with nested calls
- `dispose_nodes(var nodes: node_ptr)` - Recursively disposes nested structures

### Recursion Depth
- **Direct recursion**: `insert_tree`, `print_in_order`, `dispose_tree` (tree_sort_wirth.pas)
- **Mutual recursion**: `parse_list` calls itself and `append_node`; `dispose_nodes` calls itself recursively and `dispose_nodes` on children (nested_s_expression_list.pas)

---

## Pointer and Memory Management

| Feature | count_list | for_count_list | nested_s_expr | string_to_ll | tree_sort | Total |
|---------|------------|----------------|---------------|--------------|------------|-------|
| `^Type` (pointer type declaration) | ✓ | ✓ | ✓ | ✓ | ✓ | 5 |
| `nil` (null pointer) | ✓ | ✓ | ✓ | ✓ | ✓ | 5 |
| `new(pointer)` (allocation) | ✓ | ✓ | ✓ | ✓ | ✓ | 5 |
| `dispose(pointer)` (deallocation) | ✓ | ✓ | ✓ | ✓ | ✓ | 5 |
| `pointer^.field` (dereference) | ✓ | ✓ | ✓ | ✓ | ✓ | 5 |
| `pointer = nil` comparison | ✓ | ✓ | ✓ | ✓ | ✓ | 5 |
| `pointer <> nil` comparison | ✓ | ✓ | ✓ | ✓ | ✓ | 5 |
| Field assignment through pointer | ✓ | ✓ | ✓ | ✓ | ✓ | 5 |

### Pointer Usage Patterns

**All programs** use typed pointers with records containing pointer fields:
- Singly linked list: `next: ^node`
- S-expression node: `child: ^node; next: ^node`
- Binary tree: `left: ^tree_node; right: ^tree_node`

**Memory lifecycle:**
1. Allocation: `new(item)`
2. Field initialization: `item^.value := ...; item^.next := nil`
3. Linking: `tail^.next := item` or `t^.left := ...`
4. Traversal: `curr := curr^.next`
5. Disposal: `dispose(curr)` with proper next-pointer tracking
6. Null assignment: `head := nil`

---

## I/O Operations

| Feature | count_list | for_count_list | nested_s_expr | string_to_ll | tree_sort | Total |
|---------|------------|----------------|---------------|--------------|------------|-------|
| `writeln` | ✓ (4) | ✓ (4) | ✓ (2) | | ✓ (2) | 4 |
| `write` | | | ✓ (8) | ✓ (2) | ✓ (4) | 3 |
| `readln` | | | ✓ (1) | ✓ (1) | | 2 |
| Multi-argument write/writeln | ✓ | ✓ | ✓ | ✓ | ✓ | 5 |
| String literals | ✓ | ✓ | ✓ | ✓ | ✓ | 5 |
| Expression output | ✓ | ✓ | ✓ | ✓ | ✓ | 5 |

### I/O Patterns

**Output formatting:**
- `writeln('built: ', built)` - Mixed string literal and integer expression
- `write('[', curr^.value, '] -> ')` - Multi-argument with char/string concatenation
- `write('('); print_nodes(curr^.child); write(')')` - Nested I/O calls

**Input:**
- `readln(ch)` - Single character input
- Sentinel-based termination: `while ch <> ')' do` and `while not done do`

---

## Operators and Expressions

| Feature | count_list | for_count_list | nested_s_expr | string_to_ll | tree_sort | Total |
|---------|------------|----------------|---------------|--------------|------------|-------|
| Assignment (`:=`) | ✓ | ✓ | ✓ | ✓ | ✓ | 5 |
| Equality (`=`) | ✓ | ✓ | ✓ | ✓ | ✓ | 5 |
| Inequality (`<>`) | ✓ | ✓ | ✓ | ✓ | ✓ | 5 |
| Less than (`<`) | | | | | ✓ | 1 |
| Addition (`+`) | ✓ | ✓ | ✓ | ✓ | | 4 |
| Subtraction (`-`) | | | ✓ | | | 1 |
| Boolean AND (`and`) | ✓ | ✓ | ✓ | ✓ | ✓ | 5 |
| Boolean OR (`or`) | | | ✓ | | | 1 |
| Boolean NOT (`not`) | | | ✓ | ✓ | | 2 |
| Comparison chaining | | | ✓ | | | 1 |
| Field access (`.`) | ✓ | ✓ | ✓ | ✓ | ✓ | 5 |

### Expression Complexity
- **Arithmetic**: `i + 1`, `total + 1`, `depth + 1`, `depth - 1`
- **Boolean**: `curr <> nil`, `head = nil`, `value < t^.key`, `(pos <= count) and (input[pos] <> ')')`
- **Negation**: `not done`
- **Chained comparisons**: `(pos <= count) and (input[pos] <> ')')`

---

## Advanced Features

| Feature | count_list | for_count_list | nested_s_expr | string_to_ll | tree_sort | Total |
|---------|------------|----------------|---------------|--------------|------------|-------|
| Global variables | ✓ (4) | ✓ (4) | ✓ (6) | ✓ (8) | ✓ (2) | 5 |
| Local variables in subprograms | ✓ | ✓ | ✓ | | ✓ | 4 |
| Parameter passing | ✓ | ✓ | ✓ | | ✓ | 4 |
| Shadowing (locals vs globals) | ✓ | ✓ | ✓ | | ✓ | 4 |
| Comments (curly brace) | | | ✓ | | ✓ | 2 |
| Complex nested structures | | | ✓ | | ✓ | 2 |

### Global Variables Summary

| Program | Global Variables | Count |
|---------|------------------|-------|
| count_list.pas | `list: node_ptr`, `built: integer`, `counted: integer`, `freed: integer` | 4 |
| for_count_list.pas | Same as count_list | 4 |
| nested_s_expression_list.pas | `input: array[1..64] of char`, `count: integer`, `pos: integer`, `depth: integer`, `done: boolean`, `ch: char`, `root: node_ptr` | 7 |
| string_to_linked_list.pas | `input: array[1..32] of char`, `count: integer`, `i: integer`, `ch: char`, `head: node_ptr`, `tail: node_ptr`, `item: node_ptr`, `curr: node_ptr`, `next_item: node_ptr` | 8 |
| tree_sort_wirth.pas | `root: tree_ptr`, `first_output: boolean` | 2 |

---

## Feature Coverage Summary

### Universally Used (5/5 programs)
- Records
- Typed pointers (`^Type`)
- Named type aliases
- `if...then...else`
- `nil` comparisons
- `new`/`dispose`
- Pointer dereference (`^.`)
- `writeln`
- String literals in output
- Assignment and comparison operators
- Field access

### Common (4/5 programs)
- Integer data type
- Functions with return values
- Value and `var` parameters
- Multi-parameter subprograms
- `while...do` loops
- Local variables in subprograms
- Boolean type
- Multi-argument `write`/`writeln`
- Global variables

### Moderate (2-3/5 programs)
- `char` type (2)
- `for...to...do` loops (1)
- Static arrays (2)
- Recursion (2)
- `readln` input (2)
- Addition arithmetic (4)
- Boolean OR (1)
- Boolean NOT (2)

### Rare (1/5 programs)
- Less than comparison (`<`) - only in tree_sort_wirth.pas
- Subtraction (`-`) - only in nested_s_expression_list.pas
- Mutual recursion - only in nested_s_expression_list.pas
- Curly-brace comments - in nested_s_expression_list.pas and tree_sort_wirth.pas

---

## Program-Specific Highlights

### count_list.pas
- **Purpose**: Demonstrates linked list construction, counting, and disposal using while-loops
- **Unique features**: Clean separation of concerns (make/count/free as separate functions)
- **Lines of code**: ~101

### for_count_list.pas
- **Purpose**: Same as count_list but uses for-loops instead of while-loops
- **Unique features**: Shows for-loop with re-evaluated bounds via parameters
- **Lines of code**: ~106

### nested_s_expression_list.pas
- **Purpose**: Parses nested S-expression input into a tree-like linked structure
- **Unique features**: 
  - Most complex program (~152 lines)
  - Mutual recursion between `parse_list` and nested structure handling
  - Character-based parsing with depth tracking
  - Recursive disposal of nested structures
  - Only program using `char` comparisons and `or` operator
- **Lines of code**: ~152

### string_to_linked_list.pas
- **Purpose**: Converts user input string to linked list of characters
- **Unique features**:
  - Input buffer using static char array
  - Sentinel-based input termination
  - Filtering of special characters during list construction
  - Only program without explicit subprogram declarations (all code in main)
- **Lines of code**: ~75

### tree_sort_wirth.pas
- **Purpose**: Implements binary search tree with in-order traversal (tree sort algorithm)
- **Unique features**:
  - Binary tree structure with left/right children
  - Recursive insertion with BST property
  - In-order traversal for sorted output
  - Only program using `<` comparison operator
  - Most elegant recursive structure
- **Lines of code**: ~83

---

## Pascal Subset Not Used

Features **NOT** used in any of the `examples/lists` programs:
- `mod` operator
- Division (`/`) and multiplication (`*`)
- `downto` in for-loops
- `case` statements
- Forward declarations
- Function overloading
- Array indexing with expressions (arrays used only for char buffers)
- `array` as subprogram parameter
- `array` of types other than `char`
- Enumerated types
- Subranges
- Sets
- File I/O
- `repeat...until`
- `goto` statements
- Inline assembly

---

*Report generated by analyzing all Pascal source files in `examples/lists/` directory.*

---
Report generated at: Thu May  7 10:40:28 UTC 2026
Commit SHA: c134a58495eefd22c690149d4c6305a8810a7c07
