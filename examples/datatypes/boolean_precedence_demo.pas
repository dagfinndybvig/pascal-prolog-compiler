program boolean_precedence_demo;

function to_int(value: boolean): integer;
begin
  if value then
    to_int := 1
  else
    to_int := 0
end;

var
  a, b, c: boolean;

begin
  a := true;
  b := false;
  c := false;

  writeln('Boolean precedence demo:');
  write('true or false and false = ', to_int(a or b and c)); writeln('');
  write('(true or false) and false = ', to_int((a or b) and c)); writeln('');
  write('not true or false = ', to_int(not a or b)); writeln('');
  write('not (true or false) = ', to_int(not (a or b))); writeln('');
  write('(3 < 5) and not (7 < 2) = ', to_int((3 < 5) and not (7 < 2))); writeln('');
  write('(3 > 5) or (9 >= 9) = ', to_int((3 > 5) or (9 >= 9))); writeln('')
end.
