program set_subset_relations;

type
  SmallSet = set of 0..31;

var
  a, b, c: SmallSet;

begin
  a := [1,2,3];
  b := [1,2,3,4,5];
  c := [2,4,6];

  if a <= b then writeln(1) else writeln(0);
  if b >= a then writeln(1) else writeln(0);
  if c <= b then writeln(1) else writeln(0);

  if [] <= a then writeln(1) else writeln(0);
  if a >= [] then writeln(1) else writeln(0)
end.
