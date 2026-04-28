:- module(lexer, [lex_file/2, lex_string/2]).

:- use_module(library(readutil)).

lex_file(Path, Tokens) :-
    read_file_to_string(Path, Source, []),
    lex_string(Source, Tokens).

lex_string(Source, Tokens) :-
    string_codes(Source, Codes),
    lex_codes(Codes, 1, 1, Tokens).

lex_codes([], Line, Col, [tok(eof, Line, Col)]).
lex_codes([C|Cs], Line, Col, Tokens) :-
    (   code_type(C, space)
    ->  advance_space(C, Line, Col, NextLine, NextCol),
        lex_codes(Cs, NextLine, NextCol, Tokens)
    ;   C =:= 0'{
    ->  skip_brace_comment(Cs, Line, Col, Rest, NextLine, NextCol),
        lex_codes(Rest, NextLine, NextCol, Tokens)
    ;   C =:= 0'/, Cs = [0'/|Tail]
    ->  skip_line_comment(Tail, Line, Col, Rest, NextLine, NextCol),
        lex_codes(Rest, NextLine, NextCol, Tokens)
    ;   C =:= 0''
    ->  consume_string_literal(Cs, Rest, StringCodes, Used),
        string_codes(Text, StringCodes),
        Tokens = [tok(str(Text), Line, Col)|More],
        NextCol is Col + 1 + Used,
        lex_codes(Rest, Line, NextCol, More)
    ;   ident_start(C)
    ->  consume_ident(Cs, Rest, IdentCodes),
        atom_codes(Atom0, [C|IdentCodes]),
        downcase_atom(Atom0, Atom),
        keyword_or_ident(Atom, Token),
        Tokens = [tok(Token, Line, Col)|More],
        length([C|IdentCodes], Len),
        NextCol is Col + Len,
        lex_codes(Rest, Line, NextCol, More)
    ;   code_type(C, digit)
    ->  consume_digits(Cs, Rest, DigitCodes),
        number_codes(N, [C|DigitCodes]),
        Tokens = [tok(int(N), Line, Col)|More],
        length([C|DigitCodes], Len),
        NextCol is Col + Len,
        lex_codes(Rest, Line, NextCol, More)
    ;   consume_symbol(C, Cs, Rest, Sym, Used),
        Tokens = [tok(sym(Sym), Line, Col)|More],
        NextCol is Col + Used,
        lex_codes(Rest, Line, NextCol, More)
    ).

advance_space(0'\n, Line, _, NextLine, 1) :-
    NextLine is Line + 1.
advance_space(_, Line, Col, Line, NextCol) :-
    NextCol is Col + 1.

skip_brace_comment([], _, _, _, _, _) :-
    throw(error(syntax_error(unclosed_comment), _)).
skip_brace_comment([0'}|Rest], Line, Col, Rest, Line, NextCol) :-
    NextCol is Col + 2.
skip_brace_comment([C|Cs], Line, Col, Rest, NextLine, NextCol) :-
    advance_space(C, Line, Col, L1, C1),
    skip_brace_comment(Cs, L1, C1, Rest, NextLine, NextCol).

skip_line_comment([], Line, Col, [], Line, NextCol) :-
    NextCol is Col + 2.
skip_line_comment([0'\n|Rest], Line, _, Rest, NextLine, 1) :-
    NextLine is Line + 1.
skip_line_comment([_|Cs], Line, Col, Rest, NextLine, NextCol) :-
    Col1 is Col + 1,
    skip_line_comment(Cs, Line, Col1, Rest, NextLine, NextCol).

consume_string_literal([], _, _, _) :-
    throw(error(syntax_error(unclosed_string_literal), _)).
consume_string_literal([0'\n|_], _, _, _) :-
    throw(error(syntax_error(newline_in_string_literal), _)).
consume_string_literal([0''', 0'''|Cs], Rest, [0'''|More], Used) :-
    !,
    consume_string_literal(Cs, Rest, More, Used0),
    Used is Used0 + 2.
consume_string_literal([0'''|Rest], Rest, [], 1) :-
    !.
consume_string_literal([C|Cs], Rest, [C|More], Used) :-
    consume_string_literal(Cs, Rest, More, Used0),
    Used is Used0 + 1.

ident_start(C) :-
    code_type(C, alpha)
    ;
    C =:= 0'_.

ident_continue(C) :-
    code_type(C, alnum)
    ;
    C =:= 0'_.

consume_ident([C|Cs], Rest, [C|More]) :-
    ident_continue(C),
    !,
    consume_ident(Cs, Rest, More).
consume_ident(Rest, Rest, []).

consume_digits([C|Cs], Rest, [C|More]) :-
    code_type(C, digit),
    !,
    consume_digits(Cs, Rest, More).
consume_digits(Rest, Rest, []).

keyword_or_ident(program, kw(program)) :- !.
keyword_or_ident(var, kw(var)) :- !.
keyword_or_ident(integer, kw(integer)) :- !.
keyword_or_ident(boolean, kw(boolean)) :- !.
keyword_or_ident(char, kw(char)) :- !.
keyword_or_ident(array, kw(array)) :- !.
keyword_or_ident(of, kw(of)) :- !.
keyword_or_ident(true, kw(true)) :- !.
keyword_or_ident(false, kw(false)) :- !.
keyword_or_ident(begin, kw(begin)) :- !.
keyword_or_ident(end, kw(end)) :- !.
keyword_or_ident(if, kw(if)) :- !.
keyword_or_ident(then, kw(then)) :- !.
keyword_or_ident(else, kw(else)) :- !.
keyword_or_ident(while, kw(while)) :- !.
keyword_or_ident(do, kw(do)) :- !.
keyword_or_ident(for, kw(for)) :- !.
keyword_or_ident(to, kw(to)) :- !.
keyword_or_ident(downto, kw(downto)) :- !.
keyword_or_ident(writeln, kw(writeln)) :- !.
keyword_or_ident(write, kw(write)) :- !.
keyword_or_ident(readln, kw(readln)) :- !.
keyword_or_ident(function, kw(function)) :- !.
keyword_or_ident(procedure, kw(procedure)) :- !.
keyword_or_ident(mod, kw(mod)) :- !.
keyword_or_ident(and, kw(and)) :- !.
keyword_or_ident(or, kw(or)) :- !.
keyword_or_ident(not, kw(not)) :- !.
keyword_or_ident(Atom, ident(Atom)).

consume_symbol(0':, [0'=|Rest], Rest, ':=', 2) :- !.
consume_symbol(0'<, [0'=|Rest], Rest, '<=', 2) :- !.
consume_symbol(0'>, [0'=|Rest], Rest, '>=', 2) :- !.
consume_symbol(0'<, [0'>|Rest], Rest, '<>', 2) :- !.
consume_symbol(0'., [0'.|Rest], Rest, '..', 2) :- !.
consume_symbol(0';, Rest, Rest, ';', 1) :- !.
consume_symbol(0':, Rest, Rest, ':', 1) :- !.
consume_symbol(0',, Rest, Rest, ',', 1) :- !.
consume_symbol(0'., Rest, Rest, '.', 1) :- !.
consume_symbol(0'(, Rest, Rest, '(', 1) :- !.
consume_symbol(0'), Rest, Rest, ')', 1) :- !.
consume_symbol(0'[, Rest, Rest, '[', 1) :- !.
consume_symbol(0'], Rest, Rest, ']', 1) :- !.
consume_symbol(0'+, Rest, Rest, '+', 1) :- !.
consume_symbol(0'-, Rest, Rest, '-', 1) :- !.
consume_symbol(0'*, Rest, Rest, '*', 1) :- !.
consume_symbol(0'/, Rest, Rest, '/', 1) :- !.
consume_symbol(0'=, Rest, Rest, '=', 1) :- !.
consume_symbol(0'<, Rest, Rest, '<', 1) :- !.
consume_symbol(0'>, Rest, Rest, '>', 1) :- !.
consume_symbol(Char, _, _, _, _) :-
    throw(error(syntax_error(unexpected_character(Char)), _)).
