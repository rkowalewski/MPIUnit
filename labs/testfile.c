#include <stdio.h>
#include<stdlib.h>
#include<stdarg.h>
#include "logging.h"

void test(GetValType *ptr, int flag);
int testVar(int n, ...);

int main (void) {
  EXPECT_EQ(1, INT, 3, 3);
  EXPECT_EQ(1, INT, 1000, GETVAL(NPROCS, 5));
}


void test(GetValType *ptr, int flag) {
  printf("Param: %d, rank: %d, flag: %d\n", ptr->param, ptr->rank, flag);
}

int testVar(int n, ...) {
  va_list argp;
  va_start(argp, n);
  GetValType *ptr = va_arg(argp, GetValType *);
  printf("Param: %d, rank: %d\n", ptr->param, ptr->rank);
  va_end(argp);
  return 0;
}
