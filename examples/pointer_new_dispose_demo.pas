program pointer_new_dispose_demo;

type
  person = record
    value: integer;
    initial: char;
  end;
  person_ptr = ^person;

var
  head: person_ptr;

begin
  head := nil;

  new(head);
  head^.value := 7;
  head^.initial := 'K';
  writeln(head^.value);
  writeln(head^.initial);

  dispose(head);
  head := nil;

  if head = nil then
    writeln(1)
  else
    writeln(0);
end.
