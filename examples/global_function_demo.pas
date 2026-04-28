program global_function_demo;

function add_counter(value: integer): integer;
begin
  counter := counter + value;
  add_counter := counter
end;

var
  counter: integer;

begin
  counter := 10;
  writeln(add_counter(5));
  writeln(add_counter(7));
  writeln(counter)
end.
