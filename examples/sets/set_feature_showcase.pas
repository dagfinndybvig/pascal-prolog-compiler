program set_feature_showcase;

type
  SmallSet = set of 0..31;

var
  a, b, c, d, e: SmallSet;
  x: integer;

begin
  writeln('Set Feature Showcase');
  writeln('--------------------');

  writeln('1) Literals, ranges, and empty set');
  a := [];
  b := [1..5, 8, 10..12];
  if 4 in b then writeln('PASS: 4 is in b') else writeln('FAIL: 4 should be in b');
  if 7 in b then writeln('FAIL: 7 should not be in b') else writeln('PASS: 7 is not in b');
  if 1 in a then writeln('FAIL: empty set should contain nothing') else writeln('PASS: empty set contains nothing');

  writeln('2) Union, intersection, and difference');
  a := [1,3,5,7,9];
  c := [3,4,5,6];
  d := a + c;
  e := a * c;
  b := a - c;
  if 6 in d then writeln('PASS: 6 is in union') else writeln('FAIL: 6 should be in union');
  if 4 in e then writeln('FAIL: 4 should not be in intersection') else writeln('PASS: 4 is not in intersection');
  if 7 in b then writeln('PASS: 7 is in difference') else writeln('FAIL: 7 should be in difference');
  if 5 in b then writeln('FAIL: 5 should not be in difference') else writeln('PASS: 5 is not in difference');

  writeln('3) Equality and inequality');
  a := [1..5];
  c := [1,2,3,4,5];
  d := [2,4,6,8];
  if a = c then writeln('PASS: a equals c') else writeln('FAIL: a should equal c');
  if a <> d then writeln('PASS: a differs from d') else writeln('FAIL: a should differ from d');
  d := (d - [6,8]) + [1,3,5];
  if d = a then writeln('PASS: transformed d equals a') else writeln('FAIL: transformed d should equal a');

  writeln('4) Subset and superset relations');
  a := [2,4];
  c := [2,4,6,8];
  if a <= c then writeln('PASS: a is subset of c') else writeln('FAIL: a should be subset of c');
  if c >= a then writeln('PASS: c is superset of a') else writeln('FAIL: c should be superset of a');
  if c <= a then writeln('FAIL: c should not be subset of a') else writeln('PASS: c is not subset of a');

  writeln('5) Variable membership after updates');
  a := [1..6];
  a := (a - [2,4]) + [9];
  x := 4;
  if x in a then writeln('FAIL: 4 should have been removed') else writeln('PASS: 4 was removed');
  x := 9;
  if x in a then writeln('PASS: 9 was added') else writeln('FAIL: 9 should have been added')
end.