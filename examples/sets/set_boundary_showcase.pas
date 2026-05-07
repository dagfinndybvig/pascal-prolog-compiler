program set_boundary_showcase;

type
  SmallSet = set of 0..31;

var
  edge, mid, all, trimmed: SmallSet;
  x: integer;

begin
  writeln('Set Boundary Showcase (0..31)');
  writeln('---------------------------');

  writeln('1) Endpoint literals');
  edge := [0,31];
  if 0 in edge then writeln('PASS: 0 is present') else writeln('FAIL: 0 should be present');
  if 31 in edge then writeln('PASS: 31 is present') else writeln('FAIL: 31 should be present');
  if 30 in edge then writeln('FAIL: 30 should not be present') else writeln('PASS: 30 is not present');

  writeln('2) Full boundary range');
  all := [0..31];
  if 0 in all then writeln('PASS: lower bound included') else writeln('FAIL: lower bound missing');
  if 31 in all then writeln('PASS: upper bound included') else writeln('FAIL: upper bound missing');

  writeln('3) Union and intersection near edges');
  edge := [0,1,30,31];
  mid := [1,2,29,30];
  all := edge + mid;
  trimmed := edge * mid;
  if 2 in all then writeln('PASS: union added 2') else writeln('FAIL: union should contain 2');
  if 29 in all then writeln('PASS: union added 29') else writeln('FAIL: union should contain 29');
  if 1 in trimmed then writeln('PASS: intersection keeps 1') else writeln('FAIL: intersection should contain 1');
  if 0 in trimmed then writeln('FAIL: intersection should not contain 0') else writeln('PASS: intersection removes 0');

  writeln('4) Difference removes endpoints');
  all := [0..31];
  trimmed := all - [0,31];
  if 0 in trimmed then writeln('FAIL: 0 should be removed') else writeln('PASS: 0 removed');
  if 31 in trimmed then writeln('FAIL: 31 should be removed') else writeln('PASS: 31 removed');
  if 16 in trimmed then writeln('PASS: middle values stay') else writeln('FAIL: 16 should remain');

  writeln('5) Subset and superset at boundaries');
  edge := [0,31];
  all := [0..31];
  if edge <= all then writeln('PASS: edge is subset of full range') else writeln('FAIL: edge should be subset');
  if all >= edge then writeln('PASS: full range is superset of edge') else writeln('FAIL: full range should be superset');
  if all <= edge then writeln('FAIL: full range should not be subset of edge') else writeln('PASS: full range is not subset of edge');

  writeln('6) Variable membership with edge values');
  x := 0;
  if x in edge then writeln('PASS: variable 0 found in edge') else writeln('FAIL: variable 0 should be found');
  x := 31;
  if x in edge then writeln('PASS: variable 31 found in edge') else writeln('FAIL: variable 31 should be found');
  x := 15;
  if x in edge then writeln('FAIL: variable 15 should not be found') else writeln('PASS: variable 15 not found')
end.