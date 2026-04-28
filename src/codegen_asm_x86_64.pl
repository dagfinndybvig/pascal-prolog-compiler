% Code generator for x86-64 assembly
% This is a minimal implementation for the PoC

:- module(codegen_asm_x86_64, [
    generate_asm/2,  % generate_asm(+IR, -Assembly)
    generate_asm_text/2,  % generate_asm_text(+IR, -Assembly)
    generate_func_asm/2,  % generate_func_asm(+IRFunc, +Stream)
    asm_header/1,    % asm_header(-Header)
    asm_footer/1,    % asm_footer(-Footer)
    asm_writeln_str/2, % asm_writeln_str(+String, -Assembly)
    asm_writeln_int_text/2, % asm_writeln_int_text(+Expr, -Assembly)
    asm_assign/3,    % asm_assign(+VarName, +Expr, -Assembly)
    asm_expr/2,      % asm_expr(+Expr, -Assembly)
    init_var_offsets/1, % init_var_offsets(+Vars)
    asm_stack_overflow_handler/1, % asm_stack_overflow_handler(-Handler)
    asm_overflow_message/1, % asm_overflow_message(-Message)
    asm_stack_frame/2, % asm_stack_frame(+TotalSize, -Assembly)
    asm_main_epilogue/1, % asm_main_epilogue(-Assembly)
    total_stack_size/2, % total_stack_size(+VarsOrVarCount, -TotalSize)
    init_register_allocator/0, % init_register_allocator
    allocate_register/1, % allocate_register(-Register)
    free_register/1, % free_register(+Register)
    get_temp_register/1, % get_temp_register(-Register)
    asm_division_by_zero_handler/1, % asm_division_by_zero_handler(-Handler)
    asm_div_by_zero_message/1, % asm_div_by_zero_message(-Message)
    asm_array_bounds_handler/1, % asm_array_bounds_handler(-Handler)
    asm_array_bounds_message/1 % asm_array_bounds_message(-Message)
]).

% Counter for generating unique labels
:- dynamic label_counter/1.
label_counter(0).

% Counter and mapping for emitted string literals
:- dynamic string_counter/1.
:- dynamic string_label/2.
string_counter(0).

% Variable stack offset tracking
:- dynamic var_offset/2.

% Track if we need int_format
:- dynamic needs_int_format/0.

% Stack-frame safety configuration
:- dynamic stack_guard_size/1.
stack_guard_size(4096).  % Reserved size constant for stack safety checks

% Register allocation state
:- dynamic available_registers/1.
:- dynamic register_usage/2.

% Available registers for expression evaluation
init_register_allocator :-
    retractall(available_registers(_)),
    retractall(register_usage(_, _)),
    % Use callee-saved registers (rbx, r12-r15) for temporaries.
    % These need to be saved/restored in function prologue/epilogue.
    assert(available_registers([rbx, r12, r13, r14, r15])),
    % %rax is always used for results
    assert(register_usage(rax, used)),
    assert(register_usage(rbx, available)),
    assert(register_usage(r12, available)),
    assert(register_usage(r13, available)),
    assert(register_usage(r14, available)),
    assert(register_usage(r15, available)).

% Allocate a register for expression evaluation
allocate_register(Register) :-
    available_registers(Regs),
    member(Register, Regs),
    retract(available_registers(Regs)),
    delete(Regs, Register, NewRegs),
    assert(available_registers(NewRegs)),
    retract(register_usage(Register, _)),
    assert(register_usage(Register, used)).

% Free a register
free_register(Register) :-
    retract(register_usage(Register, _)),
    assert(register_usage(Register, available)),
    available_registers(Regs),
    retract(available_registers(Regs)),
    assert(available_registers([Register|Regs])).

% Get any available callee-saved register
get_temp_register(Register) :-
    available_registers(Regs),
    Regs \= [],
    Regs = [Register|_],
    allocate_register(Register).

% Get a register with preference for less frequently used ones
get_preferred_temp_register(Register) :-
    available_registers(Regs),
    Regs \= [],
    % Prefer r12-r15 over rbx as they're less likely to be used by system libraries
    (   member(r12, Regs) -> Register = r12
    ;   member(r13, Regs) -> Register = r13
    ;   member(r14, Regs) -> Register = r14
    ;   member(r15, Regs) -> Register = r15
    ;   member(rbx, Regs) -> Register = rbx
    ;   Regs = [Register|_]  % Fallback to first available
    ),
    allocate_register(Register).

% Initialize variable offsets and flags
init_var_offsets(Vars) :-
    retractall(var_offset(_, _)),
    retractall(needs_int_format),
    retractall(label_counter(_)),
    retractall(string_counter(_)),
    retractall(string_label(_, _)),
    assert(label_counter(0)),
    assert(string_counter(0)),
    init_var_offsets(Vars, 48),  % Main saves callee-saved regs at -8..-40
    init_register_allocator.  % Initialize register allocator

init_var_offsets([], _).
init_var_offsets([Var|Vars], Offset) :-
    storage_name(Var, Name),
    assert(var_offset(Name, Offset)),
    storage_slots(Var, Slots),
    NextOffset is Offset + (Slots * 8),
    init_var_offsets(Vars, NextOffset).

storage_name(decl(Name, _), Name) :- !.
storage_name(param(Name, _), Name) :- !.
storage_name(Name, Name).

param_name(param(Name, _), Name) :- !.
param_name(Name, Name).

local_storage_name(decl(Name, _), Name) :- !.
local_storage_name(Name, Name).

storage_type(decl(_, Type), Type) :- !.
storage_type(param(_, Type), Type) :- !.
storage_type(_, integer).

array_type_slots(array(Low, High, _), Slots) :-
    !,
    Slots is High - Low + 1.
array_type_slots(_, 1).

storage_slots(Storage, Slots) :-
    storage_type(Storage, Type),
    array_type_slots(Type, Slots).

storage_slots_before([], _, 0).
storage_slots_before([_|_], 1, 0) :- !.
storage_slots_before([Storage|Rest], Index, SlotsBefore) :-
    Index > 1,
    storage_slots(Storage, Slots),
    NextIndex is Index - 1,
    storage_slots_before(Rest, NextIndex, RestSlots),
    SlotsBefore is Slots + RestSlots.

storage_slot_count(Storages, Count) :-
    findall(Slots, (member(Storage, Storages), storage_slots(Storage, Slots)), SlotCounts),
    sum_list(SlotCounts, Count).

% Generate assembly for different IR statements
generate_asm(ir_writeln_str(String), Assembly) :-
    asm_writeln_str(String, Assembly).
generate_asm(ir_write_str(String), Assembly) :-
    asm_write_str(String, Assembly).
generate_asm(ir_writeln_int(_Expr), Assembly) :-
    format(atom(Assembly), "", []).
generate_asm(ir_write_int(_Expr), Assembly) :-
    format(atom(Assembly), "", []).
generate_asm(ir_writeln_char(_Expr), Assembly) :-
    format(atom(Assembly), "", []).
generate_asm(ir_write_char(_Expr), Assembly) :-
    format(atom(Assembly), "", []).
generate_asm(ir_writeln_char_array(_, _, _), Assembly) :-
    format(atom(Assembly), "", []).
generate_asm(ir_write_char_array(_, _, _), Assembly) :-
    format(atom(Assembly), "", []).

% Enhanced write statements for stdlib - data section
generate_asm(ir_write_int_str(_Expr, Text), Assembly) :-
    asm_string_data(Text, Assembly).
generate_asm(ir_write_str_int(Text, _Expr), Assembly) :-
    asm_string_data(Text, Assembly).
generate_asm(ir_write_int_str_int(_Expr1, Text, _Expr2), Assembly) :-
    asm_string_data(Text, Assembly).
generate_asm(ir_write_format(_, _, _, _), _) :-
    throw(error(unsupported_write_format, context(codegen/generate_asm, 'printf-style formatting is not exposed by the Pascal frontend'))).

generate_asm(ir_readln(_Name), Assembly) :-
    format(atom(Assembly), "", []).
generate_asm(ir_readln_char(_Name), Assembly) :-
    format(atom(Assembly), "", []).
generate_asm(ir_assign(_VarName, _Expr), Assembly) :-
    format(atom(Assembly), "", []).
generate_asm(ir_array_store(_, _, _, _, _), Assembly) :-
    format(atom(Assembly), "", []).
generate_asm(ir_if(_, ThenStmt, ElseStmt), Assembly) :-
    generate_asm(ThenStmt, ThenData),
    generate_asm(ElseStmt, ElseData),
    format(atom(Assembly), "~w~w", [ThenData, ElseData]).
generate_asm(ir_while(_, BodyStmt), Assembly) :-
    generate_asm(BodyStmt, BodyData),
    format(atom(Assembly), "~w", [BodyData]).
generate_asm(ir_block(Stmts), Assembly) :-
    asm_data_list(Stmts, Assembly).
generate_asm(IR, _) :-
    throw(error(unsupported_ir_for_asm_data(IR), _)).

% Calculate total stack frame size needed
% Main stores callee-saved registers at -8..-40 and variables from -48 down.
total_stack_size(Vars, TotalSize) :-
    is_list(Vars),
    !,
    storage_slot_count(Vars, SlotCount),
    RawSize is 40 + (SlotCount * 8),
    align_16(RawSize, TotalSize).
total_stack_size(VarCount, TotalSize) :-
    RawSize is 40 + (VarCount * 8),
    align_16(RawSize, TotalSize).

% Generate assembly for text section
generate_asm_text(ir_writeln_str(String), Assembly) :-
    asm_writeln_str_text(String, Assembly).
generate_asm_text(ir_write_str(String), Assembly) :-
    asm_write_str_text(String, Assembly).
generate_asm_text(ir_writeln_int(Expr), Assembly) :-
    asm_writeln_int_text(Expr, Assembly).
generate_asm_text(ir_write_int(Expr), Assembly) :-
    asm_write_int_text(Expr, Assembly).
generate_asm_text(ir_writeln_char(Expr), Assembly) :-
    asm_writeln_char_text(Expr, Assembly).
generate_asm_text(ir_write_char(Expr), Assembly) :-
    asm_write_char_text(Expr, Assembly).
generate_asm_text(ir_writeln_char_array(Name, Low, High), Assembly) :-
    asm_char_array_text(Name, Low, High, true, Assembly).
generate_asm_text(ir_write_char_array(Name, Low, High), Assembly) :-
    asm_char_array_text(Name, Low, High, false, Assembly).
generate_asm_text(ir_readln(Name), Assembly) :-
    asm_readln_text(Name, Assembly).
generate_asm_text(ir_readln_char(Name), Assembly) :-
    asm_readln_char_text(Name, Assembly).

% Enhanced write statements for stdlib
generate_asm_text(ir_write_int_str(Expr, Text), Assembly) :-
    asm_write_int_str_text(Expr, Text, Assembly).
generate_asm_text(ir_write_str_int(Text, Expr), Assembly) :-
    asm_write_str_int_text(Text, Expr, Assembly).
generate_asm_text(ir_write_int_str_int(Expr1, Text, Expr2), Assembly) :-
    asm_write_int_str_int_text(Expr1, Text, Expr2, Assembly).
generate_asm_text(ir_write_format(_, _, _, _), _) :-
    throw(error(unsupported_write_format, context(codegen/generate_asm_text, 'printf-style formatting is not exposed by the Pascal frontend'))).
generate_asm_text(ir_assign(VarName, Expr), Assembly) :-
    asm_assign(VarName, Expr, Assembly).
generate_asm_text(ir_array_store(Name, Low, High, IndexExpr, Expr), Assembly) :-
    asm_array_store(Name, Low, High, IndexExpr, Expr, Assembly).
generate_asm_text(ir_block(Stmts), Assembly) :-
    asm_stmt_list(Stmts, StmtCode),
    format(atom(Assembly), "~w", [StmtCode]).
generate_asm_text(ir_if(Cond, ThenStmt, ElseStmt), Assembly) :-
    next_label(if_else, ElseLabel),
    next_label(if_end, EndLabel),
    asm_expr(Cond, CondCode),
    generate_asm_text(ThenStmt, ThenCode),
    generate_asm_text(ElseStmt, ElseCode),
    format(
        atom(Assembly),
        "~w\tcmpq $0, %rax\n\tje ~w\n~w\tjmp ~w\n~w:\n~w~w:\n",
        [CondCode, ElseLabel, ThenCode, EndLabel, ElseLabel, ElseCode, EndLabel]
    ).
generate_asm_text(ir_while(Cond, BodyStmt), Assembly) :-
    next_label(while_start, StartLabel),
    next_label(while_end, EndLabel),
    asm_expr(Cond, CondCode),
    generate_asm_text(BodyStmt, BodyCode),
    format(
        atom(Assembly),
        "~w:\n~w\tcmpq $0, %rax\n\tje ~w\n~w\tjmp ~w\n~w:\n",
        [StartLabel, CondCode, EndLabel, BodyCode, StartLabel, EndLabel]
    ).
generate_asm_text(IR, _) :-
    throw(error(unsupported_ir_for_asm_text(IR), _)).

asm_stmt_list([], "").
asm_stmt_list([Stmt|Rest], Assembly) :-
    generate_asm_text(Stmt, FirstCode),
    asm_stmt_list(Rest, RestCode),
    format(atom(Assembly), "~w~w", [FirstCode, RestCode]).

asm_data_list([], "").
asm_data_list([Stmt|Rest], Assembly) :-
    generate_asm(Stmt, FirstData),
    asm_data_list(Rest, RestData),
    format(atom(Assembly), "~w~w", [FirstData, RestData]).

next_label(Prefix, Label) :-
    retract(label_counter(N)),
    Next is N + 1,
    assert(label_counter(Next)),
    format(atom(Label), "~w_~d", [Prefix, N]).



% Assembly header
asm_header(".data\nmain_frame_ptr:\n\t.quad 0\n"):- !.

asm_footer(".text\n\t.global main\nmain:\n\tpushq %rbp\n\tmovq %rsp, %rbp\n"):- !.

asm_call_instruction(FuncName, Assembly) :-
    % Preserve the original stack pointer, align for call, then restore it.
    format(
        atom(Assembly),
        "\tmovq %rsp, %r11\n\tandq $-16, %rsp\n\tsubq $16, %rsp\n\tmovq %r11, 8(%rsp)\n\tcall ~w\n\tmovq 8(%rsp), %rsp\n",
        [FuncName]
    ).

% Generate stack frame
asm_stack_frame(TotalSize, Assembly) :-
    format(
        atom(Assembly),
        "\tsubq $~d, %rsp\n\tmovq %rbx, -8(%rbp)\n\tmovq %r12, -16(%rbp)\n\tmovq %r13, -24(%rbp)\n\tmovq %r14, -32(%rbp)\n\tmovq %r15, -40(%rbp)\n\tmovq %rbp, main_frame_ptr(%rip)\n",
        [TotalSize]
    ).

asm_main_epilogue(
    "\tmovq -8(%rbp), %rbx\n\tmovq -16(%rbp), %r12\n\tmovq -24(%rbp), %r13\n\tmovq -32(%rbp), %r14\n\tmovq -40(%rbp), %r15\n\tmovq $0, %rax\n\tleave\n\tret\n"
):- !.

% Stack overflow handler
asm_stack_overflow_handler(
    "stack_overflow:\n\tmovq $1, %rdi\n\tleaq overflow_msg(%rip), %rsi\n\tmovq %rsp, %r11\n\tandq $-16, %rsp\n\tsubq $16, %rsp\n\tmovq %r11, 8(%rsp)\n\tcall rt_error\n\tmovq 8(%rsp), %rsp\n\tint $3\n\tud2\n"):- !.

% Stack overflow message
asm_overflow_message("overflow_msg:\n\t.asciz \"Stack overflow detected\\n\"\n"):- !.

% Division by zero error handler
asm_division_by_zero_handler(
    "division_by_zero:\n\tmovq $2, %rdi\n\tleaq div_zero_msg(%rip), %rsi\n\tmovq %rsp, %r11\n\tandq $-16, %rsp\n\tsubq $16, %rsp\n\tmovq %r11, 8(%rsp)\n\tcall rt_error\n\tmovq 8(%rsp), %rsp\n\tint $3\n\tud2\n"):- !.

% Division by zero message
asm_div_by_zero_message("div_zero_msg:\n\t.asciz \"Division by zero error\\n\"\n"):- !.

% Array bounds error handler
asm_array_bounds_handler(
    "array_bounds_error:\n\tmovq $3, %rdi\n\tleaq array_bounds_msg(%rip), %rsi\n\tmovq %rsp, %r11\n\tandq $-16, %rsp\n\tsubq $16, %rsp\n\tmovq %r11, 8(%rsp)\n\tcall rt_error\n\tmovq 8(%rsp), %rsp\n\tint $3\n\tud2\n"):- !.

asm_array_bounds_message("array_bounds_msg:\n\t.asciz \"Array index out of bounds\\n\"\n"):- !.

% Generate assembly for writeln_str
asm_writeln_str(String, DataSection) :-
    asm_string_data(String, DataSection).

asm_write_str(String, DataSection) :-
    asm_string_data(String, DataSection).

asm_writeln_str_text(String, TextSection) :-
    asm_string_call_text(String, rt_writeln_str, TextSection).

asm_write_str_text(String, TextSection) :-
    asm_string_call_text(String, rt_write_str, TextSection).

asm_writeln_int_text(Expr, TextSection) :-
    asm_expr(Expr, ExprCode),
    asm_call_instruction(rt_writeln_int, CallCode),
    format(
        atom(TextSection),
        "~w\tmovl %eax, %edi\n~w",
        [ExprCode, CallCode]
    ).

asm_write_int_text(Expr, TextSection) :-
    asm_expr(Expr, ExprCode),
    asm_call_instruction(rt_write_int, CallCode),
    format(
        atom(TextSection),
        "~w\tmovl %eax, %edi\n~w",
        [ExprCode, CallCode]
    ).

asm_writeln_char_text(Expr, TextSection) :-
    asm_expr(Expr, ExprCode),
    asm_call_instruction(rt_writeln_char, CallCode),
    format(
        atom(TextSection),
        "~w\tmovl %eax, %edi\n~w",
        [ExprCode, CallCode]
    ).

asm_write_char_text(Expr, TextSection) :-
    asm_expr(Expr, ExprCode),
    asm_call_instruction(rt_write_char, CallCode),
    format(
        atom(TextSection),
        "~w\tmovl %eax, %edi\n~w",
        [ExprCode, CallCode]
    ).

asm_char_array_text(Name, Low, High, WithNewline, TextSection) :-
    var_offset(Name, BaseOffset),
    asm_char_array_elements(BaseOffset, Low, High, Low, ElementCode),
    (   WithNewline == true
    ->  asm_call_instruction(rt_write_newline, NewlineCode)
    ;   NewlineCode = ""
    ),
    format(atom(TextSection), "~w~w", [ElementCode, NewlineCode]).

asm_char_array_elements(_, Current, High, _, "") :-
    Current > High,
    !.
asm_char_array_elements(BaseOffset, Current, High, Low, Assembly) :-
    ElementOffset is BaseOffset + ((Current - Low) * 8),
    asm_call_instruction(rt_write_char, CallCode),
    Next is Current + 1,
    asm_char_array_elements(BaseOffset, Next, High, Low, Rest),
    format(
        atom(Assembly),
        "\tmovq -~d(%rbp), %rax\n\tmovl %eax, %edi\n~w~w",
        [ElementOffset, CallCode, Rest]
    ).

% Enhanced write functions for stdlib
asm_write_int_str_text(Expr, String, TextSection) :-
    asm_expr(Expr, ExprCode),
    asm_string_label(String, Label),
    asm_call_instruction(rt_write_int_str, CallCode),
    format(
        atom(TextSection),
        "~w\tmovl %eax, %edi\n\tleaq ~w(%rip), %rsi\n~w",
        [ExprCode, Label, CallCode]
    ).

asm_write_str_int_text(String, Expr, TextSection) :-
    asm_string_label(String, Label),
    asm_expr(Expr, ExprCode),
    asm_call_instruction(rt_write_str_int, CallCode),
    format(
        atom(TextSection),
        "~w\tleaq ~w(%rip), %rdi\n\tmovl %eax, %esi\n~w",
        [ExprCode, Label, CallCode]
    ).

asm_write_int_str_int_text(Expr1, String, Expr2, TextSection) :-
    asm_expr(Expr1, ExprCode1),
    asm_string_label(String, Label),
    asm_expr(Expr2, ExprCode2),
    asm_call_instruction(rt_write_int_str_int, CallCode),
    format(
        atom(TextSection),
        "~w\tmovl %eax, %edi\n\tleaq ~w(%rip), %rdx\n~w\tmovl %eax, %esi\n~w",
        [ExprCode1, Label, ExprCode2, CallCode]
    ).

asm_readln_text(VarName, Assembly) :-
    var_offset(VarName, Offset),
    asm_call_instruction(rt_readln_int, CallCode),
    format(
        atom(Assembly),
        "~w\tmovslq %eax, %rax\n\tmovq %rax, -~d(%rbp)\n",
        [CallCode, Offset]
    ).

asm_readln_char_text(VarName, Assembly) :-
    var_offset(VarName, Offset),
    asm_call_instruction(rt_readln_char, CallCode),
    format(
        atom(Assembly),
        "~w\tmovslq %eax, %rax\n\tmovq %rax, -~d(%rbp)\n",
        [CallCode, Offset]
    ).

asm_assign(VarName, Expr, Assembly) :-
    asm_expr(Expr, ExprCode),
    var_offset(VarName, Offset),
    format(atom(Assembly), "~w\tmovq %rax, -~d(%rbp)\n", [ExprCode, Offset]).

asm_array_load(Name, Low, High, IndexExpr, Assembly) :-
    asm_expr(IndexExpr, IndexCode),
    asm_array_index_check(Low, High, CheckCode),
    var_offset(Name, BaseOffset),
    format(
        atom(Assembly),
        "~w~w\tmovq %rax, %r10\n\tmovq %rbp, %r11\n\tsubq $~d, %r11\n\tsubq %r10, %r11\n\tmovq (%r11), %rax\n",
        [IndexCode, CheckCode, BaseOffset]
    ).

asm_array_store(Name, Low, High, IndexExpr, Expr, Assembly) :-
    asm_expr(IndexExpr, IndexCode),
    asm_array_index_check(Low, High, CheckCode),
    asm_expr(Expr, ExprCode),
    var_offset(Name, BaseOffset),
    format(
        atom(Assembly),
        "~w~w\tmovq %rax, %r10\n\tpushq %r10\n~w\tpopq %r10\n\tmovq %rbp, %r11\n\tsubq $~d, %r11\n\tsubq %r10, %r11\n\tmovq %rax, (%r11)\n",
        [IndexCode, CheckCode, ExprCode, BaseOffset]
    ).

asm_array_index_check(Low, High, Assembly) :-
    format(
        atom(Assembly),
        "\tcmpq $~d, %rax\n\tjl array_bounds_error\n\tcmpq $~d, %rax\n\tjg array_bounds_error\n\tsubq $~d, %rax\n\timulq $8, %rax\n",
        [Low, High, Low]
    ).

asm_string_data(String, DataSection) :-
    ensure_string_label(String, Label, IsNew),
    (   IsNew = true
    ->  asm_escape_string(String, Escaped),
        format(atom(DataSection), "~w:\n\t.asciz \"~w\"\n", [Label, Escaped])
    ;   format(atom(DataSection), "", [])
    ).

asm_string_label(String, Label) :-
    (   string_label(String, Label)
    ->  true
    ;   next_string_label(Label),
        assert(string_label(String, Label))
    ).

asm_string_call_text(String, FuncName, TextSection) :-
    (   string_label(String, Label)
    ->  asm_call_instruction(FuncName, CallCode),
        format(atom(TextSection), "\tleaq ~w(%rip), %rdi\n~w", [Label, CallCode])
    ;   throw(error(missing_string_label(String), _))
    ).

ensure_string_label(String, Label, false) :-
    string_label(String, Label),
    !.
ensure_string_label(String, Label, true) :-
    next_string_label(Label),
    assert(string_label(String, Label)).

next_string_label(Label) :-
    retract(string_counter(N)),
    Next is N + 1,
    assert(string_counter(Next)),
    format(atom(Label), "str_~d", [N]).

asm_escape_string(Text, EscapedAtom) :-
    text_codes(Text, Codes),
    escape_asm_string_codes(Codes, EscapedCodes),
    atom_codes(EscapedAtom, EscapedCodes).

text_codes(Text, Codes) :-
    string(Text),
    !,
    string_codes(Text, Codes).
text_codes(Text, Codes) :-
    atom(Text),
    !,
    atom_codes(Text, Codes).

escape_asm_string_codes([], []).
escape_asm_string_codes([0'\\|Rest], [0'\\, 0'\\|EscapedRest]) :-
    !,
    escape_asm_string_codes(Rest, EscapedRest).
escape_asm_string_codes([0'"|Rest], [0'\\, 0'"|EscapedRest]) :-
    !,
    escape_asm_string_codes(Rest, EscapedRest).
escape_asm_string_codes([10|Rest], [0'\\, 0'n|EscapedRest]) :-
    !,
    escape_asm_string_codes(Rest, EscapedRest).
escape_asm_string_codes([Code|Rest], [Code|EscapedRest]) :-
    escape_asm_string_codes(Rest, EscapedRest).

% Generate assembly for expressions
asm_expr(ir_int(N), Assembly) :-
    format(atom(Assembly), "\tmovq $~d, %rax\n", [N]).
asm_expr(ir_bool(Value), Assembly) :-
    format(atom(Assembly), "\tmovq $~d, %rax\n", [Value]).
asm_expr(ir_char(Code), Assembly) :-
    format(atom(Assembly), "\tmovq $~d, %rax\n", [Code]).
asm_expr(ir_var(Name), Assembly) :-
    var_offset(Name, Offset),
    format(atom(Assembly), "\tmovq -~d(%rbp), %rax\n", [Offset]).
asm_expr(ir_array_load(Name, Low, High, IndexExpr), Assembly) :-
    asm_array_load(Name, Low, High, IndexExpr, Assembly).
asm_expr(ir_call(Name, Args), Assembly) :-
    length(Args, ArgCount),
    (   ArgCount > 6
    ->  throw(error(too_many_arguments(Name, ArgCount), _))
    ;   true
    ),
    % Evaluate arguments and move to registers
    asm_call_args(Args, ArgCode),
    asm_call_instruction(Name, CallCode),
    format(atom(Assembly), "~w~w", [ArgCode, CallCode]).
asm_expr(ir_unary('-', Expr), Assembly) :-
    asm_expr(Expr, ExprCode),
    format(atom(Assembly), "~w\tnegq %rax\n", [ExprCode]).
asm_expr(ir_bin('+', Left, Right), Assembly) :-
    asm_expr(Left, LeftCode),
    (   get_preferred_temp_register(TempReg)
    ->  asm_expr(Right, RightCode),
        format(atom(Assembly), "~w\tmovq %rax, %~w\n~w\taddq %~w, %rax\n", [LeftCode, TempReg, RightCode, TempReg]),
        free_register(TempReg)
    ;   % Fallback to stack-based approach if register allocation fails
        asm_expr(Right, RightCode),
        format(atom(Assembly), "~w\tpushq %rax\n~w\tpopq %r10\n\taddq %r10, %rax\n", [LeftCode, RightCode])
    ).
asm_expr(ir_bin('-', Left, Right), Assembly) :-
    asm_expr(Left, LeftCode),
    (   get_preferred_temp_register(TempReg)
    ->  asm_expr(Right, RightCode),
        format(atom(Assembly), "~w\tmovq %rax, %~w\n~w\tsubq %rax, %~w\n\tmovq %~w, %rax\n", [LeftCode, TempReg, RightCode, TempReg, TempReg]),
        free_register(TempReg)
    ;   % Fallback to stack-based approach
        asm_expr(Right, RightCode),
        format(atom(Assembly), "~w\tpushq %rax\n~w\tpopq %r10\n\tsubq %rax, %r10\n\tmovq %r10, %rax\n", [LeftCode, RightCode])
    ).
asm_expr(ir_bin('*', Left, Right), Assembly) :-
    asm_expr(Left, LeftCode),
    (   get_preferred_temp_register(TempReg)
    ->  asm_expr(Right, RightCode),
        format(atom(Assembly), "~w\tmovq %rax, %~w\n~w\timulq %~w, %rax\n", [LeftCode, TempReg, RightCode, TempReg]),
        free_register(TempReg)
    ;   % Fallback to stack-based approach
        asm_expr(Right, RightCode),
        format(atom(Assembly), "~w\tpushq %rax\n~w\tpopq %r10\n\timulq %r10, %rax\n", [LeftCode, RightCode])
    ).
asm_expr(ir_bin('/', Left, Right), Assembly) :-
    asm_expr(Left, LeftCode),
    (   get_preferred_temp_register(TempReg)
    ->  asm_expr(Right, RightCode),
        format(
            atom(Assembly),
            "~w\tmovq %rax, %~w\n~w\tmovq %rax, %r11\n\tcmpq $0, %r11\n\tje division_by_zero\n\tmovq %~w, %rax\n\tcqo\n\tidivq %r11\n",
            [LeftCode, TempReg, RightCode, TempReg]
        ),
        free_register(TempReg)
    ;   % Fallback to stack-based approach
        asm_expr(Right, RightCode),
        format(
            atom(Assembly),
            "~w\tpushq %rax\n~w\tpopq %r10\n\tmovq %rax, %r11\n\tcmpq $0, %r11\n\tje division_by_zero\n\tmovq %r10, %rax\n\tcqo\n\tidivq %r11\n",
            [LeftCode, RightCode]
        )
    ).
asm_expr(ir_bin(mod, Left, Right), Assembly) :-
    asm_expr(Left, LeftCode),
    (   get_preferred_temp_register(TempReg)
    ->  asm_expr(Right, RightCode),
        format(
            atom(Assembly),
            "~w\tmovq %rax, %~w\n~w\tmovq %rax, %r11\n\tcmpq $0, %r11\n\tje division_by_zero\n\tmovq %~w, %rax\n\tcqo\n\tidivq %r11\n\tmovq %rdx, %rax\n",
            [LeftCode, TempReg, RightCode, TempReg]
        ),
        free_register(TempReg)
    ;   % Fallback to stack-based approach
        asm_expr(Right, RightCode),
        format(
            atom(Assembly),
            "~w\tpushq %rax\n~w\tpopq %r10\n\tmovq %rax, %r11\n\tcmpq $0, %r11\n\tje division_by_zero\n\tmovq %r10, %rax\n\tcqo\n\tidivq %r11\n\tmovq %rdx, %rax\n",
            [LeftCode, RightCode]
        )
    ).
asm_expr(ir_bin('=', Left, Right), Assembly) :-
    asm_compare_expr(Left, Right, "sete", Assembly).
asm_expr(ir_bin('<>', Left, Right), Assembly) :-
    asm_compare_expr(Left, Right, "setne", Assembly).
asm_expr(ir_bin('<', Left, Right), Assembly) :-
    asm_compare_expr(Left, Right, "setl", Assembly).
asm_expr(ir_bin('<=', Left, Right), Assembly) :-
    asm_compare_expr(Left, Right, "setle", Assembly).
asm_expr(ir_bin('>', Left, Right), Assembly) :-
    asm_compare_expr(Left, Right, "setg", Assembly).
asm_expr(ir_bin('>=', Left, Right), Assembly) :-
    asm_compare_expr(Left, Right, "setge", Assembly).

% Generate argument setup for function calls.
% Arguments are evaluated left-to-right, pushed to preserve values, then popped to ABI registers.
asm_call_args(Args, Assembly) :-
    asm_push_call_args(Args, PushCode),
    length(Args, ArgCount),
    asm_pop_call_args(ArgCount, PopCode),
    format(atom(Assembly), "~w~w", [PushCode, PopCode]).

asm_push_call_args([], "").
asm_push_call_args([Arg|Rest], Assembly) :-
    asm_expr(Arg, ArgCode),
    asm_push_call_args(Rest, RestCode),
    format(atom(Assembly), "~w\tpushq %rax\n~w", [ArgCode, RestCode]).

asm_pop_call_args(0, "").
asm_pop_call_args(N, Assembly) :-
    N > 0,
    arg_register(N, Reg),
    N1 is N - 1,
    asm_pop_call_args(N1, Rest),
    format(atom(Assembly), "\tpopq ~w\n~w", [Reg, Rest]).

arg_register(1, '%rdi').
arg_register(2, '%rsi').
arg_register(3, '%rdx').
arg_register(4, '%rcx').
arg_register(5, '%r8').
arg_register(6, '%r9').

asm_compare_expr(Left, Right, SetInstr, Assembly) :-
    asm_expr(Left, LeftCode),
    (   get_preferred_temp_register(TempReg)
    ->  asm_expr(Right, RightCode),
        format(
            atom(Assembly),
            "~w\tmovq %rax, %~w\n~w\tcmpq %rax, %~w\n\t~w %al\n\tmovzbq %al, %rax\n",
            [LeftCode, TempReg, RightCode, TempReg, SetInstr]
        ),
        free_register(TempReg)
    ;   % Fallback to stack-based approach
        asm_expr(Right, RightCode),
        format(
            atom(Assembly),
            "~w\tpushq %rax\n~w\tpopq %r10\n\tcmpq %rax, %r10\n\t~w %al\n\tmovzbq %al, %rax\n",
            [LeftCode, RightCode, SetInstr]
        )
    ).

% Generate assembly for a function
generate_func_asm(ir_func(Name, Params, _ReturnType, Locals, Stmts), Stream) :-
    format(Stream, "\n# Function: ~w\n", [Name]),
    format(Stream, "\t.globl ~w\n", [Name]),
    format(Stream, "~w:\n", [Name]),
    format(Stream, "\tpushq %rbp\n", []),
    format(Stream, "\tmovq %rsp, %rbp\n", []),
    % Allocate stack space for parameters, locals, return value, and callee-saved registers
    length(Params, ParamCount),
    storage_slot_count(Locals, LocalSlotCount),
    TotalVars is ParamCount + LocalSlotCount + 1,  % +1 for return value (function name)
    % Layout at negative offsets from %rbp:
    % -8 to -40: saved callee-saved registers (5 * 8 = 40 bytes)
    % -48: return value (function name)
    % -56 onwards: parameters
    LocalVarSize is TotalVars * 8,
    CalleeSavedSize is 40,  % 5 registers * 8 bytes
    RawStackSize is CalleeSavedSize + LocalVarSize,
    align_16(RawStackSize, StackSize),
    format(Stream, "\tsubq $~d, %rsp\n", [StackSize]),
    % Save callee-saved registers to stack
    format(Stream, "\tmovq %rbx, -8(%rbp)\n", []),
    format(Stream, "\tmovq %r12, -16(%rbp)\n", []),
    format(Stream, "\tmovq %r13, -24(%rbp)\n", []),
    format(Stream, "\tmovq %r14, -32(%rbp)\n", []),
    format(Stream, "\tmovq %r15, -40(%rbp)\n", []),
    % Save parameter registers to stack
    % Return value (function name) is at -48, params start at -56
    save_params_to_stack(Params, 1, Stream),
    % Initialize return value to 0 (default if function doesn't assign to its name)
    format(Stream, "\tmovq $0, -48(%rbp)\n", []),
    % Generate function body
    (   member(IR, Stmts),
        once(generate_func_asm_text(IR, Name, Params, Locals, AsmCode)),
        write(Stream, AsmCode),
        fail
    ;   true
    ),
    % Load return value into %rax
    format(Stream, "\tmovq -48(%rbp), %rax\n", []),
    % Restore callee-saved registers
    format(Stream, "\tmovq -8(%rbp), %rbx\n", []),
    format(Stream, "\tmovq -16(%rbp), %r12\n", []),
    format(Stream, "\tmovq -24(%rbp), %r13\n", []),
    format(Stream, "\tmovq -32(%rbp), %r14\n", []),
    format(Stream, "\tmovq -40(%rbp), %r15\n", []),
    format(Stream, "\tleave\n", []),
    format(Stream, "\tret\n", []).

% Save parameter registers to stack offsets
% Return value is at -48, params start at -56 (after 5 callee-saved regs)
save_params_to_stack([], _, _).
save_params_to_stack([_|Rest], N, Stream) :-
    Offset is -48 - (N * 8),
    param_reg(N, Reg),
    format(Stream, "\tmovq ~w, ~d(%rbp)\n", [Reg, Offset]),
    N1 is N + 1,
    save_params_to_stack(Rest, N1, Stream).

param_reg(1, '%rdi').
param_reg(2, '%rsi').
param_reg(3, '%rdx').
param_reg(4, '%rcx').
param_reg(5, '%r8').
param_reg(6, '%r9').

align_16(N, N) :-
    0 is N mod 16,
    !.
align_16(N, Aligned) :-
    Aligned is N + (16 - (N mod 16)).

% Generate assembly for statements within a function (with proper variable mapping)
generate_func_asm_text(ir_assign(VarName, Expr), FuncName, Params, Locals, Assembly) :-
    asm_expr_func(Expr, FuncName, Params, Locals, ExprCode),
    asm_func_store(VarName, FuncName, Params, Locals, StoreCode),
    format(atom(Assembly), "~w~w", [ExprCode, StoreCode]).
generate_func_asm_text(ir_array_store(Name, Low, High, IndexExpr, Expr), FuncName, Params, Locals, Assembly) :-
    asm_array_store_func(Name, Low, High, IndexExpr, Expr, FuncName, Params, Locals, Assembly).
generate_func_asm_text(ir_writeln_int(Expr), FuncName, Params, Locals, Assembly) :-
    asm_expr_func(Expr, FuncName, Params, Locals, ExprCode),
    asm_call_instruction(rt_writeln_int, CallCode),
    format(atom(Assembly), "~w\tmovl %eax, %edi\n~w", [ExprCode, CallCode]).
generate_func_asm_text(ir_write_int(Expr), FuncName, Params, Locals, Assembly) :-
    asm_expr_func(Expr, FuncName, Params, Locals, ExprCode),
    asm_call_instruction(rt_write_int, CallCode),
    format(atom(Assembly), "~w\tmovl %eax, %edi\n~w", [ExprCode, CallCode]).
generate_func_asm_text(ir_writeln_char(Expr), FuncName, Params, Locals, Assembly) :-
    asm_expr_func(Expr, FuncName, Params, Locals, ExprCode),
    asm_call_instruction(rt_writeln_char, CallCode),
    format(atom(Assembly), "~w\tmovl %eax, %edi\n~w", [ExprCode, CallCode]).
generate_func_asm_text(ir_write_char(Expr), FuncName, Params, Locals, Assembly) :-
    asm_expr_func(Expr, FuncName, Params, Locals, ExprCode),
    asm_call_instruction(rt_write_char, CallCode),
    format(atom(Assembly), "~w\tmovl %eax, %edi\n~w", [ExprCode, CallCode]).
generate_func_asm_text(ir_writeln_char_array(Name, Low, High), FuncName, Params, Locals, Assembly) :-
    asm_char_array_text_func(Name, Low, High, true, FuncName, Params, Locals, Assembly).
generate_func_asm_text(ir_write_char_array(Name, Low, High), FuncName, Params, Locals, Assembly) :-
    asm_char_array_text_func(Name, Low, High, false, FuncName, Params, Locals, Assembly).
generate_func_asm_text(ir_writeln_str(Text), _, _, _, Assembly) :-
    asm_writeln_str_text(Text, Assembly).
generate_func_asm_text(ir_write_str(Text), _, _, _, Assembly) :-
    asm_write_str_text(Text, Assembly).
generate_func_asm_text(ir_readln(Name), FuncName, Params, Locals, Assembly) :-
    asm_call_instruction(rt_readln_int, CallCode),
    asm_func_store(Name, FuncName, Params, Locals, StoreCode),
    format(atom(Assembly), "~w\tmovslq %eax, %rax\n~w", [CallCode, StoreCode]).
generate_func_asm_text(ir_readln_char(Name), FuncName, Params, Locals, Assembly) :-
    asm_call_instruction(rt_readln_char, CallCode),
    asm_func_store(Name, FuncName, Params, Locals, StoreCode),
    format(atom(Assembly), "~w\tmovslq %eax, %rax\n~w", [CallCode, StoreCode]).
generate_func_asm_text(ir_if(Cond, ThenStmt, ElseStmt), FuncName, Params, Locals, Assembly) :-
    next_label(if_else, ElseLabel),
    next_label(if_end, EndLabel),
    asm_expr_func(Cond, FuncName, Params, Locals, CondCode),
    generate_func_asm_text(ThenStmt, FuncName, Params, Locals, ThenCode),
    generate_func_asm_text(ElseStmt, FuncName, Params, Locals, ElseCode),
    format(
        atom(Assembly),
        "~w\tcmpq $0, %rax\n\tje ~w\n~w\tjmp ~w\n~w:\n~w~w:\n",
        [CondCode, ElseLabel, ThenCode, EndLabel, ElseLabel, ElseCode, EndLabel]
    ).
generate_func_asm_text(ir_while(Cond, BodyStmt), FuncName, Params, Locals, Assembly) :-
    next_label(while_start, StartLabel),
    next_label(while_end, EndLabel),
    asm_expr_func(Cond, FuncName, Params, Locals, CondCode),
    generate_func_asm_text(BodyStmt, FuncName, Params, Locals, BodyCode),
    format(
        atom(Assembly),
        "~w:\n~w\tcmpq $0, %rax\n\tje ~w\n~w\tjmp ~w\n~w:\n",
        [StartLabel, CondCode, EndLabel, BodyCode, StartLabel, EndLabel]
    ).
generate_func_asm_text(ir_block(Stmts), FuncName, Params, Locals, Assembly) :-
    func_stmt_list(Stmts, FuncName, Params, Locals, StmtCode),
    format(atom(Assembly), "~w", [StmtCode]).

func_stmt_list([], _, _, _, "").
func_stmt_list([Stmt|Rest], FuncName, Params, Locals, Assembly) :-
    generate_func_asm_text(Stmt, FuncName, Params, Locals, FirstCode),
    func_stmt_list(Rest, FuncName, Params, Locals, RestCode),
    format(atom(Assembly), "~w~w", [FirstCode, RestCode]).

% Get offset for a variable within a function
% Callee-saved regs at -8 to -40, return value at -48, params at -56, -64, etc.
func_var_offset(Name, FuncName, _, _, -48) :-
    Name == FuncName,  % Return value
    !.
func_var_offset(Name, _, Params, _, Offset) :-
    nth1(Index, Params, Param),
    param_name(Param, Name),
    !,
    Offset is -48 - (Index * 8).
func_var_offset(Name, _, Params, Locals, Offset) :-
    % Handle mangled local variable names: local(Counter, VarName)
    (   Name = local(_, _)  % Already mangled
    ->  nth1(Index, Locals, Local),
        local_storage_name(Local, Name)
    ;   % Raw name - find matching mangled local
        nth1(Index, Locals, Local),
        local_storage_name(Local, local(_, Name))
    ),
    !,
    length(Params, ParamCount),
    storage_slots_before(Locals, Index, PriorLocalSlots),
    Offset is -48 - ((ParamCount + PriorLocalSlots + 1) * 8).
func_var_offset(Name, _, _, _, _) :-
    throw(error(unknown_function_variable(Name), _)).

func_global_var(Name, FuncName, Params, Locals, Offset) :-
    atom(Name),
    Name \== FuncName,
    \+ (member(Param, Params), param_name(Param, Name)),
    \+ (member(Local, Locals), local_storage_name(Local, local(_, Name))),
    var_offset(Name, Offset).

asm_func_store(Name, FuncName, Params, Locals, Assembly) :-
    (   func_global_var(Name, FuncName, Params, Locals, Offset)
    ->  format(atom(Assembly), "\tmovq main_frame_ptr(%rip), %r11\n\tmovq %rax, -~d(%r11)\n", [Offset])
    ;   func_var_offset(Name, FuncName, Params, Locals, Offset),
        format(atom(Assembly), "\tmovq %rax, ~d(%rbp)\n", [Offset])
    ).

func_array_base(Name, FuncName, Params, Locals, FrameReg, BaseOffset) :-
    (   func_global_var(Name, FuncName, Params, Locals, BaseOffset)
    ->  FrameReg = main
    ;   func_var_offset(Name, FuncName, Params, Locals, Offset),
        BaseOffset is -Offset,
        FrameReg = local
    ).

asm_array_frame_setup(main, Setup) :-
    !,
    Setup = "\tmovq main_frame_ptr(%rip), %r11\n".
asm_array_frame_setup(local, Setup) :-
    Setup = "\tmovq %rbp, %r11\n".

asm_array_load_func(Name, Low, High, IndexExpr, FuncName, Params, Locals, Assembly) :-
    asm_expr_func(IndexExpr, FuncName, Params, Locals, IndexCode),
    asm_array_index_check(Low, High, CheckCode),
    func_array_base(Name, FuncName, Params, Locals, FrameReg, BaseOffset),
    asm_array_frame_setup(FrameReg, FrameSetup),
    format(
        atom(Assembly),
        "~w~w\tmovq %rax, %r10\n~w\tsubq $~d, %r11\n\tsubq %r10, %r11\n\tmovq (%r11), %rax\n",
        [IndexCode, CheckCode, FrameSetup, BaseOffset]
    ).

asm_array_store_func(Name, Low, High, IndexExpr, Expr, FuncName, Params, Locals, Assembly) :-
    asm_expr_func(IndexExpr, FuncName, Params, Locals, IndexCode),
    asm_array_index_check(Low, High, CheckCode),
    asm_expr_func(Expr, FuncName, Params, Locals, ExprCode),
    func_array_base(Name, FuncName, Params, Locals, FrameReg, BaseOffset),
    asm_array_frame_setup(FrameReg, FrameSetup),
    format(
        atom(Assembly),
        "~w~w\tmovq %rax, %r10\n\tpushq %r10\n~w\tpopq %r10\n~w\tsubq $~d, %r11\n\tsubq %r10, %r11\n\tmovq %rax, (%r11)\n",
        [IndexCode, CheckCode, ExprCode, FrameSetup, BaseOffset]
    ).

asm_char_array_text_func(Name, Low, High, WithNewline, FuncName, Params, Locals, Assembly) :-
    func_array_base(Name, FuncName, Params, Locals, FrameReg, BaseOffset),
    asm_array_frame_setup(FrameReg, FrameSetup),
    asm_char_array_elements_func(BaseOffset, Low, High, Low, FrameSetup, ElementCode),
    (   WithNewline == true
    ->  asm_call_instruction(rt_write_newline, NewlineCode)
    ;   NewlineCode = ""
    ),
    format(atom(Assembly), "~w~w", [ElementCode, NewlineCode]).

asm_char_array_elements_func(_, Current, High, _, _, "") :-
    Current > High,
    !.
asm_char_array_elements_func(BaseOffset, Current, High, Low, FrameSetup, Assembly) :-
    ElementOffset is BaseOffset + ((Current - Low) * 8),
    asm_call_instruction(rt_write_char, CallCode),
    Next is Current + 1,
    asm_char_array_elements_func(BaseOffset, Next, High, Low, FrameSetup, Rest),
    format(
        atom(Assembly),
        "~w\tmovq -~d(%r11), %rax\n\tmovl %eax, %edi\n~w~w",
        [FrameSetup, ElementOffset, CallCode, Rest]
    ).

% Expression evaluation within function context
asm_expr_func(ir_int(N), _, _, _, Assembly) :-
    format(atom(Assembly), "\tmovq $~d, %rax\n", [N]).
asm_expr_func(ir_bool(Value), _, _, _, Assembly) :-
    format(atom(Assembly), "\tmovq $~d, %rax\n", [Value]).
asm_expr_func(ir_char(Code), _, _, _, Assembly) :-
    format(atom(Assembly), "\tmovq $~d, %rax\n", [Code]).
asm_expr_func(ir_var(Name), FuncName, Params, Locals, Assembly) :-
    (   func_global_var(Name, FuncName, Params, Locals, Offset)
    ->  format(atom(Assembly), "\tmovq main_frame_ptr(%rip), %r11\n\tmovq -~d(%r11), %rax\n", [Offset])
    ;   func_var_offset(Name, FuncName, Params, Locals, Offset),
        format(atom(Assembly), "\tmovq ~d(%rbp), %rax\n", [Offset])
    ).
asm_expr_func(ir_array_load(Name, Low, High, IndexExpr), FuncName, Params, Locals, Assembly) :-
    asm_array_load_func(Name, Low, High, IndexExpr, FuncName, Params, Locals, Assembly).
asm_expr_func(ir_call(Name, Args), FuncName, Params, Locals, Assembly) :-
    length(Args, ArgCount),
    (   ArgCount > 6
    ->  throw(error(too_many_arguments(Name, ArgCount), _))
    ;   true
    ),
    asm_call_args_func(Args, FuncName, Params, Locals, ArgCode),
    asm_call_instruction(Name, CallCode),
    format(atom(Assembly), "~w~w", [ArgCode, CallCode]).
asm_expr_func(ir_unary('-', Expr), FuncName, Params, Locals, Assembly) :-
    asm_expr_func(Expr, FuncName, Params, Locals, ExprCode),
    format(atom(Assembly), "~w\tnegq %rax\n", [ExprCode]).
asm_expr_func(ir_bin('+', Left, Right), FuncName, Params, Locals, Assembly) :-
    asm_expr_func(Left, FuncName, Params, Locals, LeftCode),
    (   get_preferred_temp_register(TempReg)
    ->  asm_expr_func(Right, FuncName, Params, Locals, RightCode),
        format(atom(Assembly), "~w\tmovq %rax, %~w\n~w\taddq %~w, %rax\n", [LeftCode, TempReg, RightCode, TempReg]),
        free_register(TempReg)
    ;   asm_expr_func(Right, FuncName, Params, Locals, RightCode),
        format(atom(Assembly), "~w\tpushq %rax\n~w\tpopq %r10\n\taddq %r10, %rax\n", [LeftCode, RightCode])
    ).
asm_expr_func(ir_bin('-', Left, Right), FuncName, Params, Locals, Assembly) :-
    asm_expr_func(Left, FuncName, Params, Locals, LeftCode),
    (   get_preferred_temp_register(TempReg)
    ->  asm_expr_func(Right, FuncName, Params, Locals, RightCode),
        format(atom(Assembly), "~w\tmovq %rax, %~w\n~w\tsubq %rax, %~w\n\tmovq %~w, %rax\n", [LeftCode, TempReg, RightCode, TempReg, TempReg]),
        free_register(TempReg)
    ;   asm_expr_func(Right, FuncName, Params, Locals, RightCode),
        format(atom(Assembly), "~w\tpushq %rax\n~w\tpopq %r10\n\tsubq %rax, %r10\n\tmovq %r10, %rax\n", [LeftCode, RightCode])
    ).
asm_expr_func(ir_bin('*', Left, Right), FuncName, Params, Locals, Assembly) :-
    asm_expr_func(Left, FuncName, Params, Locals, LeftCode),
    (   get_preferred_temp_register(TempReg)
    ->  asm_expr_func(Right, FuncName, Params, Locals, RightCode),
        format(atom(Assembly), "~w\tmovq %rax, %~w\n~w\timulq %~w, %rax\n", [LeftCode, TempReg, RightCode, TempReg]),
        free_register(TempReg)
    ;   asm_expr_func(Right, FuncName, Params, Locals, RightCode),
        format(atom(Assembly), "~w\tpushq %rax\n~w\tpopq %r10\n\timulq %r10, %rax\n", [LeftCode, RightCode])
    ).
asm_expr_func(ir_bin('/', Left, Right), FuncName, Params, Locals, Assembly) :-
    asm_expr_func(Left, FuncName, Params, Locals, LeftCode),
    (   get_preferred_temp_register(TempReg)
    ->  asm_expr_func(Right, FuncName, Params, Locals, RightCode),
        format(
            atom(Assembly),
            "~w\tmovq %rax, %~w\n~w\tmovq %rax, %r11\n\tcmpq $0, %r11\n\tje division_by_zero\n\tmovq %~w, %rax\n\tcqo\n\tidivq %r11\n",
            [LeftCode, TempReg, RightCode, TempReg]
        ),
        free_register(TempReg)
    ;   asm_expr_func(Right, FuncName, Params, Locals, RightCode),
        format(
            atom(Assembly),
            "~w\tpushq %rax\n~w\tpopq %r10\n\tmovq %rax, %r11\n\tcmpq $0, %r11\n\tje division_by_zero\n\tmovq %r10, %rax\n\tcqo\n\tidivq %r11\n",
            [LeftCode, RightCode]
        )
    ).
asm_expr_func(ir_bin(mod, Left, Right), FuncName, Params, Locals, Assembly) :-
    asm_expr_func(Left, FuncName, Params, Locals, LeftCode),
    (   get_preferred_temp_register(TempReg)
    ->  asm_expr_func(Right, FuncName, Params, Locals, RightCode),
        format(
            atom(Assembly),
            "~w\tmovq %rax, %~w\n~w\tmovq %rax, %r11\n\tcmpq $0, %r11\n\tje division_by_zero\n\tmovq %~w, %rax\n\tcqo\n\tidivq %r11\n\tmovq %rdx, %rax\n",
            [LeftCode, TempReg, RightCode, TempReg]
        ),
        free_register(TempReg)
    ;   asm_expr_func(Right, FuncName, Params, Locals, RightCode),
        format(
            atom(Assembly),
            "~w\tpushq %rax\n~w\tpopq %r10\n\tmovq %rax, %r11\n\tcmpq $0, %r11\n\tje division_by_zero\n\tmovq %r10, %rax\n\tcqo\n\tidivq %r11\n\tmovq %rdx, %rax\n",
            [LeftCode, RightCode]
        )
    ).
asm_expr_func(ir_bin(Comp, Left, Right), FuncName, Params, Locals, Assembly) :-
    comparison_op(Comp, SetInstr),
    asm_compare_expr_func(Left, Right, FuncName, Params, Locals, SetInstr, Assembly).

comparison_op('=', "sete").
comparison_op('<>', "setne").
comparison_op('<', "setl").
comparison_op('<=', "setle").
comparison_op('>', "setg").
comparison_op('>=', "setge").

asm_compare_expr_func(Left, Right, FuncName, Params, Locals, SetInstr, Assembly) :-
    asm_expr_func(Left, FuncName, Params, Locals, LeftCode),
    (   get_preferred_temp_register(TempReg)
    ->  asm_expr_func(Right, FuncName, Params, Locals, RightCode),
        format(
            atom(Assembly),
            "~w\tmovq %rax, %~w\n~w\tcmpq %rax, %~w\n\t~w %al\n\tmovzbq %al, %rax\n",
            [LeftCode, TempReg, RightCode, TempReg, SetInstr]
        ),
        free_register(TempReg)
    ;   asm_expr_func(Right, FuncName, Params, Locals, RightCode),
        format(
            atom(Assembly),
            "~w\tpushq %rax\n~w\tpopq %r10\n\tcmpq %rax, %r10\n\t~w %al\n\tmovzbq %al, %rax\n",
            [LeftCode, RightCode, SetInstr]
        )
    ).

asm_call_args_func(Args, FuncName, Params, Locals, Assembly) :-
    asm_push_call_args_func(Args, FuncName, Params, Locals, PushCode),
    length(Args, ArgCount),
    asm_pop_call_args(ArgCount, PopCode),
    format(atom(Assembly), "~w~w", [PushCode, PopCode]).

asm_push_call_args_func([], _, _, _, "").
asm_push_call_args_func([Arg|Rest], FuncName, Params, Locals, Assembly) :-
    asm_expr_func(Arg, FuncName, Params, Locals, ArgCode),
    asm_push_call_args_func(Rest, FuncName, Params, Locals, RestCode),
    format(atom(Assembly), "~w\tpushq %rax\n~w", [ArgCode, RestCode]).
