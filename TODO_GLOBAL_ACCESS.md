# Global Variable Access from Functions

**Status**: Implemented
**Priority**: Completed
**Risk**: Covered by regression tests

## Overview

Functions can access and modify global variables, matching standard Pascal behavior. Function parameters and local variables take precedence over globals with the same name, so shadowing remains predictable.

## Current Behavior

- Functions can read global variables.
- Functions can assign to global variables.
- Function parameters and local variables shadow globals.
- Global variables are still allocated in the generated `main` stack frame.
- Generated `main` records its frame pointer in `main_frame_ptr`; generated functions use that pointer when accessing true globals.

## Implementation Summary

### Semantic Analysis

`src/semantics.pl` includes globals in function scope after the function return slot, parameters, and locals. This preserves shadowing while allowing references to globals.

### IR Generation

`src/ir.pl` already appended `GlobalEnv` after function-local mappings, so function-local names resolve first and globals keep their original names.

### Code Generation

`src/codegen_asm_x86_64.pl` emits `main_frame_ptr` in the data section and stores `%rbp` there during `main` setup. Function expression and assignment code detects true global variables and loads/stores them through `main_frame_ptr`; parameters, locals, and return slots continue to use the function frame.

## Regression Coverage

`scripts/verify_math.py` includes:

- `function_global_access`: verifies function reads and writes of a global variable.
- `function_global_shadowing`: verifies a parameter shadows a global with the same name.

The full verification suite passes with global access enabled.
