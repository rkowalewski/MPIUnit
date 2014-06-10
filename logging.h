#include <stdio.h>
#include <stdarg.h>
#include <string.h>

#ifndef LOGGING_H_
#define LOGGING_H_

#define EXPECT_GT(rank, actual, expected) \
  printf("TEST%d: EXPECT_GT(%d, %d)\n", rank, actual, expected); \

#define EXPECT_VALUE_IN_RANGE(rank, value, min, max) \
  printf("TEST%d: EXPECT_TRUE(%d<=%d && %d<%d)\n", rank, min, value, value, max)

#define GETVAL(parameter, rank)\
   &((GetValType){parameter, rank}),1

#define PUTVAL(rank, parameter, value, fmt) \
  printf("TEST%d: PUTVAL(" #parameter "," #fmt ")\n", rank, value)


#define _ARG2(_0, _1, _2, _3, _4, _5, ...) _5
#define NARG2(...) _ARG2(__VA_ARGS__, 5, 4, 3, 2, 1, 0)
#define __FIND_BY_ARGS(NAME, N, ...)  NAME(N, __VA_ARGS__)
#define _FIND_BY_ARGS(NAME, N, ...) __FIND_BY_ARGS(NAME, N, __VA_ARGS__)
#define FIND_BY_ARGS(NAME, ...) _FIND_BY_ARGS(NAME, NARG2(__VA_ARGS__), __VA_ARGS__)

#define EXPECT_EQ(...) FIND_BY_ARGS(expect_eq, __VA_ARGS__)

enum e_data_types {
  STRING, INT
};

typedef struct GetValType
{
  char* name; //The parameter name
  int rank; //The destination rank who had to put the value
} GetValType;

void expect_eq_nested(va_list argp) {
  int expected_i;
  GetValType *ptr;
  int rank = va_arg(argp, int);
  int type = va_arg(argp, enum e_data_types);

  if (type == INT) {
    expected_i = va_arg(argp, int);
    ptr = va_arg(argp, GetValType *);
    printf("Test%d: EXPECT_EQ(%d, GETVAL(\"%s\", %d))\n", rank, expected_i, ptr->name, ptr->rank);
  }
}

void expected_eq_simple(va_list argp) {
  int actual_i, expected_i;
  int rank = va_arg(argp, int);
  int type = va_arg(argp, enum e_data_types);

  if (type == INT) {
    actual_i = va_arg(argp, int);
    expected_i = va_arg(argp, int);
    printf("Test%d: EXPECT_EQ(%d, %d)\n", rank, actual_i, expected_i);
  }
}

void expect_eq(int n, ...) {
  va_list argp;
  va_start(argp, n);
  switch(n) {
    case 4:
      expected_eq_simple(argp);
      break;
    case 5:
      expect_eq_nested(argp);
      break;
    default:
      printf("do nothing\n");
  }
  va_end(argp);
}

#endif
