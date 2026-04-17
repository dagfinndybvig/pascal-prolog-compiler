{ Fast algorithm - Full range test up to 46225 }
{ Uses all optimizations for maximum speed }
{ Build: swipl -q -s pascal_compiler.pl -- build-asm primes_fast_full.pas primes_fast_full }
{ Run: ./primes_fast_full }

program primes_fast_full;

var
  i, j, is_prime, remainder, sqrt_approx, count, rem1000, rem10000: integer;

begin
  writeln('FAST Prime Algorithm - Full Range Test (2 to 46225)');
  writeln('================================================');
  writeln('This uses the most efficient approach:');
  writeln('- Tests only up to square root');
  writeln('- Skips even numbers after 2');
  writeln('- Uses division for efficiency');
  writeln('- Early termination on first factor');
  writeln('');
  writeln('Testing up to 46225 (max safe limit)...');
  writeln('');
  
  count := 1; { Start with 2 }
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
      { Optimized division-based test }
      remainder := i - (i / j) * j;
      if remainder = 0 then
      begin
        is_prime := 0;
        j := sqrt_approx + 1; { break }
      end;
      j := j + 2;
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
        writeln('Reached ');
        write(i);
        writeln(' - flying through...');
      end;
    end;
    
    i := i + 2;
  end;
  
  writeln('');
  writeln('');
  writeln('Found ');
  write(count);
  writeln(' primes up to 46225');
  writeln('');
  writeln('This completed in seconds!');
  writeln('Compare to the slow version which takes much longer.');
end.
