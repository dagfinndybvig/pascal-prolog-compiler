{ Prime number calculator - prints all primes less than 200 }
{ Build command: swipl -q -s pascal_compiler.pl -- build-asm primes_less_than_200_simple.pas primes_less_than_200 }
{ Run command: ./primes_less_than_200 }

program primes_less_than_200;

var
  i, j, is_prime, quotient, product: integer;

begin
  writeln('Version 1');
  writeln('---------');
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
      { Check if i is divisible by j using division and multiplication }
      quotient := i / j;
      product := quotient * j;
      
      if product = i then
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
