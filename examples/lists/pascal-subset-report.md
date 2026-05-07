# Pascal Subset Analysis: `examples/lists/`

## Overview
Three programs demonstrate linked data structures and tree-based sorting, using pointers, records, and recursion.

---

## Programs Analyzed

| Program | Size (lines) | Purpose |
|---------|-------------|---------|
| `nested_s_expression_list.pas` | 152 | Parses nested S-expression strings into a tree of linked list nodes |
| `string_to_linked_list.pas` | 75 | Converts character input into a singly-linked list |
| `tree_sort_wirth.pas` | 83 | Implements tree sort using a binary search tree |

---

## Data Types Used

| Category | Types | Occurrences |
|----------|-------|-------------|
| **Scalar Primitives** | `integer`, `boolean`, `char` | All 3 programs |
| **Composite** | `record` | All 3 programs |
| **Pointer** | `^node`, `^node_ptr`, `^tree_node`, `^tree_ptr` | All 3 programs |
| **Array** | `array[1..32] of char`, `array[1..64] of char` | 2 programs |
| **Type Aliases** | `node = record...`, `node_ptr = ^node`, `tree_node = record...`, `tree_ptr = ^tree_node` | All 3 programs |

---

## Control Structures

| Structure | Programs |
|-----------|----------|
| `if ... then ... else` | All 3 |
| `while ... do` | nested_s_expression_list, string_to_linked_list |
| **Recursion** | nested_s_expression_list, tree_sort_wirth |
| Nested `begin/end` blocks | All 3 |

---

## Procedures & Functions

| Feature | Details | Programs |
|---------|---------|----------|
| **Procedure Declarations** | Named subprograms with parameter lists | All 3 |
| **By-Value Parameters** | `value: integer`, `nodes: node_ptr`, `item: node_ptr` | All 3 |
| **By-Reference (`var`) Parameters** | `var head: node_ptr`, `var tail: node_ptr`, `var result: node_ptr`, `var t: tree_ptr`, `var first: boolean` | nested_s_expression_list, tree_sort_wirth |
| **Parameter Count** | Up to 3 parameters | All 3 |
| **Local Variables** | Declared in procedure bodies with `var` | nested_s_expression_list, tree_sort_wirth |
| **Recursive Calls** | Procedures calling themselves | nested_s_expression_list (parse_list, dispose_nodes), tree_sort_wirth (insert_tree, print_in_order, dispose_tree) |
| **Mutual Recursion** | Not used | None |

---

## I/O Operations

| Operation | Programs |
|-----------|----------|
| `readln` | nested_s_expression_list, string_to_linked_list |
| `write` | All 3 |
| `writeln` | All 3 |
| **Multi-argument `write`** | `write('[', curr^.value, ']')`, `write('tree: ')`, `write('(')` | All 3 |

---

## Pointer & Record Operations

| Operation | Syntax | Programs |
|-----------|--------|----------|
| **Pointer Dereference** | `p^` | All 3 |
| **Record Field Access** | `p^.field` | All 3 |
| **Nil Pointer** | `nil` | All 3 |
| **Heap Allocation** | `new(p)` | All 3 |
| **Heap Deallocation** | `dispose(p)` | All 3 |
| **Field Through Pointer** | `item^.kind`, `item^.value`, `item^.child`, `item^.next`, `t^.key`, `t^.left`, `t^.right` | All 3 |
| **Nested Pointer Fields** | `curr^.next`, `t^.left`, `t^.right` | All 3 |

---

## Expressions & Operators

| Category | Operators/Features | Programs |
|----------|-------------------|----------|
| **Arithmetic** | `+`, `-` (unary and binary) | All 3 |
| **Comparison** | `=`, `<>`, `<`, `<=`, `>`, `>=` | All 3 |
| **Boolean** | `and`, `or`, `not` | nested_s_expression_list (`and`), string_to_linked_list (`and`) |
| **Assignment** | `:=` | All 3 |
| **Parentheses** | `( ... )` for grouping | All 3 |

---

## Advanced Features

| Feature | Description | Programs |
|---------|-------------|----------|
| **Typed Pointers** | Pointers to specific record types (`^node`, `^tree_node`) | All 3 |
| **Type Aliases** | Named type declarations (`type node = record...`) | All 3 |
| **Pointer Type Aliases** | `node_ptr = ^node`, `tree_ptr = ^tree_node` | All 3 |
| **Null Pointer Checks** | `if p = nil`, `while curr <> nil` | All 3 |
| **Deep Recursion** | Recursive tree/list traversal | nested_s_expression_list, tree_sort_wirth |
| **Recursive Data Structures** | Nodes containing pointers to same type | All 3 |
| **Memory Management** | Manual `new`/`dispose` with recursive disposal | All 3 |
| **Var Parameters for Pointers** | Passing pointers by reference to modify caller's pointer | nested_s_expression_list, tree_sort_wirth |
| **Array Buffer I/O** | Using `array[...] of char` as input buffer | nested_s_expression_list, string_to_linked_list |
| **S-Expression Parsing** | Nested parentheses parsing with depth tracking | nested_s_expression_list |

---

## Feature Matrix by Program

| Feature | nested_s_expression_list.pas | string_to_linked_list.pas | tree_sort_wirth.pas |
|---------|-----------------------------|---------------------------|---------------------|
| Scalar types (int/bool/char) | ✓ | ✓ | ✓ |
| Records | ✓ | ✓ | ✓ |
| Typed pointers | ✓ | ✓ | ✓ |
| Type aliases | ✓ | ✓ | ✓ |
| Static arrays | ✓ | ✓ | ✅ |
| Procedures | ✓ | ✅ | ✓ |
| By-reference parameters (`var`) | ✓ | ✅ | ✓ |
| By-value parameters | ✓ | ✓ | ✓ |
| Local variables in procedures | ✓ | ✅ | ✓ |
| Recursion | ✓ | ✅ | ✓ |
| `new` / `dispose` | ✓ | ✓ | ✓ |
| `nil` | ✓ | ✓ | ✓ |
| `readln` | ✓ | ✓ | ✅ |
| `write` / `writeln` | ✓ | ✓ | ✓ |
| Multi-arg `write` | ✓ | ✓ | ✓ |
| `if/else` | ✓ | ✓ | ✓ |
| `while/do` | ✓ | ✓ | ✅ |
| Boolean `and`/`or` | ✓ | ✓ | ✅ |
| Comparison operators | ✓ | ✓ | ✓ |
| Nested `begin/end` | ✓ | ✓ | ✓ |

---

## Notable Patterns

### 1. Linked List Construction (string_to_linked_list.pas)
```pascal
new(item);
item^.value := ch;
item^.next := nil;
```

### 2. Recursive Tree Insertion (tree_sort_wirth.pas)
```pascal
if value < t^.key then
  insert_tree(t^.left, value)
else
  insert_tree(t^.right, value);
```

### 3. Recursive Disposal with Child Cleanup (nested_s_expression_list.pas, tree_sort_wirth.pas)
```pascal
dispose_tree(t^.left);
dispose_tree(t^.right);
dispose(t);
t := nil;
```

### 4. S-Expression Parsing (nested_s_expression_list.pas)
```pascal
while (pos <= count) and (input[pos] <> ')') do
if current = '(' then
  parse_list(item^.child)
```

### 5. Var Parameters for List Building (nested_s_expression_list.pas)
```pascal
procedure append_node(var head: node_ptr; var tail: node_ptr; item: node_ptr);
begin
  if head = nil then
    head := item
  else
    tail^.next := item;
  tail := item
end;
```

---

## Summary

All three programs in `examples/lists/` heavily utilize:
- **Pointer-based data structures** (linked lists, trees)
- **Recursive algorithms** (parsing, insertion, traversal, disposal)
- **Manual memory management** (`new`/`dispose`)
- **Record types** with typed pointer fields
- **By-reference parameters** for modifying pointer variables
- **Basic I/O** (`readln`, `write`, `writeln`)

The programs do **not** use: `for` loops, `case` statements, `mod` operator, functions (only procedures), or array bounds beyond simple static char arrays.

---
Report generated at: Thu May  7 10:25:04 UTC 2026
Commit SHA: 34852f9ddbc1c93cfeec2086309f93fed287d986
