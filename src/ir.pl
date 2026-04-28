:- module(ir, [lower_program/2]).

:- discontiguous lower_stmt/6.
:- dynamic func_return_type/2.
:- dynamic func_param_modes/2.

lower_program(program(Name, Funcs, Vars, Block), ir_program(Name, IRFuncs, AllVars, IRStmts)) :-
    init_func_metadata(Funcs),
    vars_env(Vars, GlobalEnv),
    lower_funcs(Funcs, GlobalEnv, IRFuncs),
    lower_block(Block, GlobalEnv, 0, _CounterOut, IRStmts, LocalVars),
    append(Vars, LocalVars, AllVars).

init_func_metadata(Funcs) :-
    retractall(func_return_type(_, _)),
    retractall(func_param_modes(_, _)),
    forall(member(func(FuncName, Params, ReturnType, _LocalVars, _Body), Funcs),
           ( assertz(func_return_type(FuncName, ReturnType)),
             param_modes(Params, Modes),
             assertz(func_param_modes(FuncName, Modes)) )).

param_modes([], []).
param_modes([param(_, _)|Rest], [value|ModeRest]) :- param_modes(Rest, ModeRest).
param_modes([param_var(_, _)|Rest], [var_ref|ModeRest]) :- param_modes(Rest, ModeRest).

decl_name(decl(Name, _), Name).
decl_name(param(Name, _), Name).
decl_name(param_var(Name, _), Name).

decl_type(decl(_, Type), Type).
decl_type(param(_, Type), Type).
decl_type(param_var(_, Type), Type).

rename_decl(decl(_, Type), MappedName, decl(MappedName, Type)).
rename_decl(param(_, Type), MappedName, param(MappedName, Type)).
rename_decl(param_var(_, Type), MappedName, param_var(MappedName, Type)).

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
lower_stmt(for_loop(Name, Start, End, Dir, Body), Env, CounterIn, CounterOut,
           ir_block([ir_assign(MappedName, IRStart),
                     ir_while(ir_bin(CmpOp, ir_var(MappedName), IREnd),
                              ir_block([IRBody,
                                        ir_assign(MappedName,
                                                  ir_bin(StepOp, ir_var(MappedName), ir_int(1)))]))]),
           AddedVars) :-
    map_name(Name, Env, MappedName),
    lookup_type(Name, Env, integer),
    lower_expr(Start, Env, IRStart, integer),
    lower_expr(End, Env, IREnd, integer),
    for_ops(Dir, CmpOp, StepOp),
    lower_stmt(Body, Env, CounterIn, CounterOut, IRBody, AddedVars).
lower_stmt(case_stmt(Selector, Branches, ElseBody), Env, CounterIn, CounterOut, IRStmt, AddedVars) :-
    lower_stmt(ElseBody, Env, CounterIn, CounterAfterElse, IRElse, AddedElse),
    lower_case_branches(Branches, Selector, Env, CounterAfterElse, CounterOut, IRElse, IRStmt, AddedBranches),
    append(AddedElse, AddedBranches, AddedVars).
lower_stmt(writeln(expr(Expr)), Env, Counter, Counter, IRStmt, []) :-
    lower_expr(Expr, Env, IRExpr, Type),
    output_stmt(writeln, Type, IRExpr, IRStmt).
lower_stmt(writeln(str(Text)), _Env, Counter, Counter, ir_writeln_str(Text), []).
lower_stmt(writeln_multi(Args), Env, Counter, Counter, ir_block(IRStmts), []) :-
    lower_writeln_multi(Args, Env, IRStmts).
lower_stmt(write_multi(Args), Env, Counter, Counter, ir_block(IRStmts), []) :-
    lower_write_multi(Args, Env, IRStmts).
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
    func_param_modes(Name, Modes),
    lower_call_args(Args, Modes, Env, IRArgs).

output_stmt(writeln, char, IRExpr, ir_writeln_char(IRExpr)) :- !.
output_stmt(writeln, array(Low, High, char), ir_var(Name), ir_writeln_char_array(Name, Low, High)) :- !.
output_stmt(writeln, _, IRExpr, ir_writeln_int(IRExpr)).
output_stmt(write, char, IRExpr, ir_write_char(IRExpr)) :- !.
output_stmt(write, array(Low, High, char), ir_var(Name), ir_write_char_array(Name, Low, High)) :- !.
output_stmt(write, _, IRExpr, ir_write_int(IRExpr)).

lower_writeln_multi([Arg], Env, [IR]) :-
    !,
    lower_writeln_arg(writeln, Arg, Env, IR).
lower_writeln_multi([Arg|Rest], Env, [IR|IRRest]) :-
    lower_writeln_arg(write, Arg, Env, IR),
    lower_writeln_multi(Rest, Env, IRRest).

lower_write_multi([], _Env, []).
lower_write_multi([Arg|Rest], Env, [IR|IRRest]) :-
    lower_writeln_arg(write, Arg, Env, IR),
    lower_write_multi(Rest, Env, IRRest).

lower_writeln_arg(write, str(Text), _Env, ir_write_str(Text)) :- !.
lower_writeln_arg(writeln, str(Text), _Env, ir_writeln_str(Text)) :- !.
lower_writeln_arg(Mode, expr(Expr), Env, IRStmt) :-
    lower_expr(Expr, Env, IRExpr, Type),
    output_stmt(Mode, Type, IRExpr, IRStmt).

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
    func_param_modes(Name, Modes),
    lower_call_args(Args, Modes, Env, IRArgs).
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

for_ops(to, '<=', '+').
for_ops(downto, '>=', '-').

lower_case_branches([], _Selector, _Env, Counter, Counter, IRElse, IRElse, []).
lower_case_branches([case_branch(Labels, Body)|Rest], Selector, Env, CounterIn, CounterOut, IRElse, IRStmt, AddedVars) :-
    lower_stmt(Body, Env, CounterIn, CounterAfterBody, IRBody, AddedBody),
    lower_case_branches(Rest, Selector, Env, CounterAfterBody, CounterOut, IRElse, IRRest, AddedRest),
    lower_case_cond(Labels, Selector, Env, IRCond),
    IRStmt = ir_if(IRCond, IRBody, IRRest),
    append(AddedBody, AddedRest, AddedVars).

lower_case_cond([Label], Selector, Env, IRCond) :-
    !,
    lower_case_label(Label, Selector, Env, IRCond).
lower_case_cond([Label|Rest], Selector, Env, ir_bin(or, IRThis, IRRest)) :-
    lower_case_label(Label, Selector, Env, IRThis),
    lower_case_cond(Rest, Selector, Env, IRRest).

lower_case_label(label_const(int(N)), Selector, Env, ir_bin('=', IRSel, ir_int(N))) :-
    lower_expr(Selector, Env, IRSel, _).
lower_case_label(label_const(char(Code)), Selector, Env, ir_bin('=', IRSel, ir_char(Code))) :-
    lower_expr(Selector, Env, IRSel, _).

lower_exprs([], _, []).
lower_exprs([Expr|Rest], Env, [IRExpr|IRRest]) :-
    lower_expr(Expr, Env, IRExpr, _),
    lower_exprs(Rest, Env, IRRest).

lower_call_args([], [], _, []).
lower_call_args([Arg|Rest], [value|ModeRest], Env, [IRArg|IRRest]) :-
    lower_expr(Arg, Env, IRArg, _),
    lower_call_args(Rest, ModeRest, Env, IRRest).
lower_call_args([var(Name)|Rest], [var_ref|ModeRest], Env, [ir_addr_of(MappedName)|IRRest]) :-
    map_name(Name, Env, MappedName),
    lower_call_args(Rest, ModeRest, Env, IRRest).
