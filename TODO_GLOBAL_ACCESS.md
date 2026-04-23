# Feature Plan: Global Variable Access from Functions

**Status**: Planned / Not Started  
**Priority**: Medium  
**Difficulty**: Medium  
**Risk**: Low-Medium

---

## Overview

Enable functions to access and modify global variables, which is standard Pascal behavior but currently unsupported in this compiler.

## Current State

- Functions can ONLY access: parameters and local variables
- Global variables are invisible to functions
- This is a semantic restriction, not a parser limitation

## Why Add This?

1. **Pascal compatibility**: Standard Pascal allows global access
2. **Programming flexibility**: Some algorithms benefit from shared state
3. **Educational value**: Demonstrates scope resolution across translation units

---

## Implementation Plan

### Phase 1: Semantic Analysis (Semantics)

**File**: `src/semantics.pl`

**Change**: Include global variables in function scope checking

```prolog
% Line ~35, in check_all_func_bodies/4
% Before:
append([Name|Params], LocalVars, FuncScope),

% After:
append(GlobalVars, [Name|Params], FuncScope0),
append(FuncScope0, LocalVars, FuncScope),
```

**Test**: 
- Compiler should accept programs where functions reference globals
- Should still catch name collisions (local shadows global)

**Risk**: Low - only affects compile-time checking

---

### Phase 2: IR Generation (Intermediate Representation)

**File**: `src/ir.pl`

**Change**: Pass global environment to function lowering

```prolog
% Line ~16-26, in lower_funcs/3
% Before:
append(ParamEnv, [Name-Name], FuncEnv0),
vars_env(LocalEnv),
append(FuncEnv0, LocalEnv, FuncEnv1),
append(FuncEnv1, GlobalEnv, FuncEnv),  % ← GlobalEnv added at end

% After:
append(GlobalEnv, ParamEnv, FuncEnv0),  % ← Globals first (priority?)
append(FuncEnv0, [Name-Name], FuncEnv1),
append(FuncEnv1, LocalEnv, FuncEnv),
```

**Note**: Decide on shadowing rules - locals should shadow globals

**Test**:
- IR should correctly map global variable names
- Local variables should shadow globals with same name

**Risk**: Low - IR is just name mapping

---

### Phase 3: Code Generation (Assembly)

**File**: `src/codegen_asm_x86_64.pl`

**Change**: Distinguish global vs local variable access

This is the **most complex** part. Globals and locals live in different memory regions:

- **Globals**: Data section (`.data`), positive offsets or named labels
- **Locals/Params**: Stack frame, negative offsets from `%rbp`

**Approach A**: Separate offset tracking
```prolog
% Track global offsets separately
:- dynamic global_var_offset/2.

func_var_offset(Name, FuncName, Params, Locals, Offset) :-
    (   global_var_offset(Name, Offset)  % ← Global variable
    ->  true
    ;   % Fall through to local/param logic
    ).
```

**Approach B**: Unified addressing (simpler but wasteful)
- Allocate globals in stack frame too (wasteful but easier)

**Implementation Steps**:
1. Add `global_var_offset/2` dynamic predicate
2. Initialize global offsets in `init_var_offsets/1`
3. Modify `func_var_offset/5` to check globals first
4. Update `asm_expr_func/5` for `ir_var` case

**Test**:
- Functions read/write globals correctly
- No clobbering between global and local storage
- Multiple functions accessing same global

**Risk**: Medium - incorrect offsets cause crashes or wrong values

---

### Phase 4: Testing

**Test Cases**:

1. **Basic read**: Function reads global variable
2. **Basic write**: Function modifies global variable
3. **Shadowing**: Local variable shadows global with same name
4. **Multiple globals**: Function accesses multiple globals
5. **Recursion with globals**: Recursive function with global counter
6. **Collision detection**: Error when local has same name as global

**Example Test Program**:
```pascal
program global_access_test;

var
  counter: integer;

function increment: integer;
begin
  counter := counter + 1;
  increment := counter
end;

begin
  counter := 0;
  writeln(increment);  { Should print 1 }
  writeln(increment);  { Should print 2 }
  writeln(increment)   { Should print 3 }
end.
```

---

## Risks & Mitigations

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Name collision bugs | Low | Existing `ensure_no_duplicates/1` should catch most |
| Wrong memory offsets | Medium | Thorough testing with debugger; use GDB to inspect memory |
| Breaking existing code | Low | No existing code uses this feature |
| Stack/data section confusion | Medium | Clear separation in codegen; comments |

---

## Success Criteria

- [ ] Compiler accepts functions that reference global variables
- [ ] Generated executable correctly reads/writes globals from functions
- [ ] Local variables shadow globals with same name
- [ ] All existing tests still pass
- [ ] At least 3 new test cases covering different scenarios

---

## Notes

- **Grammar order**: Currently `functions → globals` in parser. This is non-standard Pascal but doesn't affect functionality. Could be changed to standard order if desired.
- **Performance**: Minimal impact - just additional offset lookups
- **ABI compliance**: No issues - globals are standard data section access

---

## Related Issues

- None currently
- Future consideration: Pass-by-reference parameters could also access globals indirectly

---

*Created: 2026-04-23*  
*Last Updated: 2026-04-23*
