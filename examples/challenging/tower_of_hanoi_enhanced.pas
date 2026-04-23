program tower_of_hanoi_enhanced;

function hanoi(n: integer): integer;
begin
  if n = 1 then
    hanoi := 1
  else
    hanoi := hanoi(n - 1) * 2 + 1
end;

var
  disks, total_moves: integer;

begin
  disks := 3;
  total_moves := hanoi(disks);
  write('Tower of Hanoi with ', disks);
  write(' disks requires ');
  write(total_moves);
  write(' moves');
  writeln('')
end.