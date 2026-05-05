program linked_list_sort_wirth;

type
  node = record
    key: integer;
    next: ^node;
  end;
  node_ptr = ^node;

var
  head: node_ptr;

procedure push_front(var h: node_ptr; value: integer);
var
  p: node_ptr;
begin
  new(p);
  p^.key := value;
  p^.next := h;
  h := p;
end;

procedure insert_sorted(var sorted: node_ptr; item: node_ptr);
var
  prev: node_ptr;
  curr: node_ptr;
begin
  if sorted = nil then
  begin
    { First element initializes the sorted chain. }
    item^.next := nil;
    sorted := item;
  end
  else
  begin
    if item^.key <= sorted^.key then
    begin
      { Insert before current head of sorted list. }
      item^.next := sorted;
      sorted := item;
    end
    else
    begin
      prev := sorted;
      curr := sorted^.next;

      { Walk until insertion point (first key >= item^.key) or list end. }
      while curr <> nil do
      begin
        if item^.key <= curr^.key then
          curr := nil
        else
        begin
          prev := prev^.next;
          curr := curr^.next;
        end;
      end;

      { Splice item after prev and before prev^.next. }
      item^.next := prev^.next;
      prev^.next := item;
    end;
  end;
end;

procedure sort_list(var h: node_ptr);
var
  unsorted: node_ptr;
  next_item: node_ptr;
  sorted: node_ptr;
begin
  sorted := nil;
  unsorted := h;

  { Detach each node from unsorted and reinsert into sorted. }
  while unsorted <> nil do
  begin
    next_item := unsorted^.next;
    insert_sorted(sorted, unsorted);
    unsorted := next_item;
  end;

  h := sorted;
end;

procedure print_list(h: node_ptr);
var
  p: node_ptr;
begin
  p := h;
  while p <> nil do
  begin
    write(p^.key);
    if p^.next <> nil then
      write(' ')
    else
      writeln('');
    p := p^.next;
  end;
end;

procedure dispose_list(var h: node_ptr);
var
  p: node_ptr;
  next_item: node_ptr;
begin
  p := h;
  { Keep next pointer before dispose so traversal remains valid. }
  while p <> nil do
  begin
    next_item := p^.next;
    dispose(p);
    p := next_item;
  end;
  h := nil;
end;

begin
  head := nil;

  push_front(head, 7);
  push_front(head, 1);
  push_front(head, 9);
  push_front(head, 3);
  push_front(head, 5);
  push_front(head, 2);

  writeln('Unsorted:');
  print_list(head);

  sort_list(head);

  writeln('Sorted:');
  print_list(head);

  dispose_list(head);
end.
