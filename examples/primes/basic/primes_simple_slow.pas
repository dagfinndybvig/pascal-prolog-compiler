program primes_simple_slow;

var
  i, j, is_prime, temp, is_divisible, count: integer;

begin
  i := 2;
  count := 0;
  
  while i <= 46000 do
  begin
    is_prime := 1;
    j := 2;
    while j < i do
    begin
      is_divisible := 0;
      temp := i;
      while temp >= j do
      begin
        temp := temp - j;
        if temp = 0 then is_divisible := 1;
      end;
      if is_divisible = 1 then
      begin
        is_prime := 0;
        j := i;
      end;
      j := j + 1;
    end;
    if is_prime = 1 then
	begin
	 count := count + 1;
	 write(i);
    	 write(' ');
	end;

    i := i + 1;

  end;
  
  writeln('');
  write('Number of primes: ');
  writeln(count);
end.
