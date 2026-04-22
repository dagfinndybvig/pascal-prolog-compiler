:- module(semantics, [check_program/1]).

check_program(program(_, Funcs, Vars, Block)) :-
    ensure_no_duplicates(Vars),
    check_funcs(Funcs, Vars, FuncSigs),
    check_block(Block, Vars, FuncSigs).

ensure_no_duplicates(Vars) :-
    msort(Vars, Sorted),
    (   has_duplicate(Sorted, Dup)
    ->  throw(error(duplicate_declaration(Dup), _))
    ;   true
    ).

has_duplicate([X, X|_], X) :- !.
has_duplicate([_|Rest], Dup) :-
    has_duplicate(Rest, Dup).

check_funcs(Funcs, GlobalVars, FuncSigs) :-
    collect_func_sigs(Funcs, FuncSigs),
    check_all_func_bodies(Funcs, GlobalVars, FuncSigs).

collect_func_sigs([], []).
collect_func_sigs([func(Name, Params, _)|Rest], [(Name, ParamCount)|RestSigs]) :-
    length(Params, ParamCount),
    ensure_no_duplicates([Name|Params]),
    collect_func_sigs(Rest, RestSigs).

check_all_func_bodies([], _, _).
check_all_func_bodies([func(Name, Params, Body)|Rest], GlobalVars, FuncSigs) :-
    check_block(Body, [Name|Params], FuncSigs),
    check_all_func_bodies(Rest, GlobalVars, FuncSigs).

check_stmts([], _, _).
check_stmts([Stmt|Rest], Vars, FuncSigs) :-
    check_stmt(Stmt, Vars, FuncSigs),
    check_stmts(Rest, Vars, FuncSigs).

check_stmt(assign(Name, Expr), Vars, FuncSigs) :-
    ensure_declared(Name, Vars),
    check_expr(Expr, Vars, FuncSigs).
check_stmt(if(Cond, Then, Else), Vars, FuncSigs) :-
    check_expr(Cond, Vars, FuncSigs),
    check_stmt(Then, Vars, FuncSigs),
    check_stmt(Else, Vars, FuncSigs).
check_stmt(while(Cond, Body), Vars, FuncSigs) :-
    check_expr(Cond, Vars, FuncSigs),
    check_stmt(Body, Vars, FuncSigs).
check_stmt(writeln(expr(Expr)), Vars, FuncSigs) :-
    check_expr(Expr, Vars, FuncSigs).
check_stmt(writeln(str(_)), _, _).
check_stmt(write(expr(Expr)), Vars, FuncSigs) :-
    check_expr(Expr, Vars, FuncSigs).
check_stmt(write(str(_)), _, _).
check_stmt(readln(Name), Vars, _) :-
    ensure_declared(Name, Vars).
check_stmt(block(LocalVars, Stmts), Vars, FuncSigs) :-
    check_block(block(LocalVars, Stmts), Vars, FuncSigs).

check_expr(int(_), _, _).
check_expr(var(Name), Vars, _) :-
    ensure_declared(Name, Vars).
check_expr(call(Name, Args), Vars, FuncSigs) :-
    ensure_function_declared(Name, FuncSigs, ExpectedArity),
    length(Args, ActualArity),
    (   ActualArity = ExpectedArity
    ->  true
    ;   throw(error(wrong_arity(Name, ExpectedArity, ActualArity), _))
    ),
    check_exprs(Args, Vars, FuncSigs).
check_expr(unary('-', Expr), Vars, FuncSigs) :-
    check_expr(Expr, Vars, FuncSigs).
check_expr(bin(_, Left, Right), Vars, FuncSigs) :-
    check_expr(Left, Vars, FuncSigs),
    check_expr(Right, Vars, FuncSigs).

check_exprs([], _, _).
check_exprs([Expr|Rest], Vars, FuncSigs) :-
    check_expr(Expr, Vars, FuncSigs),
    check_exprs(Rest, Vars, FuncSigs).

ensure_declared(Name, Vars) :-
    (   memberchk(Name, Vars)
    ->  true
    ;   throw(error(undeclared_variable(Name), _))
    ).

ensure_function_declared(Name, FuncSigs, Arity) :-
    (   memberchk((Name, Arity), FuncSigs)
    ->  true
    ;   throw(error(undeclared_function(Name), _))
    ).

check_block(block(LocalVars, Stmts), VarsInScope, FuncSigs) :-
    ensure_no_duplicates(LocalVars),
    append(LocalVars, VarsInScope, ScopeVars),
    check_stmts(Stmts, ScopeVars, FuncSigs).
