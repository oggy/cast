#include <assert.h>
#include "ruby.h"

/* Modules and classes.
 */
extern VALUE cast_mC;
extern VALUE cast_cParser;
extern VALUE cast_eParseError;

/*
 * -------------------------------------------------------------------
 *                               Helpers
 * -------------------------------------------------------------------
 */

#define Get_Struct(value, type, sval) do {          \
  sval = (cast_##type *)DATA_PTR(value);            \
} while (0)

#define Find_Struct(value, type, sval) do {                             \
  if (!rb_obj_is_kind_of(value, cast_c##type))                          \
    rb_raise(rb_eTypeError, #type " expected, got %s", rb_obj_classname(value)); \
  sval = (cast_##type *)DATA_PTR(value);                                \
} while (0)

#define Wrap_Struct(ptr, type, klass) \
  Data_Wrap_Struct(klass, cast_##type##_mark, cast_##type##_free, ptr)

/*
 * -------------------------------------------------------------------
 *                               Parser
 * -------------------------------------------------------------------
 */

typedef struct {
  /* stuff used by yylex */
  char *bot, *tok, *ptr, *cur, *pos, *lim, *top, *eof;
  long  lineno;      /* line number */
  VALUE token;       /* last token (2-element array) */
} cast_Parser;

VALUE cast_Parser_alloc(VALUE klass);
void  cast_Parser_mark(cast_Parser *parser);
void  cast_Parser_free(cast_Parser *parser);
VALUE cast_Parser_next_token(VALUE self);
void yylex(VALUE self, cast_Parser *p);
void cast_init_parser(void);

/* Lexer symbols. */
extern VALUE cast_sym_AUTO;
extern VALUE cast_sym_BREAK;
extern VALUE cast_sym_CASE;
extern VALUE cast_sym_CHAR;
extern VALUE cast_sym_CONST;
extern VALUE cast_sym_CONTINUE;
extern VALUE cast_sym_DEFAULT;
extern VALUE cast_sym_DO;
extern VALUE cast_sym_DOUBLE;
extern VALUE cast_sym_ELSE;
extern VALUE cast_sym_ENUM;
extern VALUE cast_sym_EXTERN;
extern VALUE cast_sym_FLOAT;
extern VALUE cast_sym_FOR;
extern VALUE cast_sym_GOTO;
extern VALUE cast_sym_IF;
extern VALUE cast_sym_INT;
extern VALUE cast_sym_LONG;
extern VALUE cast_sym_REGISTER;
extern VALUE cast_sym_RETURN;
extern VALUE cast_sym_SHORT;
extern VALUE cast_sym_SIGNED;
extern VALUE cast_sym_SIZEOF;
extern VALUE cast_sym_STATIC;
extern VALUE cast_sym_STRUCT;
extern VALUE cast_sym_SWITCH;
extern VALUE cast_sym_TYPEDEF;
extern VALUE cast_sym_UNION;
extern VALUE cast_sym_UNSIGNED;
extern VALUE cast_sym_VOID;
extern VALUE cast_sym_VOLATILE;
extern VALUE cast_sym_WHILE;
extern VALUE cast_sym_INLINE;
extern VALUE cast_sym_RESTRICT;
extern VALUE cast_sym_BOOL;
extern VALUE cast_sym_COMPLEX;
extern VALUE cast_sym_IMAGINARY;

extern VALUE cast_sym_FCON;
extern VALUE cast_sym_ICON;
extern VALUE cast_sym_ID;
extern VALUE cast_sym_SCON;
extern VALUE cast_sym_CCON;
extern VALUE cast_sym_TYPENAME;

extern VALUE cast_sym_ADDEQ;
extern VALUE cast_sym_ANDAND;
extern VALUE cast_sym_ANDEQ;
extern VALUE cast_sym_DEC;
extern VALUE cast_sym_ARROW;
extern VALUE cast_sym_DIVEQ;
extern VALUE cast_sym_ELLIPSIS;
extern VALUE cast_sym_EQEQ;
extern VALUE cast_sym_GEQ;
extern VALUE cast_sym_INC;
extern VALUE cast_sym_LEQ;
extern VALUE cast_sym_LSHIFT;
extern VALUE cast_sym_LSHIFTEQ;
extern VALUE cast_sym_MODEQ;
extern VALUE cast_sym_MULEQ;
extern VALUE cast_sym_NEQ;
extern VALUE cast_sym_OREQ;
extern VALUE cast_sym_OROR;
extern VALUE cast_sym_RSHIFT;
extern VALUE cast_sym_RSHIFTEQ;
extern VALUE cast_sym_SUBEQ;
extern VALUE cast_sym_XOREQ;

extern VALUE cast_sym_SEMICOLON;
extern VALUE cast_sym_LBRACE;
extern VALUE cast_sym_RBRACE;
extern VALUE cast_sym_COMMA;
extern VALUE cast_sym_COLON;
extern VALUE cast_sym_EQ;
extern VALUE cast_sym_LPAREN;
extern VALUE cast_sym_RPAREN;
extern VALUE cast_sym_LBRACKET;
extern VALUE cast_sym_RBRACKET;
extern VALUE cast_sym_DOT;
extern VALUE cast_sym_AND;
extern VALUE cast_sym_BANG;
extern VALUE cast_sym_NOT;
extern VALUE cast_sym_SUB;
extern VALUE cast_sym_ADD;
extern VALUE cast_sym_MUL;
extern VALUE cast_sym_DIV;
extern VALUE cast_sym_MOD;
extern VALUE cast_sym_LT;
extern VALUE cast_sym_GT;
extern VALUE cast_sym_XOR;
extern VALUE cast_sym_OR;
extern VALUE cast_sym_QUESTION;
