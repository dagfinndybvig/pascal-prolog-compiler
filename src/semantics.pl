:- module(semantics, [check_program/1]).

check_program(program(_, Funcs, Vars, Block)) :-
    ensure_no_duplicate_decls(Vars),
    ensure_valid_decls(Vars),
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
    ensure_return_type(ReturnType),
    ensure_scalar_decls(Params),
    decl_names(Params, ParamNames),
    ensure_no_duplicates([Name|ParamNames]),
    findall(Type, member(param(_, Type), Params), ParamTypes),
    collect_func_sigs(Rest, RestSigs).

ensure_return_type(void) :- !.
ensure_return_type(Type) :- ensure_scalar_type(Type).

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
    ensure_scalar_decls(Params),
    ensure_valid_decls(LocalVars),
    decl_names(Params, ParamNames),
    decl_names(LocalVars, LocalNames),
    append([Name|ParamNames], LocalNames, FuncScopeNames),
    ensure_no_duplicates(FuncScopeNames),
    decls_env(Params, ParamEnv),
    decls_env(LocalVars, LocalEnv),
    (   ReturnType == void
    ->  append(ParamEnv, LocalEnv, FuncScope)
    ;   append([Name-ReturnType|ParamEnv], LocalEnv, FuncScope)
    ),
    append(FuncScope, GlobalEnv, VarsInScope),
    check_block(Body, VarsInScope, FuncSigs),
    check_all_func_bodies(Rest, GlobalEnv, FuncSigs).

check_stmts([], _, _).
check_stmts([Stmt|Rest], Vars, FuncSigs) :-
    check_stmt(Stmt, Vars, FuncSigs),
    check_stmts(Rest, Vars, FuncSigs).

check_stmt(assign(Name, Expr), Vars, FuncSigs) :-
    ensure_declared(Name, Vars, TargetType),
    ensure_not_array(TargetType),
    check_expr(Expr, Vars, FuncSigs, ExprType),
    ensure_assignable(TargetType, ExprType).
check_stmt(assign_index(Name, IndexExpr, Expr), Vars, FuncSigs) :-
    ensure_declared(Name, Vars, array(_Low, _High, ElementType)),
    check_expr(IndexExpr, Vars, FuncSigs, integer),
    check_expr(Expr, Vars, FuncSigs, ExprType),
    ensure_assignable(ElementType, ExprType).
check_stmt(if(Cond, Then, Else), Vars, FuncSigs) :-
    check_expr(Cond, Vars, FuncSigs, boolean),
    check_stmt(Then, Vars, FuncSigs),
    check_stmt(Else, Vars, FuncSigs).
check_stmt(while(Cond, Body), Vars, FuncSigs) :-
    check_expr(Cond, Vars, FuncSigs, boolean),
    check_stmt(Body, Vars, FuncSigs).
check_stmt(writeln(expr(Expr)), Vars, FuncSigs) :-
    check_expr(Expr, Vars, FuncSigs, Type),
    ensure_writable_type(Type).
check_stmt(writeln(str(_)), _, _).
check_stmt(write(expr(Expr)), Vars, FuncSigs) :-
    check_expr(Expr, Vars, FuncSigs, Type),
    ensure_writable_type(Type).
check_stmt(write(str(_)), _, _).
check_stmt(write(Expr, _), Vars, FuncSigs) :-
    check_expr(Expr, Vars, FuncSigs, integer).
check_stmt(write(_, Expr), Vars, FuncSigs) :-
    check_expr(Expr, Vars, FuncSigs, integer).
check_stmt(readln(Name), Vars, _) :-
    ensure_declared(Name, Vars, Type),
    ensure_readable_type(Type).
check_stmt(block(LocalVars, Stmts), Vars, FuncSigs) :-
    check_block(block(LocalVars, Stmts), Vars, FuncSigs).
check_stmt(proc_call(Name, Args), Vars, FuncSigs) :-
    ensure_function_declared(Name, FuncSigs, ParamTypes, _ReturnType),
    length(Args, ActualArity),
    length(ParamTypes, ExpectedArity),
    (   ActualArity = ExpectedArity
    ->  true
    ;   throw(error(wrong_arity(Name, ExpectedArity, ActualArity), context(semantics/check_stmt, 'Procedure called with incorrect number of arguments')))
    ),
    check_exprs(Args, ParamTypes, Vars, FuncSigs).

check_expr(int(_), _, _, integer).
check_expr(bool(_), _, _, boolean).
check_expr(char(_), _, _, char).
check_expr(var(Name), Vars, _, Type) :-
    ensure_declared(Name, Vars, Type).
check_expr(array_ref(Name, IndexExpr), Vars, FuncSigs, ElementType) :-
    ensure_declared(Name, Vars, array(_Low, _High, ElementType)),
    check_expr(IndexExpr, Vars, FuncSigs, integer).
check_expr(call(Name, Args), Vars, FuncSigs, ReturnType) :-
    ensure_function_declared(Name, FuncSigs, ParamTypes, ReturnType),
    (   ReturnType == void
    ->  throw(error(procedure_used_as_expression(Name), context(semantics/check_expr, 'Procedures do not return a value and cannot appear in expressions')))
    ;   true
    ),
    length(Args, ActualArity),
    length(ParamTypes, ExpectedArity),
    (   ActualArity = ExpectedArity
    ->  true
    ;   throw(error(wrong_arity(Name, ExpectedArity, ActualArity), context(semantics/check_expr, 'Function called with incorrect number of arguments')))
    ),
    check_exprs(Args, ParamTypes, Vars, FuncSigs).
check_expr(unary('-', Expr), Vars, FuncSigs, integer) :-
    check_expr(Expr, Vars, FuncSigs, integer).
check_expr(unary(not, Expr), Vars, FuncSigs, boolean) :-
    check_expr(Expr, Vars, FuncSigs, boolean).
check_expr(bin(Op, Left, Right), Vars, FuncSigs, Type) :-
    check_expr(Left, Vars, FuncSigs, LeftType),
    check_expr(Right, Vars, FuncSigs, RightType),
    (   bin_expr_type(Op, LeftType, RightType, Type)
    ->  true
    ;   throw(error(type_mismatch(operator(Op), operands(LeftType, RightType)), context(semantics/check_expr, 'Operator is not defined for operand types')))
    ).

bin_expr_type(Op, integer, integer, integer) :-
    memberchk(Op, ['+', '-', '*', '/', mod]).
bin_expr_type(Op, integer, integer, boolean) :-
    memberchk(Op, ['=', '<>', '<', '<=', '>', '>=']).
bin_expr_type(Op, char, char, boolean) :-
    memberchk(Op, ['=', '<>', '<', '<=', '>', '>=']).
bin_expr_type(Op, boolean, boolean, boolean) :-
    memberchk(Op, [and, or, '=', '<>']).

check_exprs([], [], _, _).
check_exprs([Expr|Rest], [Type|Types], Vars, FuncSigs) :-
    check_expr(Expr, Vars, FuncSigs, Type),
    check_exprs(Rest, Types, Vars, FuncSigs).

ensure_declared(Name, Vars, Type) :-
    (   memberchk(Name-ActualType, Vars)
    ->  ensure_expected_type(Type, ActualType)
    ;   throw(error(undeclared_variable(Name), context(semantics/ensure_declared, 'Variable not declared in current scope')))
    ).

ensure_expected_type(Expected, Actual) :-
    var(Expected),
    !,
    Expected = Actual.
ensure_expected_type(Type, Type) :- !.
ensure_expected_type(Expected, Actual) :-
    throw(error(type_mismatch(Expected, Actual), context(semantics/ensure_declared, 'Variable has a different declared type'))).

ensure_function_declared(Name, FuncSigs, ParamTypes, ReturnType) :-
    (   memberchk(func_sig(Name, ParamTypes, ReturnType), FuncSigs)
    ->  true
    ;   throw(error(undeclared_function(Name), context(semantics/ensure_function_declared, 'Function not declared or wrong arity')))
    ).

ensure_assignable(Type, Type) :- !.
ensure_assignable(Expected, Actual) :-
    throw(error(type_mismatch(Expected, Actual), context(semantics/ensure_assignable, 'Expression type is not assignable to target'))).

ensure_writable_type(integer).
ensure_writable_type(boolean).
ensure_writable_type(char).
ensure_writable_type(array(_, _, char)).

ensure_readable_type(integer).
ensure_readable_type(char).

ensure_valid_decls([]).
ensure_valid_decls([Decl|Decls]) :-
    decl_type(Decl, Type),
    ensure_valid_type(Type),
    ensure_valid_decls(Decls).

ensure_scalar_decls([]).
ensure_scalar_decls([Decl|Decls]) :-
    decl_type(Decl, Type),
    ensure_scalar_type(Type),
    ensure_scalar_decls(Decls).

ensure_valid_type(integer).
ensure_valid_type(boolean).
ensure_valid_type(char).
ensure_valid_type(array(Low, High, ElementType)) :-
    integer(Low),
    integer(High),
    (   Low =< High
    ->  true
    ;   throw(error(invalid_array_bounds(Low, High), context(semantics/ensure_valid_type, 'Array lower bound must not exceed upper bound')))
    ),
    ensure_scalar_type(ElementType).

ensure_scalar_type(integer).
ensure_scalar_type(boolean).
ensure_scalar_type(char).
ensure_scalar_type(Type) :-
    throw(error(unsupported_type(Type), context(semantics/ensure_scalar_type, 'Only scalar types are supported here'))).

ensure_not_array(array(_, _, _)) :-
    !,
    throw(error(type_mismatch(scalar, array), context(semantics/ensure_not_array, 'Array values require indexed element access'))).
ensure_not_array(_).

check_block(block(LocalVars, Stmts), VarsInScope, FuncSigs) :-
    ensure_no_duplicate_decls(LocalVars),
    ensure_valid_decls(LocalVars),
    decls_env(LocalVars, LocalEnv),
    append(LocalEnv, VarsInScope, ScopeVars),
    check_stmts(Stmts, ScopeVars, FuncSigs).
