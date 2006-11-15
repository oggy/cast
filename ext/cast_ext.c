#include "cast.h"

/* Initialize the cast_ext module.
 */
void Init_cast_ext(void) {
  cast_mC = rb_define_module("C");
  cast_init_parser();
}
