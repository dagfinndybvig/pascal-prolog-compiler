program record_demo;

var
  p: record
    age: integer;
    initial: char;
  end;

procedure bump(var r: record
  age: integer;
  initial: char;
end);
begin
  r.age := r.age + 1;
end;

procedure bump_age(var x: integer);
begin
  x := x + 10;
end;

begin
  p.age := 41;
  p.initial := 'A';
  writeln(p.age);
  writeln(p.initial);
  bump(p);
  bump_age(p.age);
  writeln(p.age);
end.
