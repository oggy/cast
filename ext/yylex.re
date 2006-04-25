/* -*- mode: c -*- */
/* Given to re2c to generate the lexer `yylex'.
 *
 * Based on c.re in the exmaples distributed with re2c.
 */
#include <string.h>
#include "cast.h"

/*
 * -------------------------------------------------------------------
 *                               Helpers
 * -------------------------------------------------------------------
 */

#define new_func(Foo)                                       \
VALUE cast_new_##Foo##_at(long pos) {                       \
  VALUE c##Foo;                                             \
  c##Foo = rb_const_get(cast_mC, rb_intern(#Foo));          \
  return rb_funcall2(c##Foo, rb_intern("new"), 0, NULL);    \
}
#define set_func(Foo, field)                                    \
VALUE cast_##Foo##_set_##field(VALUE self, VALUE value) {       \
  return rb_funcall2(self, rb_intern(#field "="), 1, &value);   \
}

new_func(IntLiteral);
set_func(IntLiteral, format);
set_func(IntLiteral, val);
set_func(IntLiteral, suffix);

new_func(FloatLiteral);
set_func(FloatLiteral, format);
set_func(FloatLiteral, val);
set_func(FloatLiteral, suffix);

new_func(CharLiteral);
set_func(CharLiteral, wide);
set_func(CharLiteral, val);

new_func(StringLiteral);
set_func(StringLiteral, wide);
set_func(StringLiteral, val);

/*
 * -------------------------------------------------------------------
 *                                yylex
 * -------------------------------------------------------------------
 */
#define BSIZE     8192

#define YYLTYPE VALUE

#define YYCTYPE   char
#define YYCURSOR  cursor
#define YYLIMIT   p->lim
#define YYMARKER  p->ptr
#define YYFILL(n) {}

#define RET(sym)      {p->cur = cursor; rb_ary_store(p->token, 0, sym); rb_ary_store(p->token, 1, sym  ); return;}
#define RETVALUE(sym) {p->cur = cursor; rb_ary_store(p->token, 0, sym); rb_ary_store(p->token, 1, value); return;}

/* Raise a ParseError.  `s' is the format string for the exception
 * message, which must contain exactly one '%s', which is replaced by
 * the string delimited by `b' and `e'.
 */
static void error1(char *s, char *b, char *e) {
  char *str;
  str = ALLOCA_N(char, e - b + 1);
  memcpy(str, b, e-b);
  str[e-b] = '\0';
  rb_raise(cast_eParseError, s, str);
}

/* `token' is assumed to be a two element array, which is filled in.
 */
void yylex(VALUE self, cast_Parser *p) {
  char *cursor = p->cur;
  char *cp;
  VALUE value;
 std:
  p->tok = cursor;
  /*!re2c
    any      = [\000-\377];
    O        = [0-7];
    D        = [0-9];
    H        = [a-fA-F0-9];
    N        = [1-9];
    L        = [a-zA-Z_];
    E        = [Ee] [+-]? D+;
    P        = [Pp] [+-]? D+;
    FS       = [fFlL];
    IS       = [uUlL]+;

    ESC      = [\\] ([abfnrtv?'"\\] | O (O O?)? | "x" H+);
  */
  /*!re2c
    "/*"         { goto comment; }
    "//"         { goto comment2; }

    "auto"       { RET(cast_sym_AUTO); }
    "break"      { RET(cast_sym_BREAK); }
    "case"       { RET(cast_sym_CASE); }
    "char"       { RET(cast_sym_CHAR); }
    "const"      { RET(cast_sym_CONST); }
    "continue"   { RET(cast_sym_CONTINUE); }
    "default"    { RET(cast_sym_DEFAULT); }
    "do"         { RET(cast_sym_DO); }
    "double"     { RET(cast_sym_DOUBLE); }
    "else"       { RET(cast_sym_ELSE); }
    "enum"       { RET(cast_sym_ENUM); }
    "extern"     { RET(cast_sym_EXTERN); }
    "float"      { RET(cast_sym_FLOAT); }
    "for"        { RET(cast_sym_FOR); }
    "goto"       { RET(cast_sym_GOTO); }
    "if"         { RET(cast_sym_IF); }
    "int"        { RET(cast_sym_INT); }
    "long"       { RET(cast_sym_LONG); }
    "register"   { RET(cast_sym_REGISTER); }
    "return"     { RET(cast_sym_RETURN); }
    "short"      { RET(cast_sym_SHORT); }
    "signed"     { RET(cast_sym_SIGNED); }
    "sizeof"     { RET(cast_sym_SIZEOF); }
    "static"     { RET(cast_sym_STATIC); }
    "struct"     { RET(cast_sym_STRUCT); }
    "switch"     { RET(cast_sym_SWITCH); }
    "typedef"    { RET(cast_sym_TYPEDEF); }
    "union"      { RET(cast_sym_UNION); }
    "unsigned"   { RET(cast_sym_UNSIGNED); }
    "void"       { RET(cast_sym_VOID); }
    "volatile"   { RET(cast_sym_VOLATILE); }
    "while"      { RET(cast_sym_WHILE); }
    "inline"     { RET(cast_sym_INLINE); }
    "restrict"   { RET(cast_sym_RESTRICT); }
    "_Bool"      { RET(cast_sym_BOOL); }
    "_Complex"   { RET(cast_sym_COMPLEX); }
    "_Imaginary" { RET(cast_sym_IMAGINARY); }

    L (L|D)* {
        value = rb_str_new(p->tok, cursor - p->tok);
        if (rb_funcall2(rb_funcall2(self, rb_intern("type_names"), 0, NULL),
                       rb_intern("include?"), 1, &value) == Qtrue) {
          RETVALUE(cast_sym_TYPENAME);
        } else {
          RETVALUE(cast_sym_ID);
        }
    }

    SUF = L(L|D)*;

    "0" [xX] H+ SUF? {
        value = cast_new_IntLiteral_at(p->lineno);
        cast_IntLiteral_set_format(value, ID2SYM(rb_intern("hex")));
        cast_IntLiteral_set_val(value, LONG2NUM(strtol(p->tok, (char **)&cp, 16)));
        if (cp < cursor)
            cast_IntLiteral_set_suffix(value, rb_str_new(cp, cursor - cp));
        RETVALUE(cast_sym_ICON);
    }
    "0" D+ SUF? {
        value = cast_new_IntLiteral_at(p->lineno);
        cast_IntLiteral_set_format(value, ID2SYM(rb_intern("oct")));
        cast_IntLiteral_set_val(value, LONG2NUM(strtol(p->tok, (char **)&cp, 8)));
        if (cp < cursor) {
            if (cp[0] == '8' || cp[0] == '9')
                rb_raise(cast_eParseError, "bad octal digit: %c", cp[0]);
            cast_IntLiteral_set_suffix(value, rb_str_new(cp, cursor - cp));
        }
        RETVALUE(cast_sym_ICON);
    }
    ( "0" | [1-9] D* ) SUF?  {
        value = cast_new_IntLiteral_at(p->lineno);
        cast_IntLiteral_set_format(value, ID2SYM(rb_intern("dec")));
        cast_IntLiteral_set_val(value, LONG2NUM(strtol(p->tok, (char **)&cp, 10)));
        if (cp < cursor)
            cast_IntLiteral_set_suffix(value, rb_str_new(cp, cursor - cp));
        RETVALUE(cast_sym_ICON);
    }

    ( D+ E | D* "." D+ E? | D+ "." D* E? ) SUF? {
        value = cast_new_FloatLiteral_at(p->lineno);
        cast_FloatLiteral_set_format(value, ID2SYM(rb_intern("dec")));
        cast_FloatLiteral_set_val(value, rb_float_new(strtod(p->tok, (char **)&cp)));
        if (cp < cursor)
            cast_FloatLiteral_set_suffix(value, rb_str_new(cp, cursor - cp));
        RETVALUE(cast_sym_FCON);
    }
    ( "0" [Xx] (H+ P | H* "." H+ P? | H+ "." H* P?) ) SUF? {
        value = cast_new_FloatLiteral_at(p->lineno);
        cast_FloatLiteral_set_format(value, ID2SYM(rb_intern("hex")));
        cast_FloatLiteral_set_val(value, rb_float_new(strtod(p->tok, (char **)&cp)));
        if (cp < cursor)
            cast_FloatLiteral_set_suffix(value, rb_str_new(cp, cursor - cp));
        RETVALUE(cast_sym_FCON);
    }

    L? ['] (ESC|any\[\n\\'])+ ['] {
        value = cast_new_CharLiteral_at(p->lineno);
        if (p->tok[0] == 'L') {
            cast_CharLiteral_set_wide(value, Qtrue);
            cp = p->tok + 1;
        } else {
            cast_CharLiteral_set_wide(value, Qfalse);
            cp = p->tok;
        }
        cast_CharLiteral_set_val(value, rb_str_new(cp + 1, cursor - cp - 2));
        RETVALUE(cast_sym_CCON);
    }
    L? ["] (ESC|any\[\n\\"])* ["] {
        value = cast_new_StringLiteral_at(p->lineno);
        if (p->tok[0] == 'L') {
            cast_StringLiteral_set_wide(value, Qtrue);
            cp = p->tok + 1;
        } else {
            cast_StringLiteral_set_wide(value, Qfalse);
            cp = p->tok;
        }
        cast_StringLiteral_set_val(value, rb_str_new(cp + 1, cursor - cp - 2));
        RETVALUE(cast_sym_SCON);
    }

    "..."       { RET(cast_sym_ELLIPSIS); }
    ">>="       { RET(cast_sym_RSHIFTEQ); }
    "<<="       { RET(cast_sym_LSHIFTEQ); }
    "+="        { RET(cast_sym_ADDEQ); }
    "-="        { RET(cast_sym_SUBEQ); }
    "*="        { RET(cast_sym_MULEQ); }
    "/="        { RET(cast_sym_DIVEQ); }
    "%="        { RET(cast_sym_MODEQ); }
    "&="        { RET(cast_sym_ANDEQ); }
    "^="        { RET(cast_sym_XOREQ); }
    "|="        { RET(cast_sym_OREQ); }
    ">>"        { RET(cast_sym_RSHIFT); }
    "<<"        { RET(cast_sym_LSHIFT); }
    "++"        { RET(cast_sym_INC); }
    "--"        { RET(cast_sym_DEC); }
    "->"        { RET(cast_sym_ARROW); }
    "&&"        { RET(cast_sym_ANDAND); }
    "||"        { RET(cast_sym_OROR); }
    "<="        { RET(cast_sym_LEQ); }
    ">="        { RET(cast_sym_GEQ); }
    "=="        { RET(cast_sym_EQEQ); }
    "!="        { RET(cast_sym_NEQ); }
    ";"         { RET(cast_sym_SEMICOLON); }
    "{"         { RET(cast_sym_LBRACE); }
    "}"         { RET(cast_sym_RBRACE); }
    ","         { RET(cast_sym_COMMA); }
    ":"         { RET(cast_sym_COLON); }
    "="         { RET(cast_sym_EQ); }
    "("         { RET(cast_sym_LPAREN); }
    ")"         { RET(cast_sym_RPAREN); }
    "["         { RET(cast_sym_LBRACKET); }
    "]"         { RET(cast_sym_RBRACKET); }
    "."         { RET(cast_sym_DOT); }
    "&"         { RET(cast_sym_AND); }
    "!"         { RET(cast_sym_BANG); }
    "~"         { RET(cast_sym_NOT); }
    "-"         { RET(cast_sym_SUB); }
    "+"         { RET(cast_sym_ADD); }
    "*"         { RET(cast_sym_MUL); }
    "/"         { RET(cast_sym_DIV); }
    "%"         { RET(cast_sym_MOD); }
    "<"         { RET(cast_sym_LT); }
    ">"         { RET(cast_sym_GT); }
    "^"         { RET(cast_sym_XOR); }
    "|"         { RET(cast_sym_OR); }
    "?"         { RET(cast_sym_QUESTION); }

    "<:"        { RET(cast_sym_LBRACKET); }
    "<%"        { RET(cast_sym_LBRACE); }
    ":>"        { RET(cast_sym_RBRACKET); }
    "%>"        { RET(cast_sym_RBRACE); }

    [ \t\v\f]+  { goto std; }

    [\000]
        {
            if(cursor == p->eof) RET(Qnil);
            goto std;
        }

    "\n"
        {
            p->pos = cursor; ++p->lineno;
            goto std;
        }

    any
        {
            //printf("unexpected character: %c\n", *p->tok);
            rb_raise(cast_eParseError, "%d: unexpected character: %c (ASCII %d)\n", p->lineno, *p->tok, (int)*p->tok);
            goto std;
        }
  */

 comment:
  /*!re2c
    "*" "/"                    { goto std; }
    "\n"
        {
            p->tok = p->pos = cursor; ++p->lineno;
            goto comment;
        }

    [\000]
        {
            if (cursor == p->eof)
              rb_raise(cast_eParseError,
                       "%d: unclosed multiline comment",
                       p->lineno);
        }

    any                        { goto comment; }
  */

 comment2:
  /*!re2c
    "\n"
        {
            p->tok = p->pos = cursor; ++p->lineno;
            goto std;
        }

    [\000]
        {
            if (cursor == p->eof) RET(Qnil);
            goto std;
        }

    any                        { goto comment2; }
  */
}
