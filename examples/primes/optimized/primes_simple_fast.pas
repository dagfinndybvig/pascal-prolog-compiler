program primes_simple_fast;

var
  i, j, is_prime, remainder, sqrt_approx, count: integer;

begin
  i := 3;
  count := 1; { count 2 separately }
  
  while i <= 46000 do
  begin
    is_prime := 1;
    begin
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
    end;
    if is_prime = 1 then 
	begin
		count := count + 1;
		write(i);
    		write(' ');
	end;
    i := i + 2;
  end;

  writeln('');  
  write('Number of primes: ');
  writeln(count);
end.
