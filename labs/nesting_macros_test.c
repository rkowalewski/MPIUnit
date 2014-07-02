#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#define _ARG2(_0, _1, _2, ...) _2
#define NARG2(...) _ARG2(__VA_ARGS__, 2, 1, 0)
#define _ONE_OR_TWO_ARGS_1(NAME, a) a, NAME ## _default_arg_1()
#define _ONE_OR_TWO_ARGS_2(NAME, a, b) a, b
#define __ONE_OR_TWO_ARGS(NAME, N, ...) _ONE_OR_TWO_ARGS_ ## N (NAME, __VA_ARGS__)
#define _ONE_OR_TWO_ARGS(NAME, N, ...) __ONE_OR_TWO_ARGS(NAME, N, __VA_ARGS__)
#define ONE_OR_TWO_ARGS(NAME, ...) NAME(_ONE_OR_TWO_ARGS(NAME, NARG2(__VA_ARGS__), __VA_ARGS__))
#define one_or_two(...) ONE_OR_TWO_ARGS(one_or_two, __VA_ARGS__)

#define EXPECT_EQ_INT(actual, expected) \
  EXECUTE_ASSERT_FN(expect_eq, INT_##actual, INT_##expected)

#define EXECUTE_ASSERT_FN(name, value1, value2) \
  name(value1, value2);

#define INT_VAL(...) \
  VAL_INTERN(NARG2(__VA_ARGS__), INT, __VA_ARGS__)

#define VAL_INTERN(N, ...) \
  createValue(N, __VA_ARGS__)

typedef enum ReturnType_s {
  INT, STRING
} ReturnType;

typedef struct ValueType_s {
  int isLocal;
  ReturnType type;
  union {
    int valInt;
    char* valStr;
    struct {
      int rank;
      char* param;
    } distantSrc;
  } u;
} ValueType;

void one_or_two(int a, int b) {
  printf("%s seeing a=%d and b=%d\n", __func__, a, b);
}
static inline int one_or_two_default_arg_1(void) {
  return 5;
}

ValueType* createValue(int nargs, ...) {
  if (nargs < 1) {
    return NULL;
  }
  va_list arguments;
  va_start(arguments, nargs);
  
  ValueType *value = (ValueType*) malloc(sizeof(ValueType));
  value->isLocal = nargs == 1;
  value->type = va_arg(arguments, ReturnType);

  if (value->isLocal) {
    switch(value->type) {
      case INT:
        value->u.valInt = va_arg(arguments, int);
        break;
      case STRING:
        value->u.valStr = va_arg(arguments, char*);
        break;
      default: break;
    }
  } else {
    char* distantParam = va_arg(arguments, char*);
    int rank = va_arg(arguments, int);
    value->u.distantSrc.param = distantParam;
    value->u.distantSrc.rank = rank;
  }

  va_end(arguments);

  return value;
}

void printValueType(ValueType* valueType) {
  printf("ValueType:\n");
  printf("ValueType.type: %d\n", valueType->type);

  if (valueType->isLocal) {
    switch(valueType->type) {
      case INT:
        printf("ValueType.valInt: %d\n", valueType->u.valInt);
        break;
      case STRING:
        printf("ValueType.valStr: %s\n", valueType->u.valStr);
        break;
    }
  } else {
    printf("Value is not local...\n");
    printf("ValueType.u.distantSrc.param: %s\n", valueType->u.distantSrc.param);
    printf("ValueType.u.distantSrc.rank: %d\n", valueType->u.distantSrc.rank);
  }
}

void expect_eq(ValueType* expected, ValueType* actual) {
  printValueType(expected);
  printValueType(actual);

  free(expected);
  free(actual);

}

int getInteger() {
  return 100;
}

int main (void) {
  one_or_two(6);
  one_or_two(6,10);
  int x = 5;
  EXPECT_EQ_INT(VAL(1), VAL(1));
  EXPECT_EQ_INT(VAL("path", 1), VAL(getInteger()));
}



