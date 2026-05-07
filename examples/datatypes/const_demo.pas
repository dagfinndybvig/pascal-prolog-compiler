program ConstDemo;

const
  MaxSize = 100;
  Pi = 3;
  Greeting = 'Hello, World!';
  ArraySize = 10;

type
  MyArray = array[1..ArraySize] of integer;

var
  arr: MyArray;
  i: integer;

begin
  for i := 1 to MaxSize do
  begin
    if i = Pi then
      writeln(Greeting)
    else if i <= ArraySize then
    begin
      arr[i] := i * 2;
      write(arr[i], ' ')
    end
  end;
  writeln('')
end.