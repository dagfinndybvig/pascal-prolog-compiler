program ForLoopDemo;

var
  i, j, sum: integer;
  squares: array[1..5] of integer;

begin
  { Sum 1..10 with an ascending for loop }
  sum := 0;
  for i := 1 to 10 do
    sum := sum + i;
  writeln(sum);

  { Countdown with downto }
  for i := 5 downto 1 do
    writeln(i);

  { Fill an array, then read it back }
  for i := 1 to 5 do
    squares[i] := i * i;
  for j := 1 to 5 do
    writeln(squares[j])
end.
