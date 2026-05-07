program CaseBucketLists;

type
  node = record
    value: integer;
    next: ^node;
  end;
  node_ptr = ^node;

function append_node(var head: node_ptr; var tail: node_ptr; value: integer): integer;
var
  item: node_ptr;
begin
  new(item);
  item^.value := value;
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
  end;

  append_node := 1
end;

function print_list(var head: node_ptr): integer;
var
  curr: node_ptr;
  total: integer;
begin
  curr := head;
  total := 0;

  while curr <> nil do
  begin
    write(curr^.value);
    if curr^.next <> nil then
      write(' -> ')
    else
      write(' -> nil');
    curr := curr^.next;
    total := total + 1
  end;

  writeln('');
  print_list := total
end;

function free_list(var head: node_ptr): integer;
var
  curr: node_ptr;
  next_item: node_ptr;
  total: integer;
begin
  curr := head;
  total := 0;

  while curr <> nil do
  begin
    next_item := curr^.next;
    dispose(curr);
    curr := next_item;
    total := total + 1
  end;

  head := nil;
  free_list := total
end;

var
  head0, head1, head2, head3: node_ptr;
  tail0, tail1, tail2, tail3: node_ptr;
  n: integer;
  count0, count1, count2, count3: integer;
  printed0, printed1, printed2, printed3: integer;
  freed0, freed1, freed2, freed3: integer;

begin
  head0 := nil;
  head1 := nil;
  head2 := nil;
  head3 := nil;
  tail0 := nil;
  tail1 := nil;
  tail2 := nil;
  tail3 := nil;

  count0 := 0;
  count1 := 0;
  count2 := 0;
  count3 := 0;

  for n := 1 to 40 do
  begin
    case n mod 4 of
      0: count0 := count0 + append_node(head0, tail0, n);
      1: count1 := count1 + append_node(head1, tail1, n);
      2: count2 := count2 + append_node(head2, tail2, n);
      3: count3 := count3 + append_node(head3, tail3, n)
    else
      writeln('unexpected remainder')
    end
  end;

  writeln('mod 0:');
  printed0 := print_list(head0);
  writeln('count0: ', count0, ', printed0: ', printed0);

  writeln('mod 1:');
  printed1 := print_list(head1);
  writeln('count1: ', count1, ', printed1: ', printed1);

  writeln('mod 2:');
  printed2 := print_list(head2);
  writeln('count2: ', count2, ', printed2: ', printed2);

  writeln('mod 3:');
  printed3 := print_list(head3);
  writeln('count3: ', count3, ', printed3: ', printed3);

  freed0 := free_list(head0);
  freed1 := free_list(head1);
  freed2 := free_list(head2);
  freed3 := free_list(head3);

  writeln('freed: ', freed0 + freed1 + freed2 + freed3)
end.
