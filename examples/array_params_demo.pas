program ArrayParamsDemo;

var
  data: array[1..5] of integer;
  greeting: array[1..5] of char;
  i: integer;

procedure fill_squares(var arr: array[1..5] of integer);
var k: integer;
begin
  k := 1;
  while k <= 5 do
  begin
    arr[k] := k * k;
    k := k + 1
  end
end;

function array_sum(var arr: array[1..5] of integer): integer;
var k, total: integer;
begin
  total := 0;
  k := 1;
  while k <= 5 do
  begin
    total := total + arr[k];
    k := k + 1
  end;
  array_sum := total
end;

procedure set_hello(var s: array[1..5] of char);
begin
  s[1] := 'H';
  s[2] := 'e';
  s[3] := 'l';
  s[4] := 'l';
  s[5] := 'o'
end;

begin
  fill_squares(data);

  i := 1;
  while i <= 5 do
  begin
    writeln(data[i]);
    i := i + 1
  end;

  writeln(array_sum(data));

  set_hello(greeting);
  writeln(greeting)
end.
