{ Factorial - Shows overflow behavior }
{ Demonstrates 32-bit signed integer overflow }
{ 12! = 479001600 (last correct value) }
{ 13! overflows to 1932053504 }

program factorial_overflow;
var
  n, fact: integer;
begin
  n := 1;
  fact := 1;

  while n <= 15 do
  begin
    fact := fact * n;
    writeln(fact);
    n := n + 1
  end
end.
