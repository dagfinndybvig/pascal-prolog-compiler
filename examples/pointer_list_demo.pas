program pointer_list_demo;

type
  node = record
    value: integer;
    next: ^node;
  end;
  node_ptr = ^node;

var
  head: node_ptr;
  curr: node_ptr;
  new_node: node_ptr;
  sum: integer;

begin
  head := nil;

  new(head);
  head^.value := 3;
  head^.next := nil;

  new(new_node);
  new_node^.value := 5;
  new_node^.next := head;
  head := new_node;

  sum := 0;
  curr := head;
  while curr <> nil do
  begin
    sum := sum + curr^.value;
    curr := curr^.next;
  end;

  writeln(sum);

  dispose(head^.next);
  dispose(head);
  head := nil;

  if head = nil then
    writeln(1)
  else
    writeln(0);
end.
