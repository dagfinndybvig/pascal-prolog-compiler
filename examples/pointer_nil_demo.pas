program pointer_nil_demo;

type
  person = record
    age: integer;
    initial: char;
  end;
  person_ptr = ^person;

var
  p, q: person_ptr;

begin
  p := nil;
  q := p;

  if p = nil then
    writeln(1)
  else
    writeln(0);

  if p <> q then
    writeln(1)
  else
    writeln(0);
end.
