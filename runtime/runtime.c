#include "runtime.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int rt_readln_int(void) {
    int value = 0;
    if (scanf("%d", &value) != 1) {
        fprintf(stderr, "runtime error: expected integer input\n");
        exit(1);
    }
    return value;
}

int rt_readln_char(void) {
    int value = getchar();
    while (value == '\n' || value == '\r') {
        value = getchar();
    }
    if (value == EOF) {
        fprintf(stderr, "runtime error: expected character input\n");
        exit(1);
    }
    return value;
}

void rt_writeln_int(int value) {
    printf("%d\n", value);
}

void rt_writeln_char(int value) {
    printf("%c\n", (char)value);
}

void rt_writeln_str(const char *value) {
    printf("%s\n", value);
}

void rt_write_int(int value) {
    printf("%d", value);
}

void rt_write_char(int value) {
    printf("%c", (char)value);
}

void rt_write_str(const char *value) {
    printf("%s", value);
}

void rt_write_newline(void) {
    printf("\n");
}

void rt_error(int code, const char *message) {
    fprintf(stderr, "runtime error %d: %s", code, message);
    exit(code);
}

/* Enhanced write functions */

void rt_write_int_str(int value, const char *text) {
    printf("%d%s", value, text);
}

void rt_write_str_int(const char *text, int value) {
    printf("%s%d", text, value);
}

void rt_write_int_str_int(int value1, const char *text, int value2) {
    printf("%d%s%d", value1, text, value2);
}

/* String conversion functions */

void rt_int_to_buffer(int value, char *buffer, int buffer_size) {
    snprintf(buffer, buffer_size, "%d", value);
}

int64_t rt_alloc(int64_t size_bytes) {
    if (size_bytes <= 0) {
        rt_error(RT_ERROR_INVALID_OPERATION, "Invalid allocation size\n");
    }

    void *ptr = calloc(1, (size_t)size_bytes);
    if (ptr == NULL) {
        rt_error(RT_ERROR_INVALID_OPERATION, "Out of memory\n");
    }

    return (int64_t)(intptr_t)ptr;
}

void rt_free(int64_t ptr_value) {
    if (ptr_value == 0) {
        return;
    }

    free((void *)(intptr_t)ptr_value);
}
