#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

typedef enum types_e {
  INT, CHAR
} types_t;

typedef struct value_s {
  types_t type;
  void* value;
} value_t;

value_t* createValue(int n, ...) {
  va_list argp;
  va_start(argp, n);
  
  types_t type = va_arg(argp, types_t);
  void *value = va_arg(argp, void*);
  
  value_t *val = (value_t*) malloc(sizeof(value_t));
  val->value = value;
  val->type = type;
  return val;
}

int main(int argc, char** args) {
  value_t * value = createValue(2, INT, 5);
  printf("Type: %d, Value:%D", value->type, *((int*) value->value));
  
}
