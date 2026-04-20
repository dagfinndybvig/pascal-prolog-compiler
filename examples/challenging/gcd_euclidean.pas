{ Greatest Common Divisor - Euclidean Algorithm }
{ Uses modulo via: a - (a/b)*b }
{ Tests: loop logic, subtraction, multiple test cases }

program gcd_euclidean;
var
  a, b, temp, original_a, original_b, gcd: integer;
begin
  { Test 1: Coprime numbers (Fibonacci neighbors - worst case) }
  a := 34;  { F_9 }
  b := 21;  { F_8 }
  original_a := a;
  original_b := b;

  while b <> 0 do
  begin
    temp := b;
    b := a - (a / b) * b;  { a mod b using only / and * }
    a := temp
  end;

  gcd := a;
  writeln(gcd);  { Expected: 1 (coprime) }

  { Test 2: Large common factor }
  a := 1071;
  b := 462;

  while b <> 0 do
  begin
    temp := b;
    b := a - (a / b) * b;
    a := temp
  end;

  gcd := a;
  writeln(gcd)   { Expected: 21 }
end.
