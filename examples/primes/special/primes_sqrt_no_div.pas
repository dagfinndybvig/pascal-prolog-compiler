{ Square root optimized, division-free prime calculator }
{ Uses both optimizations: sqrt limit + subtraction-based testing }
{ Build command: swipl -q -s pascal_compiler.pl -- build-asm primes_sqrt_no_div.pas primes_sqrt_no_div }
{ Run command: ./primes_sqrt_no_div }

program primes_sqrt_no_div;

var
  i, j, is_prime, temp, is_divisible, sqrt_approx: integer;

begin
  writeln('Square Root + Division-Free Prime Calculator');
  writeln('-------------------------------------------');
  
  { Handle 2 separately (the only even prime) }
  writeln(2);
  
  { Check only odd numbers from 3 to 199 }
  i := 3;
  while i < 200 do
  begin
    { Assume i is prime until proven otherwise }
    is_prime := 1;
    
    { Calculate square root approximation }
    sqrt_approx := 1;
    while sqrt_approx * sqrt_approx <= i do
      sqrt_approx := sqrt_approx + 1;
    sqrt_approx := sqrt_approx - 1;
    
    { Check divisibility only by odd numbers from 3 to sqrt_approx }
    j := 3;
    while j <= sqrt_approx do
    begin
      { Test divisibility using repeated subtraction (no division) }
      is_divisible := 0;
      temp := i;
      
      while temp >= j do
      begin
        temp := temp - j;
        if temp = 0 then
        begin
          is_divisible := 1;
          temp := 0; { break early }
        end;
      end;
      
      if is_divisible = 1 then
      begin
        { Found a factor, so i is not prime }
        is_prime := 0;
        j := sqrt_approx + 1; { Break out of loop }
      end;
      j := j + 2; { Skip even divisors }
    end;
    
    { If no factor found up to sqrt(i), then i is prime }
    if is_prime = 1 then
      writeln(i);
    
    i := i + 2; { Skip even numbers }
  end;
end.