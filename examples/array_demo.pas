program array_demo;

var
  values: array[1..5] of integer;
  text: array[1..4] of char;
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

  text[1] := 'M';
  text[2] := 'a';
  text[3] := 't';
  text[4] := 'h';
  writeln(text)
end.
