#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <stdlib.h>

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

#define EXPECT_EQ_INT(expected, actual) \
  EXECUTE_ASSERT_FN(expect_eq, INT_##expected, INT_##actual)

#define EXECUTE_ASSERT_FN(name, value1, value2) \
  name(value1, value2);

#define INT_VAL(...) \
  VAL_INTERN(NARG2(__VA_ARGS__), INT, __VA_ARGS__)

#define VAL_INTERN(N, ...) \
  createAssertionValue(N, __VA_ARGS__)

#define SETRANK(x) \
  LOG_RANK = x;

#define LOG_PREFIX "Test%d: "

static unsigned int LOG_RANK = -1;

typedef enum DataType_s {
  INT, STRING
} DataType;

typedef struct AssertionValue_s {
  int isLocal;
  DataType type;
  union {
    int valInt;
    char* valStr;
    struct {
      int rank;
      char* param;
    } distantSrc;
  } uval;
} AssertionValue;

AssertionValue* createAssertionValue(int nargs, ...) {
  if (nargs < 1) return NULL;

  AssertionValue* assertionValue = (AssertionValue*) malloc(sizeof(AssertionValue));
  if (assertionValue == NULL) return NULL;

  va_list arguments;
  va_start(arguments, nargs);

  assertionValue->isLocal = nargs == 1;
  assertionValue->type = va_arg(arguments, DataType);

  if (assertionValue->isLocal) {
    switch(assertionValue->type) {
      case INT:
        assertionValue->uval.valInt = va_arg(arguments, int);
        break;
      case STRING:
        assertionValue->uval.valStr = va_arg(arguments, char*);
        break;
      default: break;
    }
  } else {
    char* distantParam = va_arg(arguments, char*);
    int rank = va_arg(arguments, int);
    assertionValue->uval.distantSrc.param = distantParam;
    assertionValue->uval.distantSrc.rank = rank;
  }

  va_end(arguments);

  return assertionValue;
}

void expect_eq(AssertionValue *expected, AssertionValue* actual) {
  if (expected == NULL || actual == NULL) return;

  if (expected->type != actual->type) {
    //TODO better error handling
    printf("Error! cannot compare different types\n");
    return;
  }

  if (!(actual->isLocal) && !(expected->isLocal)) {
    printf(LOG_PREFIX "EXPECT_TRUE(GETVAL(\"%s\", %d) == GETVAL(\"%s\"\", %d)\n", LOG_RANK, expected->uval.distantSrc.param, expected->uval.distantSrc.rank, actual->uval.distantSrc.param, actual->uval.distantSrc.rank);
    return;
  }

  switch(expected->type){
    case INT:
      if (expected->isLocal) {
        if (actual->isLocal) {
          printf(LOG_PREFIX "EXPECT_TRUE(%d==%d)\n", LOG_RANK, expected->uval.valInt, actual->uval.valInt);
        } else {
          printf(LOG_PREFIX "EXPECT_TRUE(%d == GETVAL(\"%s\", %d)\n", LOG_RANK, expected->uval.valInt, actual->uval.distantSrc.param, actual->uval.distantSrc.rank);
        }
      } else {
        printf(LOG_PREFIX "EXPECT_TRUE(GETVAL(\"%s\", %d) == %d\n", LOG_RANK, expected->uval.distantSrc.param, expected->uval.distantSrc.rank, actual->uval.valInt);
      }
      return;
    case STRING:
      if (expected->isLocal) {
        if (actual->isLocal) {
          printf(LOG_PREFIX "EXPECT_TRUE(%s==%s)\n", LOG_RANK, expected->uval.valStr, actual->uval.valStr);
        } else {
          printf(LOG_PREFIX "EXPECT_TRUE(%s == GETVAL(\"%s\", %d)\n", LOG_RANK, expected->uval.valStr, actual->uval.distantSrc.param, actual->uval.distantSrc.rank);
        }
      } else {
        printf(LOG_PREFIX "EXPECT_TRUE(GETVAL(\"%s\", %d) == %s\n", LOG_RANK, expected->uval.distantSrc.param, expected->uval.distantSrc.rank, actual->uval.valStr);
      }
      break;
  }

  free(expected);
  free(actual);
}
#endif
