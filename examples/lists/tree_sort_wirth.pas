program tree_sort_wirth;

type
  tree_node = record
    key: integer;
    left: ^tree_node;
    right: ^tree_node;
  end;
  tree_ptr = ^tree_node;

var
  root: tree_ptr;
  first_output: boolean;

procedure insert_tree(var t: tree_ptr; value: integer);
begin
  if t = nil then
  begin
    { A nil subtree becomes a newly allocated leaf. }
    new(t);
    t^.key := value;
    t^.left := nil;
    t^.right := nil;
  end
  else
  begin
    if value < t^.key then
      insert_tree(t^.left, value)
    else
      insert_tree(t^.right, value);
  end;
end;

procedure print_in_order(t: tree_ptr; var first: boolean);
begin
  if t <> nil then
  begin
    print_in_order(t^.left, first);

    if first then
    begin
      write(t^.key);
      first := false;
    end
    else
    begin
      write(' ');
      write(t^.key);
    end;

    print_in_order(t^.right, first);
  end;
end;

procedure dispose_tree(var t: tree_ptr);
begin
  if t <> nil then
  begin
    { Free children before freeing the current node. }
    dispose_tree(t^.left);
    dispose_tree(t^.right);
    dispose(t);
    t := nil;
  end;
end;

begin
  root := nil;

  insert_tree(root, 7);
  insert_tree(root, 1);
  insert_tree(root, 9);
  insert_tree(root, 3);
  insert_tree(root, 5);
  insert_tree(root, 2);

  writeln('Tree sort:');
  first_output := true;
  print_in_order(root, first_output);
  writeln('');

  dispose_tree(root);
end.
