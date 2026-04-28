#!/usr/bin/env python3
import json
import math
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BIN_DIR = ROOT / ".verify_bin"


def run(cmd, *, input_text=None, timeout=240):
    return subprocess.run(
        cmd,
        cwd=ROOT,
        text=True,
        input=input_text,
        capture_output=True,
        timeout=timeout,
    )


def primes_upto(n):
    if n < 2:
        return []
    sieve = [True] * (n + 1)
    sieve[0] = False
    sieve[1] = False
    for i in range(2, int(n ** 0.5) + 1):
        if sieve[i]:
            for j in range(i * i, n + 1, i):
                sieve[j] = False
    return [i for i, is_p in enumerate(sieve) if is_p]


def parse_ints(text):
    return [int(x) for x in re.findall(r"\b\d+\b", text)]


def verify_prime_sequence(output, limit, stop_marker=None):
    segment = output.split(stop_marker)[0] if stop_marker else output
    values = [n for n in parse_ints(segment) if n <= limit]
    if 2 in values:
        values = values[values.index(2) :]
    expected = primes_upto(limit)
    return {
        "count": len(values),
        "matches": values == expected,
        "first10": values[:10],
        "last5": values[-5:],
    }


def verify_prime_sequence_allow_duplicate_banner_two(output, limit):
    values = [n for n in parse_ints(output) if n <= limit]
    if len(values) >= 2 and values[0] == 2 and values[1] == 2:
        values = values[1:]
    if 2 in values:
        values = values[values.index(2) :]
    expected = primes_upto(limit)
    return {
        "count": len(values),
        "matches": values == expected,
        "first10": values[:10],
        "last5": values[-5:],
    }


def build_example(pas_path):
    out_bin = BIN_DIR / pas_path.stem
    proc = run(
        [
            "swipl",
            "-q",
            "-s",
            "pascal_compiler.pl",
            "--",
            "build-asm",
            str(pas_path),
            str(out_bin),
        ]
    )
    return proc.returncode == 0, out_bin, proc.stderr.strip()


def build_and_run_source(source_text, name, *, input_text=None, timeout=120):
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
        return {
            "build_ok": False,
            "build_returncode": proc_build.returncode,
            "build_stderr": proc_build.stderr.strip(),
            "run": None,
        }

    proc_run = run([str(out_bin)], input_text=input_text, timeout=timeout)
    return {
        "build_ok": True,
        "build_returncode": proc_build.returncode,
        "build_stderr": proc_build.stderr.strip(),
        "run": {
            "returncode": proc_run.returncode,
            "stdout": proc_run.stdout,
            "stderr": proc_run.stderr,
        },
    }


def check_expected_stdout_lines(result, expected_lines):
    if not result["build_ok"]:
        return {
            "build_ok": False,
            "build_returncode": result["build_returncode"],
            "build_stderr": result["build_stderr"],
            "pass": False,
        }

    run_result = result["run"]
    stdout_lines = [line.strip() for line in run_result["stdout"].splitlines() if line.strip()]
    return {
        "build_ok": True,
        "returncode": run_result["returncode"],
        "stdout_lines": stdout_lines,
        "expected_stdout_lines": expected_lines,
        "pass": run_result["returncode"] == 0 and stdout_lines == expected_lines,
    }


def main():
    BIN_DIR.mkdir(exist_ok=True)
    examples = sorted((ROOT / "examples").rglob("*.pas"))
    build_results = {}
    for pas in examples:
        ok, out_bin, stderr = build_example(pas.relative_to(ROOT))
        build_results[str(pas.relative_to(ROOT))] = {
            "ok": ok,
            "binary": str(out_bin),
            "stderr": stderr,
        }

    checks = {}
    small_prime_programs = [
        "primes_less_than_200_simple",
        "primes_no_division",
        "primes_mult_sub",
        "primes_sqrt_optimized",
        "primes_sqrt_no_div",
    ]
    for name in small_prime_programs:
        proc = run([str(BIN_DIR / name)])
        checks[name] = verify_prime_sequence(proc.stdout, 199)
        checks[name]["returncode"] = proc.returncode

    less200_v2 = run([str(BIN_DIR / "primes_less_than_200")])
    checks["primes_less_than_200"] = verify_prime_sequence_allow_duplicate_banner_two(
        less200_v2.stdout, 199
    )
    checks["primes_less_than_200"]["returncode"] = less200_v2.returncode

    for name in ["primes_simple_slow", "primes_simple_fast"]:
        proc = run([str(BIN_DIR / name)], timeout=300)
        m = re.search(r"Number of primes:\s*(\d+)", proc.stdout)
        checks[name] = {
            "returncode": proc.returncode,
            "reported_count": int(m.group(1)) if m else None,
            "expected_count": len(primes_upto(46000)),
        }

    summary_proc = run([str(BIN_DIR / "primes_with_summary")], timeout=300)
    checks["primes_with_summary"] = verify_prime_sequence(
        summary_proc.stdout, 46000, "Found these primes between"
    )
    checks["primes_with_summary"]["returncode"] = summary_proc.returncode

    comp_proc = run([str(BIN_DIR / "comprehensive_test")], input_text="7\n")
    checks["comprehensive_test"] = {
        "returncode": comp_proc.returncode,
        "tail": comp_proc.stdout.splitlines()[-4:],
    }

    div_zero_source = """program div_zero_check;
var
  a, b, c: integer;
begin
  a := 5;
  b := 0;
  c := a / b;
  writeln(c)
end.
"""
    div_zero_result = build_and_run_source(div_zero_source, "regression_div_zero")
    if div_zero_result["build_ok"]:
        div_zero_run = div_zero_result["run"]
        stderr = div_zero_run["stderr"]
        rc = div_zero_run["returncode"]
        checks["division_by_zero_guard"] = {
            "build_ok": True,
            "returncode": rc,
            "stderr": stderr,
            "expected_non_signal_exit": rc > 0,
            "expected_runtime_message": (
                "runtime error 2" in stderr
                or "Division by zero" in stderr
                or "division by zero" in stderr
            ),
            "pass": rc > 0
            and (
                "runtime error 2" in stderr
                or "Division by zero" in stderr
                or "division by zero" in stderr
            ),
        }
    else:
        checks["division_by_zero_guard"] = {
            "build_ok": False,
            "build_returncode": div_zero_result["build_returncode"],
            "build_stderr": div_zero_result["build_stderr"],
            "pass": False,
        }

    mangle_collision_source = """program mangle_collision;
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
"""
    mangle_result = build_and_run_source(mangle_collision_source, "regression_mangle_collision")
    checks["mangling_collision_scope"] = check_expected_stdout_lines(mangle_result, ["1"])

    expression_stress_source = """program expression_stress;
var
  a, b, c, d, e, r: integer;
begin
  a := 7;
  b := 3;
  c := 2;
  d := 5;
  e := 11;
  r := (((a + b) * (c + d)) - (e * (a - c))) / b;
  writeln(r);
  r := -(-(-a));
  writeln(r);
  r := (a * b) + (c * d) + (e / c);
  writeln(r);
  if (a + b) > (e - c) then
    writeln(1)
  else
    writeln(0)
end.
"""
    expr_stress_result = build_and_run_source(
        expression_stress_source,
        "regression_expression_stress",
    )
    checks["expression_stress"] = check_expected_stdout_lines(
        expr_stress_result,
        ["5", "-7", "36", "1"],
    )

    division_sign_source = """program division_signs;
var
  a, b: integer;
begin
  a := -7;
  b := 2;
  writeln(a / b);
  a := 7;
  b := -2;
  writeln(a / b);
  a := -7;
  b := -2;
  writeln(a / b)
end.
"""
    division_sign_result = build_and_run_source(
        division_sign_source,
        "regression_division_signs",
    )
    checks["division_sign_semantics"] = check_expected_stdout_lines(
        division_sign_result,
        ["-3", "-3", "3"],
    )

    nested_control_source = """program nested_control_flow;
var
  i, sum: integer;
begin
  i := 1;
  sum := 0;
  while i <= 10 do
  begin
    if i < 5 then
      sum := sum + i
    else
      sum := sum + (i * 2);
    i := i + 1
  end;
  writeln(sum);

  begin
    var sum: integer;
    sum := 999;
    writeln(sum)
  end;

  writeln(sum)
end.
"""
    nested_control_result = build_and_run_source(
        nested_control_source,
        "regression_nested_control",
    )
    checks["nested_control_flow_scope"] = check_expected_stdout_lines(
        nested_control_result,
        ["100", "999", "100"],
    )

    semantic_regressions = {
        "duplicate_function_rejected": (
            """program duplicate_function_check;
function foo(x: integer): integer;
begin
  foo := x
end;
function foo(y: integer): integer;
begin
  foo := y + 1
end;
begin
  writeln(foo(1))
end.
""",
            "duplicate function",
        ),
        "too_many_parameters_rejected": (
            """program too_many_parameters_check;
function many(a,b,c,d,e,h,g: integer): integer;
begin
  many := a
end;
begin
  writeln(1)
end.
""",
            "too many parameters",
        ),
        "param_local_duplicate_rejected": (
            """program param_local_duplicate_check;
function foo(x: integer): integer;
var
  x: integer;
begin
  foo := x
end;
begin
  writeln(foo(1))
end.
""",
            "duplicate declaration",
        ),
        "boolean_operator_type_rejected": (
            """program boolean_operator_type_check;
var
  b: boolean;
begin
  b := 1 and 2
end.
""",
            "type mismatch",
        ),
    }

    for name, (source, expected_message) in semantic_regressions.items():
        pas_path = BIN_DIR / f"{name}.pas"
        pas_path.write_text(source)
        proc = run(
            [
                "swipl",
                "-q",
                "-s",
                "pascal_compiler.pl",
                "--",
                "check",
                str(pas_path.relative_to(ROOT)),
            ]
        )
        combined_output = proc.stdout + proc.stderr
        checks[name] = {
            "returncode": proc.returncode,
            "expected_failure": proc.returncode != 0,
            "expected_message": expected_message in combined_output,
            "pass": proc.returncode != 0 and expected_message in combined_output,
        }

    global_access_source = """program function_global_access_check;
function addg(x: integer): integer;
begin
  addg := x + g
end;
function inc(): integer;
begin
  g := g + 1;
  inc := g
end;
var
  g: integer;
begin
  g := 5;
  writeln(addg(2));
  writeln(inc());
  writeln(g)
end.
"""
    global_access_result = build_and_run_source(
        global_access_source,
        "regression_function_global_access",
    )
    checks["function_global_access"] = check_expected_stdout_lines(
        global_access_result,
        ["7", "6", "6"],
    )

    var_before_function_source = """program var_before_function_check;
var
  g: integer;
function addg(x: integer): integer;
begin
  g := g + x;
  addg := g
end;
begin
  g := 10;
  writeln(addg(5));
  writeln(g)
end.
"""
    var_before_function_result = build_and_run_source(
        var_before_function_source,
        "regression_var_before_function",
    )
    checks["var_before_function_order"] = check_expected_stdout_lines(
        var_before_function_result,
        ["15", "15"],
    )

    global_shadow_source = """program function_global_shadow;
function f(g: integer): integer;
begin
  f := g + 1
end;
var
  g: integer;
begin
  g := 10;
  writeln(f(3));
  writeln(g)
end.
"""
    global_shadow_result = build_and_run_source(
        global_shadow_source,
        "regression_function_global_shadow",
    )
    checks["function_global_shadowing"] = check_expected_stdout_lines(
        global_shadow_result,
        ["4", "10"],
    )

    bool_char_source = """program bool_char_check;
function choose(flag: boolean): char;
begin
  if flag then
    choose := 'Y'
  else
    choose := 'N'
end;
var
  flag: boolean;
  c: char;
begin
  flag := 4 < 9;
  c := choose(flag);
  writeln(c);
  flag := c = 'Y';
  if flag then
    writeln(c)
  else
    writeln('N')
end.
"""
    bool_char_result = build_and_run_source(
        bool_char_source,
        "regression_bool_char",
    )
    checks["boolean_char_scalars"] = check_expected_stdout_lines(
        bool_char_result,
        ["Y", "Y"],
    )

    boolean_ops_source = """program boolean_operator_check;
function both_positive(a, b: integer): boolean;
begin
  both_positive := (a > 0) and (b > 0)
end;
function to_int(value: boolean): integer;
begin
  if value then
    to_int := 1
  else
    to_int := 0
end;
var
  t, f: boolean;
begin
  t := true;
  f := false;
  writeln(to_int(t and f));
  writeln(to_int(t or f));
  writeln(to_int(not t));
  writeln(to_int(not f));
  writeln(to_int(both_positive(3, 4)));
  writeln(to_int(both_positive(3, -4)));
  writeln(to_int((1 < 2) and not (2 < 1)));
  writeln(to_int((1 > 2) or (2 > 1)))
end.
"""
    boolean_ops_result = build_and_run_source(
        boolean_ops_source,
        "regression_boolean_operators",
    )
    checks["boolean_operators"] = check_expected_stdout_lines(
        boolean_ops_result,
        ["0", "1", "0", "1", "1", "0", "1", "1"],
    )

    type_mismatch_source = """program type_mismatch_check;
var
  i: integer;
  b: boolean;
begin
  b := true;
  i := b
end.
"""
    type_mismatch_path = BIN_DIR / "type_mismatch_check.pas"
    type_mismatch_path.write_text(type_mismatch_source)
    type_mismatch_proc = run(
        [
            "swipl",
            "-q",
            "-s",
            "pascal_compiler.pl",
            "--",
            "check",
            str(type_mismatch_path.relative_to(ROOT)),
        ]
    )
    type_mismatch_output = type_mismatch_proc.stdout + type_mismatch_proc.stderr
    checks["type_mismatch_rejected"] = {
        "returncode": type_mismatch_proc.returncode,
        "expected_failure": type_mismatch_proc.returncode != 0,
        "expected_message": "type mismatch" in type_mismatch_output,
        "pass": type_mismatch_proc.returncode != 0
        and "type mismatch" in type_mismatch_output,
    }

    array_source = """program array_check;
var
  a: array[1..4] of integer;
  text: array[1..3] of char;
  i: integer;
  sum: integer;
begin
  a[1] := 4;
  a[2] := 6;
  a[3] := 8;
  a[4] := 10;
  i := 1;
  sum := 0;
  while i <= 4 do
  begin
    sum := sum + a[i];
    i := i + 1
  end;
  writeln(sum);
  text[1] := 'O';
  text[2] := 'K';
  text[3] := '?';
  writeln(text)
end.
"""
    array_result = build_and_run_source(
        array_source,
        "regression_static_arrays",
    )
    checks["static_arrays_and_char_buffers"] = check_expected_stdout_lines(
        array_result,
        ["28", "OK?"],
    )

    bounds_source = """program array_bounds_check;
var
  a: array[1..2] of integer;
begin
  a[0] := 1
end.
"""
    bounds_result = build_and_run_source(bounds_source, "regression_array_bounds")
    if bounds_result["build_ok"]:
        bounds_run = bounds_result["run"]
        checks["array_bounds_check"] = {
            "build_ok": True,
            "returncode": bounds_run["returncode"],
            "stderr": bounds_run["stderr"],
            "pass": bounds_run["returncode"] == 3
            and "Array index out of bounds" in bounds_run["stderr"],
        }
    else:
        checks["array_bounds_check"] = {
            "build_ok": False,
            "build_returncode": bounds_result["build_returncode"],
            "build_stderr": bounds_result["build_stderr"],
            "pass": False,
        }

    procedures_source = """program procedure_check;
var
  total: integer;
procedure add(x: integer);
begin
  total := total + x
end;
procedure reset;
begin
  total := 0
end;
begin
  reset;
  add(3);
  add(4);
  writeln(total);
  reset();
  add(10);
  writeln(total)
end.
"""
    procedures_result = build_and_run_source(
        procedures_source,
        "regression_procedures",
    )
    checks["procedures"] = check_expected_stdout_lines(
        procedures_result,
        ["7", "10"],
    )

    procedure_as_expr_source = """program proc_as_expr_check;
procedure noop;
begin
  noop := 0
end;
begin
end.
"""
    proc_as_expr_path = BIN_DIR / "proc_as_expr_check.pas"
    proc_as_expr_path.write_text(procedure_as_expr_source)
    proc_as_expr_proc = run(
        [
            "swipl",
            "-q",
            "-s",
            "pascal_compiler.pl",
            "--",
            "check",
            str(proc_as_expr_path.relative_to(ROOT)),
        ]
    )
    checks["procedure_assign_to_name_rejected"] = {
        "returncode": proc_as_expr_proc.returncode,
        "pass": proc_as_expr_proc.returncode != 0,
    }

    var_params_source = """program var_params_check;
var
  a, b: integer;
procedure swap(var x, y: integer);
var t: integer;
begin t := x; x := y; y := t end;
begin
  a := 3;
  b := 9;
  swap(a, b);
  writeln(a);
  writeln(b)
end.
"""
    var_params_result = build_and_run_source(var_params_source, "regression_var_params")
    checks["var_params_swap"] = check_expected_stdout_lines(
        var_params_result, ["9", "3"]
    )

    var_param_literal_source = """program var_param_literal_check;
procedure inc(var v: integer);
begin v := v + 1 end;
begin
  inc(42)
end.
"""
    var_param_literal_path = BIN_DIR / "var_param_literal_check.pas"
    var_param_literal_path.write_text(var_param_literal_source)
    var_param_literal_proc = run(
        [
            "swipl",
            "-q",
            "-s",
            "pascal_compiler.pl",
            "--",
            "check",
            str(var_param_literal_path.relative_to(ROOT)),
        ]
    )
    checks["var_param_literal_rejected"] = {
        "returncode": var_param_literal_proc.returncode,
        "pass": var_param_literal_proc.returncode != 0,
    }

    array_params_source = """program array_params_check;
var
  a: array[1..3] of integer;

procedure fill(var arr: array[1..3] of integer);
begin
  arr[1] := 10;
  arr[2] := 20;
  arr[3] := 30
end;

function total(var arr: array[1..3] of integer): integer;
begin
  total := arr[1] + arr[2] + arr[3]
end;

begin
  fill(a);
  writeln(a[1]);
  writeln(a[2]);
  writeln(a[3]);
  writeln(total(a))
end.
"""
    array_params_result = build_and_run_source(array_params_source, "regression_array_params")
    checks["array_params"] = check_expected_stdout_lines(
        array_params_result, ["10", "20", "30", "60"]
    )

    result = {
        "build_results": build_results,
        "checks": checks,
    }
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
