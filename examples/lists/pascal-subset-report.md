# Pascal Subset Analysis: `examples/lists/` Programs

## Overview

The `examples/lists/` directory contains **9 Pascal programs** totaling **~1,262 lines** demonstrating linked lists, trees, and various data structure manipulations. All programs compile to native x86-64 via the Pascal-to-Prolog compiler.

---

## Program-by-Program Feature Breakdown

| Program | Lines | Description |
|---------|-------|-------------|
| `case_bucket_lists.pas` | 133 | Distributes numbers 1-40 into 4 linked lists based on `mod 4` using `case` |
| `const_list.pas` | 105 | Builds linked list using **typed constants** (`const` declarations) |
| `count_list.pas` | 101 | Creates list, counts nodes, frees memory with `while` loops |
| `for_count_list.pas` | 106 | Uses `for ... to ... do` loops for list creation, counting, and freeing |
| `nested_s_expression_list.pas` | 152 | Parses nested S-expressions into tree-structured linked lists with **recursion** |
| `primes_under_1000_list.pas` | 129 | Builds list of primes < 1000 using `mod`, `for`, and `is_prime` function |
| `set_to_list.pas` | 120 | Converts **Pascal set** `[1,3,4,7,10..12,20,31]` to linked list |
| `string_to_linked_list.pas` | 75 | Reads string input and builds character-linked list |
| `tree_sort_wirth.pas` | 83 | Binary search tree implementation with in-order traversal |

---

## Pascal Subset Enumeration

### 📦 Data Types

| Type | Category | Used In | Count |
|------|----------|---------|-------|
| `integer` | Scalar | All 9 | 9 |
| `char` | Scalar | 6 | 6 |
| `boolean` | Scalar | 3 | 3 |
| `record` | Structured | 8 | 8 |
| `^Type` (pointer) | Reference | 8 | 8 |
| `array[Low..High] of T` | Static array | 2 | 2 |
| `set of Low..High` | Set | 1 | 1 |

**Record details:**
- `node = record value: integer; next: ^node; end` (7 programs)
- `node = record kind: char; value: char; child: ^node; next: ^node; end` (nested_s_expression_list)
- `tree_node = record key: integer; left: ^tree_node; right: ^tree_node; end` (tree_sort_wirth)

**Pointer types:**
- `node_ptr = ^node` (7 programs)
- `tree_ptr = ^tree_node` (tree_sort_wirth)

**Array types:**
- `array[1..64] of char` (nested_s_expression_list)
- `array[1..32] of char` (string_to_linked_list)

**Set type:**
- `int_set = set of 0..31` (set_to_list)

---

### 🎯 Constants

| Feature | Used In | Examples |
|---------|---------|----------|
| Typed global `const` | `const_list.pas` | `ListSize: integer = 5;`, `StartValue: integer = 10;`, `StepValue: integer = 3;`, `Prefix: char = '#';` |

---

### 🔄 Control Structures

| Structure | Used In | Count |
|-----------|---------|-------|
| `if ... then` | All 9 | 9 |
| `if ... then ... else` | 8 | 8 |
| `while ... do` | 7 | 7 |
| `for ... to ... do` | 5 | 5 |
| `case ... of ... else ... end` | 1 | 1 |
| **Recursion** | 4 | 4 |

**Recursion usage:**
- `parse_list` (nested_s_expression_list)
- `print_nodes` (nested_s_expression_list)
- `dispose_nodes` (nested_s_expression_list)
- `insert_tree`, `print_in_order`, `dispose_tree` (tree_sort_wirth)

**`for` loop bounds:**
- `for n := 1 to 40 do` (case_bucket_lists)
- `for n := 1 to size do` (count_list)
- `for i := 1 to size do` (for_count_list)
- `for n := 2 to limit - 1 do` (primes_under_1000_list)
- `for n := 0 to 31 do` (set_to_list)

**`case` statement:**
- `case n mod 4 of 0: ...; 1: ...; 2: ...; 3: ... else ... end` (case_bucket_lists)

---

### ⚙️ Procedures and Functions

| Feature | Used In | Count |
|---------|---------|-------|
| **Functions (returning integer)** | 8 | 8 |
| **Functions (returning boolean)** | 1 | 1 |
| **Procedures (void)** | 4 | 4 |
| **Parameters by value** | 8 | 8 |
| **Parameters by reference (`var`)** | 8 | 8 |
| **Multiple parameters** (up to 3) | 8 | 8 |
| **Function recursion** | 1 | 1 |

**Function examples:**
- `is_prime(n: integer): boolean` (primes_under_1000_list)
- `append_node(var head: node_ptr; var tail: node_ptr; value: integer): integer`
- `print_list(var head: node_ptr): integer`
- `free_list(var head: node_ptr): integer`
- `build_list(var head: node_ptr): integer` (const_list)
- `make_list(var head: node_ptr; size: integer): integer`
- `count_nodes(var head: node_ptr): integer`

**Procedure examples:**
- `append_node(var head: node_ptr; var tail: node_ptr; item: node_ptr)` (nested_s_expression_list)
- `parse_list(var result: node_ptr)`
- `print_nodes(nodes: node_ptr)`
- `dispose_nodes(var nodes: node_ptr)`
- `insert_tree(var t: tree_ptr; value: integer)` (tree_sort_wirth)
- `print_in_order(t: tree_ptr; var first: boolean)`
- `dispose_tree(var t: tree_ptr)`

---

### 🖨️ I/O Operations

| Operation | Used In | Count |
|-----------|---------|-------|
| `readln` | 2 | 2 |
| `write` | 8 | 8 |
| `writeln` | 8 | 8 |
| **Multi-argument write/writeln** | 8 | 8 |

**I/O examples:**
- `readln(ch)` (nested_s_expression_list, string_to_linked_list)
- `write(curr^.value)` (case_bucket_lists)
- `write(Prefix, curr^.value, ' ')` (const_list - multi-arg)
- `writeln('built: ', built, ', printed0: ', printed0)` (case_bucket_lists - multi-arg)
- `writeln('Tree sort:')` (tree_sort_wirth)

---

### 💾 Memory Management

| Feature | Used In | Count |
|---------|---------|-------|
| `new(pointer)` | 8 | 8 |
| `dispose(pointer)` | 8 | 8 |
| `nil` | 8 | 8 |
| `pointer^` (dereference) | 8 | 8 |
| `pointer^.field` (field through pointer) | 8 | 8 |
| `head := nil` (null assignment) | 8 | 8 |

**Heap allocation patterns:**
```pascal
new(item);
item^.value := value;
item^.next := nil;
```

**Recursive disposal:**
```pascal
dispose_tree(t^.left);
dispose_tree(t^.right);
dispose(t);
t := nil;
```

---

### 🔢 Operators

| Category | Operators | Used In |
|----------|-----------|---------|
| **Arithmetic** | `+`, `-`, `*`, `/` | 6 |
| **Modulo** | `mod` | 4 |
| **Comparison** | `=`, `<>`, `<`, `<=`, `>`, `>=` | 8 |
| **Boolean** | `and`, `or`, `not` | 3 |
| **Set** | `in`, `[...]` (set literal), `..` (range) | 1 |
| **Assignment** | `:=` | All 9 |
| **Member access** | `.` | 8 |
| **Pointer dereference** | `^` | 8 |

**Operator examples:**
- `n mod d = 0` (primes_under_1000_list)
- `d * d <= n` (primes_under_1000_list)
- `n in selected` (set_to_list)
- `[1, 3, 4, 7, 10..12, 20, 31]` (set_to_list)
- `(d * d <= n) and is_prime` (primes_under_1000_list)
- `if head = nil then` (count_list)

---

### 🏷️ Type Declarations

| Feature | Used In | Count |
|---------|---------|-------|
| `type` aliases | 8 | 8 |
| Named record types | 8 | 8 |
| Named pointer types | 8 | 8 |

**Type declaration examples:**
```pascal
type
  node = record
    value: integer;
    next: ^node;
  end;
  node_ptr = ^node;
```

---

### 📊 Feature Usage Summary Table

| Feature | case_bucket | const_list | count_list | for_count | nested_s_expr | primes_1000 | set_to_list | string_to_ll | tree_sort | **Total** |
|---------|-------------|------------|------------|-----------|--------------|-------------|-------------|-------------|-----------|----------|
| `integer` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **9** |
| `char` | ✅ | ✅ | | | ✅ | | ✅ | ✅ | | **5** |
| `boolean` | | ✅ | ✅ | | ✅ | ✅ | | | | **4** |
| `record` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **8** |
| Pointers (`^`) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **8** |
| `array` | | | | | ✅ | | | ✅ | | **2** |
| `set` | | | | | | | ✅ | | | **1** |
| `const` | | ✅ | | | | | | | | **1** |
| `if/else` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **9** |
| `while` | ✅ | ✅ | ✅ | | ✅ | ✅ | ✅ | ✅ | | **7** |
| `for..to` | ✅ | | | ✅ | | ✅ | ✅ | | | **4** |
| `case` | ✅ | | | | | | | | | **1** |
| Recursion | | | | | ✅ | | | | ✅ | **2** |
| Functions | ✅ | ✅ | ✅ | ✅ | | ✅ | ✅ | | | **6** |
| Procedures | | | | | ✅ | | | | ✅ | **2** |
| `var` params | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | | ✅ | **8** |
| `new/dispose` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **9** |
| `readln` | | | | | ✅ | | | ✅ | | **2** |
| `write/writeln` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **9** |
| Multi-arg I/O | ✅ | ✅ | ✅ | ✅ | | ✅ | ✅ | | ✅ | **7** |

---

## Key Observations

### Most Used Features (Across All Programs)
1. **Records + Pointers** - 8/9 programs use linked data structures
2. **`new`/`dispose`** - All programs perform heap allocation/deallocation
3. **`if/else`** - All 9 programs use conditional logic
4. **`write`/`writeln`** - All 9 programs produce output
5. **`while` loops** - 7 programs use while for iteration
6. **`var` parameters** - 8 programs pass by reference
7. **Functions returning integer** - 6 programs use integer-returning functions

### Unique/Notable Features per Program
| Program | Unique Feature |
|---------|----------------|
| `case_bucket_lists.pas` | `case ... of ... else ... end` statement |
| `const_list.pas` | Typed `const` declarations with compile-time evaluation |
| `for_count_list.pas` | `for ... to ... do` loops for all operations |
| `nested_s_expression_list.pas` | Recursive parsing, nested records, `char` handling, `array` input buffer |
| `primes_under_1000_list.pas` | Prime checking with `mod`, boolean function |
| `set_to_list.pas` | **Pascal sets** with `set of 0..31`, membership (`in`), range literals (`10..12`) |
| `string_to_linked_list.pas` | Character-linked list from user input |
| `tree_sort_wirth.pas` | Binary search tree with recursive insert/traversal |

### Advanced Pascal Features Demonstrated
- ✅ **Typed pointers** with `^`, `nil`, `new`, `dispose`
- ✅ **Recursion** in both procedures and functions
- ✅ **By-reference parameters** (`var`) for modifying pointers
- ✅ **Record field access through pointers** (`item^.value`, `t^.left`)
- ✅ **Multi-argument `write`/`writeln`**
- ✅ **Set types** with membership testing
- ✅ **Typed constants** (global `const` declarations)
- ✅ **`case` statements** with integer selectors
- ✅ **`for` loops** with `to`
- ✅ **Static arrays** for input buffering
- ✅ **Type aliases** via `type` declarations

### Not Used in `examples/lists/`
- Division operator `/` (only `mod`, `*`, `+`, `-` used)
- `downto` in `for` loops
- `@` (address-of operator)
- Division-by-zero handling
- Global variables accessed within functions/procedures (all globals are passed or are standalone)
- Forward declarations
- Array bounds checking errors (arrays used are for input only)
- Set algebra operators (`+`, `-`, `*`) - only membership (`in`) used

---
Report generated at: Fri May  8 07:41:19 UTC 2026
Commit SHA: c50838fb7dae28f8a4c0457361f10bdfc23bedab
