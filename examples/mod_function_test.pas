{ Test program that invokes a function using the mod operator
  Expected output: 1 (since 10 mod 3 = 1)
}

program mod_function_test;

function calculate_remainder(a, b: integer): integer;
begin
  calculate_remainder := a mod b
end;

var result: integer;

begin
  result := calculate_remainder(10, 3);
  writeln(result)
end.