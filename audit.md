# Project Audit Report

Date: 2026-04-17
Project: pascal-prolog-v1.3
Auditor: GitHub Copilot (GPT-5.3-Codex)

## Scope

This audit covered:
- Compiler front-end and backend modules.
- Runtime library.
- Verification script and documented test workflow.
- Targeted negative tests to validate error-path behavior.

Reviewed files:
- `pascal_compiler.pl`
- `src/lexer.pl`
- `src/parser.pl`
- `src/semantics.pl`
- `src/ir.pl`
- `src/codegen_asm_x86_64.pl`
- `runtime/runtime.c`
- `runtime/runtime.h`
- `scripts/verify_math.py`

## Executive Summary

Initial audit findings identified one critical runtime safety bug, one high-severity semantic correctness bug, and one medium-severity backend robustness bug. All three were implemented and verified as fixed in this workspace. A subsequent hardening pass found two additional codegen defects, which were also fixed and added to regression coverage.

Current status: baseline verification and added hardening regressions pass.

## Findings (Ordered by Severity)

### 1) Critical: divide-by-zero guard is incorrect in fallback division path

Severity: Critical  
Type: Runtime safety / crash

#### Description
The fallback assembly emission for integer division checks the wrong register before `idivq`, which can allow a real divide-by-zero to reach the CPU instruction and trigger SIGFPE instead of the intended runtime error handler.

#### Evidence
In `asm_expr(ir_bin('/', Left, Right), Assembly)`, fallback code emits:
- `movq %rax, %r11`
- `cmpq $0, %rcx`
- `je division_by_zero`
- `movq %rcx, %rax`
- `idivq %r11`

Here `%r11` holds the divisor, but the zero-check uses `%rcx`.

Reference:
- `src/codegen_asm_x86_64.pl` around lines 374-377.

#### Reproduction
1. Compile and run:

```bash
cat > /tmp/div_zero_check.pas << 'EOF'
program div_zero_check;
var
  a, b, c: integer;
begin
  a := 5;
  b := 0;
  c := a / b;
  writeln(c)
end.
EOF

swipl -q -s pascal_compiler.pl -- build-asm /tmp/div_zero_check.pas /tmp/div_zero_check
/tmp/div_zero_check
```

2. Observed result:
- `Floating point exception (core dumped)`
- exit code `136`
- no controlled `rt_error` message

#### Impact
- Violates documented runtime safety behavior.
- Turns a handled language/runtime error into process termination.

#### Recommendation
- In fallback division emission, compare the actual divisor register against zero before `idivq`.
- Add regression tests that assert non-zero exit via `rt_error` (not SIGFPE) for division by zero.

---

### 2) High: IR local-variable mangling can collide with user identifiers

Severity: High  
Type: Semantic correctness

#### Description
Local symbols are mangled as `<name>__<counter>`. User identifiers can legally contain underscores and digits, so user variables can collide with compiler-generated names.

#### Evidence
- Mangling format: `format(atom(Mangled), "~w__~d", [Var, CounterIn])`
- Name mapping and lookups are by symbolic name; collisions can redirect reads/writes.

References:
- `src/ir.pl` around line 20.
- `src/codegen_asm_x86_64.pl` variable offset usage around lines 104 and 331.

#### Reproduction
1. Compile and run:

```bash
cat > /tmp/mangle_collision.pas << 'EOF'
program mangle_collision;
var
  x__0, y: integer;
begin
  x__0 := 1;
  begin
    var x: integer;
    x := 2;
    writeln(x__0)
  end
end.
EOF

swipl -q -s pascal_compiler.pl -- build-asm /tmp/mangle_collision.pas /tmp/mangle_collision
/tmp/mangle_collision
```

2. Observed result:
- output: `2`

Expected output is `1` (outer variable), but collision aliases it to inner generated symbol.

#### Impact
- Valid user programs can produce incorrect results.
- Breaks lexical scoping guarantees.

#### Recommendation
- Use an internal naming scheme that cannot be produced by user source (for example, a reserved prefix plus metadata not accepted by lexer, or an opaque unique term rather than string concatenation).
- Add tests for user identifiers that resemble internal names.

---

### 3) Medium: register allocator initialization is inconsistent

Severity: Medium  
Type: Backend robustness

#### Description
The allocator publishes available registers `[rbx, r12, r13, r14, r15]` but only initializes usage facts for `rax` and `rcx`. Allocation then attempts to retract usage facts that may not exist.

#### Evidence
- `init_register_allocator/0` initializes available list with callee-saved registers.
- `allocate_register/1` calls `retract(register_usage(Register, _))` for selected register.
- No initial `register_usage/2` entries for `rbx`, `r12`, `r13`, `r14`, `r15`.

Reference:
- `src/codegen_asm_x86_64.pl` around lines 50-67.

#### Impact
- Causes allocation path failures and increased fallback behavior.
- Increases chance of hitting buggy fallback logic (including finding #1).

#### Recommendation
- Fully initialize `register_usage/2` for every register in the available list.
- Add allocator unit checks for allocate/free lifecycle.

## Validation of Existing Claims

The bundled verification script succeeds for included examples and prime checks.

Command run:

```bash
python3 scripts/verify_math.py
```

Observed outcome:
- Example builds reported as successful.
- Prime sequence/count checks reported matching expected values.
- Comprehensive test reported successful execution.

Note: this suite currently does not include adversarial backend safety/collision tests, which is why the above defects are not detected.

## Risk Assessment

- Immediate release risk: High.
- Why: one crash-class bug and one semantic miscompilation bug are reproducible with small valid programs.

## Recommended Next Actions

1. Fix division fallback zero-check register usage and add a dedicated divide-by-zero regression test.
2. Replace string-based local mangling with collision-proof internal identifiers.
3. Repair allocator initialization consistency and add backend regression tests around allocation/fallback behavior.
4. Extend `scripts/verify_math.py` (or add companion checks) to include negative/safety tests and symbol-collision tests.

## Remediation Patch Plan (Exact Changes)

This section defines concrete code edits for the three findings.

### A) Fix divide-by-zero fallback path in codegen

File:
- `src/codegen_asm_x86_64.pl`

Current fallback sequence checks `%rcx` and divides by `%r11`. This must check the divisor register (`%r11`).

Planned replacement in fallback format string for `asm_expr(ir_bin('/', Left, Right), Assembly)`:

Current intent in generated assembly:
- left in `%rcx`
- right in `%rax`
- divisor copied to `%r11`

Required sequence:
- `movq %rax, %r11`        ; divisor
- `cmpq $0, %r11`          ; check divisor (not `%rcx`)
- `je division_by_zero`
- `movq %rcx, %rax`        ; dividend
- `cqo`
- `idivq %r11`

Concrete edit target:
- Change the emitted `cmpq $0, %rcx` to `cmpq $0, %r11` in the fallback division emitter.

### B) Make local-name mangling collision-proof

File:
- `src/ir.pl`

Current mangling:
- `"~w__~d"`

Problem:
- User identifiers can legally contain this pattern.

Recommended implementation:
1. Introduce a prefix reserved for compiler internals that cannot be produced by source identifiers.
2. The simplest robust option is to stop using user-visible atom concatenation and use opaque internal terms for locals.

Suggested representation change:
- Replace mangled atom with term `local(CounterIn, Var)`.

Required adjustments:
1. In `allocate_locals/5`, replace:
   - `format(atom(Mangled), "~w__~d", [Var, CounterIn])`
   with:
   - `Mangled = local(CounterIn, Var)`
2. Keep `map_name/3` unchanged; it is agnostic to mapped value shape.
3. Verify `src/codegen_asm_x86_64.pl` uses mapped names as opaque keys (`var_offset/2` already supports non-atom keys).

This removes all namespace collision between user identifiers and compiler-generated names.

### C) Fix allocator initialization consistency

File:
- `src/codegen_asm_x86_64.pl`

Current issue:
- `available_registers([rbx, r12, r13, r14, r15])` but missing corresponding `register_usage/2` entries.

Planned edits in `init_register_allocator/0`:
1. Add usage initialization for all allocatable registers:
   - `assert(register_usage(rbx, available))`
   - `assert(register_usage(r12, available))`
   - `assert(register_usage(r13, available))`
   - `assert(register_usage(r14, available))`
   - `assert(register_usage(r15, available))`
2. Keep:
   - `assert(register_usage(rax, used))`
   - `assert(register_usage(rcx, available))`
3. Optionally remove fallback branch in `get_temp_register/1` that returns `rcx` without marking usage; prefer explicit failure to force known-safe fallback logic in callers.

## Regression Test Plan

Add targeted tests that fail before fixes and pass after fixes.

### 1) Division-by-zero safety test

Location:
- Extend `scripts/verify_math.py`

Test input program (temp file generated by script):
- `a := 5; b := 0; c := a / b;`

Assertions:
1. Program exits with non-zero code.
2. `stderr` contains `runtime error 2` or `Division by zero`.
3. Process does not terminate by signal (`returncode` should be positive in Python terms, not negative signal value).

### 2) Mangling-collision semantic test

Location:
- Extend `scripts/verify_math.py`

Test program:
- global `x__0 := 1`
- nested `var x: integer; x := 2; writeln(x__0)`

Assertion:
1. Output must be exactly `1`.

### 3) Allocator sanity checks (compile+execute matrix)

Location options:
- `scripts/verify_math.py` (fast smoke section), or
- new `scripts/verify_backend.py` for backend-only checks.

Programs to include:
1. Deep arithmetic expressions requiring many temporaries.
2. Mixed relational/arithmetic expressions in loop and if conditions.

Assertions:
1. Build succeeds.
2. Runtime output matches expected deterministic values.

### 4) Suggested code shape for script extension

In `scripts/verify_math.py`, add helper:

```python
def build_and_run_source(source_text, name, input_text=None, timeout=120):
  pas_path = BIN_DIR / f"{name}.pas"
  out_bin = BIN_DIR / name
  pas_path.write_text(source_text)
  proc_build = run(
    [
      "swipl",
      "-q",
      "-s",
      "pascal_compiler.pl",
      "--",
      "build-asm",
      str(pas_path.relative_to(ROOT)),
      str(out_bin),
    ]
  )
  if proc_build.returncode != 0:
    return {"build_ok": False, "build_stderr": proc_build.stderr, "run": None}
  proc_run = run([str(out_bin)], input_text=input_text, timeout=timeout)
  return {
    "build_ok": True,
    "run": {
      "returncode": proc_run.returncode,
      "stdout": proc_run.stdout,
      "stderr": proc_run.stderr,
    },
  }
```

Then add two checks in `main()`:
1. `division_by_zero_guard` check using generated source and assertions above.
2. `mangling_collision_scope` check using generated source and exact output assertion.

These checks should be included in final JSON output under `checks` so CI can fail automatically on regressions.

## Implementation Status (Completed)

The remediation plan above has been implemented in this workspace.

### Code changes applied

1. `src/codegen_asm_x86_64.pl`
- Fixed divide fallback zero-check to validate divisor register (`%r11`) before `idivq`.
- Initialized allocator usage state for all allocatable registers (`rcx`, `rbx`, `r12`, `r13`, `r14`, `r15`).
- Updated register-emission format strings to emit real register operands (for example `%rcx` instead of `rcx`) in temp-register code paths.

2. `src/ir.pl`
- Replaced string-concatenated local mangling with opaque internal term representation:
  - from: `"<name>__<counter>"`
  - to: `local(Counter, Name)`

3. `scripts/verify_math.py`
- Added helper `build_and_run_source(...)` for generated regression programs.
- Added new checks under `checks`:
  - `division_by_zero_guard`
  - `mangling_collision_scope`

### Post-fix verification results

1. Division-by-zero reproducer now behaves correctly:
- exit code: `2`
- stderr: `runtime error 2: Division by zero error`
- no SIGFPE crash

2. Name-collision reproducer now behaves correctly:
- output: `1`

3. Full verification script succeeds and includes new passing checks:
- `division_by_zero_guard.pass == true`
- `mangling_collision_scope.pass == true`
- all example builds still successful

### Residual notes

- The new regression checks are integrated into JSON output, but no external CI pipeline wiring is included in this repository state.
- If CI is added later, failing on `checks[*].pass == false` is recommended.

## Additional Hardening Pass (Completed)

A second hardening pass was executed with deeper backend stress tests. This pass both expanded test coverage and uncovered two additional codegen defects, which were fixed.

### Additional regressions added

In `scripts/verify_math.py`, the following checks were added:

1. `expression_stress`
- Verifies deep arithmetic composition, unary behavior, and relational result correctness.

2. `division_sign_semantics`
- Verifies integer division truncation toward zero for negative operands.

3. `nested_control_flow_scope`
- Verifies loop+branch interaction and block shadowing behavior in one program.

### Additional defects found and fixed

1. Nested-expression temp register clobbering in codegen
- Symptom: incorrect arithmetic results on deep expressions.
- Root cause: temp register reserved after generating right-side code, allowing reuse/clobber in nested emission.
- Fix: reserve temp register before generating right-side expression code.

2. Reversed operand order in compare path when using allocated temp registers
- Symptom: incorrect relational outcomes (for example, loop conditions evaluating backwards).
- Root cause: `cmp` operand order in one path implemented `right ? left` semantics.
- Fix: emit compare as `cmpq %rax, %<left_temp>` before `set*`.

### Post-hardening results

After fixes, all baseline and hardening checks pass:

- `division_by_zero_guard`: pass
- `mangling_collision_scope`: pass
- `expression_stress`: pass
- `division_sign_semantics`: pass
- `nested_control_flow_scope`: pass
- all example builds: successful

## Appendix: Commands Used During Audit

```bash
python3 scripts/verify_math.py | head -n 120

swipl -q -s pascal_compiler.pl -- build-asm /tmp/div_zero_check.pas /tmp/div_zero_check
/tmp/div_zero_check

swipl -q -s pascal_compiler.pl -- build-asm /tmp/mangle_collision.pas /tmp/mangle_collision
/tmp/mangle_collision
```
