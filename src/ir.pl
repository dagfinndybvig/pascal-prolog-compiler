:- module(ir, [lower_program/2]).

:- discontiguous lower_stmt/6.

lower_program(program(Name, Funcs, Vars, Block), ir_program(Name, IRFuncs, AllVars, IRStmts)) :-
    vars_env(Vars, GlobalEnv),
    lower_funcs(Funcs, GlobalEnv, IRFuncs),
    lower_block(Block, GlobalEnv, 0, _CounterOut, IRStmts, LocalVars),
    append(Vars, LocalVars, AllVars).

vars_env([], []).
vars_env([Var|Vars], [Var-Var|EnvTail]) :-
    vars_env(Vars, EnvTail).

lower_funcs([], _, []).
lower_funcs([func(Name, Params, Body)|Rest], GlobalEnv, [ir_func(Name, Params, FuncLocals, IRBody)|IRFuncsRest]) :-
    vars_env(Params, ParamEnv),
    % Add function name to environment for return value assignment
    append(ParamEnv, [Name-Name], FuncEnv0),
    append(FuncEnv0, GlobalEnv, FuncEnv),
    lower_block(Body, FuncEnv, 0, _CounterOut, IRBody, FuncLocals),
    lower_funcs(Rest, GlobalEnv, IRFuncsRest).

lower_block(block(LocalVars, Stmts), ParentEnv, CounterIn, CounterOut, IRStmts, AddedVars) :-
    allocate_locals(LocalVars, CounterIn, CounterNext, LocalMappings, LocalAllocations),
    append(LocalMappings, ParentEnv, ScopeEnv),
    lower_stmts(Stmts, ScopeEnv, CounterNext, CounterOut, IRStmts, NestedAllocations),
    append(LocalAllocations, NestedAllocations, AddedVars).

allocate_locals([], Counter, Counter, [], []).
allocate_locals([Var|Vars], CounterIn, CounterOut, [Var-Mangled|MapTail], [Mangled|AllocTail]) :-
    Mangled = local(CounterIn, Var),
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
lower_stmt(if(Cond, Then, Else), Env, CounterIn, CounterOut, ir_if(IRCond, IRThen, IRElse), AddedVars) :-
    lower_expr(Cond, Env, IRCond),
    lower_stmt(Then, Env, CounterIn, CounterThen, IRThen, AddedThen),
    lower_stmt(Else, Env, CounterThen, CounterOut, IRElse, AddedElse),
    append(AddedThen, AddedElse, AddedVars).
lower_stmt(while(Cond, Body), Env, CounterIn, CounterOut, ir_while(IRCond, IRBody), AddedVars) :-
    lower_expr(Cond, Env, IRCond),
    lower_stmt(Body, Env, CounterIn, CounterOut, IRBody, AddedVars).
lower_stmt(writeln(expr(Expr)), Env, Counter, Counter, ir_writeln_int(IRExpr), []) :-
    lower_expr(Expr, Env, IRExpr).
lower_stmt(writeln(str(Text)), _Env, Counter, Counter, ir_writeln_str(Text), []).
lower_stmt(write(expr(Expr)), Env, Counter, Counter, ir_write_int(IRExpr), []) :-
    lower_expr(Expr, Env, IRExpr).
lower_stmt(write(str(Text)), _Env, Counter, Counter, ir_write_str(Text), []).

% Enhanced write statements for stdlib
lower_stmt(write_int_str(Expr, Text), Env, Counter, Counter, ir_write_int_str(IRExpr, NormalizedText), []) :-
    lower_expr(Expr, Env, IRExpr),
    normalize_string_literal(Text, NormalizedText).

% Normalize string literal to ensure it's wrapped in str()/1
normalize_string_literal(str(Text), str(Text)) :- !.
normalize_string_literal(Text, str(Text)).
lower_stmt(write_str_int(Text, Expr), Env, Counter, Counter, ir_write_str_int(NormalizedText, IRExpr), []) :-
    lower_expr(Expr, Env, IRExpr),
    normalize_string_literal(Text, NormalizedText).
lower_stmt(write_int_str_int(Expr1, Text, Expr2), Env, Counter, Counter, ir_write_int_str_int(IRExpr1, NormalizedText, IRExpr2), []) :-
    lower_expr(Expr1, Env, IRExpr1),
    lower_expr(Expr2, Env, IRExpr2),
    normalize_string_literal(Text, NormalizedText).
lower_stmt(write_format(Text, Expr1, Expr2, Expr3), Env, Counter, Counter, ir_write_format(NormalizedText, IRExpr1, IRExpr2, IRExpr3), []) :-
    lower_expr(Expr1, Env, IRExpr1),
    lower_expr(Expr2, Env, IRExpr2),
    lower_expr(Expr3, Env, IRExpr3),
    normalize_string_literal(Text, NormalizedText).
lower_stmt(readln(Name), Env, Counter, Counter, ir_readln(MappedName), []) :-
    map_name(Name, Env, MappedName).
lower_stmt(block(LocalVars, Stmts), Env, CounterIn, CounterOut, ir_block(IRStmts), AddedVars) :-
    lower_block(block(LocalVars, Stmts), Env, CounterIn, CounterOut, IRStmts, AddedVars).

map_name(Name, [Name-Mapped|_], Mapped) :-
    !.
map_name(Name, [_|Rest], Mapped) :-
    map_name(Name, Rest, Mapped).

lower_expr(int(N), _Env, ir_int(N)).
lower_expr(var(Name), Env, ir_var(MappedName)) :-
    map_name(Name, Env, MappedName).
lower_expr(call(Name, Args), Env, ir_call(Name, IRArgs)) :-
    lower_exprs(Args, Env, IRArgs).
lower_expr(unary('-', Expr), Env, ir_unary('-', IRExpr)) :-
    lower_expr(Expr, Env, IRExpr).
lower_expr(bin(Op, Left, Right), Env, ir_bin(Op, IRLeft, IRRight)) :-
    lower_expr(Left, Env, IRLeft),
    lower_expr(Right, Env, IRRight).

lower_exprs([], _, []).
lower_exprs([Expr|Rest], Env, [IRExpr|IRRest]) :-
    lower_expr(Expr, Env, IRExpr),
    lower_exprs(Rest, Env, IRRest).
