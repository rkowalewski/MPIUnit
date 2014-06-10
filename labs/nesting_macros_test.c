#include <stdio.h>
#define _ARG2(_0, _1, _2, ...) _2
#define NARG2(...) _ARG2(__VA_ARGS__, 2, 1, 0)
#define _ONE_OR_TWO_ARGS_1(NAME, a) a, NAME ## _default_arg_1()
#define _ONE_OR_TWO_ARGS_2(NAME, a, b) a, b
#define __ONE_OR_TWO_ARGS(NAME, N, ...) _ONE_OR_TWO_ARGS_ ## N (NAME, __VA_ARGS__)
#define _ONE_OR_TWO_ARGS(NAME, N, ...) __ONE_OR_TWO_ARGS(NAME, N, __VA_ARGS__)
#define ONE_OR_TWO_ARGS(NAME, ...) NAME(_ONE_OR_TWO_ARGS(NAME, NARG2(__VA_ARGS__), __VA_ARGS__))
#define one_or_two(...) ONE_OR_TWO_ARGS(one_or_two, __VA_ARGS__)

void one_or_two(int a, int b) { printf("%s seeing a=%d and b=%d\n", __func__, a, b); }
static inline int one_or_two_default_arg_1(void) {  return 5; }
 
int main (void) {
  one_or_two(6);
  one_or_two(6,10);
}
