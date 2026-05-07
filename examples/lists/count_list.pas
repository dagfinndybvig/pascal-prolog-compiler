program CountList;

type
  node = record
    value: integer;
    next: ^node;
  end;
  node_ptr = ^node;

function make_list(var head: node_ptr; size: integer): integer;
var
  tail: node_ptr;
  item: node_ptr;
  i: integer;
begin
  head := nil;
  tail := nil;
  i := 1;

  while i <= size do
  begin
    new(item);
    item^.value := i;
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

    i := i + 1
  end;

  make_list := size
end;

function count_nodes(var head: node_ptr): integer;
var
  curr: node_ptr;
  total: integer;
begin
  total := 0;
  curr := head;

  while curr <> nil do
  begin
    total := total + 1;
    curr := curr^.next
  end;

  count_nodes := total
end;

function free_list(var head: node_ptr): integer;
var
  curr: node_ptr;
  next_item: node_ptr;
  total: integer;
begin
  total := 0;
  curr := head;

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
  list: node_ptr;
  built: integer;
  counted: integer;
  freed: integer;

begin
  built := make_list(list, 5);
  counted := count_nodes(list);

  writeln('built: ', built);
  writeln('count: ', counted);

  freed := free_list(list);
  writeln('freed: ', freed);

  if list = nil then
    writeln('empty: 1')
  else
    writeln('empty: 0')
end.
