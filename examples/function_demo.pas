{ Function Demonstration Program
  Shows various function features including:
  - Simple functions with multiple parameters
  - Recursive functions (factorial)
  - Function calls within expressions
  - Nested function calls
  
  Expected output:
  7
  30
  120
  16
  55
}

program function_demo;

function add(a, b: integer): integer;
begin
  add := a + b
end;

function multiply(x, y: integer): integer;
begin
  multiply := x * y
end;

function factorial(n: integer): integer;
begin
  if n <= 1 then
    factorial := 1
  else
    factorial := n * factorial(n - 1)
end;

function sum_of_squares(a, b: integer): integer;
begin
  sum_of_squares := multiply(a, a) + multiply(b, b)
end;

function fibonacci(n: integer): integer;
begin
  if n <= 0 then
    fibonacci := 0
  else if n = 1 then
    fibonacci := 1
  else
    fibonacci := fibonacci(n - 1) + fibonacci(n - 2)
end;

var result: integer;
begin
  { Test 1: Simple addition }
  result := add(3, 4);
  writeln(result);
  
  { Test 2: Multiplication }
  result := multiply(5, 6);
  writeln(result);
  
  { Test 3: Factorial (recursive) }
  result := factorial(5);
  writeln(result);
  
  { Test 4: Nested function calls }
  result := add(multiply(2, 3), 10);
  writeln(result);
  
  { Test 5: Fibonacci (recursive) }
  result := fibonacci(10);
  writeln(result)
end.

