program FullBinomial;

function binomialCoefficient(n, k: integer): integer;
begin
  if k = 0 or k = n then
    binomialCoefficient := 1
  else
    binomialCoefficient := binomialCoefficient(n-1, k-1) + binomialCoefficient(n-1, k)
end;

var
  row, col, value: integer;

begin
  for row := 0 to 6 do
  begin
    for col := 0 to row do
    begin
      value := binomialCoefficient(row, col);
      if col < row then
        write(value, ' ')
      else
        writeln(value)
    end
  end
end.
