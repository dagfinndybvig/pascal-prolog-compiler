program procedures_demo;

var
  total: integer;

procedure print_banner(label_value: integer);
begin
  writeln('--- step ---');
  writeln(label_value)
end;

procedure add_to_total(amount: integer);
begin
  total := total + amount
end;

procedure reset_total;
begin
  total := 0
end;

begin
  reset_total;
  print_banner(1);
  add_to_total(10);
  add_to_total(20);
  print_banner(2);
  add_to_total(12);
  writeln(total)
end.
