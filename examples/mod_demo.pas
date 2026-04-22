{ Mod operator demonstration
  The mod operator returns the remainder of integer division.
  
  Expected output:
  2
  6
  0
  1
}

program mod_demo;

function is_even(n: integer): integer;
begin
  if (n mod 2) = 0 then
    is_even := 1
  else
    is_even := 0
end;

var a, b: integer;
begin
  { Basic mod operations }
  a := 17;
  b := 5;
  writeln(a mod b);  { 17 mod 5 = 2 }
  
  a := 20;
  b := 7;
  writeln(a mod b);  { 20 mod 7 = 6 }
  
  a := 100;
  b := 10;
  writeln(a mod b);  { 100 mod 10 = 0 }
  
  { Using mod in a function }
  writeln(is_even(42))  { 42 is even, so returns 1 }
end.
