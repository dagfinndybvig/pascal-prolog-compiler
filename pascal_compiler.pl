:- module(pascal_compiler, [
    parse_pascal/2,
    check_pascal/1,
    compile_to_asm/2,
    build_asm/2
]).

:- use_module(library(process)).
:- use_module(library(filesex)).
:- use_module(src/parser).
:- use_module(src/semantics).
:- use_module(src/ir).
:- use_module(src/codegen_asm_x86_64).

parse_pascal(SourcePath, AST) :-
    parse_file(SourcePath, AST).

check_pascal(SourcePath) :-
    parse_pascal(SourcePath, AST),
    check_program(AST).

compile_to_c(SourcePath, COutPath) :-
    parse_pascal(SourcePath, AST),
    check_program(AST),
    lower_program(AST, IRProgram),
    write_c_file(COutPath, IRProgram).



% Compile to assembly
compile_to_asm(SourcePath, AsmOutPath) :-
    parse_pascal(SourcePath, AST),
    check_program(AST),
    lower_program(AST, IRProgram),
    write_asm_file(AsmOutPath, IRProgram).

% Build executable via assembly
build_asm(SourcePath, OutputPath) :-
    parse_pascal(SourcePath, AST),
    check_program(AST),
    lower_program(AST, IRProgram),
    setup_call_cleanup(
        tmp_file_stream(text, TempAsmPath, AsmStream),
        (
            close(AsmStream),
            write_asm_file(TempAsmPath, IRProgram),
            setup_call_cleanup(
                tmp_file_stream(text, TempObjPath, ObjStream),
                (
                    close(ObjStream),
                    process_create(
                        path(gcc),
                        [
                            '-x', 'assembler',
                            TempAsmPath,
                            '-c',
                            '-o', TempObjPath
                        ],
                        [process(PID1)]
                    ),
                    process_wait(PID1, Status1),
                    expect_success(Status1),
                    runtime_paths(RuntimeCPath, RuntimeIncludeDir),
                    process_create(
                        path(gcc),
                        [
                            TempObjPath,
                            RuntimeCPath,
                            '-I', RuntimeIncludeDir,
                            '-o', OutputPath
                        ],
                        [process(PID2)]
                    ),
                    process_wait(PID2, Status2),
                    expect_success(Status2)
                ),
                delete_file(TempObjPath)
            )
        ),
        delete_file(TempAsmPath)
    ).

runtime_paths(RuntimeCPath, RuntimeIncludeDir) :-
    source_file(pascal_compiler:build_asm(_, _), File),
    file_directory_name(File, Dir),
    directory_file_path(Dir, runtime, RuntimeIncludeDir),
    directory_file_path(RuntimeIncludeDir, 'runtime.c', RuntimeCPath).

% Write assembly file
write_asm_file(AsmPath, ir_program(_, Funcs, Vars, IRStmts)) :-
    open(AsmPath, write, Stream),
    init_var_offsets(Vars),
    total_stack_size(Vars, TotalSize),
    asm_header(Header),
    write(Stream, Header),
    % Generate data section for main program
    (   member(IR, IRStmts),
        once(generate_asm(IR, AsmCode)),
        write(Stream, AsmCode),
        fail
    ;   true
    ),
    % Generate data section for functions
    (   member(ir_func(_, _, _, _, FuncStmts), Funcs),
        member(IR, FuncStmts),
        once(generate_asm(IR, AsmCode)),
        write(Stream, AsmCode),
        fail
    ;   true
    ),
    asm_footer(FooterStart),
    write(Stream, FooterStart),
    % Add stack frame with overflow protection for main
    asm_stack_frame(TotalSize, StackFrame),
    write(Stream, StackFrame),
    % Generate main program code
    (   member(IR, IRStmts),
        once(generate_asm_text(IR, AsmCode)),
        write(Stream, AsmCode),
        fail
    ;   true
    ),
    asm_main_epilogue(MainEpilogue),
    write(Stream, MainEpilogue),
    % Generate function code
    (   member(Func, Funcs),
        once(generate_func_asm(Func, Stream)),
        fail
    ;   true
    ),
    % Add error handlers at the end
    asm_stack_overflow_handler(OverflowHandler),
    write(Stream, OverflowHandler),
    asm_overflow_message(OverflowMsg),
    write(Stream, OverflowMsg),
    asm_division_by_zero_handler(DivZeroHandler),
    write(Stream, DivZeroHandler),
    asm_div_by_zero_message(DivZeroMsg),
    write(Stream, DivZeroMsg),
    asm_array_bounds_handler(ArrayBoundsHandler),
    write(Stream, ArrayBoundsHandler),
    asm_array_bounds_message(ArrayBoundsMsg),
    write(Stream, ArrayBoundsMsg),
    close(Stream).

expect_success(exit(0)) :- !.
expect_success(Status) :-
    throw(error(gcc_failed(Status), _)).

:- multifile prolog:message//1.

prolog:message(error(duplicate_declaration(Name), context(_, Detail))) -->
    [ 'duplicate declaration: ~w (~w)'-[Name, Detail] ].
prolog:message(error(duplicate_function(Name), context(_, Detail))) -->
    [ 'duplicate function: ~w (~w)'-[Name, Detail] ].
prolog:message(error(too_many_parameters(Name, Count), context(_, Detail))) -->
    [ 'too many parameters for function ~w: ~d (maximum 6; ~w)'-[Name, Count, Detail] ].
prolog:message(error(too_many_arguments(Name, Count), _)) -->
    [ 'too many arguments for function ~w: ~d (maximum 6)'-[Name, Count] ].
prolog:message(error(wrong_arity(Name, Expected, Actual), context(_, Detail))) -->
    [ 'wrong arity for function ~w: expected ~d, got ~d (~w)'-[Name, Expected, Actual, Detail] ].
prolog:message(error(undeclared_variable(Name), context(_, Detail))) -->
    [ 'undeclared variable: ~w (~w)'-[Name, Detail] ].
prolog:message(error(undeclared_function(Name), context(_, Detail))) -->
    [ 'undeclared function: ~w (~w)'-[Name, Detail] ].
prolog:message(error(gcc_failed(Status), _)) -->
    [ 'gcc failed: ~w'-[Status] ].
prolog:message(error(unsupported_write_format, context(_, Detail))) -->
    [ 'unsupported write format (~w)'-[Detail] ].
prolog:message(error(type_mismatch(Expected, Actual), context(_, Detail))) -->
    [ 'type mismatch: expected ~w, got ~w (~w)'-[Expected, Actual, Detail] ].
prolog:message(error(unsupported_type(Type), context(_, Detail))) -->
    [ 'unsupported type: ~w (~w)'-[Type, Detail] ].
prolog:message(error(invalid_array_bounds(Low, High), context(_, Detail))) -->
    [ 'invalid array bounds: ~d..~d (~w)'-[Low, High, Detail] ].

usage :-
    writeln("Usage:"),
    writeln("  swipl -q -s pascal_compiler.pl -- parse <source.pas>"),
    writeln("  swipl -q -s pascal_compiler.pl -- check <source.pas>"),
    writeln("  swipl -q -s pascal_compiler.pl -- asm <source.pas> <out.s>"),
    writeln("  swipl -q -s pascal_compiler.pl -- build-asm <source.pas> <out_binary>"),
    writeln("  swipl -q -s pascal_compiler.pl -- build_asm <source.pas> <out_binary>").

main :-
    current_prolog_flag(argv, Argv),
    (   Argv = [parse, Source]
    ->  parse_pascal(Source, AST),
        writeln(AST)
    ;   Argv = [check, Source]
    ->  check_pascal(Source),
        writeln(ok)
    ;   Argv = [asm, Source, AsmOut]
    ->  compile_to_asm(Source, AsmOut),
        format("Wrote ~w~n", [AsmOut])
    ;   Argv = ['build-asm', Source, OutBin]
    ->  build_asm(Source, OutBin),
        format("Built ~w~n", [OutBin])
    ;   Argv = [build_asm, Source, OutBin]
    ->  build_asm(Source, OutBin),
        format("Built ~w~n", [OutBin])
    ;   usage,
        halt(1)
    ).

:- initialization(main, main).
