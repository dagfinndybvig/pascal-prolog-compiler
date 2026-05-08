program ConstDemo;

const
  MaxSize: integer = 10;
  Pivot: integer = 3;
  Step: integer = 2;
  Marker: char = '!';

var
  i: integer;

begin
  for i := 1 to MaxSize do
  begin
    if i = Pivot then
      write(Marker, ' ')
    else
      write(i * Step, ' ')
  end;
  writeln('')
end.