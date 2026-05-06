program StringToLinkedList;

type
  Node = record
    value: char;
    next: ^Node;
  end;
  NodePtr = ^Node;

procedure AppendNode(var head: NodePtr; value: char);
var
  newNode, current: NodePtr;
begin
  new(newNode);
  newNode^.value := value;
  newNode^.next := nil;

  if head = nil then
    head := newNode
  else
  begin
    current := head;
    while current^.next <> nil do
      current := current^.next;
    current^.next := newNode;
  end;
end;

function ParseLispList(input: string): NodePtr;
var
  head: NodePtr;
  i: integer;
  c: char;
begin
  head := nil;
  i := 2; { Skip the opening '(' }
  while i <= Length(input) - 1 do { Skip the closing ')' }
  begin
    c := input[i];
    if c <> ' ' then
      AppendNode(head, c);
    i := i + 1;
  end;
  ParseLispList := head;
end;

procedure PrintLinkedList(head: NodePtr);
var
  current: NodePtr;
begin
  current := head;
  while current <> nil do
  begin
    write(current^.value, ' -> ');
    current := current^.next;
  end;
  writeln('nil');
end;

var
  input: string;
  head: NodePtr;
begin
  input := '(a b c)';
  head := ParseLispList(input);
  PrintLinkedList(head);
end.