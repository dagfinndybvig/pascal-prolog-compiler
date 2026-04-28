# Datatype Examples

These programs showcase the datatype features added in v1.5.0:

- `scalars_showcase.pas`: `boolean` and `char` variables, scalar functions, and boolean conditions.
- `boolean_edge_cases.pas`: boolean `and`, `or`, and `not` operators in expressions and functions.
- `boolean_truth_table.pas`: truth-table style output for `and`, `or`, and `not`.
- `boolean_array_filters.pas`: boolean arrays populated from combined integer predicates.
- `boolean_precedence_demo.pas`: precedence and parentheses with boolean operators.
- `array_math_showcase.pas`: static integer arrays, indexed access, loops, and boolean function results.
- `char_buffer_showcase.pas`: fixed-size `array of char` text output and function writes to a global char buffer.
- `global_array_function_showcase.pas`: function writes to a global integer array and the main program reads it back.

Build any example with:

```bash
swipl -q -s pascal_compiler.pl -- build-asm examples/datatypes/scalars_showcase.pas scalars_showcase
./scalars_showcase
```
