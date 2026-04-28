program global_var_before_function_demo;

var
  counter: integer;

function add_counter(value: integer): integer;
begin
  counter := counter + value;
  add_counter := counter
end;

begin
  counter := 10;
  writeln(add_counter(5));
  writeln(add_counter(7));
  writeln(counter)
end.
