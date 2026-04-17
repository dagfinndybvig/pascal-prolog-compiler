{ Square root optimized prime calculator }
{ Only tests divisors up to approximate square root of i }
{ Build command: swipl -q -s pascal_compiler.pl -- build-asm primes_sqrt_optimized.pas primes_sqrt_optimized }
{ Run command: ./primes_sqrt_optimized }

program primes_sqrt_optimized;

var
  i, j, is_prime, remainder, sqrt_approx, found_factor: integer;

begin
  writeln('Square Root Optimized Prime Calculator');
  writeln('--------------------------------------');
  
  { Handle 2 separately (the only even prime) }
  writeln(2);
  
  { Check only odd numbers from 3 to 199 }
  i := 3;
  while i < 200 do
  begin
    { Assume i is prime until proven otherwise }
    is_prime := 1;
    
    { Calculate square root approximation inline }
    { Find largest integer whose square is <= i }
    sqrt_approx := 1;
    while sqrt_approx * sqrt_approx <= i do
      sqrt_approx := sqrt_approx + 1;
    sqrt_approx := sqrt_approx - 1; { We overshot by 1 }
    
    { Check divisibility only by odd numbers from 3 to sqrt_approx }
    j := 3;
    found_factor := 0;
    while j <= sqrt_approx do
    begin
      { Calculate remainder using: i - (i/j)*j }
      remainder := i - (i / j) * j;
      
      if remainder = 0 then
      begin
        { Found a factor, so i is not prime }
        found_factor := 1;
        j := sqrt_approx + 1; { Break out of loop }
      end;
      j := j + 2; { Skip even divisors }
    end;
    
    { If no factor found up to sqrt(i), then i is prime }
    if found_factor = 0 then
      writeln(i);
    
    i := i + 2; { Skip even numbers }
  end;
end.