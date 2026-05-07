program NestedSExpressionList;

type
  node = record
    kind: char;
    value: char;
    child: ^node;
    next: ^node;
  end;
  node_ptr = ^node;

var
  input: array[1..64] of char;
  count: integer;
  pos: integer;
  depth: integer;
  done: boolean;
  ch: char;
  root: node_ptr;

procedure append_node(var head: node_ptr; var tail: node_ptr; item: node_ptr);
begin
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

procedure parse_list(var result: node_ptr);
var
  tail: node_ptr;
  item: node_ptr;
  current: char;
begin
  result := nil;
  tail := nil;

  if input[pos] = '(' then
    pos := pos + 1;

  while (pos <= count) and (input[pos] <> ')') do
  begin
    current := input[pos];

    if current = ' ' then
      pos := pos + 1
    else
    begin
      new(item);
      item^.kind := 'A';
      item^.value := ' ';
      item^.child := nil;
      item^.next := nil;

      if current = '(' then
      begin
        item^.kind := 'L';
        parse_list(item^.child)
      end
      else
      begin
        item^.value := current;
        pos := pos + 1
      end;

      append_node(result, tail, item)
    end
  end;

  if (pos <= count) and (input[pos] = ')') then
    pos := pos + 1
end;

procedure print_nodes(nodes: node_ptr);
var
  curr: node_ptr;
begin
  curr := nodes;
  while curr <> nil do
  begin
    if curr^.kind = 'A' then
      write('[', curr^.value, ']')
    else
    begin
      write('(');
      print_nodes(curr^.child);
      write(')')
    end;

    if curr^.next <> nil then
      write(' -> ')
    else
      write(' -> nil');

    curr := curr^.next
  end
end;

procedure dispose_nodes(var nodes: node_ptr);
var
  curr: node_ptr;
  next_item: node_ptr;
begin
  curr := nodes;
  while curr <> nil do
  begin
    next_item := curr^.next;
    if curr^.kind = 'L' then
      dispose_nodes(curr^.child);
    dispose(curr);
    curr := next_item
  end;
  nodes := nil
end;

begin
  count := 0;
  depth := 0;
  done := false;

  while not done do
  begin
    readln(ch);
    count := count + 1;
    input[count] := ch;

    if ch = '(' then
      depth := depth + 1
    else
      if ch = ')' then
      begin
        depth := depth - 1;
        if depth = 0 then
          done := true
      end
  end;

  pos := 1;
  parse_list(root);

  write('tree: ');
  print_nodes(root);
  writeln('');

  dispose_nodes(root)
end.
