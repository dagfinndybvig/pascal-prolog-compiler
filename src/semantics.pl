:- module(semantics, [check_program/1]).

check_program(program(_, Funcs, Vars, Block)) :-
    ensure_no_duplicate_decls(Vars),
    decls_env(Vars, GlobalEnv),
    check_funcs(Funcs, GlobalEnv, FuncSigs),
    check_block(Block, GlobalEnv, FuncSigs).

decl_name(decl(Name, _), Name).
decl_name(param(Name, _), Name).

decl_type(decl(_, Type), Type).
decl_type(param(_, Type), Type).

decl_env_entry(Decl, Name-Type) :-
    decl_name(Decl, Name),
    decl_type(Decl, Type).

decls_env([], []).
decls_env([Decl|Decls], [Entry|Env]) :-
    decl_env_entry(Decl, Entry),
    decls_env(Decls, Env).

decl_names(Decls, Names) :-
    findall(Name, (member(Decl, Decls), decl_name(Decl, Name)), Names).

ensure_no_duplicate_decls(Decls) :-
    decl_names(Decls, Names),
    ensure_no_duplicates(Names).

ensure_no_duplicates(Vars) :-
    msort(Vars, Sorted),
    (   has_duplicate(Sorted, Dup)
    ->  throw(error(duplicate_declaration(Dup), context(semantics/ensure_no_duplicates, 'Variable or parameter declared multiple times')))
    ;   true
    ).

has_duplicate([X, X|_], X) :- !.
has_duplicate([_|Rest], Dup) :-
    has_duplicate(Rest, Dup).

check_funcs(Funcs, GlobalEnv, FuncSigs) :-
    collect_func_sigs(Funcs, FuncSigs),
    ensure_no_duplicate_functions(FuncSigs),
    check_all_func_bodies(Funcs, GlobalEnv, FuncSigs).

collect_func_sigs([], []).
collect_func_sigs([func(Name, Params, ReturnType, _LocalVars, _Body)|Rest], [func_sig(Name, ParamTypes, ReturnType)|RestSigs]) :-
    length(Params, ParamCount),
    ensure_param_limit(Name, ParamCount),
    decl_names(Params, ParamNames),
    ensure_no_duplicates([Name|ParamNames]),
    findall(Type, member(param(_, Type), Params), ParamTypes),
    collect_func_sigs(Rest, RestSigs).

ensure_no_duplicate_functions(FuncSigs) :-
    findall(Name, member(func_sig(Name, _, _), FuncSigs), Names),
    (   msort(Names, Sorted),
        has_duplicate(Sorted, Dup)
    ->  throw(error(duplicate_function(Dup), context(semantics/ensure_no_duplicate_functions, 'Function declared more than once')))
    ;   true
    ).

ensure_param_limit(Name, Count) :-
    (   Count =< 6
    ->  true
    ;   throw(error(too_many_parameters(Name, Count), context(semantics/ensure_param_limit, 'Functions support at most 6 parameters')))
    ).

check_all_func_bodies([], _, _).
check_all_func_bodies([func(Name, Params, ReturnType, LocalVars, Body)|Rest], GlobalEnv, FuncSigs) :-
    ensure_no_duplicate_decls(Params),
    ensure_no_duplicate_decls(LocalVars),
    decl_names(Params, ParamNames),
    decl_names(LocalVars, LocalNames),
    append([Name|ParamNames], LocalNames, FuncScopeNames),
    ensure_no_duplicates(FuncScopeNames),
    decls_env(Params, ParamEnv),
    decls_env(LocalVars, LocalEnv),
    append([Name-ReturnType|ParamEnv], LocalEnv, FuncScope),
    append(FuncScope, GlobalEnv, VarsInScope),
    check_block(Body, VarsInScope, FuncSigs),
    check_all_func_bodies(Rest, GlobalEnv, FuncSigs).

check_stmts([], _, _).
check_stmts([Stmt|Rest], Vars, FuncSigs) :-
    check_stmt(Stmt, Vars, FuncSigs),
    check_stmts(Rest, Vars, FuncSigs).

check_stmt(assign(Name, Expr), Vars, FuncSigs) :-
    ensure_declared(Name, Vars, TargetType),
    check_expr(Expr, Vars, FuncSigs, ExprType),
    ensure_assignable(TargetType, ExprType).
check_stmt(if(Cond, Then, Else), Vars, FuncSigs) :-
    check_expr(Cond, Vars, FuncSigs, integer),
    check_stmt(Then, Vars, FuncSigs),
    check_stmt(Else, Vars, FuncSigs).
check_stmt(while(Cond, Body), Vars, FuncSigs) :-
    check_expr(Cond, Vars, FuncSigs, integer),
    check_stmt(Body, Vars, FuncSigs).
check_stmt(writeln(expr(Expr)), Vars, FuncSigs) :-
    check_expr(Expr, Vars, FuncSigs, integer).
check_stmt(writeln(str(_)), _, _).
check_stmt(write(expr(Expr)), Vars, FuncSigs) :-
    check_expr(Expr, Vars, FuncSigs, integer).
check_stmt(write(str(_)), _, _).
check_stmt(write(Expr, _), Vars, FuncSigs) :-
    check_expr(Expr, Vars, FuncSigs, integer).
check_stmt(write(_, Expr), Vars, FuncSigs) :-
    check_expr(Expr, Vars, FuncSigs, integer).
check_stmt(readln(Name), Vars, _) :-
    ensure_declared(Name, Vars, integer).
check_stmt(block(LocalVars, Stmts), Vars, FuncSigs) :-
    check_block(block(LocalVars, Stmts), Vars, FuncSigs).

check_expr(int(_), _, _, integer).
check_expr(var(Name), Vars, _, Type) :-
    ensure_declared(Name, Vars, Type).
check_expr(call(Name, Args), Vars, FuncSigs, ReturnType) :-
    ensure_function_declared(Name, FuncSigs, ParamTypes, ReturnType),
    length(Args, ActualArity),
    length(ParamTypes, ExpectedArity),
    (   ActualArity = ExpectedArity
    ->  true
    ;   throw(error(wrong_arity(Name, ExpectedArity, ActualArity), context(semantics/check_expr, 'Function called with incorrect number of arguments')))
    ),
    check_exprs(Args, ParamTypes, Vars, FuncSigs).
check_expr(unary('-', Expr), Vars, FuncSigs, integer) :-
    check_expr(Expr, Vars, FuncSigs, integer).
check_expr(bin(Op, Left, Right), Vars, FuncSigs, Type) :-
    bin_expr_type(Op, LeftType, RightType, Type),
    check_expr(Left, Vars, FuncSigs, LeftType),
    check_expr(Right, Vars, FuncSigs, RightType).

bin_expr_type(Op, integer, integer, integer) :-
    memberchk(Op, ['+', '-', '*', '/', mod, '=', '<>', '<', '<=', '>', '>=']).

check_exprs([], [], _, _).
check_exprs([Expr|Rest], [Type|Types], Vars, FuncSigs) :-
    check_expr(Expr, Vars, FuncSigs, Type),
    check_exprs(Rest, Types, Vars, FuncSigs).

ensure_declared(Name, Vars, Type) :-
    (   memberchk(Name-Type, Vars)
    ->  true
    ;   throw(error(undeclared_variable(Name), context(semantics/ensure_declared, 'Variable not declared in current scope')))
    ).

ensure_function_declared(Name, FuncSigs, ParamTypes, ReturnType) :-
    (   memberchk(func_sig(Name, ParamTypes, ReturnType), FuncSigs)
    ->  true
    ;   throw(error(undeclared_function(Name), context(semantics/ensure_function_declared, 'Function not declared or wrong arity')))
    ).

ensure_assignable(Type, Type) :- !.
ensure_assignable(Expected, Actual) :-
    throw(error(type_mismatch(Expected, Actual), context(semantics/ensure_assignable, 'Expression type is not assignable to target'))).

check_block(block(LocalVars, Stmts), VarsInScope, FuncSigs) :-
    ensure_no_duplicate_decls(LocalVars),
    decls_env(LocalVars, LocalEnv),
    append(LocalEnv, VarsInScope, ScopeVars),
    check_stmts(Stmts, ScopeVars, FuncSigs).
