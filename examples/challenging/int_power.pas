{ Integer Power - Exponentiation by Squaring }
{ Tests: nested loops, accumulating multiplication }

program int_power;
var
  base, exp, result, i: integer;
begin
  { Calculate 2^10 = 1024 }
  base := 2;
  exp := 10;
  result := 1;
  i := 0;

  while i < exp do
  begin
    result := result * base;
    i := i + 1
  end;

  writeln(result);  { Expected: 1024 }

  { Verify by repeated division }
  i := 0;
  while result > 1 do
  begin
    result := result / 2;
    i := i + 1
  end;

  writeln(i)  { Expected: 10 }
end.
