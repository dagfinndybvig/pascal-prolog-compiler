program pointer_null_guard_demo;

type
  int_alias = integer;
  int_ptr = ^int_alias;

var
  p: int_ptr;

begin
  p := nil;
  writeln(p^);
end.
