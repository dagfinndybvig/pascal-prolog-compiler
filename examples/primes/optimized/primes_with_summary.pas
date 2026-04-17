{ Prime display with summary at end }
program primes_with_summary;

var
  i, j, is_prime, remainder, sqrt_approx: integer;

begin
  write('2 ');
  i := 3;
  
  while i <= 46000 do
  begin
    is_prime := 1;
    
    sqrt_approx := 1;
    while sqrt_approx * sqrt_approx <= i do
      sqrt_approx := sqrt_approx + 1;
    sqrt_approx := sqrt_approx - 1;
    
    j := 3;
    while j <= sqrt_approx do
    begin
      remainder := i - (i / j) * j;
      if remainder = 0 then
      begin
        is_prime := 0;
        j := sqrt_approx + 1;
      end;
      j := j + 2;
    end;
    
    if is_prime = 1 then
    begin
      write(i);
      write(' ');
    end;
    
    i := i + 2;
  end;
  
  writeln('');
  writeln('');
  writeln('Found these primes between 2 and 46000');
end.
