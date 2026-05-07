program StringToLinkedList;

type
  node = record
    value: char;
    next: ^node;
  end;
  node_ptr = ^node;

var
  input: array[1..32] of char;
  count: integer;
  i: integer;
  ch: char;
  head: node_ptr;
  tail: node_ptr;
  item: node_ptr;
  curr: node_ptr;
  next_item: node_ptr;

begin
  count := 0;
  ch := ' ';

  while ch <> ')' do
  begin
    readln(ch);
    count := count + 1;
    input[count] := ch
  end;

  head := nil;
  tail := nil;

  i := 1;
  while i <= count do
  begin
    ch := input[i];
    if (ch <> '(') and (ch <> ')') and (ch <> ' ') then
    begin
      new(item);
      item^.value := ch;
      item^.next := nil;

      if head = nil then
      begin
        head := item;
        tail := item
      end
      else
      begin
        tail^.next := item;
        tail := item
      end
    end;
    i := i + 1
  end;

  write('list: ');
  curr := head;
  while curr <> nil do
  begin
    write('[', curr^.value, '] -> ');
    curr := curr^.next
  end;
  writeln('nil');

  curr := head;
  while curr <> nil do
  begin
    next_item := curr^.next;
    dispose(curr);
    curr := next_item
  end
end.
