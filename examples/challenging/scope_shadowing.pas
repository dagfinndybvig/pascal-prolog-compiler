{ Deeply Nested Scope Shadowing Test }
{ Tests variable allocation, scope isolation, name mangling }
{ Each 'x' should be independent }

program scope_shadowing;
var
  x, sum: integer;
begin
  x := 1;
  sum := 0;

  begin
    var x: integer;
    x := 10;
    sum := sum + x;  { sum = 10 }

    begin
      var x: integer;
      x := 100;
      sum := sum + x;  { sum = 110 }

      begin
        var x: integer;
        x := 1000;
        sum := sum + x   { sum = 1110 }
      end;

      sum := sum + x   { sum = 1210, x = 100 here }
    end;

    sum := sum + x   { sum = 1220, x = 10 here }
  end;

  sum := sum + x;  { sum = 1221, x = 1 here }
  writeln(sum)     { Expected: 1221 }
end.
