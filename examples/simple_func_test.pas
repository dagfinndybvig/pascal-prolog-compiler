program simple_func_test;

function simple(a: integer): integer;
begin
  simple := a + 1;
end;

begin
  writeln(simple(5));
end.
