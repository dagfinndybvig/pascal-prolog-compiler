:- module(semantics, [check_program/1]).

:- dynamic type_alias/2.

check_program(program(_, ConstDecls, TypeDecls, Funcs, Vars, Block)) :-
    init_type_aliases(TypeDecls),
    check_const_decls(ConstDecls, [], GlobalConstEnv),
    ensure_no_duplicate_decls(Vars),
    ensure_const_var_disjoint(ConstDecls, Vars),
    ensure_valid_decls(Vars),
    decls_env(Vars, GlobalVarEnv),
    append(GlobalConstEnv, GlobalVarEnv, GlobalEnv),
    check_funcs(Funcs, GlobalEnv, FuncSigs),
    check_block(Block, GlobalEnv, FuncSigs).

init_type_aliases(TypeDecls) :-
    retractall(type_alias(_, _)),
    ensure_no_duplicate_type_decls(TypeDecls),
    forall(member(type_decl(Name, Type), TypeDecls), assertz(type_alias(Name, Type))),
    validate_type_aliases(TypeDecls).

ensure_no_duplicate_type_decls(TypeDecls) :-
    findall(Name, member(type_decl(Name, _), TypeDecls), Names),
    ensure_no_duplicates(Names).

validate_type_aliases([]).
validate_type_aliases([type_decl(_, Type)|Rest]) :-
    resolve_type(Type, _ResolvedType),
    validate_type_aliases(Rest).

resolve_type(Type, Resolved) :-
    resolve_type(Type, [], normal, Resolved).

resolve_type(type_ref(Name), Seen, Mode, Resolved) :-
    !,
    (   Mode == through_ptr
    ->  (   type_alias(Name, _)
        ->  Resolved = type_ref(Name)
        ;   throw(error(undeclared_type(Name), context(semantics/resolve_type, 'Named type not declared')))
        )
    ;   (   memberchk(Name, Seen)
        ->  throw(error(recursive_type_alias(Name), context(semantics/resolve_type, 'Recursive type aliases must be through pointer indirection')))
        ;   (   type_alias(Name, Type)
            ->  resolve_type(Type, [Name|Seen], Mode, Resolved)
            ;   throw(error(undeclared_type(Name), context(semantics/resolve_type, 'Named type not declared')))
            )
        )
    ).
resolve_type(array(Low, High, ElementType), Seen, _Mode, array(Low, High, ResolvedElement)) :-
    !,
    resolve_type(ElementType, Seen, normal, ResolvedElement).
resolve_type(ptr(TargetType), Seen, _Mode, ptr(ResolvedTarget)) :-
    !,
    resolve_type(TargetType, Seen, through_ptr, ResolvedTarget).
resolve_type(record(Fields), Seen, _Mode, record(ResolvedFields)) :-
    !,
    resolve_record_fields(Fields, Seen, ResolvedFields).
resolve_type(Type, _Seen, _Mode, Type).

resolve_record_fields([], _Seen, []).
resolve_record_fields([field(Name, Type)|Rest], Seen, [field(Name, ResolvedType)|ResolvedRest]) :-
    resolve_type(Type, Seen, normal, ResolvedType),
    resolve_record_fields(Rest, Seen, ResolvedRest).

decl_name(decl(Name, _), Name).
decl_name(param(Name, _), Name).
decl_name(param_var(Name, _), Name).
decl_name(const_decl(Name, _, _), Name).

decl_type(decl(_, Type), Type).
decl_type(param(_, Type), Type).
decl_type(param_var(_, Type), Type).
decl_type(const_decl(_, Type, _), Type).

param_spec(param(_, Type), spec(value, Type)).
param_spec(param_var(_, Type), spec(var_ref, Type)).

const_name_type(const_decl(Name, Type, _), Name-Type).

decls_env([], []).
decls_env([Decl|Decls], [Entry|Env]) :-
    decl_env_entry(Decl, Entry),
    decls_env(Decls, Env).

decl_env_entry(Decl, Name-Type) :-
    decl_name(Decl, Name),
    decl_type(Decl, RawType),
    resolve_type(RawType, Type).

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

% Check const declarations and build read-only environment entries.
check_const_decls([], _VarsInScope, []).
check_const_decls([const_decl(Name, Type, Expr)|Rest], VarsInScope, [Name-const(Type, Value)|ConstEnvRest]) :-
    ensure_no_duplicate_const(Name, VarsInScope),
    ensure_valid_type(Type),
    eval_const_expr(Expr, VarsInScope, Value, EvaluatedType),
    ensure_assignable(Type, EvaluatedType),
    check_const_decls(Rest, [Name-const(Type, Value)|VarsInScope], ConstEnvRest).

ensure_const_var_disjoint(ConstDecls, Vars) :-
    findall(Name, member(decl(Name, _), Vars), VarNames),
    forall(member(const_decl(ConstName, _, _), ConstDecls),
           (   memberchk(ConstName, VarNames)
           ->  throw(error(duplicate_declaration(ConstName), context(semantics/ensure_const_var_disjoint, 'const and var share the same name in one scope')))
           ;   true
           )).

ensure_no_duplicate_const(Name, VarsInScope) :-
    (   memberchk(Name-_, VarsInScope)
    ->  throw(error(duplicate_declaration(Name), context(semantics/ensure_no_duplicate_const, 'Constant declared multiple times')))
    ;   true
    ).

% Evaluate constant expressions (literals, simple arithmetic, etc.)
eval_const_expr(int(N), _Vars, int(N), integer).
eval_const_expr(bool(Value), _Vars, bool(Value), boolean).
eval_const_expr(char(Code), _Vars, char(Code), char).
eval_const_expr(nil, _Vars, nil, nil_type).
eval_const_expr(var(Name), Vars, Value, Type) :-
    memberchk(Name-const(Type, Value), Vars),
    !.
eval_const_expr(unary('-', Expr), Vars, int(Value), integer) :-
    eval_const_expr(Expr, Vars, int(Inner), integer),
    Value is -Inner.
eval_const_expr(unary(not, Expr), Vars, bool(Value), boolean) :-
    eval_const_expr(Expr, Vars, bool(Inner), boolean),
    (   Inner == true
    ->  Value = false
    ;   Value = true
    ).
eval_const_expr(bin(Op, Left, Right), Vars, int(Value), integer) :-
    eval_const_expr(Left, Vars, int(LVal), integer),
    eval_const_expr(Right, Vars, int(RVal), integer),
    eval_bin_op(Op, LVal, RVal, Value).
eval_const_expr(Expr, _Vars, _Value, _Type) :-
    throw(error(non_constant_expression(Expr), context(semantics/eval_const_expr, 'Const expression must be a constant'))).

eval_bin_op('+', L, R, S) :- S is L + R.
eval_bin_op('-', L, R, S) :- S is L - R.
eval_bin_op('*', L, R, S) :- S is L * R.
eval_bin_op('/', L, R, S) :- R =\= 0, S is L // R.
eval_bin_op(mod, L, R, S) :- R =\= 0, S is L mod R.

check_funcs(Funcs, GlobalEnv, FuncSigs) :-
    collect_func_sigs(Funcs, FuncSigs),
    ensure_no_duplicate_functions(FuncSigs),
    check_all_func_bodies(Funcs, GlobalEnv, FuncSigs).

collect_func_sigs([], []).
collect_func_sigs([func(Name, Params, ReturnType, _LocalVars, _Body)|Rest], [func_sig(Name, ParamSpecs, ReturnType)|RestSigs]) :-
    length(Params, ParamCount),
    ensure_param_limit(Name, ParamCount),
    ensure_return_type(ReturnType),
    ensure_param_decls(Params),
    decl_names(Params, ParamNames),
    ensure_no_duplicates([Name|ParamNames]),
    maplist(param_spec, Params, ParamSpecs),
    collect_func_sigs(Rest, RestSigs).

ensure_param_decls([]).
ensure_param_decls([param(_, Type)|Rest]) :-
    ensure_scalar_type(Type),
    ensure_param_decls(Rest).
ensure_param_decls([param_var(_, Type)|Rest]) :-
    ensure_valid_type(Type),
    ensure_param_decls(Rest).

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
    ensure_param_decls(Params),
    ensure_valid_decls(LocalVars),
    decl_names(Params, ParamNames),
    decl_names(LocalVars, LocalNames),
    append([Name|ParamNames], LocalNames, FuncScopeNames),
    ensure_no_duplicates(FuncScopeNames),
    decls_env(Params, ParamEnv),
    (   ReturnType == void
    ->  FuncEnv0 = ParamEnv
    ;   append(ParamEnv, [Name-ReturnType], FuncEnv0)
    ),
    decls_env(LocalVars, LocalEnv),
    append(FuncEnv0, LocalEnv, FuncEnv),
    append(FuncEnv, GlobalEnv, VarsInScope),
    check_block(Body, VarsInScope, FuncSigs),
    check_all_func_bodies(Rest, GlobalEnv, FuncSigs).

check_stmts([], _, _).
check_stmts([Stmt|Rest], Vars, FuncSigs) :-
    check_stmt(Stmt, Vars, FuncSigs),
    check_stmts(Rest, Vars, FuncSigs).

check_stmt(assign(Name, Expr), Vars, FuncSigs) :-
    ensure_writable_name(Name, Vars),
    ensure_declared(Name, Vars, TargetType),
    ensure_not_aggregate(TargetType),
    check_expr(Expr, Vars, FuncSigs, ExprType),
    ensure_assignable(TargetType, ExprType).
check_stmt(assign_index(Name, IndexExpr, Expr), Vars, FuncSigs) :-
    ensure_writable_name(Name, Vars),
    ensure_declared(Name, Vars, array(_Low, _High, ElementType)),
    check_expr(IndexExpr, Vars, FuncSigs, integer),
    check_expr(Expr, Vars, FuncSigs, ExprType),
    ensure_assignable(ElementType, ExprType).
check_stmt(assign_field(Name, Field, Expr), Vars, FuncSigs) :-
    ensure_writable_name(Name, Vars),
    ensure_declared(Name, Vars, RecordType),
    ensure_record_type(RecordType, Name, Fields),
    ensure_record_field(Fields, Name, Field, FieldType),
    check_expr(Expr, Vars, FuncSigs, ExprType),
    ensure_assignable(FieldType, ExprType).
check_stmt(assign_ptr_field(Name, Field, Expr), Vars, FuncSigs) :-
    ensure_writable_name(Name, Vars),
    ensure_declared(Name, Vars, PtrType),
    ensure_pointer_target_record(PtrType, Name, Fields),
    ensure_record_field(Fields, Name, Field, FieldType),
    check_expr(Expr, Vars, FuncSigs, ExprType),
    ensure_assignable(FieldType, ExprType).
check_stmt(assign_deref(Name, Expr), Vars, FuncSigs) :-
    ensure_writable_name(Name, Vars),
    ensure_declared(Name, Vars, PtrType),
    ensure_pointer_type(PtrType, Name, TargetType),
    ensure_not_aggregate(TargetType),
    check_expr(Expr, Vars, FuncSigs, ExprType),
    ensure_assignable(TargetType, ExprType).
check_stmt(if(Cond, Then, Else), Vars, FuncSigs) :-
    check_expr(Cond, Vars, FuncSigs, boolean),
    check_stmt(Then, Vars, FuncSigs),
    check_stmt(Else, Vars, FuncSigs).
check_stmt(while(Cond, Body), Vars, FuncSigs) :-
    check_expr(Cond, Vars, FuncSigs, boolean),
    check_stmt(Body, Vars, FuncSigs).
check_stmt(for_loop(Name, Start, End, _Dir, Body), Vars, FuncSigs) :-
    ensure_declared(Name, Vars, integer),
    check_expr(Start, Vars, FuncSigs, integer),
    check_expr(End, Vars, FuncSigs, integer),
    check_stmt(Body, Vars, FuncSigs).
check_stmt(case_stmt(Selector, Branches, ElseBody), Vars, FuncSigs) :-
    check_expr(Selector, Vars, FuncSigs, SelType),
    ensure_case_selector_type(SelType),
    forall(member(case_branch(Labels, Body), Branches),
           ( forall(member(Label, Labels), ensure_case_label(Label, SelType)),
             check_stmt(Body, Vars, FuncSigs) )),
    check_stmt(ElseBody, Vars, FuncSigs).
check_stmt(writeln(expr(Expr)), Vars, FuncSigs) :-
    check_expr(Expr, Vars, FuncSigs, Type),
    ensure_writable_type(Type).
check_stmt(writeln(str(_)), _, _).
check_stmt(writeln_multi(Args), Vars, FuncSigs) :-
    forall(member(Arg, Args), check_writeln_arg(Arg, Vars, FuncSigs)).
check_stmt(write_multi(Args), Vars, FuncSigs) :-
    forall(member(Arg, Args), check_writeln_arg(Arg, Vars, FuncSigs)).
check_stmt(write(expr(Expr)), Vars, FuncSigs) :-
    check_expr(Expr, Vars, FuncSigs, Type),
    ensure_writable_type(Type).
check_stmt(write(str(_)), _, _).
check_stmt(write(Expr, _), Vars, FuncSigs) :-
    check_expr(Expr, Vars, FuncSigs, Type),
    ensure_writable_type(Type).
check_stmt(write(_, Expr), Vars, FuncSigs) :-
    check_expr(Expr, Vars, FuncSigs, Type),
    ensure_writable_type(Type).
check_stmt(readln(Name), Vars, _) :-
    ensure_writable_name(Name, Vars),
    ensure_declared(Name, Vars, Type),
    ensure_readable_type(Type).
check_stmt(readln_field(Name, Field), Vars, _) :-
    ensure_writable_name(Name, Vars),
    ensure_declared(Name, Vars, RecordType),
    ensure_record_type(RecordType, Name, Fields),
    ensure_record_field(Fields, Name, Field, FieldType),
    ensure_readable_type(FieldType).
check_stmt(new_ptr(LValue), Vars, _) :-
    ensure_writable_lvalue(LValue, Vars),
    lvalue_type(LValue, Vars, LType),
    ensure_pointer_type(LType, LValue, _TargetType).
check_stmt(dispose_ptr(LValue), Vars, _) :-
    ensure_writable_lvalue(LValue, Vars),
    lvalue_type(LValue, Vars, LType),
    ensure_pointer_type(LType, LValue, _TargetType).
check_stmt(block(LocalConsts, LocalVars, Stmts), Vars, FuncSigs) :-
    check_block(block(LocalConsts, LocalVars, Stmts), Vars, FuncSigs).
check_stmt(proc_call(Name, Args), Vars, FuncSigs) :-
    ensure_function_declared(Name, FuncSigs, ParamSpecs, _ReturnType),
    length(Args, ActualArity),
    length(ParamSpecs, ExpectedArity),
    (   ActualArity = ExpectedArity
    ->  true
    ;   throw(error(wrong_arity(Name, ExpectedArity, ActualArity), context(semantics/check_stmt, 'Procedure called with incorrect number of arguments')))
    ),
    check_call_args(Args, ParamSpecs, Name, Vars, FuncSigs).

check_expr(int(_), _, _, integer).
check_expr(bool(_), _, _, boolean).
check_expr(char(_), _, _, char).
check_expr(nil, _, _, nil_type).
check_expr(set_lit(Elements), Vars, FuncSigs, set_literal(Bounds)) :-
    check_set_literal_elements(Elements, Vars, FuncSigs, Bounds).
check_expr(var(Name), Vars, _, Type) :-
    ensure_declared(Name, Vars, Type).
check_expr(addr_of(Name), Vars, _, ptr(Type)) :-
    ensure_declared(Name, Vars, Type).
check_expr(ptr_deref(Name), Vars, _, TargetType) :-
    ensure_declared(Name, Vars, PtrType),
    ensure_pointer_type(PtrType, Name, TargetType0),
    resolve_type(TargetType0, TargetType).
check_expr(field_ref(Name, Field), Vars, _, FieldType) :-
    ensure_declared(Name, Vars, RecordType),
    ensure_record_type(RecordType, Name, Fields),
    ensure_record_field(Fields, Name, Field, FieldType).
check_expr(ptr_field_ref(Name, Field), Vars, _, FieldType) :-
    ensure_declared(Name, Vars, PtrType),
    ensure_pointer_target_record(PtrType, Name, Fields),
    ensure_record_field(Fields, Name, Field, FieldType).
check_expr(array_ref(Name, IndexExpr), Vars, FuncSigs, ElementType) :-
    ensure_declared(Name, Vars, array(_Low, _High, ElementType)),
    check_expr(IndexExpr, Vars, FuncSigs, integer).
check_expr(call(Name, Args), Vars, FuncSigs, ReturnType) :-
    ensure_function_declared(Name, FuncSigs, ParamSpecs, ReturnType),
    (   ReturnType == void
    ->  throw(error(procedure_used_as_expression(Name), context(semantics/check_expr, 'Procedures do not return a value and cannot appear in expressions')))
    ;   true
    ),
    length(Args, ActualArity),
    length(ParamSpecs, ExpectedArity),
    (   ActualArity = ExpectedArity
    ->  true
    ;   throw(error(wrong_arity(Name, ExpectedArity, ActualArity), context(semantics/check_expr, 'Function called with incorrect number of arguments')))
    ),
    check_call_args(Args, ParamSpecs, Name, Vars, FuncSigs).
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
bin_expr_type(Op, LeftType0, RightType0, SetType) :-
    memberchk(Op, ['+', '-', '*']),
    set_binary_result_type(LeftType0, RightType0, SetType),
    !.
bin_expr_type(Op, integer, integer, boolean) :-
    memberchk(Op, ['=', '<>', '<', '<=', '>', '>=']).
bin_expr_type(Op, char, char, boolean) :-
    memberchk(Op, ['=', '<>', '<', '<=', '>', '>=']).
bin_expr_type(Op, boolean, boolean, boolean) :-
    memberchk(Op, [and, or, '=', '<>']).
bin_expr_type(Op, LeftType, RightType, boolean) :-
    is_pointer_type(LeftType),
    is_pointer_type(RightType),
    memberchk(Op, ['=', '<>']),
    pointer_types_compatible(LeftType, RightType).
bin_expr_type(Op, LeftType, nil_type, boolean) :-
    is_pointer_type(LeftType),
    memberchk(Op, ['=', '<>']).
bin_expr_type(Op, nil_type, RightType, boolean) :-
    is_pointer_type(RightType),
    memberchk(Op, ['=', '<>']).
bin_expr_type(Op, LeftType0, RightType0, boolean) :-
    memberchk(Op, ['=', '<>', '<=', '>=']),
    set_comparable_types(LeftType0, RightType0),
    !.
bin_expr_type(in, integer, SetType0, boolean) :-
    resolve_type(SetType0, SetType),
    is_set_value_type(SetType).
bin_expr_type(in, integer, set_literal(_), boolean).

is_pointer_type(ptr(_)).

check_exprs([], [], _, _).
check_exprs([Expr|Rest], [Type|Types], Vars, FuncSigs) :-
    check_expr(Expr, Vars, FuncSigs, Type),
    check_exprs(Rest, Types, Vars, FuncSigs).

check_call_args([], [], _, _, _).
check_call_args([Arg|Rest], [spec(value, Type)|SpecRest], FuncName, Vars, FuncSigs) :-
    check_expr(Arg, Vars, FuncSigs, ActualType),
    ensure_assignable(Type, ActualType),
    check_call_args(Rest, SpecRest, FuncName, Vars, FuncSigs).
check_call_args([Arg|Rest], [spec(var_ref, Type)|SpecRest], FuncName, Vars, FuncSigs) :-
    ensure_var_ref_arg(Arg, Type, FuncName, Vars),
    check_call_args(Rest, SpecRest, FuncName, Vars, FuncSigs).

ensure_var_ref_arg(var(Name), Type, _FuncName, Vars) :-
    !,
    ensure_writable_name(Name, Vars),
    ensure_declared(Name, Vars, ActualType),
    resolve_type(ActualType, ResolvedActual),
    resolve_type(Type, ResolvedType),
    (   ResolvedActual == ResolvedType
    ->  true
    ;   throw(error(type_mismatch(ResolvedType, ResolvedActual), context(semantics/ensure_var_ref_arg, 'var argument has wrong type')))
    ).
ensure_var_ref_arg(field_ref(Name, Field), Type, _FuncName, Vars) :-
    !,
    ensure_writable_name(Name, Vars),
    ensure_declared(Name, Vars, RecordType),
    ensure_record_type(RecordType, Name, Fields),
    ensure_record_field(Fields, Name, Field, ActualType),
    resolve_type(ActualType, ResolvedActual),
    resolve_type(Type, ResolvedType),
    (   ResolvedActual == ResolvedType
    ->  true
    ;   throw(error(type_mismatch(ResolvedType, ResolvedActual), context(semantics/ensure_var_ref_arg, 'var field argument has wrong type')))
    ).
ensure_var_ref_arg(ptr_deref(Name), Type, _FuncName, Vars) :-
    !,
    ensure_writable_name(Name, Vars),
    ensure_declared(Name, Vars, PtrType),
    ensure_pointer_type(PtrType, Name, ActualType),
    resolve_type(ActualType, ResolvedActual),
    resolve_type(Type, ResolvedType),
    (   ResolvedActual == ResolvedType
    ->  true
    ;   throw(error(type_mismatch(ResolvedType, ResolvedActual), context(semantics/ensure_var_ref_arg, 'var dereference argument has wrong type')))
    ).
ensure_var_ref_arg(ptr_field_ref(Name, Field), Type, _FuncName, Vars) :-
    !,
    ensure_writable_name(Name, Vars),
    ensure_declared(Name, Vars, PtrType),
    ensure_pointer_target_record(PtrType, Name, Fields),
    ensure_record_field(Fields, Name, Field, ActualType),
    resolve_type(ActualType, ResolvedActual),
    resolve_type(Type, ResolvedType),
    (   ResolvedActual == ResolvedType
    ->  true
    ;   throw(error(type_mismatch(ResolvedType, ResolvedActual), context(semantics/ensure_var_ref_arg, 'var pointer-field argument has wrong type')))
    ).
ensure_var_ref_arg(Arg, _Type, FuncName, _Vars) :-
    throw(error(var_arg_not_lvalue(FuncName, Arg), context(semantics/ensure_var_ref_arg, 'var parameter requires a variable argument'))).

ensure_writable_name(Name, Vars) :-
    (   memberchk(Name-const(_, _), Vars)
    ->  throw(error(assign_to_const(Name), context(semantics/ensure_writable_name, 'Constant values are read-only')))
    ;   true
    ).

ensure_writable_lvalue(var(Name), Vars) :-
    !,
    ensure_writable_name(Name, Vars).
ensure_writable_lvalue(field_ref(Name, _), Vars) :-
    !,
    ensure_writable_name(Name, Vars).
ensure_writable_lvalue(ptr_deref(Name), Vars) :-
    !,
    ensure_writable_name(Name, Vars).
ensure_writable_lvalue(ptr_field_ref(Name, _), Vars) :-
    !,
    ensure_writable_name(Name, Vars).
ensure_writable_lvalue(_, _).

ensure_declared(Name, Vars, Type) :-
    (   memberchk(Name-const(ConstType, _), Vars)
    ->  ensure_expected_type(Type, ConstType)
    ;   memberchk(Name-ActualType, Vars)
    ->  ensure_expected_type(Type, ActualType)
    ;   throw(error(undeclared_variable(Name), context(semantics/ensure_declared, 'Variable not declared in current scope')))
    ).

ensure_expected_type(Expected, Actual) :-
    var(Expected),
    !,
    Expected = Actual.
ensure_expected_type(Type, Type) :- !.
ensure_expected_type(Expected, Actual) :-
    resolve_type(Expected, ResolvedExpected),
    resolve_type(Actual, ResolvedActual),
    (   ResolvedExpected == ResolvedActual
    ->  true
    ;   throw(error(type_mismatch(ResolvedExpected, ResolvedActual), context(semantics/ensure_declared, 'Variable has a different declared type')))
    ).

ensure_function_declared(Name, FuncSigs, ParamTypes, ReturnType) :-
    (   memberchk(func_sig(Name, ParamTypes, ReturnType), FuncSigs)
    ->  true
    ;   throw(error(undeclared_function(Name), context(semantics/ensure_function_declared, 'Function not declared or wrong arity')))
    ).

ensure_assignable(Type, Type) :- !.
ensure_assignable(Expected0, nil_type) :-
    resolve_type(Expected0, Expected),
    is_pointer_type(Expected),
    !.
ensure_assignable(Expected0, Actual0) :-
    resolve_type(Expected0, Expected),
    resolve_type(Actual0, Actual),
    set_assignable(Expected, Actual),
    !.
ensure_assignable(Expected0, Actual0) :-
    resolve_type(Expected0, Expected),
    resolve_type(Actual0, Actual),
    types_compatible(Expected, Actual),
    !.
ensure_assignable(Expected, Actual) :-
    throw(error(type_mismatch(Expected, Actual), context(semantics/ensure_assignable, 'Expression type is not assignable to target'))).

set_assignable(set(subrange(Low, High)), set_literal(empty_bounds)) :-
    integer(Low),
    integer(High),
    !.
set_assignable(set(subrange(Low, High)), set_literal(bounds(Min, Max))) :-
    integer(Low),
    integer(High),
    Low =< Min,
    Max =< High,
    !.

types_compatible(Expected, Actual) :-
    Expected == Actual,
    !.
types_compatible(Expected, Actual) :-
    is_pointer_type(Expected),
    is_pointer_type(Actual),
    pointer_types_compatible(Expected, Actual).

pointer_types_compatible(ptr(ExpectedTarget0), ptr(ActualTarget0)) :-
    resolve_type(ExpectedTarget0, ExpectedTarget),
    resolve_type(ActualTarget0, ActualTarget),
    ExpectedTarget == ActualTarget.

set_comparable_types(LeftType0, RightType0) :-
    resolve_type(LeftType0, LeftType),
    resolve_type(RightType0, RightType),
    (   set_binary_result_type(LeftType, RightType, _)
    ->  true
    ;   LeftType = set_literal(empty_bounds), is_set_value_type(RightType)
    ;   RightType = set_literal(empty_bounds), is_set_value_type(LeftType)
    ).

set_binary_result_type(LeftType0, RightType0, SetType) :-
    resolve_type(LeftType0, LeftType),
    resolve_type(RightType0, RightType),
    set_binary_result_type_resolved(LeftType, RightType, SetType).

set_binary_result_type_resolved(set(subrange(Low, High)), set(subrange(Low, High)), set(subrange(Low, High))).
set_binary_result_type_resolved(set(subrange(Low, High)), set_literal(empty_bounds), set(subrange(Low, High))).
set_binary_result_type_resolved(set_literal(empty_bounds), set(subrange(Low, High)), set(subrange(Low, High))).
set_binary_result_type_resolved(set(subrange(Low, High)), set_literal(bounds(Min, Max)), set(subrange(Low, High))) :-
    Low =< Min,
    Max =< High.
set_binary_result_type_resolved(set_literal(bounds(Min, Max)), set(subrange(Low, High)), set(subrange(Low, High))) :-
    Low =< Min,
    Max =< High.

is_set_value_type(set(subrange(_, _))).

check_set_literal_elements([], _Vars, _FuncSigs, empty_bounds).
check_set_literal_elements([Elem|Rest], Vars, FuncSigs, bounds(Min, Max)) :-
    set_elem_bounds(Elem, Vars, FuncSigs, ElemMin, ElemMax),
    check_set_literal_rest(Rest, Vars, FuncSigs, ElemMin, ElemMax, Min, Max).

check_set_literal_rest([], _Vars, _FuncSigs, Min, Max, Min, Max).
check_set_literal_rest([Elem|Rest], Vars, FuncSigs, AccMin, AccMax, Min, Max) :-
    set_elem_bounds(Elem, Vars, FuncSigs, ElemMin, ElemMax),
    NextMin is min(AccMin, ElemMin),
    NextMax is max(AccMax, ElemMax),
    check_set_literal_rest(Rest, Vars, FuncSigs, NextMin, NextMax, Min, Max).

set_elem_bounds(set_elem_value(Expr), Vars, FuncSigs, Value, Value) :-
    check_expr(Expr, Vars, FuncSigs, integer),
    eval_const_int_expr(Expr, Value),
    ensure_set_member_range(Value).
set_elem_bounds(set_elem_range(LowExpr, HighExpr), Vars, FuncSigs, Low, High) :-
    check_expr(LowExpr, Vars, FuncSigs, integer),
    check_expr(HighExpr, Vars, FuncSigs, integer),
    eval_const_int_expr(LowExpr, Low),
    eval_const_int_expr(HighExpr, High),
    (   Low =< High
    ->  true
    ;   throw(error(invalid_set_literal_range(Low, High), context(semantics/set_elem_bounds, 'Set literal range lower bound must not exceed upper bound')))
    ),
    ensure_set_member_range(Low),
    ensure_set_member_range(High).

eval_const_int_expr(int(N), N).
eval_const_int_expr(unary('-', Expr), Value) :-
    eval_const_int_expr(Expr, Inner),
    Value is -Inner.
eval_const_int_expr(Expr, _) :-
    throw(error(non_constant_set_literal_expr(Expr), context(semantics/eval_const_int_expr, 'Set literal elements must be constant integer expressions'))).

ensure_set_member_range(Value) :-
    (   Value >= 0,
        Value =< 63
    ->  true
    ;   throw(error(set_value_out_of_range(Value, 0, 63), context(semantics/ensure_set_member_range, 'v1 set values must be in 0..63')))
    ).

ensure_writable_type(integer).
ensure_writable_type(boolean).
ensure_writable_type(char).
ensure_writable_type(array(_, _, char)).

check_writeln_arg(str(_), _, _).
check_writeln_arg(expr(Expr), Vars, FuncSigs) :-
    check_expr(Expr, Vars, FuncSigs, Type),
    ensure_writable_type(Type).

ensure_case_selector_type(integer) :- !.
ensure_case_selector_type(char) :- !.
ensure_case_selector_type(Type) :-
    throw(error(case_selector_type(Type), _)).

ensure_case_label(label_const(int(_)), integer) :- !.
ensure_case_label(label_const(char(_)), char) :- !.
ensure_case_label(Label, SelType) :-
    throw(error(case_label_type_mismatch(Label, SelType), _)).

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
ensure_valid_type(type_ref(Name)) :-
    !,
    resolve_type(type_ref(Name), Resolved),
    ensure_valid_type(Resolved).
ensure_valid_type(ptr(TargetType)) :-
    !,
    ensure_pointer_target_declared(TargetType).
ensure_valid_type(array(Low, High, ElementType)) :-
    integer(Low),
    integer(High),
    (   Low =< High
    ->  true
    ;   throw(error(invalid_array_bounds(Low, High), context(semantics/ensure_valid_type, 'Array lower bound must not exceed upper bound')))
    ),
    ensure_scalar_type(ElementType).
ensure_valid_type(set(subrange(Low, High))) :-
    integer(Low),
    integer(High),
    (   Low =< High
    ->  true
    ;   throw(error(invalid_set_bounds(Low, High), context(semantics/ensure_valid_type, 'Set lower bound must not exceed upper bound')))
    ),
    (   Low >= 0,
        High =< 63
    ->  true
    ;   throw(error(set_bounds_out_of_range(Low, High, 0, 63), context(semantics/ensure_valid_type, 'v1 set bounds must fit in 0..63')))
    ).
ensure_valid_type(record(Fields)) :-
    ensure_record_fields_valid(Fields).

ensure_record_fields_valid(Fields) :-
    findall(FieldName, member(field(FieldName, _), Fields), FieldNames),
    ensure_no_duplicates(FieldNames),
    forall(member(field(_, FieldType), Fields), ensure_valid_type(FieldType)).

ensure_scalar_type(integer).
ensure_scalar_type(boolean).
ensure_scalar_type(char).
ensure_scalar_type(ptr(_)).
ensure_scalar_type(set(subrange(_, _))).
ensure_scalar_type(type_ref(Name)) :-
    !,
    resolve_type(type_ref(Name), Resolved),
    ensure_scalar_type(Resolved).
ensure_scalar_type(Type) :-
    throw(error(unsupported_type(Type), context(semantics/ensure_scalar_type, 'Only scalar types are supported here'))).

ensure_not_aggregate(array(_, _, _)) :-
    !,
    throw(error(type_mismatch(scalar, array), context(semantics/ensure_not_array, 'Array values require indexed element access'))).
ensure_not_aggregate(record(_)) :-
    !,
    throw(error(type_mismatch(scalar, record), context(semantics/ensure_not_aggregate, 'Record values require field access'))).
ensure_not_aggregate(_).

ensure_record_type(record(Fields), _Name, Fields) :- !.
ensure_record_type(type_ref(Name), RecordName, Fields) :-
    !,
    resolve_type(type_ref(Name), Resolved),
    ensure_record_type(Resolved, RecordName, Fields).
ensure_record_type(Type, Name, _) :-
    throw(error(type_mismatch(record, Type), context(semantics/check_expr, Name))).

ensure_record_field(Fields, _RecordName, Field, Type) :-
    member(field(Field, Type), Fields),
    !.
ensure_record_field(_Fields, RecordName, Field, _Type) :-
    throw(error(unknown_record_field(RecordName, Field), context(semantics/check_expr, 'Record field not declared'))).

ensure_pointer_type(Type0, Name, TargetType) :-
    resolve_type(Type0, Type),
    (   Type = ptr(TargetType)
    ->  true
    ;   throw(error(type_mismatch(pointer, Type), context(semantics/check_expr, Name)))
    ).

ensure_pointer_target_record(PtrType, Name, Fields) :-
    ensure_pointer_type(PtrType, Name, TargetType),
    ensure_record_type(TargetType, Name, Fields).

ensure_pointer_target_declared(type_ref(Name)) :-
    !,
    (   type_alias(Name, _)
    ->  true
    ;   throw(error(undeclared_type(Name), context(semantics/ensure_valid_type, 'Named pointer target type not declared')))
    ).
ensure_pointer_target_declared(TargetType) :-
    resolve_type(TargetType, ResolvedTarget),
    ensure_valid_type(ResolvedTarget).

lvalue_type(var(Name), Vars, Type) :-
    ensure_declared(Name, Vars, Type).
lvalue_type(field_ref(Name, Field), Vars, Type) :-
    ensure_declared(Name, Vars, RecordType),
    ensure_record_type(RecordType, Name, Fields),
    ensure_record_field(Fields, Name, Field, Type).
lvalue_type(ptr_deref(Name), Vars, Type) :-
    ensure_declared(Name, Vars, PtrType),
    ensure_pointer_type(PtrType, Name, Type).
lvalue_type(ptr_field_ref(Name, Field), Vars, Type) :-
    ensure_declared(Name, Vars, PtrType),
    ensure_pointer_target_record(PtrType, Name, Fields),
    ensure_record_field(Fields, Name, Field, Type).

check_block(block(LocalConsts, LocalVars, Stmts), VarsInScope, FuncSigs) :-
    check_const_decls(LocalConsts, VarsInScope, LocalConstEnv),
    ensure_no_duplicate_decls(LocalVars),
    ensure_const_var_disjoint(LocalConsts, LocalVars),
    ensure_valid_decls(LocalVars),
    decls_env(LocalVars, LocalEnv),
    append(LocalConstEnv, LocalEnv, ScopeVars0),
    append(ScopeVars0, VarsInScope, ScopeVars),
    check_stmts(Stmts, ScopeVars, FuncSigs).