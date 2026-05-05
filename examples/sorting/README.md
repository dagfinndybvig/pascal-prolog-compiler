# Sorting Examples

This folder contains linked-list sorting examples for the Pascal-Prolog compiler.

## Program: linked_list_sort_wirth.pas

`linked_list_sort_wirth.pas` demonstrates a classic pointer-based list sort in Pascal style:

- A singly linked list node type (`node`) with fields `key` and `next`
- Dynamic allocation with `new` and cleanup with `dispose`
- In-place list sorting by rebuilding a sorted list through ordered insertion

The program:

1. Builds an unsorted list
2. Prints the unsorted sequence
3. Sorts the list in ascending order
4. Prints the sorted sequence
5. Frees all allocated nodes

Expected shape of output:

- `Unsorted:` followed by the original list order
- `Sorted:` followed by ascending keys

## Algorithm Summary

The sort is insertion sort adapted to linked lists:

1. Start with an empty `sorted` list.
2. Remove one node at a time from the original list.
3. Insert that node into the correct position in `sorted`.
4. Continue until all nodes are moved.

Why this works well for linked lists:

- Insertion in the middle is pointer rewiring, not element shifting.
- The algorithm is simple and uses no extra array storage.
- It is stable when implemented with a `<=`/`<` placement policy.

Complexity:

- Time: `O(n^2)` in the average and worst case
- Extra space: `O(1)` auxiliary (excluding the list nodes themselves)

## Historical Background

Linked lists and insertion-based list processing are central ideas in early structured programming and compiler education.

Niklaus Wirth (designer of Pascal) emphasized programs that are compact, understandable, and close to the underlying data structure. His famous book *Algorithms + Data Structures = Programs* uses sorting as one of its recurring teaching themes because sorting exposes the relationship between representation, invariants, and algorithmic cost especially well.

In Wirth's style, sorting is not just a practical task; it is a laboratory for comparing algorithmic ideas. Simple methods such as insertion sort, selection sort, and exchange-based sorting show how local transformations gradually organize data. More advanced methods such as Shellsort, quicksort, and heapsort show how careful data-structure choices and divide-and-conquer reasoning can dramatically change performance. The examples are deliberately concrete: arrays, records, files, and linked structures make the cost of each operation visible.

That is why a linked-list insertion sort is a natural Wirth-style example for this compiler. The algorithm is small enough to read at once, but it still exercises the essential Pascal machinery: records, typed pointers, explicit allocation, dereference, and disciplined pointer rewiring. Unlike array sorting, no elements are shifted through contiguous memory; nodes are removed from one list and inserted into another by changing `next` fields.

This project’s example is therefore not intended to be the fastest possible sorter. It is intended to show the same lesson Wirth often emphasized: the algorithm and the data representation should be studied together. Once the values live in list nodes instead of array cells, insertion becomes a pointer operation, and the program’s correctness depends on maintaining clear list invariants.

In that tradition, list algorithms are often expressed through explicit pointer movement and clear invariants.

This example follows that style:

- Small procedures with focused responsibilities
- Explicit pointer manipulation (`p^`, `p^.next`)
- Clear lifecycle management (`new`/`dispose`)

For this project, it also serves as a practical end-to-end stress test for:

- Recursive pointer-capable record types
- Dereference and field access code generation
- Runtime allocation and deallocation support
