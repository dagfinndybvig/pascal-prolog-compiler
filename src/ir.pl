:- module(ir, [lower_program/2]).

:- discontiguous lower_stmt/6.
:- dynamic func_return_type/2.

lower_program(program(Name, Funcs, Vars, Block), ir_program(Name, IRFuncs, AllVars, IRStmts)) :-
    init_func_return_types(Funcs),
    vars_env(Vars, GlobalEnv),
    lower_funcs(Funcs, GlobalEnv, IRFuncs),
    lower_block(Block, GlobalEnv, 0, _CounterOut, IRStmts, LocalVars),
    append(Vars, LocalVars, AllVars).

init_func_return_types(Funcs) :-
    retractall(func_return_type(_, _)),
    forall(member(func(FuncName, _Params, ReturnType, _LocalVars, _Body), Funcs),
           assertz(func_return_type(FuncName, ReturnType))).

decl_name(decl(Name, _), Name).
decl_name(param(Name, _), Name).

decl_type(decl(_, Type), Type).
decl_type(param(_, Type), Type).

rename_decl(decl(_, Type), MappedName, decl(MappedName, Type)).
rename_decl(param(_, Type), MappedName, param(MappedName, Type)).

vars_env([], []).
vars_env([Decl|Vars], [Name-MappedName-Type|EnvTail]) :-
    decl_name(Decl, Name),
    decl_type(Decl, Type),
    MappedName = Name,
    vars_env(Vars, EnvTail).

lower_funcs([], _, []).
lower_funcs([func(Name, Params, ReturnType, FuncLocalVars, block(BlockLocalVars, Stmts))|Rest], GlobalEnv, [ir_func(Name, Params, ReturnType, FuncLocals, IRBody)|IRFuncsRest]) :-
    vars_env(Params, ParamEnv),
    (   ReturnType == void
    ->  FuncEnv0 = ParamEnv
    ;   append(ParamEnv, [Name-Name-ReturnType], FuncEnv0)
    ),
    vars_env(FuncLocalVars, LocalEnv),
    append(FuncEnv0, LocalEnv, FuncEnv1),
    append(FuncEnv1, GlobalEnv, FuncEnv),
    append(FuncLocalVars, BlockLocalVars, AllLocalVars),
    lower_block(block(AllLocalVars, Stmts), FuncEnv, 0, _CounterOut, IRBody, FuncLocals),
    lower_funcs(Rest, GlobalEnv, IRFuncsRest).

lower_block(block(LocalVars, Stmts), ParentEnv, CounterIn, CounterOut, IRStmts, AddedVars) :-
    allocate_locals(LocalVars, CounterIn, CounterNext, LocalMappings, LocalAllocations),
    append(LocalMappings, ParentEnv, ScopeEnv),
    lower_stmts(Stmts, ScopeEnv, CounterNext, CounterOut, IRStmts, NestedAllocations),
    append(LocalAllocations, NestedAllocations, AddedVars).

allocate_locals([], Counter, Counter, [], []).
allocate_locals([Decl|Vars], CounterIn, CounterOut, [Name-Mangled-Type|MapTail], [TypedMangled|AllocTail]) :-
    decl_name(Decl, Name),
    decl_type(Decl, Type),
    Mangled = local(CounterIn, Name),
    rename_decl(Decl, Mangled, TypedMangled),
    CounterNext is CounterIn + 1,
    allocate_locals(Vars, CounterNext, CounterOut, MapTail, AllocTail).

lower_stmts([], _Env, Counter, Counter, [], []).
lower_stmts([Stmt|Rest], Env, CounterIn, CounterOut, [IRStmt|IRRest], AddedVars) :-
    lower_stmt(Stmt, Env, CounterIn, CounterNext, IRStmt, AddedHere),
    lower_stmts(Rest, Env, CounterNext, CounterOut, IRRest, AddedTail),
    append(AddedHere, AddedTail, AddedVars).

lower_stmt(assign(Name, Expr), Env, Counter, Counter, ir_assign(MappedName, IRExpr), []) :-
    map_name(Name, Env, MappedName),
    lower_expr(Expr, Env, IRExpr).
lower_stmt(assign_index(Name, IndexExpr, Expr), Env, Counter, Counter, ir_array_store(MappedName, Low, High, IRIndex, IRExpr), []) :-
    map_name(Name, Env, MappedName),
    lookup_type(Name, Env, array(Low, High, _ElementType)),
    lower_expr(IndexExpr, Env, IRIndex, integer),
    lower_expr(Expr, Env, IRExpr, _).
lower_stmt(if(Cond, Then, Else), Env, CounterIn, CounterOut, ir_if(IRCond, IRThen, IRElse), AddedVars) :-
    lower_expr(Cond, Env, IRCond),
    lower_stmt(Then, Env, CounterIn, CounterThen, IRThen, AddedThen),
    lower_stmt(Else, Env, CounterThen, CounterOut, IRElse, AddedElse),
    append(AddedThen, AddedElse, AddedVars).
lower_stmt(while(Cond, Body), Env, CounterIn, CounterOut, ir_while(IRCond, IRBody), AddedVars) :-
    lower_expr(Cond, Env, IRCond),
    lower_stmt(Body, Env, CounterIn, CounterOut, IRBody, AddedVars).
lower_stmt(writeln(expr(Expr)), Env, Counter, Counter, IRStmt, []) :-
    lower_expr(Expr, Env, IRExpr, Type),
    output_stmt(writeln, Type, IRExpr, IRStmt).
lower_stmt(writeln(str(Text)), _Env, Counter, Counter, ir_writeln_str(Text), []).
lower_stmt(write(expr(Expr)), Env, Counter, Counter, IRStmt, []) :-
    lower_expr(Expr, Env, IRExpr, Type),
    output_stmt(write, Type, IRExpr, IRStmt).
lower_stmt(write(str(Text)), _Env, Counter, Counter, ir_write_str(Text), []).

% Enhanced write statements for stdlib
lower_stmt(write(Expr, Text), Env, Counter, Counter, ir_write_int_str(IRExpr, StringContent), []) :-
    lower_expr(Expr, Env, IRExpr, integer),
    extract_string_content(Text, StringContent).

extract_string_content(str(Text), Text) :- !.
extract_string_content(Text, Text).

normalize_string_literal(str(Text), str(Text)) :- !.
normalize_string_literal(Text, str(Text)).
lower_stmt(write(Text, Expr), Env, Counter, Counter, ir_write_str_int(StringContent, IRExpr), []) :-
    lower_expr(Expr, Env, IRExpr, integer),
    extract_string_content(Text, StringContent).
lower_stmt(write_int_str_int(Expr1, Text, Expr2), Env, Counter, Counter, ir_write_int_str_int(IRExpr1, StringContent, IRExpr2), []) :-
    lower_expr(Expr1, Env, IRExpr1, integer),
    lower_expr(Expr2, Env, IRExpr2, integer),
    extract_string_content(Text, StringContent).
lower_stmt(write_format(Text, Expr1, Expr2, Expr3), Env, Counter, Counter, ir_write_format(StringContent, IRExpr1, IRExpr2, IRExpr3), []) :-
    lower_expr(Expr1, Env, IRExpr1, integer),
    lower_expr(Expr2, Env, IRExpr2, integer),
    lower_expr(Expr3, Env, IRExpr3, integer),
    extract_string_content(Text, StringContent).
lower_stmt(readln(Name), Env, Counter, Counter, IRStmt, []) :-
    map_name(Name, Env, MappedName),
    lookup_type(Name, Env, Type),
    input_stmt(Type, MappedName, IRStmt).
lower_stmt(block(LocalVars, Stmts), Env, CounterIn, CounterOut, ir_block(IRStmts), AddedVars) :-
    lower_block(block(LocalVars, Stmts), Env, CounterIn, CounterOut, IRStmts, AddedVars).
lower_stmt(proc_call(Name, Args), Env, Counter, Counter, ir_proc_call(Name, IRArgs), []) :-
    lower_exprs(Args, Env, IRArgs).

output_stmt(writeln, char, IRExpr, ir_writeln_char(IRExpr)) :- !.
output_stmt(writeln, array(Low, High, char), ir_var(Name), ir_writeln_char_array(Name, Low, High)) :- !.
output_stmt(writeln, _, IRExpr, ir_writeln_int(IRExpr)).
output_stmt(write, char, IRExpr, ir_write_char(IRExpr)) :- !.
output_stmt(write, array(Low, High, char), ir_var(Name), ir_write_char_array(Name, Low, High)) :- !.
output_stmt(write, _, IRExpr, ir_write_int(IRExpr)).

input_stmt(char, MappedName, ir_readln_char(MappedName)) :- !.
input_stmt(_, MappedName, ir_readln(MappedName)).

map_name(Name, [Name-Mapped-_|_], Mapped) :-
    !.
map_name(Name, [_|Rest], Mapped) :-
    map_name(Name, Rest, Mapped).

lookup_type(Name, [Name-_-Type|_], Type) :-
    !.
lookup_type(Name, [_|Rest], Type) :-
    lookup_type(Name, Rest, Type).

lower_expr(Expr, Env, IRExpr) :-
    lower_expr(Expr, Env, IRExpr, _).

lower_expr(int(N), _Env, ir_int(N), integer).
lower_expr(bool(Value), _Env, ir_bool(Value), boolean).
lower_expr(char(Code), _Env, ir_char(Code), char).
lower_expr(var(Name), Env, ir_var(MappedName), Type) :-
    map_name(Name, Env, MappedName),
    lookup_type(Name, Env, Type).
lower_expr(array_ref(Name, IndexExpr), Env, ir_array_load(MappedName, Low, High, IRIndex), ElementType) :-
    map_name(Name, Env, MappedName),
    lookup_type(Name, Env, array(Low, High, ElementType)),
    lower_expr(IndexExpr, Env, IRIndex, integer).
lower_expr(call(Name, Args), Env, ir_call(Name, IRArgs), Type) :-
    func_return_type(Name, Type),
    lower_exprs(Args, Env, IRArgs).
lower_expr(unary('-', Expr), Env, ir_unary('-', IRExpr), integer) :-
    lower_expr(Expr, Env, IRExpr, integer).
lower_expr(unary(not, Expr), Env, ir_unary(not, IRExpr), boolean) :-
    lower_expr(Expr, Env, IRExpr, boolean).
lower_expr(bin(Op, Left, Right), Env, ir_bin(Op, IRLeft, IRRight), Type) :-
    lower_expr(Left, Env, IRLeft, LeftType),
    lower_expr(Right, Env, IRRight, RightType),
    lowered_bin_type(Op, LeftType, RightType, Type).

lowered_bin_type(Op, integer, integer, integer) :-
    memberchk(Op, ['+', '-', '*', '/', mod]),
    !.
lowered_bin_type(_, _, _, boolean).

lower_exprs([], _, []).
lower_exprs([Expr|Rest], Env, [IRExpr|IRRest]) :-
    lower_expr(Expr, Env, IRExpr, _),
    lower_exprs(Rest, Env, IRRest).
