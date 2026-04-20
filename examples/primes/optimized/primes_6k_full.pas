{ 6k +/- 1 Wheel Factorization - Full Range Test (2 to 46225) }
{ This tests the 6k +/- 1 optimization on the full range }
{ Build: swipl -q -s pascal_compiler.pl -- build-asm primes_6k_full.pas primes_6k_full }
{ Run: time ./primes_6k_full }
{ Implemented by Kimi }

program primes_6k_full;

var
  n, divisor, remainder, sqrt_approx, is_prime, step, count, rem1000, rem10000: integer;

begin
  writeln('6k +/- 1 Wheel Factorization - Full Range Test (2 to 46225)');
  writeln('==========================================================');
  writeln('');
  writeln('All primes > 3 are of the form 6k+1 or 6k-1');
  writeln('This skips multiples of 2 AND 3 for maximum efficiency');
  writeln('');
  writeln('Testing up to 46225 (max safe limit)...');
  writeln('');
  
  count := 0;
  
  { Count 2 and 3 separately }
  count := count + 1;
  write('2 ');
  count := count + 1;
  write('3 ');
  
  { Start from 5 - first number of form 6k-1 }
  n := 5;
  
  while n <= 46225 do
  begin
    { Assume n is prime }
    is_prime := 1;
    
    { Calculate square root approximation }
    sqrt_approx := 1;
    while sqrt_approx * sqrt_approx <= n do
      sqrt_approx := sqrt_approx + 1;
    sqrt_approx := sqrt_approx - 1;
    
    { Test divisors of the form 6k +/- 1 only }
    divisor := 5;
    step := 2;  { Alternates between 2 and 4 }
    
    while divisor <= sqrt_approx do
    begin
      remainder := n - (n / divisor) * divisor;
      
      if remainder = 0 then
      begin
        is_prime := 0;
        divisor := sqrt_approx + 1;  { Break }
      end;
      
      { Move to next wheel position }
      divisor := divisor + step;
      if step = 2 then
        step := 4
      else
        step := 2;
    end;
    
    if is_prime = 1 then
      count := count + 1;
    
    { Show progress every 1000 numbers }
    rem1000 := n - (n / 1000) * 1000;
    if rem1000 = 0 then
    begin
      write('.');
      rem10000 := n - (n / 10000) * 10000;
      if rem10000 = 0 then
      begin
        writeln('');
        write('Reached ');
        writeln(n);
      end;
    end;
    
    { Move to next candidate: alternate adding 2 and 4 }
    if n - (n / 6) * 6 = 5 then
      n := n + 2
    else
      n := n + 4;
  end;
  
  writeln('');
  writeln('');
  write('Total primes found: ');
  writeln(count);
  writeln('');
  writeln('(Expected: 4792 primes up to 46225)');
end.
