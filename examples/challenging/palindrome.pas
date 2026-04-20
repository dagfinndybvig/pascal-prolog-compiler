{ Palindrome Number Check }
{ Reverses digits using / and mod operations }
{ Tests: digit extraction, number reconstruction }

program palindrome;
var
  n, original, reversed, remainder, temp: integer;
begin
  { Check if 12321 is a palindrome }
  n := 12321;
  original := n;
  reversed := 0;

  while n > 0 do
  begin
    { Extract last digit: n mod 10 }
    temp := n / 10;
    remainder := n - temp * 10;

    { Build reversed number }
    reversed := reversed * 10 + remainder;

    { Remove last digit }
    n := temp
  end;

  writeln(reversed);  { Expected: 12321 }

  if original = reversed then
    writeln(1)  { Expected: 1 (is palindrome) }
  else
    writeln(0);

  { Test non-palindrome: 12345 }
  n := 12345;
  original := n;
  reversed := 0;

  while n > 0 do
  begin
    temp := n / 10;
    remainder := n - temp * 10;
    reversed := reversed * 10 + remainder;
    n := temp
  end;

  writeln(reversed);  { Expected: 54321 }

  if original = reversed then
    writeln(1)
  else
    writeln(0)  { Expected: 0 (not palindrome) }
end.
