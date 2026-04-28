program global_array_function_showcase;

function store_square(index, value: integer): boolean;
begin
  squares[index] := value * value;
  store_square := true
end;

var
  squares: array[1..4] of integer;
  ok: boolean;
  i: integer;
  total: integer;

begin
  ok := store_square(1, 1);
  ok := store_square(2, 2);
  ok := store_square(3, 3);
  ok := store_square(4, 4);

  i := 1;
  total := 0;
  while i <= 4 do
  begin
    total := total + squares[i];
    i := i + 1
  end;

  if ok then
    writeln(total)
  else
    writeln(0)
end.
