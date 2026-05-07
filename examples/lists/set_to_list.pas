program SetToList;

type
  int_set = set of 0..31;

  node = record
    value: integer;
    next: ^node;
  end;
  node_ptr = ^node;

function append_value(var head: node_ptr; var tail: node_ptr; value: integer): integer;
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

  append_value := 1
end;

function print_list(var head: node_ptr): integer;
var
  curr: node_ptr;
  total: integer;
begin
  curr := head;
  total := 0;

  write('list: ');
  if curr = nil then
    write('nil')
  else
  begin
    while curr <> nil do
    begin
      write(curr^.value);
      if curr^.next <> nil then
        write(' -> ')
      else
        write(' -> nil');
      curr := curr^.next;
      total := total + 1
    end
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
  selected: int_set;
  list: node_ptr;
  tail: node_ptr;
  n: integer;
  built: integer;
  shown: integer;
  freed: integer;

begin
  selected := [1, 3, 4, 7, 10..12, 20, 31];

  writeln('Set to linked list demo');
  writeln('Source set: [1, 3, 4, 7, 10..12, 20, 31]');

  list := nil;
  tail := nil;
  built := 0;

  for n := 0 to 31 do
  begin
    if n in selected then
      built := built + append_value(list, tail, n)
  end;

  shown := print_list(list);
  freed := free_list(list);

  writeln('built: ', built);
  writeln('shown: ', shown);
  writeln('freed: ', freed);

  if list = nil then
    writeln('empty after free: 1')
  else
    writeln('empty after free: 0')
end.
