:- module(parser, [parse_file/2, parse_tokens/2]).

:- use_module(lexer).

parse_file(Path, Program) :-
    lex_file(Path, Tokens),
    parse_tokens(Tokens, Program).

parse_tokens(Tokens, Program) :-
    (   phrase(program(Program), Tokens)
    ->  true
    ;   throw(error(syntax_error(invalid_pascal_program), _))
    ).

program(program(Name, Funcs, Vars, Block)) -->
    keyword(program),
    identifier(Name),
    symbol(';'),
    func_declarations(Funcs),
    declarations(Vars),
    block(Block),
    symbol('.'),
    [tok(eof, _, _)].

func_declarations(Funcs) -->
    keyword(function),
    !,
    func_decl(First),
    func_decls_rest(Rest),
    { append([First], Rest, Funcs) }.
func_declarations([]) -->
    [].

func_decls_rest(Funcs) -->
    keyword(function),
    !,
    func_decl(First),
    func_decls_rest(Rest),
    { append([First], Rest, Funcs) }.
func_decls_rest([]) -->
    [].

func_decl(func(Name, Params, LocalVars, Body)) -->
    identifier(Name),
    symbol('('),
    params(Params),
    symbol(')'),
    symbol(':'),
    keyword(integer),
    symbol(';'),
    declarations(LocalVars),
    block(Body),
    symbol(';').

params(Params) -->
    ident_list(Params),
    symbol(':'),
    keyword(integer),
    !.
params([]) -->
    [].

declarations(Vars) -->
    keyword(var),
    !,
    var_decls(Vars).
declarations([]) -->
    [].

var_decls(Vars) -->
    var_decl(Names),
    symbol(';'),
    !,
    var_decls(Rest),
    { append(Names, Rest, Vars) }.
var_decls([]) -->
    [].

var_decl(Names) -->
    ident_list(Names),
    symbol(':'),
    keyword(integer).

ident_list([Name|Rest]) -->
    identifier(Name),
    ident_list_tail(Rest).

ident_list_tail([Name|Rest]) -->
    symbol(','),
    !,
    identifier(Name),
    ident_list_tail(Rest).
ident_list_tail([]) -->
    [].

block(block(LocalVars, Stmts)) -->
    keyword(begin),
    block_declarations(LocalVars),
    stmt_list(Stmts),
    keyword(end).

block_declarations(Vars) -->
    keyword(var),
    !,
    var_decls(Vars).
block_declarations([]) -->
    [].

stmt_list([]) -->
    peek_keyword(end),
    !.
stmt_list([Stmt|Rest]) -->
    statement(Stmt),
    stmt_tail(Rest).

stmt_tail(Rest) -->
    symbol(';'),
    !,
    stmt_list(Rest).
stmt_tail([]) -->
    [].

statement(Stmt) -->
    block(Stmt),
    !.
statement(if(Cond, Then, Else)) -->
    keyword(if),
    expression(Cond),
    keyword(then),
    statement(Then),
    optional_else(Else),
    !.
statement(while(Cond, Body)) -->
    keyword(while),
    expression(Cond),
    keyword(do),
    statement(Body),
    !.
statement(writeln(Arg)) -->
    keyword(writeln),
    symbol('('),
    writeln_arg(Arg),
    symbol(')'),
    !.
% Enhanced write statements for stdlib - must come BEFORE basic write to match first
statement(write(Expr, Text)) -->
    keyword(write),
    symbol('('),
    expression(Expr),
    symbol(','),
    string_literal(Text),
    symbol(')'),
    !.
statement(write(Text, Expr)) -->
    keyword(write),
    symbol('('),
    string_literal(Text),
    symbol(','),
    expression(Expr),
    symbol(')'),
    !.
% statement(write_int_str_int(Expr1, Text, Expr2)) -->
%     keyword(write),
%     symbol('('),
%     expression(Expr1),
%     symbol(','),
%     string_literal(Text),
%     symbol(','),
%     expression(Expr2),
%     symbol(')'),
%     !.
% statement(write_format(Text, Expr1, Expr2, Expr3)) -->
%     keyword(write),
%     symbol('('),
%     string_literal(Text),
%     symbol(','),
%     expression(Expr1),
%     symbol(','),
%     expression(Expr2),
%     symbol(','),
%     expression(Expr3),
%     symbol(')'),
%     !.

% Basic write statement - must come after enhanced versions
statement(write(Arg)) -->
    keyword(write),
    symbol('('),
    writeln_arg(Arg),
    symbol(')'),
    !.

statement(readln(Name)) -->
    keyword(readln),
    symbol('('),
    identifier(Name),
    symbol(')'),
    !.
statement(assign(Name, Expr)) -->
    identifier(Name),
    symbol(':='),
    expression(Expr),
    !.

optional_else(Else) -->
    keyword(else),
    !,
    statement(Else).
optional_else(block([], [])) -->
    [].

expression(Expr) -->
    additive(Left),
    relational_tail(Left, Expr).

relational_tail(Left, Expr) -->
    rel_op(Op),
    !,
    additive(Right),
    { Expr = bin(Op, Left, Right) }.
relational_tail(Expr, Expr) -->
    [].

rel_op('=') --> symbol('=').
rel_op('<>') --> symbol('<>').
rel_op('<') --> symbol('<').
rel_op('<=') --> symbol('<=').
rel_op('>') --> symbol('>').
rel_op('>=') --> symbol('>=').

additive(Expr) -->
    multiplicative(Left),
    additive_tail(Left, Expr).

additive_tail(Acc, Expr) -->
    add_op(Op),
    !,
    multiplicative(Right),
    { Next = bin(Op, Acc, Right) },
    additive_tail(Next, Expr).
additive_tail(Expr, Expr) -->
    [].

add_op('+') --> symbol('+').
add_op('-') --> symbol('-').

multiplicative(Expr) -->
    unary(Left),
    multiplicative_tail(Left, Expr).

multiplicative_tail(Acc, Expr) -->
    mul_op(Op),
    !,
    unary(Right),
    { Next = bin(Op, Acc, Right) },
    multiplicative_tail(Next, Expr).
multiplicative_tail(Expr, Expr) -->
    [].

mul_op('*') --> symbol('*').
mul_op('/') --> symbol('/').
mul_op(mod) --> keyword(mod).

unary(unary('-', Expr)) -->
    symbol('-'),
    !,
    unary(Expr).
unary(Expr) -->
    primary(Expr).

primary(int(N)) -->
    [tok(int(N), _, _)],
    !.
primary(call(Name, Args)) -->
    identifier(Name),
    symbol('('),
    expr_list(Args),
    symbol(')'),
    !.
primary(var(Name)) -->
    identifier(Name),
    !.
primary(Expr) -->
    symbol('('),
    expression(Expr),
    symbol(')').

expr_list([Expr|Rest]) -->
    expression(Expr),
    expr_list_tail(Rest).
expr_list([]) -->
    [].

expr_list_tail([Expr|Rest]) -->
    symbol(','),
    !,
    expression(Expr),
    expr_list_tail(Rest).
expr_list_tail([]) -->
    [].

writeln_arg(str(Text)) -->
    string_literal(Text),
    !.
writeln_arg(expr(Expr)) -->
    expression(Expr).

keyword(K) -->
    [tok(kw(K), _, _)].

identifier(Name) -->
    [tok(ident(Name), _, _)].

symbol(S) -->
    [tok(sym(S), _, _)].

string_literal(Text) -->
    [tok(str(Text), _, _)].

peek_keyword(K, [tok(kw(K), _, _)|Tokens], [tok(kw(K), _, _)|Tokens]).
