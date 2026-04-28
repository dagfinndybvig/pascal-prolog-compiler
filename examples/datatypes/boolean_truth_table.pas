program boolean_truth_table;

function to_int(value: boolean): integer;
begin
  if value then
    to_int := 1
  else
    to_int := 0
end;

function both(left, right: boolean): boolean;
begin
  both := left and right
end;

function either(left, right: boolean): boolean;
begin
  either := left or right
end;

var
  t, f: boolean;

begin
  t := true;
  f := false;

  writeln('Boolean truth table:');
  write('true and true = ', to_int(both(t, t))); writeln('');
  write('true and false = ', to_int(both(t, f))); writeln('');
  write('false and true = ', to_int(both(f, t))); writeln('');
  write('false and false = ', to_int(both(f, f))); writeln('');
  write('true or true = ', to_int(either(t, t))); writeln('');
  write('true or false = ', to_int(either(t, f))); writeln('');
  write('false or true = ', to_int(either(f, t))); writeln('');
  write('false or false = ', to_int(either(f, f))); writeln('');
  write('not true = ', to_int(not t)); writeln('');
  write('not false = ', to_int(not f)); writeln('')
end.
