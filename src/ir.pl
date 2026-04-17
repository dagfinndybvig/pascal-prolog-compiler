:- module(ir, [lower_program/2]).

lower_program(program(Name, Vars, Block), ir_program(Name, AllVars, IRStmts)) :-
    vars_env(Vars, GlobalEnv),
    lower_block(Block, GlobalEnv, 0, _CounterOut, IRStmts, LocalVars),
    append(Vars, LocalVars, AllVars).

vars_env([], []).
vars_env([Var|Vars], [Var-Var|EnvTail]) :-
    vars_env(Vars, EnvTail).

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
lower_expr(unary('-', Expr), Env, ir_unary('-', IRExpr)) :-
    lower_expr(Expr, Env, IRExpr).
lower_expr(bin(Op, Left, Right), Env, ir_bin(Op, IRLeft, IRRight)) :-
    lower_expr(Left, Env, IRLeft),
    lower_expr(Right, Env, IRRight).
