program set_equality;

type
  SmallSet = set of 0..31;

var
  a, b, c: SmallSet;

begin
  a := [1..5];
  b := [1,2,3,4,5];
  c := [2,4,6,8];

  if a = b then writeln(1) else writeln(0);
  if a <> c then writeln(1) else writeln(0);

  c := (c - [6,8]) + [1,3,5];
  if c = [1,2,3,4,5] then writeln(1) else writeln(0)
end.
