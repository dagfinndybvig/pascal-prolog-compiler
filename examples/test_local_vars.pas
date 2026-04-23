program test_local_vars;

function test_func(a: integer): integer;
var
  local_x: integer;
begin
  local_x := a * 2;
  test_func := local_x + 1;
end;

begin
  writeln(test_func(5));
end.
