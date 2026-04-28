program array_math_showcase;

function is_even(n: integer): boolean;
begin
  is_even := (n mod 2) = 0
end;

var
  values: array[1..5] of integer;
  i: integer;
  sum: integer;

begin
  values[1] := 2;
  values[2] := 3;
  values[3] := 5;
  values[4] := 7;
  values[5] := 11;

  i := 1;
  sum := 0;
  while i <= 5 do
  begin
    sum := sum + values[i];
    i := i + 1
  end;

  writeln(sum);
  if is_even(sum) then
    writeln('E')
  else
    writeln('O')
end.
