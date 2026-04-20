{ Integer Square Root - Newton's Method }
{ Finds the largest integer x such that x*x <= n }
{ Tests: division, comparison, loop convergence }

program isqrt_newton;
var
  n, x, y, check: integer;
begin
  { Test 1: Perfect square }
  n := 16;
  x := n;
  y := 1;

  while x > y do
  begin
    x := (x + y) / 2;
    y := n / x
  end;

  writeln(x);       { Expected: 4 }
  check := x * x;
  writeln(check);   { Expected: 16 }

  { Test 2: Non-perfect square }
  n := 20;
  x := n;
  y := 1;

  while x > y do
  begin
    x := (x + y) / 2;
    y := n / x
  end;

  writeln(x);       { Expected: 4 (floor of sqrt(20)) }
  check := x * x;
  writeln(check);   { Expected: 16 }

  { Test 3: Verify (x+1)^2 > n }
  check := (x + 1) * (x + 1);
  writeln(check)    { Expected: 25 }
end.
