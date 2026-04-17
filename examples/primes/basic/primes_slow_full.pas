{ Slowest algorithm - Full range test up to 46225 }
{ This will be VERY slow but demonstrates the need for optimization }
{ Build: swipl -q -s pascal_compiler.pl -- build-asm primes_slow_full.pas primes_slow_full }
{ Run: ./primes_slow_full }

program primes_slow_full;

var
  i, j, is_prime, temp, is_divisible, count, rem1000, rem10000: integer;

begin
  writeln('SLOW Prime Algorithm - Full Range Test (2 to 46225)');
  writeln('================================================');
  writeln('This uses the least efficient approach:');
  writeln('- Tests ALL numbers from 2 to n-1');
  writeln('- Uses repeated subtraction (no division)');
  writeln('- No square root optimization');
  writeln('- No skipping of even numbers');
  writeln('');
  writeln('WARNING: This will take a LONG time!');
  writeln('Testing up to 46225 (max safe limit)...');
  writeln('');
  
  count := 0;
  i := 2;
  
  { Test up to the maximum safe limit }
  while i <= 46225 do
  begin
    { Assume prime }
    is_prime := 1;
    
    { Test ALL numbers from 2 to i-1 (very inefficient) }
    j := 2;
    while j < i do
    begin
      { Naive subtraction-based divisibility test }
      is_divisible := 0;
      temp := i;
      while temp >= j do
      begin
        temp := temp - j;
        if temp = 0 then
          is_divisible := 1;
      end;
      
      if is_divisible = 1 then
      begin
        is_prime := 0;
        j := i; { break early }
      end;
      j := j + 1;
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
        writeln(' - still going...');
      end;
    end;
    
    i := i + 1;
  end;
  
  writeln('');
  writeln('');
  writeln('Found ');
  write(count);
  writeln(' primes up to 46225');
  writeln('');
  writeln('Compare this to the optimized version which');
  writeln('finds the same result in seconds!');
end.
