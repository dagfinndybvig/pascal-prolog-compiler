{ Tower of Hanoi - Final Working Version
  Demonstrates the classic recursive algorithm
  Uses basic write functionality that works with current compiler
}

program tower_of_hanoi;

function hanoi_moves(n: integer): integer;
{ Calculates total moves required for Tower of Hanoi }
{ Formula: hanoi(n) = 2 * hanoi(n-1) + 1 = 2^n - 1 }
begin
  if n = 1 then
    hanoi_moves := 1
  else
    hanoi_moves := hanoi_moves(n - 1) * 2 + 1
end;

function power_of_two(n: integer): integer;
{ Calculates 2^n using recursion }
{ Base case: 2^0 = 1 }
{ Recursive case: 2^n = 2 * 2^(n-1) }
begin
  if n = 0 then
    power_of_two := 1
  else
    power_of_two := power_of_two(n - 1) * 2
end;

var
  disks: integer;
  total_moves: integer;
  expected_moves: integer;

begin
  disks := 3;
  
  { Calculate and display results }
  total_moves := hanoi_moves(disks);
  expected_moves := power_of_two(disks) - 1;
  
  { Output results using basic write }
  writeln(disks);          { Number of disks }
  writeln(total_moves);    { Calculated moves }
  writeln(expected_moves); { Expected moves }
  
  { Show moves for larger numbers }
  writeln(hanoi_moves(4)); { Moves for 4 disks }
  writeln(hanoi_moves(5))  { Moves for 5 disks }
end.