program set_basic_ops;

type
  SmallSet = set of 0..31;

var
  a, b, c: SmallSet;
  x: integer;

begin
  a := [1,3,5,7,9];
  b := [3,4,5,6];

  c := a + b;
  if 6 in c then writeln(1) else writeln(0);

  c := a * b;
  if 3 in c then writeln(1) else writeln(0);
  if 4 in c then writeln(1) else writeln(0);

  c := a - b;
  if 7 in c then writeln(1) else writeln(0);
  if 5 in c then writeln(1) else writeln(0);

  x := 9;
  if x in c then writeln(1) else writeln(0)
end.
