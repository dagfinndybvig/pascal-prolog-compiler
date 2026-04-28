program boolean_char_demo;

function choose_mark(ok: boolean): char;
begin
  if ok then
    choose_mark := 'Y'
  else
    choose_mark := 'N'
end;

var
  ok: boolean;
  mark: char;

begin
  ok := 10 > 3;
  mark := choose_mark(ok);
  writeln(mark);
  ok := mark = 'Y';
  if ok then
    writeln('T')
  else
    writeln('F')
end.
