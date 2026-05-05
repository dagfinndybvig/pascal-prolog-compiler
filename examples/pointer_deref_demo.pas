program pointer_deref_demo;

type
  int_alias = integer;
  person = record
    age: integer;
    initial: char;
  end;
  person_ptr = ^person;
  int_ptr = ^int_alias;

var
  r: person;
  p: person_ptr;
  x: integer;
  ip: int_ptr;

procedure inc(var n: integer);
begin
  n := n + 1;
end;

begin
  r.age := 20;
  r.initial := 'Z';
  p := @r;

  p^.age := p^.age + 2;
  writeln(p^.age);
  writeln(r.age);

  x := 5;
  ip := @x;
  ip^ := ip^ + 3;
  writeln(x);

  inc(ip^);
  inc(p^.age);
  writeln(x);
  writeln(r.age);
end.
