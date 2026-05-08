program ConstList;

const
  ListSize: integer = 5;
  StartValue: integer = 10;
  StepValue: integer = 3;
  Prefix: char = '#';

type
  node = record
    value: integer;
    next: ^node;
  end;
  node_ptr = ^node;

function build_list(var head: node_ptr): integer;
var
  tail: node_ptr;
  item: node_ptr;
  i: integer;
  value: integer;
begin
  head := nil;
  tail := nil;
  i := 0;

  while i < ListSize do
  begin
    new(item);
    value := StartValue + i * StepValue;
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

    i := i + 1
  end;

  build_list := ListSize
end;

function print_and_count(var head: node_ptr): integer;
var
  curr: node_ptr;
  count: integer;
begin
  curr := head;
  count := 0;

  while curr <> nil do
  begin
    write(Prefix, curr^.value, ' ');
    count := count + 1;
    curr := curr^.next
  end;

  writeln('');
  print_and_count := count
end;

function free_list(var head: node_ptr): integer;
var
  curr: node_ptr;
  next_item: node_ptr;
  count: integer;
begin
  curr := head;
  count := 0;

  while curr <> nil do
  begin
    next_item := curr^.next;
    dispose(curr);
    curr := next_item;
    count := count + 1
  end;

  head := nil;
  free_list := count
end;

var
  head: node_ptr;
  built: integer;
  counted: integer;
  freed: integer;

begin
  built := build_list(head);
  counted := print_and_count(head);
  freed := free_list(head);

  writeln('built: ', built);
  writeln('counted: ', counted);
  writeln('freed: ', freed)
end.
