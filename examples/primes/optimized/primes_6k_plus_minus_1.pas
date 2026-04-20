{ Prime number calculator using 6k +/- 1 wheel factorization }
{ This is a classic optimization: all primes > 3 are of the form 6k +/- 1 }
{ That is, they are congruent to 1 or 5 modulo 6 }
{ This skips multiples of 2 and 3, reducing checks by 33% vs odds-only }
{ Build command: swipl -q -s pascal_compiler.pl -- build-asm primes_6k_plus_minus_1.pas primes_6k_plus_minus_1 }
{ Run command: ./primes_6k_plus_minus_1 }
{ Implemented by Kimi }

program primes_6k_plus_minus_1;

var
  n, divisor, remainder, sqrt_approx, is_prime, step, count: integer;

begin
  writeln('6k +/- 1 Wheel Factorization Prime Calculator');
  writeln('----------------------------------------------');
  writeln('');
  writeln('All primes > 3 are of the form 6k+1 or 6k-1 (i.e., 6k+5)');
  writeln('This skips multiples of 2 AND 3, checking only 2 numbers');
  writeln('out of every 6 (a 33% reduction over odds-only method)');
  writeln('');
  
  count := 0;
  
  { Handle the only even prime separately }
  writeln(2);
  count := count + 1;
  
  { Handle the only prime divisible by 3 }
  writeln(3);
  count := count + 1;
  
  { Start checking from 5 - the first number of the form 6k-1 }
  { 5 = 6*1 - 1, so k=1, form is 6k-1 }
  n := 5;
  
  while n < 200 do
  begin
    { Assume n is prime until proven otherwise }
    is_prime := 1;
    
    { Calculate approximate square root of n }
    { We need to check divisors only up to sqrt(n) }
    sqrt_approx := 1;
    while sqrt_approx * sqrt_approx <= n do
      sqrt_approx := sqrt_approx + 1;
    sqrt_approx := sqrt_approx - 1;
    
    { Check if n is divisible by any number up to sqrt_approx }
    { First check 2 and 3 explicitly (though n is never even or divisible by 3) }
    { Then check only divisors of the form 6k +/- 1: 5, 7, 11, 13, 17, 19, 23, 25... }
    
    divisor := 5;
    { step alternates between 2 and 4 to skip multiples of 3 }
    { 5 + 2 = 7 (6*1+1, then 6*2-1), 7 + 4 = 11 (6*2-1, then 6*2+1) }
    { 11 + 2 = 13, 13 + 4 = 17, etc. }
    step := 2;
    
    while divisor <= sqrt_approx do
    begin
      { Calculate remainder using: n - (n/divisor)*divisor }
      remainder := n - (n / divisor) * divisor;
      
      if remainder = 0 then
      begin
        { Found a divisor, n is composite }
        is_prime := 0;
        divisor := sqrt_approx + 1; { Break out of loop }
      end;
      
      { Move to next potential divisor: 5, 7, 11, 13, 17, 19, 23, 25... }
      divisor := divisor + step;
      { Alternate step between 2 and 4 }
      if step = 2 then
        step := 4
      else
        step := 2;
    end;
    
    { If no divisor found, n is prime }
    if is_prime = 1 then
    begin
      writeln(n);
      count := count + 1;
    end;
    
    { Move to next candidate of the form 6k +/- 1 }
    { We alternate adding 2 and 4 to skip multiples of 2 and 3 }
    { Current n is either 6k-1 or 6k+1 }
    { If n = 6k-1, next is 6k+1 (add 2) }
    { If n = 6k+1, next is 6(k+1)-1 = 6k+5 (add 4) }
    if n - (n / 6) * 6 = 5 then
      { n mod 6 = 5, so n = 6k-1, next is 6k+1, add 2 }
      n := n + 2
    else
      { n mod 6 = 1, so n = 6k+1, next is 6(k+1)-1, add 4 }
      n := n + 4;
  end;
  
  writeln('');
  write('Total primes found: ');
  writeln(count);
end.
