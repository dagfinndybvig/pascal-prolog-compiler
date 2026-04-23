#ifndef PASCAL_PROLOG_RUNTIME_H
#define PASCAL_PROLOG_RUNTIME_H

int rt_readln_int(void);
void rt_writeln_int(int value);
void rt_writeln_str(const char *value);
void rt_write_int(int value);
void rt_write_str(const char *value);
void rt_error(int code, const char *message);

/* Enhanced write functions */
void rt_write_int_str(int value, const char *text);
void rt_write_str_int(const char *text, int value);
void rt_write_int_str_int(int value1, const char *text, int value2);
void rt_write_format(const char *format, int arg1, int arg2, int arg3);

/* String conversion functions */
void rt_int_to_buffer(int value, char *buffer, int buffer_size);

/* Error codes */
#define RT_ERROR_STACK_OVERFLOW 1
#define RT_ERROR_DIVISION_BY_ZERO 2
#define RT_ERROR_ARRAY_BOUNDS 3
#define RT_ERROR_NULL_POINTER 4
#define RT_ERROR_INVALID_OPERATION 5

#endif
