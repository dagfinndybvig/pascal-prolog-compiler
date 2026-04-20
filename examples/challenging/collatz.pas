{ Collatz Sequence (3n+1 problem) }
{ Tests: complex conditional logic, odd/even detection }
{ Note: Uses n - (n/2)*2 to test for evenness }

program collatz;
var
  n, steps, max_val: integer;
begin
  n := 27;  { Known long sequence }
  steps := 0;
  max_val := n;

  while n <> 1 do
  begin
    { Check if n is even: n mod 2 = 0 }
    if (n - (n / 2) * 2) = 0 then
      n := n / 2
    else
      n := n * 3 + 1;

    steps := steps + 1;

    if n > max_val then
      max_val := n
  end;

  writeln(steps);     { Expected: 111 for starting value 27 }
  writeln(max_val)    { Expected: 9232 (peak value) }
end.
