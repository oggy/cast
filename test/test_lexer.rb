######################################################################
#
# Lexer routine tests.  We only test nontrivial tokens, as things like
# operators are exercised sufficiently in the parser tests
# (test_parser.rb).
#
######################################################################

class LexerTest < Test::Unit::TestCase
  def check(s)
    check_ast(s){|inp| C::Parser.new.parse(inp)}
  end

  def test_id_and_typename
    check <<EOS
typedef int Mytype;
void f() {
  mytype * a;
  Mytype * a;
  _1234, _a1234, _1234L;
}
----
TranslationUnit
    entities:
        - Declaration
            storage: typedef
            type: Int
            declarators:
                - Declarator
                    name: "Mytype"
        - FunctionDef
            type: Function
                type: Void
            name: "f"
            def: Block
                stmts:
                    - ExpressionStatement
                        expr: Multiply
                            expr1: Variable
                                name: "mytype"
                            expr2: Variable
                                name: "a"
                    - Declaration
                        type: CustomType
                            name: "Mytype"
                        declarators:
                            - Declarator
                                indirect_type: Pointer
                                name: "a"
                    - ExpressionStatement
                        expr: Comma
                            exprs:
                                - Variable
                                    name: "_1234"
                                - Variable
                                    name: "_a1234"
                                - Variable
                                    name: "_1234L"
EOS
  end
  def test_int_literal
    check <<EOS
void f() {
  0, 00, 000, 0x0, 0x00;
  1234, 1234l, 1234ll;
  01234u, 01234ul, 01234ull;
  0x1234U, 0x1234L, 0x1234ULL;
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
                        expr: Comma
                            exprs:
                                - IntLiteral
                                    val: 0
                                - IntLiteral
                                    format: oct
                                    val: 0
                                - IntLiteral
                                    format: oct
                                    val: 0
                                - IntLiteral
                                    format: hex
                                    val: 0
                                - IntLiteral
                                    format: hex
                                    val: 0
                    - ExpressionStatement
                        expr: Comma
                            exprs:
                                - IntLiteral
                                    val: 1234
                                - IntLiteral
                                    val: 1234
                                    suffix: "l"
                                - IntLiteral
                                    val: 1234
                                    suffix: "ll"
                    - ExpressionStatement
                        expr: Comma
                            exprs:
                                - IntLiteral
                                    format: oct
                                    val: 668
                                    suffix: "u"
                                - IntLiteral
                                    format: oct
                                    val: 668
                                    suffix: "ul"
                                - IntLiteral
                                    format: oct
                                    val: 668
                                    suffix: "ull"
                    - ExpressionStatement
                        expr: Comma
                            exprs:
                                - IntLiteral
                                    format: hex
                                    val: 4660
                                    suffix: "U"
                                - IntLiteral
                                    format: hex
                                    val: 4660
                                    suffix: "L"
                                - IntLiteral
                                    format: hex
                                    val: 4660
                                    suffix: "ULL"
EOS
    assert_raise(C::ParseError){C::Parser.new.parse('void f() {12lll;}')}
    assert_raise(C::ParseError){C::Parser.new.parse('void f() {12ulL;}')}
    assert_raise(C::ParseError){C::Parser.new.parse('void f() {12lul;}')}
    assert_raise(C::ParseError){C::Parser.new.parse('void f() {123_4;}')}
  end
  def test_float_literal
    check <<EOS
void f() {
  123e4, 123E-4;
  123.4e10, .123E-4;
  123.4e5, 123.E-10;

  0xabp2, 0xabcP-10;
  0xabc.dp3, 0xabcP-11;
  0xabc.dp4, 0xabc.P-12;
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
                        expr: Comma
                            exprs:
                                - FloatLiteral
                                    val: 1230000.0
                                - FloatLiteral
                                    val: 0.0123
                    - ExpressionStatement
                        expr: Comma
                            exprs:
                                - FloatLiteral
                                    val: 1234000000000.0
                                - FloatLiteral
                                    val: 1.23e-05
                    - ExpressionStatement
                        expr: Comma
                            exprs:
                                - FloatLiteral
                                    val: 12340000.0
                                - FloatLiteral
                                    val: 1.23e-08
                    - ExpressionStatement
                        expr: Comma
                            exprs:
                                - FloatLiteral
                                    format: hex
                                    val: 684.0
                                - FloatLiteral
                                    format: hex
                                    val: 2.68359375
                    - ExpressionStatement
                        expr: Comma
                            exprs:
                                - FloatLiteral
                                    format: hex
                                    val: 21990.5
                                - FloatLiteral
                                    format: hex
                                    val: 1.341796875
                    - ExpressionStatement
                        expr: Comma
                            exprs:
                                - FloatLiteral
                                    format: hex
                                    val: 43981.0
                                - FloatLiteral
                                    format: hex
                                    val: 0.6708984375
EOS
    assert_raise(C::ParseError){C::Parser.new.parse('void f() {0x123.4pa;}')}
  end
  def test_string_literal
    check <<EOS
void f() {
  "ab", L"ab", x"ab";
  "a\\0b", L"a\\x0fb", "a\\vb";
  "a	b", L"a	b";
  "a
b", L"a
b";
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
                        expr: Comma
                            exprs:
                                - StringLiteral
                                    val: "ab"
                                - StringLiteral
                                    prefix: "L"
                                    val: "ab"
                                - StringLiteral
                                    prefix: "x"
                                    val: "ab"
                    - ExpressionStatement
                        expr: Comma
                            exprs:
                                - StringLiteral
                                    val: "a\\\\0b"
                                - StringLiteral
                                    prefix: "L"
                                    val: "a\\\\x0fb"
                                - StringLiteral
                                    val: "a\\\\vb"
                    - ExpressionStatement
                        expr: Comma
                            exprs:
                                - StringLiteral
                                    val: "a\\tb"
                                - StringLiteral
                                    prefix: "L"
                                    val: "a\\tb"
                    - ExpressionStatement
                        expr: Comma
                            exprs:
                                - StringLiteral
                                    val: "a\\nb"
                                - StringLiteral
                                    prefix: "L"
                                    val: "a\\nb"
EOS
    assert_raise(C::ParseError){C::Parser.new.parse('void f() {xy"ab";}')}
  end
  def test_char_literal
    check <<EOS
void f() {
  'a', L'a', x'a';
  '\\0', L'\\xf', '\\v';
  '	', L'
';
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
                        expr: Comma
                            exprs:
                                - CharLiteral
                                    val: "a"
                                - CharLiteral
                                    prefix: "L"
                                    val: "a"
                                - CharLiteral
                                    prefix: "x"
                                    val: "a"
                    - ExpressionStatement
                        expr: Comma
                            exprs:
                                - CharLiteral
                                    val: "\\\\0"
                                - CharLiteral
                                    prefix: "L"
                                    val: "\\\\xf"
                                - CharLiteral
                                    val: "\\\\v"
                    - ExpressionStatement
                        expr: Comma
                            exprs:
                                - CharLiteral
                                    val: "\\t"
                                - CharLiteral
                                    prefix: "L"
                                    val: "\\n"
EOS
    assert_raise(C::ParseError){C::Parser.new.parse("void f() {xy'ab';}")}
  end
end
