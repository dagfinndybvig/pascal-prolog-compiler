program CaseDemo;

var
  n, i: integer;
  grade: char;

begin
  for i := 1 to 6 do
  begin
    case i of
      1: writeln('one');
      2, 3: writeln('two or three');
      4: writeln('four');
      5: writeln('five')
    else
      writeln('other: ', i)
    end
  end;

  grade := 'B';
  case grade of
    'A': writeln('excellent');
    'B': writeln('good');
    'C': writeln('ok')
  else
    writeln('unknown grade')
  end;

  n := -1;
  case n of
    0: writeln('zero');
    -1: writeln('negative one')
  else
    writeln('other number')
  end
end.
