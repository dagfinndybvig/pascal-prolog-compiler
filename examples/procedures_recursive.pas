program procedures_recursive;

procedure countdown(n: integer);
begin
  if n > 0 then
  begin
    writeln(n);
    countdown(n - 1)
  end
  else
    writeln('done')
end;

begin
  countdown(3)
end.
