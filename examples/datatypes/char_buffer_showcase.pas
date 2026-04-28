program char_buffer_showcase;

function fill_message(): boolean;
begin
  message[1] := 'P';
  message[2] := 'a';
  message[3] := 's';
  message[4] := 'c';
  message[5] := 'a';
  message[6] := 'l';
  fill_message := true
end;

var
  message: array[1..6] of char;

begin
  if fill_message() then
    writeln(message)
  else
    writeln('F')
end.
