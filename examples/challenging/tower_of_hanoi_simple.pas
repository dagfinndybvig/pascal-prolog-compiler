{ Tower of Hanoi
  Classic recursive algorithm demonstration
  Calculates the minimum number of moves required to solve the Tower of Hanoi puzzle
  Formula: hanoi(n) = 2 * hanoi(n-1) + 1 = 2^n - 1
  
  For 3 disks: 2^3 - 1 = 7 moves (expected output)
  This demonstrates the exponential growth of the problem complexity
}

program tower_of_hanoi;

function hanoi(n: integer): integer;
{ Recursive function implementing the Tower of Hanoi algorithm }
{ Base case: hanoi(1) = 1 (move single disk) }
{ Recursive case: hanoi(n) = 2 * hanoi(n-1) + 1 }
begin
  if n = 1 then
    hanoi := 1
  else
    hanoi := hanoi(n - 1) * 2 + 1
end;

var
  disks: integer;
  total_moves: integer;

begin
  disks := 3; { Solve for 3 disks }
  total_moves := hanoi(disks);
  writeln(total_moves) { Output: 7 moves }
end.