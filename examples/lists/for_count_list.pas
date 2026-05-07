program ForCountList;

type
  node = record
    value: integer;
    next: ^node;
  end;
  node_ptr = ^node;

function make_list_for(var head: node_ptr; size: integer): integer;
var
  tail: node_ptr;
  item: node_ptr;
  i: integer;
begin
  head := nil;
  tail := nil;

  for i := 1 to size do
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
    end
  end;

  make_list_for := size
end;

function count_nodes_for(var head: node_ptr; size: integer): integer;
var
  curr: node_ptr;
  i: integer;
  total: integer;
begin
  curr := head;
  total := 0;

  for i := 1 to size do
  begin
    if curr <> nil then
    begin
      total := total + 1;
      curr := curr^.next
    end
  end;

  count_nodes_for := total
end;

function free_list_for(var head: node_ptr; size: integer): integer;
var
  curr: node_ptr;
  next_item: node_ptr;
  i: integer;
  total: integer;
begin
  curr := head;
  total := 0;

  for i := 1 to size do
  begin
    if curr <> nil then
    begin
      next_item := curr^.next;
      dispose(curr);
      curr := next_item;
      total := total + 1
    end
  end;

  head := nil;
  free_list_for := total
end;

var
  list: node_ptr;
  built: integer;
  counted: integer;
  freed: integer;

begin
  built := make_list_for(list, 5);
  counted := count_nodes_for(list, built);

  writeln('built: ', built);
  writeln('count: ', counted);

  freed := free_list_for(list, counted);
  writeln('freed: ', freed);

  if list = nil then
    writeln('empty: 1')
  else
    writeln('empty: 0')
end.
