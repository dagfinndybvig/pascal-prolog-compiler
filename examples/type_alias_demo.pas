program type_alias_demo;

type
  smallint = integer;
  letter = char;
  person = record
    age: smallint;
    initial: letter;
  end;

var
  p: person;
  n: smallint;

begin
  p.age := 33;
  p.initial := 'B';
  n := p.age + 7;
  writeln(n);
  writeln(p.initial);
end.
