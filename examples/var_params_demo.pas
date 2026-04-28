program VarParamsDemo;

var
  x, y, z: integer;

procedure swap(var a, b: integer);
var
  t: integer;
begin
  t := a;
  a := b;
  b := t
end;

procedure inc_by(var counter: integer; delta: integer);
begin
  counter := counter + delta
end;

function bump(var slot: integer): integer;
begin
  slot := slot + 1;
  bump := slot
end;

begin
  x := 1;
  y := 2;
  z := 10;

  writeln(x);
  writeln(y);
  swap(x, y);
  writeln(x);
  writeln(y);

  inc_by(z, 5);
  writeln(z);

  writeln(bump(z));
  writeln(z)
end.
