{ Odds-Only Prime Algorithm - Full Range Test (2 to 46225) }
{ Tests only odd divisors, skipping even numbers after 2 }
{ This is the baseline for comparing 6k +/- 1 optimization }
{ Build: swipl -q -s pascal_compiler.pl -- build-asm primes_odds_only_full.pas primes_odds_only_full }
{ Run: time ./primes_odds_only_full }
{ Implemented by Kimi }

program primes_odds_only_full;

var
  i, j, is_prime, remainder, sqrt_approx, count, rem1000, rem10000: integer;

begin
  writeln('Odds-Only Prime Algorithm - Full Range Test (2 to 46225)');
  writeln('=========================================================');
  writeln('');
  writeln('Baseline: Tests only odd numbers as potential divisors');
  writeln('Skips even numbers, but still checks multiples of 3 (9, 15, 21...)');
  writeln('');
  writeln('Testing up to 46225 (max safe limit)...');
  writeln('');
  
  count := 1;  { Count 2 separately }
  write('2 ');
  
  { Test odd numbers from 3 to 46225 }
  i := 3;
  
  while i <= 46225 do
  begin
    { Assume prime }
    is_prime := 1;
    
    { Calculate square root approximation }
    sqrt_approx := 1;
    while sqrt_approx * sqrt_approx <= i do
      sqrt_approx := sqrt_approx + 1;
    sqrt_approx := sqrt_approx - 1;
    
    { Test only odd numbers from 3 to sqrt_approx }
    j := 3;
    while j <= sqrt_approx do
    begin
      remainder := i - (i / j) * j;
      if remainder = 0 then
      begin
        is_prime := 0;
        j := sqrt_approx + 1;  { Break }
      end;
      j := j + 2;  { Skip even divisors }
    end;
    
    if is_prime = 1 then
      count := count + 1;
    
    { Show progress every 1000 numbers }
    rem1000 := i - (i / 1000) * 1000;
    if rem1000 = 0 then
    begin
      write('.');
      rem10000 := i - (i / 10000) * 10000;
      if rem10000 = 0 then
      begin
        writeln('');
        write('Reached ');
        writeln(i);
      end;
    end;
    
    i := i + 2;  { Skip even numbers }
  end;
  
  writeln('');
  writeln('');
  write('Total primes found: ');
  writeln(count);
  writeln('');
  writeln('(Compare timing with 6k +/- 1 wheel algorithm)');
end.
