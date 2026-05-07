program PrimesUnder1000List;

type
  node = record
    value: integer;
    next: ^node;
  end;
  node_ptr = ^node;

function is_prime(n: integer): boolean;
var
  d: integer;
begin
  if n < 2 then
    is_prime := false
  else
  begin
    is_prime := true;
    d := 2;
    while (d * d <= n) and is_prime do
    begin
      if n mod d = 0 then
        is_prime := false
      else
        d := d + 1
    end
  end
end;

function append_prime(var head: node_ptr; var tail: node_ptr; value: integer): integer;
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

  append_prime := 1
end;

function build_prime_list(var head: node_ptr; limit: integer): integer;
var
  tail: node_ptr;
  n: integer;
  total: integer;
begin
  head := nil;
  tail := nil;
  total := 0;

  for n := 2 to limit - 1 do
  begin
    if is_prime(n) then
      total := total + append_prime(head, tail, n)
  end;

  build_prime_list := total
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
  list: node_ptr;
  built: integer;
  shown: integer;
  freed: integer;

begin
  built := build_prime_list(list, 1000);
  shown := print_list(list);
  freed := free_list(list);

  writeln('count: ', built);
  writeln('shown: ', shown);
  writeln('freed: ', freed)
end.
