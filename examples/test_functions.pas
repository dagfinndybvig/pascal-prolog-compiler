program test_functions;

function add(a, b: integer): integer;
begin
  add := a + b
end;

function multiply(x, y: integer): integer;
begin
  multiply := x * y
end;

var result: integer;
begin
  result := add(3, 4);
  writeln(result);
  result := multiply(5, 6);
  writeln(result);
  result := add(multiply(2, 3), 10);
  writeln(result)
end.
