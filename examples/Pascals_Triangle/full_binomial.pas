program FullBinomial;

function binomialCoefficient(n, k: integer): integer;
begin
  if k = 0 or k = n then
    binomialCoefficient := 1
  else
    binomialCoefficient := binomialCoefficient(n-1, k-1) + binomialCoefficient(n-1, k)
end;

var result: integer;
begin
  result := binomialCoefficient(2, 1);
  writeln(result);
end.