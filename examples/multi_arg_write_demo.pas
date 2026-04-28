program MultiArgWriteDemo;

var
  name: array[1..5] of char;
  score, bonus: integer;

begin
  name[1] := 'A'; name[2] := 'l'; name[3] := 'i';
  name[4] := 'c'; name[5] := 'e';

  score := 42;
  bonus := 8;

  writeln('Player: ', name);
  writeln('Score: ', score, ' (+', bonus, ' bonus)');
  writeln('Total: ', score + bonus);

  write('Status: ');
  writeln('OK')
end.
