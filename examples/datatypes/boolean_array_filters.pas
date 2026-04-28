program boolean_array_filters;

function is_even(n: integer): boolean;
begin
  is_even := (n mod 2) = 0
end;

function is_large(n: integer): boolean;
begin
  is_large := n > 5
end;

function to_int(value: boolean): integer;
begin
  if value then
    to_int := 1
  else
    to_int := 0
end;

var
  values: array[1..6] of integer;
  accepted: array[1..6] of boolean;
  i, count: integer;

begin
  values[1] := 1;
  values[2] := 2;
  values[3] := 6;
  values[4] := 7;
  values[5] := 8;
  values[6] := 9;

  i := 1;
  count := 0;
  while i <= 6 do
  begin
    accepted[i] := is_even(values[i]) and is_large(values[i]);
    if accepted[i] then
      count := count + 1
    else
      count := count;
    write('accepted flag = ', to_int(accepted[i])); writeln('');
    i := i + 1
  end;

  write('accepted count = ', count); writeln('')
end.
