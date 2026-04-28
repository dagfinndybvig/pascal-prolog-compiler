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
    top_level_declarations(Funcs, Vars),
    block(Block),
    symbol('.'),
    [tok(eof, _, _)].

top_level_declarations(Funcs, Vars) -->
    declarations(Vars),
    func_declarations(Funcs).
top_level_declarations(Funcs, Vars) -->
    func_declarations(Funcs),
    declarations(Vars).

func_declarations([First|Rest]) -->
    subprogram_decl(First),
    !,
    func_declarations(Rest).
func_declarations([]) -->
    [].

subprogram_decl(Decl) -->
    keyword(function),
    !,
    func_decl(Decl).
subprogram_decl(Decl) -->
    keyword(procedure),
    proc_decl(Decl).

func_decl(func(Name, Params, ReturnType, LocalVars, Body)) -->
    identifier(Name),
    symbol('('),
    params(Params),
    symbol(')'),
    symbol(':'),
    type_spec(ReturnType),
    symbol(';'),
    declarations(LocalVars),
    block(Body),
    symbol(';').

proc_decl(func(Name, Params, void, LocalVars, Body)) -->
    identifier(Name),
    symbol('('),
    params(Params),
    symbol(')'),
    symbol(';'),
    declarations(LocalVars),
    block(Body),
    symbol(';').
proc_decl(func(Name, [], void, LocalVars, Body)) -->
    identifier(Name),
    symbol(';'),
    declarations(LocalVars),
    block(Body),
    symbol(';').

params(Params) -->
    param_segment(First),
    param_segments_rest(Rest),
    !,
    { append(First, Rest, Params) }.
params([]) -->
    [].

param_segments_rest(Params) -->
    symbol(';'),
    !,
    param_segment(First),
    param_segments_rest(Rest),
    { append(First, Rest, Params) }.
param_segments_rest([]) -->
    [].

param_segment(Params) -->
    keyword(var),
    !,
    ident_list(Names),
    symbol(':'),
    type_spec(Type),
    { make_var_params(Names, Type, Params) }.
param_segment(Params) -->
    ident_list(Names),
    symbol(':'),
    type_spec(Type),
    { make_params(Names, Type, Params) }.

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
    ident_list(RawNames),
    symbol(':'),
    type_spec(Type),
    { make_decls(RawNames, Type, Names) }.

type_spec(integer) -->
    keyword(integer).
type_spec(boolean) -->
    keyword(boolean).
type_spec(char) -->
    keyword(char).
type_spec(array(Low, High, ElementType)) -->
    keyword(array),
    symbol('['),
    [tok(int(Low), _, _)],
    symbol('..'),
    [tok(int(High), _, _)],
    symbol(']'),
    keyword(of),
    scalar_type_spec(ElementType).

scalar_type_spec(integer) -->
    keyword(integer).
scalar_type_spec(boolean) -->
    keyword(boolean).
scalar_type_spec(char) -->
    keyword(char).

make_params([], _, []).
make_params([Name|Names], Type, [param(Name, Type)|Params]) :-
    make_params(Names, Type, Params).

make_var_params([], _, []).
make_var_params([Name|Names], Type, [param_var(Name, Type)|Params]) :-
    make_var_params(Names, Type, Params).

make_decls([], _, []).
make_decls([Name|Names], Type, [decl(Name, Type)|Decls]) :-
    make_decls(Names, Type, Decls).

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
statement(case_stmt(Selector, Branches, ElseBody)) -->
    keyword(case),
    expression(Selector),
    keyword(of),
    case_branches(Branches),
    case_else(ElseBody),
    keyword(end),
    !.
statement(for_loop(Name, Start, End, Dir, Body)) -->
    keyword(for),
    [tok(ident(Name), _, _)],
    symbol(:=),
    expression(Start),
    for_direction(Dir),
    expression(End),
    keyword(do),
    statement(Body),
    !.
statement(writeln(Arg)) -->
    keyword(writeln),
    symbol('('),
    writeln_args([Arg|RestArgs]),
    { RestArgs == [] },
    symbol(')'),
    !.
statement(writeln_multi([A,B|Rest])) -->
    keyword(writeln),
    symbol('('),
    writeln_args([A,B|Rest]),
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

% Basic write statement - must come after enhanced versions
statement(write(Arg)) -->
    keyword(write),
    symbol('('),
    writeln_args([Arg|RestArgs]),
    { RestArgs == [] },
    symbol(')'),
    !.
statement(write_multi([A,B|Rest])) -->
    keyword(write),
    symbol('('),
    writeln_args([A,B|Rest]),
    symbol(')'),
    !.

statement(readln(Name)) -->
    keyword(readln),
    symbol('('),
    identifier(Name),
    symbol(')'),
    !.
statement(proc_call(Name, Args)) -->
    identifier(Name),
    symbol('('),
    expr_list(Args),
    symbol(')'),
    !.
statement(proc_call(Name, [])) -->
    identifier(Name),
    peek_proc_call_end,
    !.
statement(assign_index(Name, IndexExpr, Expr)) -->
    identifier(Name),
    symbol('['),
    expression(IndexExpr),
    symbol(']'),
    symbol(':='),
    expression(Expr),
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

for_direction(to) --> keyword(to), !.
for_direction(downto) --> keyword(downto).

case_branches([Branch|Rest]) -->
    case_branch(Branch),
    case_branches_tail(Rest).

case_branches_tail([Branch|Rest]) -->
    symbol(';'),
    peek_not_case_end,
    !,
    case_branch(Branch),
    case_branches_tail(Rest).
case_branches_tail([]) --> [].

case_branch(case_branch(Labels, Body)) -->
    case_labels(Labels),
    symbol(':'),
    statement(Body).

case_labels([Label|Rest]) -->
    case_label(Label),
    case_labels_tail(Rest).

case_labels_tail([Label|Rest]) -->
    symbol(','),
    !,
    case_label(Label),
    case_labels_tail(Rest).
case_labels_tail([]) --> [].

case_label(label_const(int(N))) -->
    symbol('-'),
    [tok(int(M), _, _)],
    !,
    { N is -M }.
case_label(label_const(int(N))) -->
    [tok(int(N), _, _)],
    !.
case_label(label_const(char(Code))) -->
    [tok(str(Text), _, _)],
    { string_length(Text, 1), string_codes(Text, [Code]) },
    !.

case_else(Body) -->
    keyword(else),
    !,
    statement(Body).
case_else(block([], [])) --> [].

peek_not_case_end(Stream, Stream) :-
    \+ next_is_case_end(Stream).
next_is_case_end([tok(kw(else), _, _)|_]).
next_is_case_end([tok(kw(end), _, _)|_]).

expression(Expr) -->
    disjunction(Expr).

disjunction(Expr) -->
    conjunction(Left),
    disjunction_tail(Left, Expr).

disjunction_tail(Acc, Expr) -->
    keyword(or),
    !,
    conjunction(Right),
    { Next = bin(or, Acc, Right) },
    disjunction_tail(Next, Expr).
disjunction_tail(Expr, Expr) -->
    [].

conjunction(Expr) -->
    relational(Left),
    conjunction_tail(Left, Expr).

conjunction_tail(Acc, Expr) -->
    keyword(and),
    !,
    relational(Right),
    { Next = bin(and, Acc, Right) },
    conjunction_tail(Next, Expr).
conjunction_tail(Expr, Expr) -->
    [].

relational(Expr) -->
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
unary(unary(not, Expr)) -->
    keyword(not),
    !,
    unary(Expr).
unary(Expr) -->
    primary(Expr).

primary(int(N)) -->
    [tok(int(N), _, _)],
    !.
primary(bool(1)) -->
    keyword(true),
    !.
primary(bool(0)) -->
    keyword(false),
    !.
primary(char(Code)) -->
    [tok(str(Text), _, _)],
    { string_length(Text, 1),
      string_codes(Text, [Code])
    },
    !.
primary(call(Name, Args)) -->
    identifier(Name),
    symbol('('),
    expr_list(Args),
    symbol(')'),
    !.
primary(array_ref(Name, IndexExpr)) -->
    identifier(Name),
    symbol('['),
    expression(IndexExpr),
    symbol(']'),
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

writeln_args([Arg|Rest]) -->
    writeln_arg(Arg),
    writeln_args_tail(Rest).

writeln_args_tail([Arg|Rest]) -->
    symbol(','),
    !,
    writeln_arg(Arg),
    writeln_args_tail(Rest).
writeln_args_tail([]) -->
    [].

keyword(K) -->
    [tok(kw(K), _, _)].

identifier(Name) -->
    [tok(ident(Name), _, _)].

symbol(S) -->
    [tok(sym(S), _, _)].

string_literal(Text) -->
    [tok(str(Text), _, _)].

peek_keyword(K, [tok(kw(K), _, _)|Tokens], [tok(kw(K), _, _)|Tokens]).

peek_proc_call_end([tok(sym(';'), L, C)|T], [tok(sym(';'), L, C)|T]).
peek_proc_call_end([tok(sym('.'), L, C)|T], [tok(sym('.'), L, C)|T]).
peek_proc_call_end([tok(kw(end), L, C)|T], [tok(kw(end), L, C)|T]).
peek_proc_call_end([tok(kw(else), L, C)|T], [tok(kw(else), L, C)|T]).
