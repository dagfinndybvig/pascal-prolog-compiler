{ Expression Register Allocation Stress Test }
{ Forces register spilling with deeply nested expressions }
{ Tests: register allocation, complex evaluation order }

program expr_register_stress;
var
  a, b, c, d, e, f, g, h, result: integer;
begin
  a := 1; b := 2; c := 3; d := 4;
  e := 5; f := 6; g := 7; h := 8;

  { Expression requiring many registers }
  result := (((a + b) * (c + d)) - ((e + f) * (g + h))) /
            (((a - b) + (c - d)) * ((e - f) + (g - h)));

  writeln(result);  { Expected: -36 }

  { Another deep nesting }
  result := a + b * c - d / e + f * g - h +
            a * (b + c * (d - e / (f + g * h)));

  writeln(result)   { Expected: 55 }
end.
