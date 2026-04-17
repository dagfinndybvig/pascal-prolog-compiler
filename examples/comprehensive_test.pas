program comprehensive_test;

var
  a, b, c, result, temp, user_input: integer;

begin
  { Test basic arithmetic }
  a := 10;
  b := 20;
  c := a + b;
  writeln(c);
  
  { Test more arithmetic operations }
  result := a * b;
  writeln(result);
  
  result := b / a;
  writeln(result);
  
  { Test complex expression }
  result := ((a + b) * 2) / 3;
  writeln(result);
  
  { Test unary operations }
  temp := -a;
  writeln(temp);
  
  temp := -(-b);
  writeln(temp);
  
  { Test relational operators }
  if a < b then
    writeln(1)
  else
    writeln(0);
  
  if a = 10 then
    writeln(1)
  else
    writeln(0);
  
  if b >= a then
    writeln(1)
  else
    writeln(0);
  
  { Test nested blocks }
  begin
    var inner: integer;
    inner := a + b;
    writeln(inner)
  end;
  
  { Test while loop }
  temp := 0;
  c := 1;
  while c <= 5 do
  begin
    temp := temp + c;
    c := c + 1
  end;
  writeln(temp);
  
  { Test input operations }
  write('Enter a number: ');
  readln(user_input);
  write('You entered: ');
  writeln(user_input);
  
  { Use input in calculation }
  result := user_input * 2;
  write('Double of your input: ');
  writeln(result);
  
  { Test string output }
  writeln('Test completed successfully!')
end.
