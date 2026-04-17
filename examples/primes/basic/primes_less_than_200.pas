{ Prime number calculator - prints all primes less than 200 }
{ Build command: swipl -q -s pascal_compiler.pl -- build-asm primes_less_than_200.pas primes_less_than_200 }
{ Run command: ./primes_less_than_200 }

program primes_less_than_200;

var
  i, j, is_prime, remainder: integer;

begin
  writeln('Version 2');
  writeln('.........');

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
      { Calculate remainder using: i - (i/j)*j }
      { This is more efficient than the previous (i/j)*j = i approach }
      remainder := i - (i / j) * j;
      
      if remainder = 0 then
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
