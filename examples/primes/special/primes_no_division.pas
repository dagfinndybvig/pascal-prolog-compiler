{ Prime number calculator - prints all primes less than 200 }
{ Uses subtraction instead of division to check divisibility }
{ Build command: swipl -q -s pascal_compiler.pl -- build-asm primes_no_division.pas primes_no_division }
{ Run command: ./primes_no_division }

program primes_no_division;

var
  i, j, is_prime, temp, is_divisible: integer;

begin
  writeln('Division-Free Prime Calculator');
  writeln('-------------------------------');
  
  { Print all prime numbers less than 200 }
  i := 2; { Start from 2, the first prime number }
  
  while i < 200 do
  begin
    { Assume i is prime until proven otherwise }
    is_prime := 1;
    
    { Check if i is divisible by any number from 2 to i-1 }
    j := 2;
    while j < i do
    begin
      { Check divisibility using repeated subtraction instead of division }
      is_divisible := 0;
      temp := i;
      
      { Subtract j repeatedly until temp < j }
      while temp >= j do
      begin
        temp := temp - j;
        { If we reach exactly 0, it's divisible }
        if temp = 0 then
        begin
          is_divisible := 1;
          temp := 0; { break early }
        end;
      end;
      
      if is_divisible = 1 then
      begin
        { i is divisible by j, so it's not prime }
        is_prime := 0;
        j := i; { Break out of the inner loop }
      end;
      j := j + 1;
    end;
    
    { If is_prime is still 1, then i is prime }
    if is_prime = 1 then
      writeln(i);
    
    i := i + 1;
  end;
end.