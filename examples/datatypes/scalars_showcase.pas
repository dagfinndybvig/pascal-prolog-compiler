program scalars_showcase;

function is_small(n: integer): boolean;
begin
  is_small := n < 10
end;

function marker(flag: boolean): char;
begin
  if flag then
    marker := 'Y'
  else
    marker := 'N'
end;

var
  flag: boolean;
  mark: char;

begin
  flag := is_small(7);
  mark := marker(flag);
  writeln(mark);
  if flag then
    writeln('T')
  else
    writeln('F')
end.
