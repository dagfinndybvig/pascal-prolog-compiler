program set_ranges_and_empty;

type
  MidSet = set of 10..20;

var
  s, t: MidSet;

begin
  s := [];
  if 12 in s then writeln(1) else writeln(0);

  s := [10..13, 18..20];
  if 11 in s then writeln(1) else writeln(0);
  if 17 in s then writeln(1) else writeln(0);

  t := [12, 14, 16, 18];
  s := s + t;
  if 14 in s then writeln(1) else writeln(0);
  if 15 in s then writeln(1) else writeln(0)
end.
