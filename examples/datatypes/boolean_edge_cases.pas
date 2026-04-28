program boolean_edge_cases;

function bool_and(a, b: boolean): boolean;
begin
    bool_and := a and b;
end;

function bool_or(a, b: boolean): boolean;
begin
    bool_or := a or b;
end;

function bool_not(a: boolean): boolean;
begin
    bool_not := not a;
end;

function char_compare(a, b: char): boolean;
begin
    char_compare := a = b;
end;

function boolean_to_integer(b: boolean): integer;
begin
    if b then
        boolean_to_integer := 1
    else
        boolean_to_integer := 0;
end;

var
    b1, b2, b3: boolean;
    c1, c2: char;
    i: integer;

begin
    b1 := true;
    b2 := false;
    b3 := b1 and b2;

    { Test boolean operators }
    write('true and false = ', boolean_to_integer(b3)); writeln('');
    write('true or false = ', boolean_to_integer(b1 or b2)); writeln('');
    write('not true = ', boolean_to_integer(not b1)); writeln('');
    write('not false = ', boolean_to_integer(not b2)); writeln('');

    { Test boolean functions }
    write('bool_and(true, false) = ', boolean_to_integer(bool_and(b1, b2))); writeln('');
    write('bool_or(true, false) = ', boolean_to_integer(bool_or(b1, b2))); writeln('');
    write('bool_not(true) = ', boolean_to_integer(bool_not(b1))); writeln('');

    { Test char comparisons }
    c1 := 'A';
    c2 := 'B';
    write('''A'' = ''A''? ', boolean_to_integer(char_compare(c1, 'A'))); writeln('');
    write('''A'' = ''B''? ', boolean_to_integer(char_compare(c1, c2))); writeln('');
    write('''A'' < ''B''? ', boolean_to_integer(c1 < c2)); writeln('');
    write('''B'' > ''A''? ', boolean_to_integer(c2 > c1)); writeln('');

    { Test mixed expressions }
    i := 42;
    write('42 <> 0 = ', boolean_to_integer(i <> 0)); writeln('');
    write('0 <> 0 = ', boolean_to_integer(0 <> 0)); writeln('');

    { Test boolean return in condition }
    if bool_and(b1, not b2) then
        writeln('Boolean function in condition: PASS')
    else
        writeln('Boolean function in condition: FAIL');

    writeln('Boolean edge cases test completed.');
end.
