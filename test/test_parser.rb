###
### ##################################################################
###
### Parser routine tests.  One test for each grammar rule.
###
### ##################################################################
###

require 'common.rb'

class ParserTest < Test::Unit::TestCase
  include CheckAst
  def check s
    check_ast(s){|inp| C::Parser.new.parse(inp)}
  end

  def test_comments
    check <<EOS
/* blah "blah" 'blah' */
void f() {
    1;
    /* " */
    2;
    /* /* * / */
    3;
    /*/*/
    4;
    /* multiline comment
     */
    5;
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: IntLiteral
                            val: 1
                    - ExpressionStatement
                        expr: IntLiteral
                            val: 2
                    - ExpressionStatement
                        expr: IntLiteral
                            val: 3
                    - ExpressionStatement
                        expr: IntLiteral
                            val: 4
                    - ExpressionStatement
                        expr: IntLiteral
                            val: 5
EOS
#"
  end

  def test_translation_unit
    check <<EOS
int i;
----
TranslationUnit
    entities:
        - Declaration
            type: Int
            declarators:
                - Declarator
                    name: "i"
EOS
    check <<EOS
int i;
int i;
----
TranslationUnit
    entities:
        - Declaration
            type: Int
            declarators:
                - Declarator
                    name: "i"
        - Declaration
            type: Int
            declarators:
                - Declarator
                    name: "i"
EOS
    assert_raise(ParseError){C::Parser.new.parse("")}
    assert_raise(ParseError){C::Parser.new.parse(";")}
  end

  def test_external_declaration
    check <<EOS
int i;
void f() {}
----
TranslationUnit
    entities:
        - Declaration
            type: Int
            declarators:
                - Declarator
                    name: "i"
        - FunctionDef
            type: Function
                type: Void
            name: "f"
EOS
  end

  def test_function_def
    check <<EOS
int main(int, char **) {}
int main(argc, argv) char **argv; int argc; {}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Int
                params:
                    - Parameter
                        type: Int
                    - Parameter
                        type: Pointer
                            type: Pointer
                                type: Char
            name: "main"
        - FunctionDef (no_prototype)
            type: Function
                type: Int
                params:
                    - Parameter
                        type: Int
                        name: "argc"
                    - Parameter
                        type: Pointer
                            type: Pointer
                                type: Char
                        name: "argv"
            name: "main"
EOS
    ## non-function type
    assert_raise(ParseError){C::Parser.new.parse("int f {}")}

    ## both prototype and declist
    assert_raise(ParseError){C::Parser.new.parse("void f(int argc, int argv) int argc, argv; {}")}
    assert_raise(ParseError){C::Parser.new.parse("void f(int argc, argv) int argv; {}")}

    ## bad param name
    assert_raise(ParseError){C::Parser.new.parse("void f(argc, argv) int argx, argc; {}")}
    assert_raise(ParseError){C::Parser.new.parse("void f(argc, argv) int argx, argc, argv; {}")}

    ## type missing
    assert_raise(ParseError){C::Parser.new.parse("void f(argc, argv) int argc; {}")}

    ## bad storage
    assert_raise(ParseError){C::Parser.new.parse("typedef void f(argc, argv) int argc; {}")}
    assert_raise(ParseError){C::Parser.new.parse("auto void f(argc, argv) int argc; {}")}
    assert_raise(ParseError){C::Parser.new.parse("register void f(argc, argv) int argc; {}")}

    ## duplicate storages
    assert_raise(ParseError){C::Parser.new.parse("static  auto     int i;")}
    assert_raise(ParseError){C::Parser.new.parse("static  extern   int i;")}
    assert_raise(ParseError){C::Parser.new.parse("typedef register int i;")}

    ## `inline' can be repeated
    assert_nothing_raised{C::Parser.new.parse("inline inline int i() {}")}
  end

  def test_declaration_list
    check <<EOS
int main(argc, argv) int argc, argv; {}
int main(argc, argv) int argc, argv; int; {}
int main(argc, argv) int argc; int argv; int; {}
int main(argc, argv) int argc, *argv; int; {}
----
TranslationUnit
    entities:
        - FunctionDef (no_prototype)
            type: Function
                type: Int
                params:
                    - Parameter
                        type: Int
                        name: "argc"
                    - Parameter
                        type: Int
                        name: "argv"
            name: "main"
        - FunctionDef (no_prototype)
            type: Function
                type: Int
                params:
                    - Parameter
                        type: Int
                        name: "argc"
                    - Parameter
                        type: Int
                        name: "argv"
            name: "main"
        - FunctionDef (no_prototype)
            type: Function
                type: Int
                params:
                    - Parameter
                        type: Int
                        name: "argc"
                    - Parameter
                        type: Int
                        name: "argv"
            name: "main"
        - FunctionDef (no_prototype)
            type: Function
                type: Int
                params:
                    - Parameter
                        type: Int
                        name: "argc"
                    - Parameter
                        type: Pointer
                            type: Int
                        name: "argv"
            name: "main"
EOS
  end

  def test_statement
    check <<EOS
void f() {
    a: ;
    {}
    ;
    if (0);
    while (0);
    return;
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        labels:
                            - PlainLabel
                                name: "a"
                    - Block
                    - ExpressionStatement
                    - If
                        cond: IntLiteral
                            val: 0
                        then: ExpressionStatement
                    - While
                        cond: IntLiteral
                            val: 0
                        stmt: ExpressionStatement
                    - Return
EOS
  end

  def test_labeled_statement
    check <<EOS
typedef int I;
void f() {
    a: I: case 1: default: ;
    if (0)
        b: I: case 2: default: ;
    switch (0)
    c: I: case 3: default: {
        d: I: case 4: default: ;
    }
}
----
TranslationUnit
    entities:
        - Declaration
            storage: typedef
            type: Int
            declarators:
                - Declarator
                    name: "I"
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        labels:
                            - PlainLabel
                                name: "a"
                            - PlainLabel
                                name: "I"
                            - Case
                                expr: IntLiteral
                                    val: 1
                            - Default
                    - If
                        cond: IntLiteral
                            val: 0
                        then: ExpressionStatement
                            labels:
                                - PlainLabel
                                    name: "b"
                                - PlainLabel
                                    name: "I"
                                - Case
                                    expr: IntLiteral
                                        val: 2
                                - Default
                    - Switch
                        cond: IntLiteral
                            val: 0
                        stmt: Block
                            labels:
                                - PlainLabel
                                    name: "c"
                                - PlainLabel
                                    name: "I"
                                - Case
                                    expr: IntLiteral
                                        val: 3
                                - Default
                            stmts:
                                - ExpressionStatement
                                    labels:
                                        - PlainLabel
                                            name: "d"
                                        - PlainLabel
                                            name: "I"
                                        - Case
                                            expr: IntLiteral
                                                val: 4
                                        - Default
EOS
  end

  def test_compound_statement
    check <<EOS
void f() {
    { }
    {;}
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - Block
                    - Block
                        stmts:
                            - ExpressionStatement
EOS
  end

  def test_block_item_list
    check <<EOS
void f() {; }
void f() {;;}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                    - ExpressionStatement
EOS
  end

  def test_block_item
    check <<EOS
void f() {   ;}
void f() {int;}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - Declaration
                        type: Int
EOS
  end

  def test_expression_statement
    check <<EOS
void f() {
    ;
    1;
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                    - ExpressionStatement
                        expr: IntLiteral
                            val: 1
EOS
  end

  def test_selection_statement
    check <<EOS
void f() {
    if (1) ;
    if (1) ; else ;
    if (1) ; else if (2) ; else ;
    if (1) if (2) ; else ;
    if (1) if (2) ; else ; else ;
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - If
                        cond: IntLiteral
                            val: 1
                        then: ExpressionStatement
                    - If
                        cond: IntLiteral
                            val: 1
                        then: ExpressionStatement
                        else: ExpressionStatement
                    - If
                        cond: IntLiteral
                            val: 1
                        then: ExpressionStatement
                        else: If
                            cond: IntLiteral
                                val: 2
                            then: ExpressionStatement
                            else: ExpressionStatement
                    - If
                        cond: IntLiteral
                            val: 1
                        then: If
                            cond: IntLiteral
                                val: 2
                            then: ExpressionStatement
                            else: ExpressionStatement
                    - If
                        cond: IntLiteral
                            val: 1
                        then: If
                            cond: IntLiteral
                                val: 2
                            then: ExpressionStatement
                            else: ExpressionStatement
                        else: ExpressionStatement
EOS
    check <<EOS
void f() {
    switch (1)
    case 1:
    x:
    default:
        ;
    switch (1)
    case 1:
    y:
    default:
        if (0) ; else ;
    switch (1) {
    case 1:
    case 2: ;
    z:
    default: ;
    }
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - Switch
                        cond: IntLiteral
                            val: 1
                        stmt: ExpressionStatement
                            labels:
                                - Case
                                    expr: IntLiteral
                                        val: 1
                                - PlainLabel
                                    name: "x"
                                - Default
                    - Switch
                        cond: IntLiteral
                            val: 1
                        stmt: If
                            labels:
                                - Case
                                    expr: IntLiteral
                                        val: 1
                                - PlainLabel
                                    name: "y"
                                - Default
                            cond: IntLiteral
                                val: 0
                            then: ExpressionStatement
                            else: ExpressionStatement
                    - Switch
                        cond: IntLiteral
                            val: 1
                        stmt: Block
                            stmts:
                                - ExpressionStatement
                                    labels:
                                        - Case
                                            expr: IntLiteral
                                                val: 1
                                        - Case
                                            expr: IntLiteral
                                                val: 2
                                - ExpressionStatement
                                    labels:
                                        - PlainLabel
                                            name: "z"
                                        - Default
EOS
  end

  def test_iteration_statement
    check <<EOS
void f() {
    while (0) ;
    do ; while (0) ;
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - While
                        cond: IntLiteral
                            val: 0
                        stmt: ExpressionStatement
                    - While (do)
                        cond: IntLiteral
                            val: 0
                        stmt: ExpressionStatement
EOS
    check <<EOS
void f() {
    for (i = 0; i < 10; ++i) ;
    for (i = 0; i < 10;    ) ;
    for (i = 0;       ; ++i) ;
    for (i = 0;       ;    ) ;
    for (     ; i < 10; ++i) ;
    for (     ; i < 10;    ) ;
    for (     ;       ; ++i) ;
    for (     ;       ;    ) ;
    for (int i = 0, j = 1; i < 10, j < 10; ++i, ++j) ;
    for (int i = 0, j = 1; i < 10, j < 10;         ) ;
    for (int i = 0, j = 1;               ; ++i, ++j) ;
    for (int i = 0, j = 1;               ;         ) ;
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - For
                        init: Assign
                            lval: Variable
                                name: "i"
                            rval: IntLiteral
                                val: 0
                        cond: Less
                            expr1: Variable
                                name: "i"
                            expr2: IntLiteral
                                val: 10
                        iter: PreInc
                            expr: Variable
                                name: "i"
                        stmt: ExpressionStatement
                    - For
                        init: Assign
                            lval: Variable
                                name: "i"
                            rval: IntLiteral
                                val: 0
                        cond: Less
                            expr1: Variable
                                name: "i"
                            expr2: IntLiteral
                                val: 10
                        stmt: ExpressionStatement
                    - For
                        init: Assign
                            lval: Variable
                                name: "i"
                            rval: IntLiteral
                                val: 0
                        iter: PreInc
                            expr: Variable
                                name: "i"
                        stmt: ExpressionStatement
                    - For
                        init: Assign
                            lval: Variable
                                name: "i"
                            rval: IntLiteral
                                val: 0
                        stmt: ExpressionStatement
                    - For
                        cond: Less
                            expr1: Variable
                                name: "i"
                            expr2: IntLiteral
                                val: 10
                        iter: PreInc
                            expr: Variable
                                name: "i"
                        stmt: ExpressionStatement
                    - For
                        cond: Less
                            expr1: Variable
                                name: "i"
                            expr2: IntLiteral
                                val: 10
                        stmt: ExpressionStatement
                    - For
                        iter: PreInc
                            expr: Variable
                                name: "i"
                        stmt: ExpressionStatement
                    - For
                        stmt: ExpressionStatement
                    - For
                        init: Declaration
                            type: Int
                            declarators:
                                - Declarator
                                    name: "i"
                                    init: IntLiteral
                                        val: 0
                                - Declarator
                                    name: "j"
                                    init: IntLiteral
                                        val: 1
                        cond: Comma
                            exprs:
                                - Less
                                    expr1: Variable
                                        name: "i"
                                    expr2: IntLiteral
                                        val: 10
                                - Less
                                    expr1: Variable
                                        name: "j"
                                    expr2: IntLiteral
                                        val: 10
                        iter: Comma
                            exprs:
                                - PreInc
                                    expr: Variable
                                        name: "i"
                                - PreInc
                                    expr: Variable
                                        name: "j"
                        stmt: ExpressionStatement
                    - For
                        init: Declaration
                            type: Int
                            declarators:
                                - Declarator
                                    name: "i"
                                    init: IntLiteral
                                        val: 0
                                - Declarator
                                    name: "j"
                                    init: IntLiteral
                                        val: 1
                        cond: Comma
                            exprs:
                                - Less
                                    expr1: Variable
                                        name: "i"
                                    expr2: IntLiteral
                                        val: 10
                                - Less
                                    expr1: Variable
                                        name: "j"
                                    expr2: IntLiteral
                                        val: 10
                        stmt: ExpressionStatement
                    - For
                        init: Declaration
                            type: Int
                            declarators:
                                - Declarator
                                    name: "i"
                                    init: IntLiteral
                                        val: 0
                                - Declarator
                                    name: "j"
                                    init: IntLiteral
                                        val: 1
                        iter: Comma
                            exprs:
                                - PreInc
                                    expr: Variable
                                        name: "i"
                                - PreInc
                                    expr: Variable
                                        name: "j"
                        stmt: ExpressionStatement
                    - For
                        init: Declaration
                            type: Int
                            declarators:
                                - Declarator
                                    name: "i"
                                    init: IntLiteral
                                        val: 0
                                - Declarator
                                    name: "j"
                                    init: IntLiteral
                                        val: 1
                        stmt: ExpressionStatement
EOS
  end

  def test_jump_statement
    check <<EOS
typedef int I;
void f() {
    goto x;
    continue;
    break;
    return 0;
    return;
    goto I;
}
----
TranslationUnit
    entities:
        - Declaration
            storage: typedef
            type: Int
            declarators:
                - Declarator
                    name: "I"
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - Goto
                        target: "x"
                    - Continue
                    - Break
                    - Return
                        expr: IntLiteral
                            val: 0
                    - Return
                    - Goto
                        target: "I"
EOS
  end

  def test_declaration
    check <<EOS
int;
int i;
int i, j;
----
TranslationUnit
    entities:
        - Declaration
            type: Int
        - Declaration
            type: Int
            declarators:
                - Declarator
                    name: "i"
        - Declaration
            type: Int
            declarators:
                - Declarator
                    name: "i"
                - Declarator
                    name: "j"
EOS
    ## duplicate storages
    assert_raise(ParseError){C::Parser.new.parse("static  auto     int     ;")}
    assert_raise(ParseError){C::Parser.new.parse("static  extern   int i   ;")}
    assert_raise(ParseError){C::Parser.new.parse("typedef register int i, j;")}

    ## `inline' can be repeated
    assert_nothing_raised{C::Parser.new.parse("inline inline int f();")}
  end

  def test_declaration_specifiers
    check <<EOS
typedef int X;
int typedef Y;
const int const i;
inline int inline i();
----
TranslationUnit
    entities:
        - Declaration
            storage: typedef
            type: Int
            declarators:
                - Declarator
                    name: "X"
        - Declaration
            storage: typedef
            type: Int
            declarators:
                - Declarator
                    name: "Y"
        - Declaration
            type: Int (const)
            declarators:
                - Declarator
                    name: "i"
        - Declaration (inline)
            type: Int
            declarators:
                - Declarator
                    indirect_type: Function
                    name: "i"
EOS
  end

  def test_init_declarator_list
    check <<EOS
int i;
int i, j;
----
TranslationUnit
    entities:
        - Declaration
            type: Int
            declarators:
                - Declarator
                    name: "i"
        - Declaration
            type: Int
            declarators:
                - Declarator
                    name: "i"
                - Declarator
                    name: "j"
EOS
  end

  def test_init_declarator
    check <<EOS
int i;
int i = 0;
----
TranslationUnit
    entities:
        - Declaration
            type: Int
            declarators:
                - Declarator
                    name: "i"
        - Declaration
            type: Int
            declarators:
                - Declarator
                    name: "i"
                    init: IntLiteral
                        val: 0
EOS
  end

  def test_storage_class_specifier
    check <<EOS
typedef int I;
extern  int i;
static  int f() {
    auto int i;
    register int j;
}
----
TranslationUnit
    entities:
        - Declaration
            storage: typedef
            type: Int
            declarators:
                - Declarator
                    name: "I"
        - Declaration
            storage: extern
            type: Int
            declarators:
                - Declarator
                    name: "i"
        - FunctionDef
            storage: static
            type: Function
                type: Int
            name: "f"
            def: Block
                stmts:
                    - Declaration
                        storage: auto
                        type: Int
                        declarators:
                            - Declarator
                                name: "i"
                    - Declaration
                        storage: register
                        type: Int
                        declarators:
                            - Declarator
                                name: "j"
EOS
  end

  def test_type_specifier
    check <<EOS
void;

char;

char signed;

char unsigned;

short;
int short;
int short;
int short signed;

short unsigned;
int short unsigned;

int;
signed;
int signed;

unsigned;
int unsigned;

long;
long signed;
int long;
int long signed;

long unsigned;
int long unsigned;

long long;
long long signed;
int long long;
int long long signed;

long long unsigned;
int long long unsigned;

float;

double;

double long;

_Bool;

_Complex float;

_Complex double;

_Complex long double;

_Imaginary float;

_Imaginary double;

_Imaginary double long;

struct s;
enum e;
typedef int I;
I;
----
TranslationUnit
    entities:
        - Declaration
            type: Void
        - Declaration
            type: Char
        - Declaration
            type: Char
                signed: true
        - Declaration
            type: Char
                signed: false
        - Declaration
            type: Int
                longness: -1
        - Declaration
            type: Int
                longness: -1
        - Declaration
            type: Int
                longness: -1
        - Declaration
            type: Int
                longness: -1
        - Declaration
            type: Int (unsigned)
                longness: -1
        - Declaration
            type: Int (unsigned)
                longness: -1
        - Declaration
            type: Int
        - Declaration
            type: Int
        - Declaration
            type: Int
        - Declaration
            type: Int (unsigned)
        - Declaration
            type: Int (unsigned)
        - Declaration
            type: Int
                longness: 1
        - Declaration
            type: Int
                longness: 1
        - Declaration
            type: Int
                longness: 1
        - Declaration
            type: Int
                longness: 1
        - Declaration
            type: Int (unsigned)
                longness: 1
        - Declaration
            type: Int (unsigned)
                longness: 1
        - Declaration
            type: Int
                longness: 2
        - Declaration
            type: Int
                longness: 2
        - Declaration
            type: Int
                longness: 2
        - Declaration
            type: Int
                longness: 2
        - Declaration
            type: Int (unsigned)
                longness: 2
        - Declaration
            type: Int (unsigned)
                longness: 2
        - Declaration
            type: Float
        - Declaration
            type: Float
                longness: 1
        - Declaration
            type: Float
                longness: 2
        - Declaration
            type: Bool
        - Declaration
            type: Complex
        - Declaration
            type: Complex
                longness: 1
        - Declaration
            type: Complex
                longness: 2
        - Declaration
            type: Imaginary
        - Declaration
            type: Imaginary
                longness: 1
        - Declaration
            type: Imaginary
                longness: 2
        - Declaration
            type: Struct
                name: "s"
        - Declaration
            type: Enum
                name: "e"
        - Declaration
            storage: typedef
            type: Int
            declarators:
                - Declarator
                    name: "I"
        - Declaration
            type: CustomType
                name: "I"
EOS
    ## some illegal combos
    assert_raise(ParseError){C::Parser.new.parse("int float;")}
    assert_raise(ParseError){C::Parser.new.parse("struct s {} int;")}
    assert_raise(ParseError){C::Parser.new.parse("_Complex;")}
    assert_raise(ParseError){C::Parser.new.parse("_Complex _Imaginary float;")}
    assert_raise(ParseError){C::Parser.new.parse("short long;")}
    assert_raise(ParseError){C::Parser.new.parse("signed unsigned char;")}
    assert_raise(ParseError){C::Parser.new.parse("int int;")}
    assert_raise(ParseError){C::Parser.new.parse("long char;")}
    assert_raise(ParseError){C::Parser.new.parse("long long long;")}
  end

  def test_struct_or_union_specifier
    check <<EOS
struct s { int i; } ;
struct   { int i; } ;
struct s            ;
typedef int I       ;
struct I { int i; } ;
struct I            ;
----
TranslationUnit
    entities:
        - Declaration
            type: Struct
                name: "s"
                members:
                    - Declaration
                        type: Int
                        declarators:
                            - Declarator
                                name: "i"
        - Declaration
            type: Struct
                members:
                    - Declaration
                        type: Int
                        declarators:
                            - Declarator
                                name: "i"
        - Declaration
            type: Struct
                name: "s"
        - Declaration
            storage: typedef
            type: Int
            declarators:
                - Declarator
                    name: "I"
        - Declaration
            type: Struct
                name: "I"
                members:
                    - Declaration
                        type: Int
                        declarators:
                            - Declarator
                                name: "i"
        - Declaration
            type: Struct
                name: "I"
EOS
  end

  def test_struct_or_union
    check <<EOS
struct s;
union u;
----
TranslationUnit
    entities:
        - Declaration
            type: Struct
                name: "s"
        - Declaration
            type: Union
                name: "u"
EOS
  end

  def test_struct_declaration_list
    check <<EOS
struct   { int i; } ;
struct   { int i; int j; } ;
----
TranslationUnit
    entities:
        - Declaration
            type: Struct
                members:
                    - Declaration
                        type: Int
                        declarators:
                            - Declarator
                                name: "i"
        - Declaration
            type: Struct
                members:
                    - Declaration
                        type: Int
                        declarators:
                            - Declarator
                                name: "i"
                    - Declaration
                        type: Int
                        declarators:
                            - Declarator
                                name: "j"
EOS
  end

  def test_struct_declaration
    check <<EOS
struct { int i; };
----
TranslationUnit
    entities:
        - Declaration
            type: Struct
                members:
                    - Declaration
                        type: Int
                        declarators:
                            - Declarator
                                name: "i"
EOS
  end

  def test_specifier_qualifier_list
    check <<EOS
void f() {
    sizeof(int const);
    sizeof(const int);
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: Sizeof
                            expr: Int (const)
                    - ExpressionStatement
                        expr: Sizeof
                            expr: Int (const)
EOS
    ## quals can be repeated
    assert_nothing_raised{C::Parser.new.parse("void f() {sizeof(const const int);}")}
  end

  def test_struct_declarator_list
    check <<EOS
struct { int i; };
struct { int i, j; };
----
TranslationUnit
    entities:
        - Declaration
            type: Struct
                members:
                    - Declaration
                        type: Int
                        declarators:
                            - Declarator
                                name: "i"
        - Declaration
            type: Struct
                members:
                    - Declaration
                        type: Int
                        declarators:
                            - Declarator
                                name: "i"
                            - Declarator
                                name: "j"
EOS
  end

  def test_struct_declarator
    check <<EOS
struct { int i; };
struct { int i : 1; };
struct { int   : 2; };
----
TranslationUnit
    entities:
        - Declaration
            type: Struct
                members:
                    - Declaration
                        type: Int
                        declarators:
                            - Declarator
                                name: "i"
        - Declaration
            type: Struct
                members:
                    - Declaration
                        type: Int
                        declarators:
                            - Declarator
                                name: "i"
                                num_bits: IntLiteral
                                    val: 1
        - Declaration
            type: Struct
                members:
                    - Declaration
                        type: Int
                        declarators:
                            - Declarator
                                num_bits: IntLiteral
                                    val: 2
EOS
  end

  def test_enum_specifier
    check <<EOS
enum e { i  };
enum   { i  };
enum e { i, };
enum   { i, };
enum e       ;
typedef int E;
enum E { i  };
enum E { i, };
enum E       ;
----
TranslationUnit
    entities:
        - Declaration
            type: Enum
                name: "e"
                members:
                    - Enumerator
                        name: "i"
        - Declaration
            type: Enum
                members:
                    - Enumerator
                        name: "i"
        - Declaration
            type: Enum
                name: "e"
                members:
                    - Enumerator
                        name: "i"
        - Declaration
            type: Enum
                members:
                    - Enumerator
                        name: "i"
        - Declaration
            type: Enum
                name: "e"
        - Declaration
            storage: typedef
            type: Int
            declarators:
                - Declarator
                    name: "E"
        - Declaration
            type: Enum
                name: "E"
                members:
                    - Enumerator
                        name: "i"
        - Declaration
            type: Enum
                name: "E"
                members:
                    - Enumerator
                        name: "i"
        - Declaration
            type: Enum
                name: "E"
EOS
  end

  def test_enumerator_list
    check <<EOS
enum e { i    };
enum e { i, j };
----
TranslationUnit
    entities:
        - Declaration
            type: Enum
                name: "e"
                members:
                    - Enumerator
                        name: "i"
        - Declaration
            type: Enum
                name: "e"
                members:
                    - Enumerator
                        name: "i"
                    - Enumerator
                        name: "j"
EOS
  end

  def test_enumerator
    check <<EOS
enum e { i   };
enum e { i=0 };
----
TranslationUnit
    entities:
        - Declaration
            type: Enum
                name: "e"
                members:
                    - Enumerator
                        name: "i"
        - Declaration
            type: Enum
                name: "e"
                members:
                    - Enumerator
                        name: "i"
                        val: IntLiteral
                            val: 0
EOS
  end

  def test_type_qualifier
    check <<EOS
const    int;
restrict int;
volatile int;
----
TranslationUnit
    entities:
        - Declaration
            type: Int (const)
        - Declaration
            type: Int (restrict)
        - Declaration
            type: Int (volatile)
EOS
  end

  def test_function_specifier
    check <<EOS
inline int f();
----
TranslationUnit
    entities:
        - Declaration (inline)
            type: Int
            declarators:
                - Declarator
                      indirect_type: Function
                      name: "f"
EOS
  end

  def test_declarator
    check <<EOS
int *p;
int *const restrict volatile p;
int  i, *volatile restrict const *p[];
int *i, *const (*restrict (*volatile p)[])();
----
TranslationUnit
    entities:
        - Declaration
            type: Int
            declarators:
                - Declarator
                    indirect_type: Pointer
                    name: "p"
        - Declaration
            type: Int
            declarators:
                - Declarator
                    indirect_type: Pointer (const restrict volatile)
                    name: "p"
        - Declaration
            type: Int
            declarators:
                - Declarator
                    name: "i"
                - Declarator
                    indirect_type: Array
                        type: Pointer
                            type: Pointer (const restrict volatile)
                    name: "p"
        - Declaration
            type: Int
            declarators:
                - Declarator
                    indirect_type: Pointer
                    name: "i"
                - Declarator
                    indirect_type: Pointer (volatile)
                        type: Array
                            type: Pointer (restrict)
                                type: Function
                                    type: Pointer (const)
                    name: "p"
EOS
  end

  def test_direct_declarator
    ## TODO
  end

  def test_pointer
    check <<EOS
int *const p;
int *      p;
int *const *p;
int *      *p;
----
TranslationUnit
    entities:
        - Declaration
            type: Int
            declarators:
                - Declarator
                    indirect_type: Pointer (const)
                    name: "p"
        - Declaration
            type: Int
            declarators:
                - Declarator
                    indirect_type: Pointer
                    name: "p"
        - Declaration
            type: Int
            declarators:
                - Declarator
                    indirect_type: Pointer
                        type: Pointer (const)
                    name: "p"
        - Declaration
            type: Int
            declarators:
                - Declarator
                    indirect_type: Pointer
                        type: Pointer
                    name: "p"
EOS
  end

  def test_type_qualifier_list
    check <<EOS
int *const p;
int *const restrict p;
----
TranslationUnit
    entities:
        - Declaration
            type: Int
            declarators:
                - Declarator
                    indirect_type: Pointer (const)
                    name: "p"
        - Declaration
            type: Int
            declarators:
                - Declarator
                    indirect_type: Pointer (const restrict)
                    name: "p"
EOS
  end

  def test_parameter_type_list
    check <<EOS
void f(int i) {}
void f(int i, ...) {}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
                params:
                    - Parameter
                        type: Int
                        name: "i"
            name: "f"
        - FunctionDef
            type: Function (var_args)
                type: Void
                params:
                    - Parameter
                        type: Int
                        name: "i"
            name: "f"
EOS
  end

  def test_parameter_list
    check <<EOS
void f(int i) {}
void f(int i, int j) {}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
                params:
                    - Parameter
                        type: Int
                        name: "i"
            name: "f"
        - FunctionDef
            type: Function
                type: Void
                params:
                    - Parameter
                        type: Int
                        name: "i"
                    - Parameter
                        type: Int
                        name: "j"
            name: "f"
EOS
  end

  def test_parameter_declaration
    check <<EOS
void f(int i);
void f(int *);
void f(int  );
----
TranslationUnit
    entities:
        - Declaration
            type: Void
            declarators:
                - Declarator
                    indirect_type: Function
                        params:
                            - Parameter
                                type: Int
                                name: "i"
                    name: "f"
        - Declaration
            type: Void
            declarators:
                - Declarator
                    indirect_type: Function
                        params:
                            - Parameter
                                type: Pointer
                                    type: Int
                    name: "f"
        - Declaration
            type: Void
            declarators:
                - Declarator
                    indirect_type: Function
                        params:
                            - Parameter
                                type: Int
                    name: "f"
EOS
  end

  def test_identifier_list
    check <<EOS
void f(i);
void f(i, j);
----
TranslationUnit
    entities:
        - Declaration
            type: Void
            declarators:
                - Declarator
                    indirect_type: Function
                        params:
                            - Parameter
                                name: "i"
                    name: "f"
        - Declaration
            type: Void
            declarators:
                - Declarator
                    indirect_type: Function
                        params:
                            - Parameter
                                name: "i"
                            - Parameter
                                name: "j"
                    name: "f"
EOS
  end

  def test_type_name
    check <<EOS
void f() {
    sizeof(int *);
    sizeof(int  );
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: Sizeof
                            expr: Pointer
                                type: Int
                    - ExpressionStatement
                        expr: Sizeof
                            expr: Int
EOS
  end

  def test_abstract_declarator
    check <<EOS
void f(int *  );
void f(int *[]);
void f(int  []);
----
TranslationUnit
    entities:
        - Declaration
            type: Void
            declarators:
                - Declarator
                    indirect_type: Function
                        params:
                            - Parameter
                                type: Pointer
                                    type: Int
                    name: "f"
        - Declaration
            type: Void
            declarators:
                - Declarator
                    indirect_type: Function
                        params:
                            - Parameter
                                type: Array
                                    type: Pointer
                                        type: Int
                    name: "f"
        - Declaration
            type: Void
            declarators:
                - Declarator
                    indirect_type: Function
                        params:
                            - Parameter
                                type: Array
                                    type: Int
                    name: "f"
EOS
  end

  def test_direct_abstract_declarator
    ## TODO
  end

  def test_typedef_name
    check <<EOS
typedef int I;
I;
----
TranslationUnit
    entities:
        - Declaration
            storage: typedef
            type: Int
            declarators:
                - Declarator
                    name: "I"
        - Declaration
            type: CustomType
                name: "I"
EOS
  end

  def test_initializer
    check <<EOS
int x =  1  ;
int x = {1 };
int x = {1,};
----
TranslationUnit
    entities:
        - Declaration
            type: Int
            declarators:
                - Declarator
                    name: "x"
                    init: IntLiteral
                        val: 1
        - Declaration
            type: Int
            declarators:
                - Declarator
                    name: "x"
                    init: CompoundLiteral
                        member_inits:
                            - MemberInit
                                init: IntLiteral
                                    val: 1
        - Declaration
            type: Int
            declarators:
                - Declarator
                    name: "x"
                    init: CompoundLiteral
                        member_inits:
                            - MemberInit
                                init: IntLiteral
                                    val: 1
EOS
  end

  def test_initializer_list
    check <<EOS
int x = {.x = 1};
int x = {     1};
int x = {1, .x = 1};
int x = {1,      1};
----
TranslationUnit
    entities:
        - Declaration
            type: Int
            declarators:
                - Declarator
                    name: "x"
                    init: CompoundLiteral
                        member_inits:
                            - MemberInit
                                member:
                                    - Member
                                        name: "x"
                                init: IntLiteral
                                    val: 1
        - Declaration
            type: Int
            declarators:
                - Declarator
                    name: "x"
                    init: CompoundLiteral
                        member_inits:
                            - MemberInit
                                init: IntLiteral
                                    val: 1
        - Declaration
            type: Int
            declarators:
                - Declarator
                    name: "x"
                    init: CompoundLiteral
                        member_inits:
                            - MemberInit
                                init: IntLiteral
                                    val: 1
                            - MemberInit
                                member:
                                    - Member
                                        name: "x"
                                init: IntLiteral
                                    val: 1
        - Declaration
            type: Int
            declarators:
                - Declarator
                    name: "x"
                    init: CompoundLiteral
                        member_inits:
                            - MemberInit
                                init: IntLiteral
                                    val: 1
                            - MemberInit
                                init: IntLiteral
                                    val: 1
EOS
  end

  def test_designation
    check <<EOS
int x = {.x = 1};
----
TranslationUnit
    entities:
        - Declaration
            type: Int
            declarators:
                - Declarator
                    name: "x"
                    init: CompoundLiteral
                        member_inits:
                            - MemberInit
                                member:
                                    - Member
                                        name: "x"
                                init: IntLiteral
                                    val: 1
EOS
  end

  def test_designator_list
    check <<EOS
int x = {.x = 1};
int x = {.x .y = 1};
----
TranslationUnit
    entities:
        - Declaration
            type: Int
            declarators:
                - Declarator
                    name: "x"
                    init: CompoundLiteral
                        member_inits:
                            - MemberInit
                                member:
                                    - Member
                                        name: "x"
                                init: IntLiteral
                                    val: 1
        - Declaration
            type: Int
            declarators:
                - Declarator
                    name: "x"
                    init: CompoundLiteral
                        member_inits:
                            - MemberInit
                                member:
                                    - Member
                                        name: "x"
                                    - Member
                                        name: "y"
                                init: IntLiteral
                                    val: 1
EOS
  end

  def test_designator
    check <<EOS
int x = {.x  = 1};
int x = {[0] = 1};
----
TranslationUnit
    entities:
        - Declaration
            type: Int
            declarators:
                - Declarator
                    name: "x"
                    init: CompoundLiteral
                        member_inits:
                            - MemberInit
                                member:
                                    - Member
                                        name: "x"
                                init: IntLiteral
                                    val: 1
        - Declaration
            type: Int
            declarators:
                - Declarator
                    name: "x"
                    init: CompoundLiteral
                        member_inits:
                            - MemberInit
                                member:
                                    - IntLiteral
                                        val: 0
                                init: IntLiteral
                                    val: 1
EOS
  end

  def test_primary_expression
    check <<EOS
void f() {
    x;
    1;
    "";
    (1);
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: Variable
                            name: "x"
                    - ExpressionStatement
                        expr: IntLiteral
                            val: 1
                    - ExpressionStatement
                        expr: StringLiteral
                            val: ""
                    - ExpressionStatement
                        expr: IntLiteral
                            val: 1
EOS
  end

  def test_postfix_expression
    check <<EOS
void f() {
    x;
    x[1];
    x(1);
    x();
    x.a;
    x->a;
    x++;
    x--;
    (int){1};
    (int){1,};
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: Variable
                            name: "x"
                    - ExpressionStatement
                        expr: Index
                            expr: Variable
                                name: "x"
                            index: IntLiteral
                                val: 1
                    - ExpressionStatement
                        expr: Call
                            expr: Variable
                                name: "x"
                            args:
                                - IntLiteral
                                    val: 1
                    - ExpressionStatement
                        expr: Call
                            expr: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: Dot
                            expr: Variable
                                name: "x"
                            member: Member
                                name: "a"
                    - ExpressionStatement
                        expr: Arrow
                            expr: Variable
                                name: "x"
                            member: Member
                                name: "a"
                    - ExpressionStatement
                        expr: PostInc
                            expr: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: PostDec
                            expr: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: CompoundLiteral
                            type: Int
                            member_inits:
                                - MemberInit
                                    init: IntLiteral
                                        val: 1
                    - ExpressionStatement
                        expr: CompoundLiteral
                            type: Int
                            member_inits:
                                - MemberInit
                                    init: IntLiteral
                                        val: 1
EOS
  end

  def test_argument_expression_list
    check <<EOS
void f() {
    x(1);
    x(int);
    x(1, int);
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: Call
                            expr: Variable
                                name: "x"
                            args:
                                - IntLiteral
                                    val: 1
                    - ExpressionStatement
                        expr: Call
                            expr: Variable
                                name: "x"
                            args:
                                - Int
                    - ExpressionStatement
                        expr: Call
                            expr: Variable
                                name: "x"
                            args:
                                - IntLiteral
                                    val: 1
                                - Int
EOS
  end

  def test_argument_expression
    check <<EOS
void f() {
    x(a = 1);
    x(int*);
    x(const struct s[]);
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: Call
                            expr: Variable
                                name: "x"
                            args:
                                - Assign
                                    lval: Variable
                                        name: "a"
                                    rval: IntLiteral
                                        val: 1
                    - ExpressionStatement
                        expr: Call
                            expr: Variable
                                name: "x"
                            args:
                                - Pointer
                                    type: Int
                    - ExpressionStatement
                        expr: Call
                            expr: Variable
                                name: "x"
                            args:
                                - Array
                                    type: Struct (const)
                                        name: "s"
EOS
  end

  def test_unary_expression
    check <<EOS
void f() {
    x;
    ++x;
    --x;
    &x;
    sizeof x;
    sizeof(int);
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: Variable
                            name: "x"
                    - ExpressionStatement
                        expr: PreInc
                            expr: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: PreDec
                            expr: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: Address
                            expr: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: Sizeof
                            expr: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: Sizeof
                            expr: Int
EOS
  end

  def test_unary_operator
    check <<EOS
void f() {
    &x;
    *x;
    +x;
    -x;
    ~x;
    !x;
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: Address
                            expr: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: Dereference
                            expr: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: Positive
                            expr: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: Negative
                            expr: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: BitNot
                            expr: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: Not
                            expr: Variable
                                name: "x"
EOS
  end

  def test_cast_expression
    check <<EOS
void f() {
    x;
    (int)x;
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: Variable
                            name: "x"
                    - ExpressionStatement
                        expr: Cast
                            type: Int
                            expr: Variable
                                name: "x"
EOS
  end

  def test_multiplicative_expression
    check <<EOS
void f() {
    x;
    x * x;
    x / x;
    x % x;
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: Variable
                            name: "x"
                    - ExpressionStatement
                        expr: Multiply
                            expr1: Variable
                                name: "x"
                            expr2: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: Divide
                            expr1: Variable
                                name: "x"
                            expr2: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: Mod
                            expr1: Variable
                                name: "x"
                            expr2: Variable
                                name: "x"
EOS
  end

  def test_additive_expression
    check <<EOS
void f() {
    x;
    x + x;
    x - x;
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: Variable
                            name: "x"
                    - ExpressionStatement
                        expr: Add
                            expr1: Variable
                                name: "x"
                            expr2: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: Subtract
                            expr1: Variable
                                name: "x"
                            expr2: Variable
                                name: "x"
EOS
  end

  def test_shift_expression
    check <<EOS
void f() {
    x;
    x << x;
    x >> x;
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: Variable
                            name: "x"
                    - ExpressionStatement
                        expr: ShiftLeft
                            expr1: Variable
                                name: "x"
                            expr2: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: ShiftRight
                            expr1: Variable
                                name: "x"
                            expr2: Variable
                                name: "x"
EOS
  end

  def test_relational_expression
    check <<EOS
void f() {
    x;
    x <  x;
    x >  x;
    x <= x;
    x >= x;
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: Variable
                            name: "x"
                    - ExpressionStatement
                        expr: Less
                            expr1: Variable
                                name: "x"
                            expr2: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: More
                            expr1: Variable
                                name: "x"
                            expr2: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: LessOrEqual
                            expr1: Variable
                                name: "x"
                            expr2: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: MoreOrEqual
                            expr1: Variable
                                name: "x"
                            expr2: Variable
                                name: "x"
EOS
  end

  def test_equality_expression
    check <<EOS
void f() {
    x;
    x == x;
    x != x;
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: Variable
                            name: "x"
                    - ExpressionStatement
                        expr: Equal
                            expr1: Variable
                                name: "x"
                            expr2: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: NotEqual
                            expr1: Variable
                                name: "x"
                            expr2: Variable
                                name: "x"
EOS
  end

  def test_and_expression
    check <<EOS
void f() {
    x;
    x & x;
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: Variable
                            name: "x"
                    - ExpressionStatement
                        expr: BitAnd
                            expr1: Variable
                                name: "x"
                            expr2: Variable
                                name: "x"
EOS
  end

  def test_exclusive_or_expression
    check <<EOS
void f() {
    x;
    x ^ x;
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: Variable
                            name: "x"
                    - ExpressionStatement
                        expr: BitXor
                            expr1: Variable
                                name: "x"
                            expr2: Variable
                                name: "x"
EOS
  end

  def test_inclusive_or_expression
    check <<EOS
void f() {
    x;
    x | x;
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: Variable
                            name: "x"
                    - ExpressionStatement
                        expr: BitOr
                            expr1: Variable
                                name: "x"
                            expr2: Variable
                                name: "x"
EOS
  end

  def test_logical_and_expression
    check <<EOS
void f() {
    x;
    x && x;
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: Variable
                            name: "x"
                    - ExpressionStatement
                        expr: And
                            expr1: Variable
                                name: "x"
                            expr2: Variable
                                name: "x"
EOS
  end

  def test_logical_or_expression
    check <<EOS
void f() {
    x;
    x || x;
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: Variable
                            name: "x"
                    - ExpressionStatement
                        expr: Or
                            expr1: Variable
                                name: "x"
                            expr2: Variable
                                name: "x"
EOS
  end

  def test_conditional_expression
    check <<EOS
void f() {
    x;
    x ? x : x;
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: Variable
                            name: "x"
                    - ExpressionStatement
                        expr: Conditional
                            cond: Variable
                                name: "x"
                            then: Variable
                                name: "x"
                            else: Variable
                                name: "x"
EOS
  end

  def test_assignment_expression
    check <<EOS
void f() {
    x;
    x = x;
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: Variable
                            name: "x"
                    - ExpressionStatement
                        expr: Assign
                            lval: Variable
                                name: "x"
                            rval: Variable
                                name: "x"
EOS
  end

  def test_assignment_operator
    check <<EOS
void f() {
    x   = x;
    x  *= x;
    x  /= x;
    x  %= x;
    x  += x;
    x  -= x;
    x <<= x;
    x >>= x;
    x  &= x;
    x  ^= x;
    x  |= x;
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: Assign
                            lval: Variable
                                name: "x"
                            rval: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: MultiplyAssign
                            lval: Variable
                                name: "x"
                            rval: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: DivideAssign
                            lval: Variable
                                name: "x"
                            rval: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: ModAssign
                            lval: Variable
                                name: "x"
                            rval: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: AddAssign
                            lval: Variable
                                name: "x"
                            rval: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: SubtractAssign
                            lval: Variable
                                name: "x"
                            rval: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: ShiftLeftAssign
                            lval: Variable
                                name: "x"
                            rval: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: ShiftRightAssign
                            lval: Variable
                                name: "x"
                            rval: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: BitAndAssign
                            lval: Variable
                                name: "x"
                            rval: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: BitXorAssign
                            lval: Variable
                                name: "x"
                            rval: Variable
                                name: "x"
                    - ExpressionStatement
                        expr: BitOrAssign
                            lval: Variable
                                name: "x"
                            rval: Variable
                                name: "x"
EOS
  end

  def test_expression
    check <<EOS
void f() {
    a;
    a, b;
    a, b, c;
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: Variable
                            name: "a"
                    - ExpressionStatement
                        expr: Comma
                            exprs:
                                - Variable
                                    name: "a"
                                - Variable
                                    name: "b"
                    - ExpressionStatement
                        expr: Comma
                            exprs:
                                - Variable
                                    name: "a"
                                - Variable
                                    name: "b"
                                - Variable
                                    name: "c"
EOS
  end

  def test_constant_expression
    check <<EOS
void f() {
    1;
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: IntLiteral
                            val: 1
EOS
  end

  def test_identifier
    check <<EOS
void f() {
    _abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890;
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: Variable
                            name: "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
EOS
  end

  def test_constant
    check <<EOS
void f() {
    1;
    1.0;
    'a';
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: IntLiteral
                            val: 1
                    - ExpressionStatement
                        expr: FloatLiteral
                            val: 1.0
                    - ExpressionStatement
                        expr: CharLiteral
                            val: "a"
EOS
  end

  def test_enumeration_constant
    check <<EOS
void f() {
    a;
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: Variable
                            name: "a"
EOS
  end

  def test_string_literal
    check <<EOS
void f() {
    "";
}
----
TranslationUnit
    entities:
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: StringLiteral
                            val: ""
EOS
  end
end
