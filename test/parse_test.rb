######################################################################
#
# Tests for the parse methods.
#
######################################################################

require 'test_helper'

class MatchTest < Test::Unit::TestCase
  def setup
    C.default_parser = C::Parser.new
  end
  def test_node_matches
    i = C::Int.new
    assert_same(true, i.match?(i))
    assert_same(true, i.match?('int'))

    l = C::IntLiteral.new(10)
    assert_same(true, l.match?(l))
    assert_same(true, l.match?(10))

    i = C::Int.new
    assert_same(false, i.match?('unsigned int'))
    assert_same(false, i.match?('long int'))
    assert_same(false, i.match?('no int here'))  ## shouldn't raise!

    l = C::IntLiteral.new(10)
    assert_same(false, i.match?(10.0))

    t = C::CustomType.new('T')
    #
    assert_same(false, t.match?('T'))
    #
    parser = C::Parser.new
    parser.type_names << 'T'
    assert_same(true, t.match?('T', parser))
    #
    assert_same(false, t.match?('T'))
    #
    C.default_parser.type_names << 'T'
    assert_same(true, t.match?('T'))
  end

  def test_nodelist_match
    list = C::NodeArray[]
    assert_same(true, list.match?(list))
    assert_same(true, list.match?([]))

    list = C::NodeArray[C::Int.new, C::IntLiteral.new(10)]
    list2 = C::NodeChain[C::Int.new, C::IntLiteral.new(10)]
    assert_same(true, list.match?(list))
    assert_same(true, list.match?(list2))
    assert_same(true, list.match?(['int', 10]))

    list = C::NodeArray[C::NodeArray[C::Int.new], C::NodeChain[]]
    list2 = C::NodeChain[C::NodeChain[C::Int.new], C::NodeArray[]]
    assert_same(true, list.match?(list))
    assert_same(true, list.match?(list2))
    assert_same(true, list.match?([['int'], []]))
    assert_same(false, list.match?([[], ['int']]))
    assert_same(false, list.match?(['int']))
    assert_same(false, list.match?([['int']]))

    t = C::NodeArray[C::CustomType.new('T')]
    #
    assert_same(false, t.match?(['T']))
    #
    parser = C::Parser.new
    parser.type_names << 'T'
    assert_same(true, t.match?(['T'], parser))
    #
    assert_same(false, t.match?(['T']))
    #
    C.default_parser.type_names << 'T'
    assert_same(true, t.match?(['T']))
  end
end

class ParseTests < Test::Unit::TestCase
  def check(klass, s)
    check_ast(s){|inp| klass.parse(inp)}
  end

  def test_translation_unit
    check C::TranslationUnit, <<EOS
int i;
void (*f)(void *);
----
TranslationUnit
    entities:
        - Declaration
            type: Int
            declarators:
                - Declarator
                    name: "i"
        - Declaration
            type: Void
            declarators:
                - Declarator
                    indirect_type: Pointer
                        type: Function
                            params:
                                - Parameter
                                    type: Pointer
                                        type: Void
                    name: "f"
EOS
    assert_raise(C::ParseError){C::TranslationUnit.parse('')}
  end

  def test_declaration
    check C::Declaration, <<EOS
int i;
----
Declaration
    type: Int
    declarators:
        - Declarator
            name: "i"
EOS
    check C::Declaration, <<EOS
int i, j;
----
Declaration
    type: Int
    declarators:
        - Declarator
            name: "i"
        - Declarator
            name: "j"
EOS
    assert_raise(C::ParseError){C::Declaration.parse('int i; int j;')}
    assert_raise(C::ParseError){C::Declaration.parse('int f() {}')}
    assert_raise(C::ParseError){C::Declaration.parse('')}
  end

  def test_parameter
    check C::Parameter, <<EOS
int i
----
Parameter
    type: Int
    name: "i"
EOS
    check C::Parameter, <<EOS
int
----
Parameter
    type: Int
EOS
    check C::Parameter, <<EOS
i
----
Parameter
    name: "i"
EOS
    check C::Parameter, <<EOS
void
----
Parameter
    type: Void
EOS
    assert_raise(C::ParseError){C::Parameter.parse('...')}
    assert_raise(C::ParseError){C::Parameter.parse(') {} void (')}
    assert_raise(C::ParseError){C::Parameter.parse('); void(')}
    assert_raise(C::ParseError){C::Parameter.parse('i,j')}
    assert_raise(C::ParseError){C::Parameter.parse('int,float')}
    assert_raise(C::ParseError){C::Parameter.parse('')}
  end

  def test_declarator
    check C::Declarator, <<EOS
x
----
Declarator
    name: "x"
EOS
    check C::Declarator, <<EOS
*x
----
Declarator
    indirect_type: Pointer
    name: "x"
EOS
    check C::Declarator, <<EOS
x[10]
----
Declarator
    indirect_type: Array
        length: IntLiteral
            val: 10
    name: "x"
EOS
    check C::Declarator, <<EOS
x : 2
----
Declarator
    name: "x"
    num_bits: IntLiteral
        val: 2
EOS
    check C::Declarator, <<EOS
x = 2
----
Declarator
    name: "x"
    init: IntLiteral
        val: 2
EOS
    check C::Declarator, <<EOS
*x(int argc, char **argv)
----
Declarator
    indirect_type: Function
        type: Pointer
        params:
            - Parameter
                type: Int
                name: "argc"
            - Parameter
                type: Pointer
                    type: Pointer
                        type: Char
                name: "argv"
    name: "x"
EOS
    assert_raise(C::ParseError){C::Declarator.parse('i:1;}; struct {int i')}
    assert_raise(C::ParseError){C::Declarator.parse('i:1; int j')}
    assert_raise(C::ParseError){C::Declarator.parse('i:1,j')}
    assert_raise(C::ParseError){C::Declarator.parse('f; int f;')}
    assert_raise(C::ParseError){C::Declarator.parse('i,j')}
    assert_raise(C::ParseError){C::Declarator.parse(';')}
    assert_raise(C::ParseError){C::Declarator.parse('')}
  end

  def test_function_def
    check C::FunctionDef, <<EOS
int f() {}
----
FunctionDef
    type: Function
        type: Int
    name: "f"
EOS
    check C::FunctionDef, <<EOS
void *f(void *) {}
----
FunctionDef
    type: Function
        type: Pointer
            type: Void
        params:
            - Parameter
                type: Pointer
                    type: Void
    name: "f"
EOS
    assert_raise(C::ParseError){C::FunctionDef.parse('void f(); void g();')}
    assert_raise(C::ParseError){C::FunctionDef.parse('int i;')}
    assert_raise(C::ParseError){C::FunctionDef.parse('void f();')}
    assert_raise(C::ParseError){C::FunctionDef.parse(';')}
    assert_raise(C::ParseError){C::FunctionDef.parse('')}
  end

  def test_enumerator
    check C::Enumerator, <<EOS
X
----
Enumerator
    name: "X"
EOS
    check C::Enumerator, <<EOS
X=10
----
Enumerator
    name: "X"
    val: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::Enumerator.parse('} enum {')}
    assert_raise(C::ParseError){C::Enumerator.parse('} f() {')}
    assert_raise(C::ParseError){C::Enumerator.parse('X, Y')}
    assert_raise(C::ParseError){C::Enumerator.parse('')}
  end

  def test_member_initializer
    check C::MemberInit, <<EOS
1
----
MemberInit
    init: IntLiteral
        val: 1
EOS
    check C::MemberInit, <<EOS
1,
----
MemberInit
    init: IntLiteral
        val: 1
EOS
    check C::MemberInit, <<EOS
i
----
MemberInit
    init: Variable
        name: "i"
EOS
    check C::MemberInit, <<EOS
.i = i
----
MemberInit
    member:
        - Member
            name: "i"
    init: Variable
        name: "i"
EOS
    check C::MemberInit, <<EOS
.i [5] = 10.0
----
MemberInit
    member:
        - Member
            name: "i"
        - IntLiteral
            val: 5
    init: FloatLiteral
        val: 10.0
EOS
    assert_raise(C::ParseError){C::MemberInit.parse('} int f() {')}
    assert_raise(C::ParseError){C::MemberInit.parse('}} f() {{')}
    assert_raise(C::ParseError){C::MemberInit.parse('1}; x = {1')}
    assert_raise(C::ParseError){C::MemberInit.parse('1}, y')}
    assert_raise(C::ParseError){C::MemberInit.parse('1, 2')}
    assert_raise(C::ParseError){C::MemberInit.parse('')}
  end

  def test_member
    check C::Member, <<EOS
x
----
Member
    name: "x"
EOS
    assert_raise(C::ParseError){C::Member.parse('a = 1};} int f() {struct s x = {a')}
    assert_raise(C::ParseError){C::Member.parse('a = 1}; struct s y = {.a')}
    assert_raise(C::ParseError){C::Member.parse('a = 1}, x = {.a')}
    assert_raise(C::ParseError){C::Member.parse('x = 1, y')}
    assert_raise(C::ParseError){C::Member.parse('1')}
    assert_raise(C::ParseError){C::Member.parse('a .b')}
  end

  def test_block
    check C::Block, <<EOS
{}
----
Block
EOS
    check C::Block, <<EOS
{{}}
----
Block
    stmts:
        - Block
EOS
    assert_raise(C::ParseError){C::Block.parse('} void f() {')}
    assert_raise(C::ParseError){C::Block.parse(';;')}
    assert_raise(C::ParseError){C::Block.parse('int i;')}
    assert_raise(C::ParseError){C::Block.parse(';')}
    assert_raise(C::ParseError){C::Block.parse('')}
  end

  def test_if
    check C::If, <<EOS
if (1) 10;
----
If
    cond: IntLiteral
        val: 1
    then: ExpressionStatement
        expr: IntLiteral
            val: 10
EOS
    check C::If, <<EOS
if (1) 10; else 20;
----
If
    cond: IntLiteral
        val: 1
    then: ExpressionStatement
        expr: IntLiteral
            val: 10
    else: ExpressionStatement
        expr: IntLiteral
            val: 20
EOS
    assert_raise(C::ParseError){C::If.parse('} void f() {')}
    assert_raise(C::ParseError){C::If.parse(';;')}
    assert_raise(C::ParseError){C::If.parse('int i;')}
    assert_raise(C::ParseError){C::If.parse(';')}
    assert_raise(C::ParseError){C::If.parse('')}
  end

  def test_switch
    check C::Switch, <<EOS
switch (x);
----
Switch
    cond: Variable
        name: "x"
    stmt: ExpressionStatement
EOS
    assert_raise(C::ParseError){C::Switch.parse('} void f() {')}
    assert_raise(C::ParseError){C::Switch.parse(';;')}
    assert_raise(C::ParseError){C::Switch.parse('int i;')}
    assert_raise(C::ParseError){C::Switch.parse(';')}
    assert_raise(C::ParseError){C::Switch.parse('')}
  end

  def test_while
    check C::While, <<EOS
while (1);
----
While
    cond: IntLiteral
        val: 1
    stmt: ExpressionStatement
EOS
    check C::While, <<EOS
do ; while (1);
----
While (do)
    cond: IntLiteral
        val: 1
    stmt: ExpressionStatement
EOS
    assert_raise(C::ParseError){C::While.parse('} void f() {')}
    assert_raise(C::ParseError){C::While.parse(';;')}
    assert_raise(C::ParseError){C::While.parse('int i;')}
    assert_raise(C::ParseError){C::While.parse(';')}
    assert_raise(C::ParseError){C::While.parse('')}
  end

  def test_for
    check C::For, <<EOS
for (;;);
----
For
    stmt: ExpressionStatement
EOS
    check C::For, <<EOS
for (int i; ; );
----
For
    init: Declaration
        type: Int
        declarators:
            - Declarator
                name: "i"
    stmt: ExpressionStatement
EOS
    assert_raise(C::ParseError){C::For.parse('} void f() {')}
    assert_raise(C::ParseError){C::For.parse(';;')}
    assert_raise(C::ParseError){C::For.parse('int i;')}
    assert_raise(C::ParseError){C::For.parse(';')}
    assert_raise(C::ParseError){C::For.parse('')}
  end

  def test_goto
    check C::Goto, <<EOS
goto x;
----
Goto
    target: "x"
EOS
    assert_raise(C::ParseError){C::Goto.parse('} void f() {')}
    assert_raise(C::ParseError){C::Goto.parse(';;')}
    assert_raise(C::ParseError){C::Goto.parse('int i;')}
    assert_raise(C::ParseError){C::Goto.parse(';')}
    assert_raise(C::ParseError){C::Goto.parse('')}
  end

  def test_continue
    check C::Continue, <<EOS
continue;
----
Continue
EOS
    assert_raise(C::ParseError){C::Continue.parse('} void f() {')}
    assert_raise(C::ParseError){C::Continue.parse(';;')}
    assert_raise(C::ParseError){C::Continue.parse('int i;')}
    assert_raise(C::ParseError){C::Continue.parse(';')}
    assert_raise(C::ParseError){C::Continue.parse('')}
  end

  def test_break
    check C::Break, <<EOS
break;
----
Break
EOS
    assert_raise(C::ParseError){C::Break.parse('} void f() {')}
    assert_raise(C::ParseError){C::Break.parse(';;')}
    assert_raise(C::ParseError){C::Break.parse('int i;')}
    assert_raise(C::ParseError){C::Break.parse(';')}
    assert_raise(C::ParseError){C::Break.parse('')}
  end

  def test_return
    check C::Return, <<EOS
return;
----
Return
EOS
    check C::Return, <<EOS
return 10;
----
Return
    expr: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::Return.parse('} void f() {')}
    assert_raise(C::ParseError){C::Return.parse(';;')}
    assert_raise(C::ParseError){C::Return.parse('int i;')}
    assert_raise(C::ParseError){C::Return.parse(';')}
    assert_raise(C::ParseError){C::Return.parse('')}
  end

  def test_expression_statement
    check C::ExpressionStatement, <<EOS
;
----
ExpressionStatement
EOS
    check C::ExpressionStatement, <<EOS
10;
----
ExpressionStatement
    expr: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::ExpressionStatement.parse('} void f() {')}
    assert_raise(C::ParseError){C::ExpressionStatement.parse(';;')}
    assert_raise(C::ParseError){C::ExpressionStatement.parse('int i;')}
    assert_raise(C::ParseError){C::ExpressionStatement.parse('return;')}
    assert_raise(C::ParseError){C::ExpressionStatement.parse('')}
  end

  def test_statement
    check C::Statement, <<EOS
{}
----
Block
EOS
    check C::Statement, <<EOS
if (1) 10; else 20;
----
If
    cond: IntLiteral
        val: 1
    then: ExpressionStatement
        expr: IntLiteral
            val: 10
    else: ExpressionStatement
        expr: IntLiteral
            val: 20
EOS
    check C::Statement, <<EOS
switch (x);
----
Switch
    cond: Variable
        name: "x"
    stmt: ExpressionStatement
EOS
    check C::Statement, <<EOS
while (1) ;
----
While
    cond: IntLiteral
        val: 1
    stmt: ExpressionStatement
EOS
    check C::Statement, <<EOS
do ; while (1);
----
While (do)
    cond: IntLiteral
        val: 1
    stmt: ExpressionStatement
EOS
    check C::Statement, <<EOS
for (;;) ;
----
For
    stmt: ExpressionStatement
EOS
    check C::Statement, <<EOS
goto x;
----
Goto
    target: "x"
EOS
    check C::Statement, <<EOS
continue;
----
Continue
EOS
    check C::Statement, <<EOS
break;
----
Break
EOS
    check C::Statement, <<EOS
return;
----
Return
EOS
    check C::Statement, <<EOS
;
----
ExpressionStatement
EOS
    assert_raise(C::ParseError){C::Statement.parse('} void f() {')}
    assert_raise(C::ParseError){C::Statement.parse(';;')}
    assert_raise(C::ParseError){C::Statement.parse('int i;')}
    assert_raise(C::ParseError){C::Statement.parse('')}
  end

  def test_plain_label
    check C::PlainLabel, <<EOS
x:
----
PlainLabel
    name: "x"
EOS
    assert_raise(C::ParseError){C::PlainLabel.parse('} void f() {')}
    assert_raise(C::ParseError){C::PlainLabel.parse(';')}
    assert_raise(C::ParseError){C::PlainLabel.parse('')}
    assert_raise(C::ParseError){C::PlainLabel.parse('x')}
    assert_raise(C::ParseError){C::PlainLabel.parse('case 1:')}
    assert_raise(C::ParseError){C::PlainLabel.parse('default:')}
  end

  def test_default
    check C::Default, <<EOS
default:
----
Default
EOS
    assert_raise(C::ParseError){C::Default.parse('} void f() {')}
    assert_raise(C::ParseError){C::Default.parse(';')}
    assert_raise(C::ParseError){C::Default.parse('')}
    assert_raise(C::ParseError){C::Default.parse('x')}
    assert_raise(C::ParseError){C::Default.parse('x:')}
    assert_raise(C::ParseError){C::Default.parse('case 1:')}
  end

  def test_case
    check C::Case, <<EOS
case 1:
----
Case
    expr: IntLiteral
        val: 1
EOS
    assert_raise(C::ParseError){C::Case.parse('} void f() {')}
    assert_raise(C::ParseError){C::Case.parse(';')}
    assert_raise(C::ParseError){C::Case.parse('')}
    assert_raise(C::ParseError){C::Case.parse('x:')}
    assert_raise(C::ParseError){C::Case.parse('default:')}
  end

  def test_label
    check C::Label, <<EOS
x:
----
PlainLabel
    name: "x"
EOS
    check C::Label, <<EOS
default:
----
Default
EOS
    check C::Label, <<EOS
case 1:
----
Case
    expr: IntLiteral
        val: 1
EOS
    assert_raise(C::ParseError){C::Label.parse('} void f() {')}
    assert_raise(C::ParseError){C::Label.parse(';')}
    assert_raise(C::ParseError){C::Label.parse('')}
    assert_raise(C::ParseError){C::Label.parse('x')}
  end

  def test_comma
    check C::Comma, <<EOS
++i, ++j
----
Comma
    exprs:
        - PreInc
            expr: Variable
                name: "i"
        - PreInc
            expr: Variable
                name: "j"
EOS
    check C::Comma, <<EOS
(++i, ++j)
----
Comma
    exprs:
        - PreInc
            expr: Variable
                name: "i"
        - PreInc
            expr: Variable
                name: "j"
EOS
    assert_raise(C::ParseError){C::Comma.parse('} void f() {')}
    assert_raise(C::ParseError){C::Comma.parse(';')}
    assert_raise(C::ParseError){C::Comma.parse('int i')}
    assert_raise(C::ParseError){C::Comma.parse('int')}
    assert_raise(C::ParseError){C::Comma.parse('if (0)')}
    assert_raise(C::ParseError){C::Comma.parse('switch (0)')}
    assert_raise(C::ParseError){C::Comma.parse('for (;;)')}
    assert_raise(C::ParseError){C::Comma.parse('goto')}
    assert_raise(C::ParseError){C::Comma.parse('return')}
  end

  def test_conditional
    check C::Conditional, <<EOS
1 ? 10 : 20
----
Conditional
    cond: IntLiteral
        val: 1
    then: IntLiteral
        val: 10
    else: IntLiteral
        val: 20
EOS
    assert_raise(C::ParseError){C::Conditional.parse('} void f() {')}
    assert_raise(C::ParseError){C::Conditional.parse(';')}
    assert_raise(C::ParseError){C::Conditional.parse('int i')}
    assert_raise(C::ParseError){C::Conditional.parse('int')}
    assert_raise(C::ParseError){C::Conditional.parse('if (0)')}
    assert_raise(C::ParseError){C::Conditional.parse('switch (0)')}
    assert_raise(C::ParseError){C::Conditional.parse('for (;;)')}
    assert_raise(C::ParseError){C::Conditional.parse('goto')}
    assert_raise(C::ParseError){C::Conditional.parse('return')}
  end

  def test_cast
    check C::Cast, <<EOS
(int)10.0
----
Cast
    type: Int
    expr: FloatLiteral
        val: 10.0
EOS
    assert_raise(C::ParseError){C::Cast.parse('} void f() {')}
    assert_raise(C::ParseError){C::Cast.parse(';')}
    assert_raise(C::ParseError){C::Cast.parse('int i')}
    assert_raise(C::ParseError){C::Cast.parse('int')}
    assert_raise(C::ParseError){C::Cast.parse('if (0)')}
    assert_raise(C::ParseError){C::Cast.parse('switch (0)')}
    assert_raise(C::ParseError){C::Cast.parse('for (;;)')}
    assert_raise(C::ParseError){C::Cast.parse('goto')}
    assert_raise(C::ParseError){C::Cast.parse('return')}
  end

  def test_address
    check C::Address, <<EOS
&x
----
Address
    expr: Variable
        name: "x"
EOS
    assert_raise(C::ParseError){C::Address.parse('} void f() {')}
    assert_raise(C::ParseError){C::Address.parse(';')}
    assert_raise(C::ParseError){C::Address.parse('int i')}
    assert_raise(C::ParseError){C::Address.parse('int')}
    assert_raise(C::ParseError){C::Address.parse('if (0)')}
    assert_raise(C::ParseError){C::Address.parse('switch (0)')}
    assert_raise(C::ParseError){C::Address.parse('for (;;)')}
    assert_raise(C::ParseError){C::Address.parse('goto')}
    assert_raise(C::ParseError){C::Address.parse('return')}
  end

  def test_dereference
    check C::Dereference, <<EOS
*x
----
Dereference
    expr: Variable
        name: "x"
EOS
    assert_raise(C::ParseError){C::Dereference.parse('} void f() {')}
    assert_raise(C::ParseError){C::Dereference.parse(';')}
    assert_raise(C::ParseError){C::Dereference.parse('int i')}
    assert_raise(C::ParseError){C::Dereference.parse('int')}
    assert_raise(C::ParseError){C::Dereference.parse('if (0)')}
    assert_raise(C::ParseError){C::Dereference.parse('switch (0)')}
    assert_raise(C::ParseError){C::Dereference.parse('for (;;)')}
    assert_raise(C::ParseError){C::Dereference.parse('goto')}
    assert_raise(C::ParseError){C::Dereference.parse('return')}
  end

  def test_sizeof
    check C::Sizeof, <<EOS
sizeof i
----
Sizeof
    expr: Variable
        name: "i"
EOS
    check C::Sizeof, <<EOS
sizeof(int)
----
Sizeof
    expr: Int
EOS
    assert_raise(C::ParseError){C::Sizeof.parse('} void f() {')}
    assert_raise(C::ParseError){C::Sizeof.parse(';')}
    assert_raise(C::ParseError){C::Sizeof.parse('int i')}
    assert_raise(C::ParseError){C::Sizeof.parse('int')}
    assert_raise(C::ParseError){C::Sizeof.parse('if (0)')}
    assert_raise(C::ParseError){C::Sizeof.parse('switch (0)')}
    assert_raise(C::ParseError){C::Sizeof.parse('for (;;)')}
    assert_raise(C::ParseError){C::Sizeof.parse('goto')}
    assert_raise(C::ParseError){C::Sizeof.parse('return')}
  end

  def test_index
    check C::Index, <<EOS
x[10][20]
----
Index
    expr: Index
        expr: Variable
            name: "x"
        index: IntLiteral
            val: 10
    index: IntLiteral
        val: 20
EOS
    assert_raise(C::ParseError){C::Index.parse('} void f() {')}
    assert_raise(C::ParseError){C::Index.parse(';')}
    assert_raise(C::ParseError){C::Index.parse('int i')}
    assert_raise(C::ParseError){C::Index.parse('int')}
    assert_raise(C::ParseError){C::Index.parse('if (0)')}
    assert_raise(C::ParseError){C::Index.parse('switch (0)')}
    assert_raise(C::ParseError){C::Index.parse('for (;;)')}
    assert_raise(C::ParseError){C::Index.parse('goto')}
    assert_raise(C::ParseError){C::Index.parse('return')}
  end

  def test_call
    check C::Call, <<EOS
x(10, 20)()
----
Call
    expr: Call
        expr: Variable
            name: "x"
        args:
            - IntLiteral
                val: 10
            - IntLiteral
                val: 20
EOS
    assert_raise(C::ParseError){C::Call.parse('} void f() {')}
    assert_raise(C::ParseError){C::Call.parse(';')}
    assert_raise(C::ParseError){C::Call.parse('int i')}
    assert_raise(C::ParseError){C::Call.parse('int')}
    assert_raise(C::ParseError){C::Call.parse('if (0)')}
    assert_raise(C::ParseError){C::Call.parse('switch (0)')}
    assert_raise(C::ParseError){C::Call.parse('for (;;)')}
    assert_raise(C::ParseError){C::Call.parse('goto')}
    assert_raise(C::ParseError){C::Call.parse('return')}
  end

  def test_arrow
    check C::Arrow, <<EOS
x->y
----
Arrow
    expr: Variable
        name: "x"
    member: Member
        name: "y"
EOS
    assert_raise(C::ParseError){C::Arrow.parse('} void f() {')}
    assert_raise(C::ParseError){C::Arrow.parse(';')}
    assert_raise(C::ParseError){C::Arrow.parse('int i')}
    assert_raise(C::ParseError){C::Arrow.parse('int')}
    assert_raise(C::ParseError){C::Arrow.parse('if (0)')}
    assert_raise(C::ParseError){C::Arrow.parse('switch (0)')}
    assert_raise(C::ParseError){C::Arrow.parse('for (;;)')}
    assert_raise(C::ParseError){C::Arrow.parse('goto')}
    assert_raise(C::ParseError){C::Arrow.parse('return')}
  end

  def test_dot
    check C::Dot, <<EOS
x.y
----
Dot
    expr: Variable
        name: "x"
    member: Member
        name: "y"
EOS
    assert_raise(C::ParseError){C::Dot.parse('} void f() {')}
    assert_raise(C::ParseError){C::Dot.parse(';')}
    assert_raise(C::ParseError){C::Dot.parse('int i')}
    assert_raise(C::ParseError){C::Dot.parse('int')}
    assert_raise(C::ParseError){C::Dot.parse('if (0)')}
    assert_raise(C::ParseError){C::Dot.parse('switch (0)')}
    assert_raise(C::ParseError){C::Dot.parse('for (;;)')}
    assert_raise(C::ParseError){C::Dot.parse('goto')}
    assert_raise(C::ParseError){C::Dot.parse('return')}
  end

  def test_positive
    check C::Positive, <<EOS
+1
----
Positive
    expr: IntLiteral
        val: 1
EOS
    assert_raise(C::ParseError){C::Positive.parse('} void f() {')}
    assert_raise(C::ParseError){C::Positive.parse(';')}
    assert_raise(C::ParseError){C::Positive.parse('int i')}
    assert_raise(C::ParseError){C::Positive.parse('int')}
    assert_raise(C::ParseError){C::Positive.parse('if (0)')}
    assert_raise(C::ParseError){C::Positive.parse('switch (0)')}
    assert_raise(C::ParseError){C::Positive.parse('for (;;)')}
    assert_raise(C::ParseError){C::Positive.parse('goto')}
    assert_raise(C::ParseError){C::Positive.parse('return')}
  end

  def test_negative
    check C::Negative, <<EOS
-1
----
Negative
    expr: IntLiteral
        val: 1
EOS
    assert_raise(C::ParseError){C::Negative.parse('} void f() {')}
    assert_raise(C::ParseError){C::Negative.parse(';')}
    assert_raise(C::ParseError){C::Negative.parse('int i')}
    assert_raise(C::ParseError){C::Negative.parse('int')}
    assert_raise(C::ParseError){C::Negative.parse('if (0)')}
    assert_raise(C::ParseError){C::Negative.parse('switch (0)')}
    assert_raise(C::ParseError){C::Negative.parse('for (;;)')}
    assert_raise(C::ParseError){C::Negative.parse('goto')}
    assert_raise(C::ParseError){C::Negative.parse('return')}
  end

  def test_add
    check C::Add, <<EOS
1 + 10
----
Add
    expr1: IntLiteral
        val: 1
    expr2: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::Add.parse('} void f() {')}
    assert_raise(C::ParseError){C::Add.parse(';')}
    assert_raise(C::ParseError){C::Add.parse('int i')}
    assert_raise(C::ParseError){C::Add.parse('int')}
    assert_raise(C::ParseError){C::Add.parse('if (0)')}
    assert_raise(C::ParseError){C::Add.parse('switch (0)')}
    assert_raise(C::ParseError){C::Add.parse('for (;;)')}
    assert_raise(C::ParseError){C::Add.parse('goto')}
    assert_raise(C::ParseError){C::Add.parse('return')}
  end

  def test_subtract
    check C::Subtract, <<EOS
1 - 10
----
Subtract
    expr1: IntLiteral
        val: 1
    expr2: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::Subtract.parse('} void f() {')}
    assert_raise(C::ParseError){C::Subtract.parse(';')}
    assert_raise(C::ParseError){C::Subtract.parse('int i')}
    assert_raise(C::ParseError){C::Subtract.parse('int')}
    assert_raise(C::ParseError){C::Subtract.parse('if (0)')}
    assert_raise(C::ParseError){C::Subtract.parse('switch (0)')}
    assert_raise(C::ParseError){C::Subtract.parse('for (;;)')}
    assert_raise(C::ParseError){C::Subtract.parse('goto')}
    assert_raise(C::ParseError){C::Subtract.parse('return')}
  end

  def test_multiply
    check C::Multiply, <<EOS
1 * 10
----
Multiply
    expr1: IntLiteral
        val: 1
    expr2: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::Multiply.parse('} void f() {')}
    assert_raise(C::ParseError){C::Multiply.parse(';')}
    assert_raise(C::ParseError){C::Multiply.parse('int i')}
    assert_raise(C::ParseError){C::Multiply.parse('int')}
    assert_raise(C::ParseError){C::Multiply.parse('if (0)')}
    assert_raise(C::ParseError){C::Multiply.parse('switch (0)')}
    assert_raise(C::ParseError){C::Multiply.parse('for (;;)')}
    assert_raise(C::ParseError){C::Multiply.parse('goto')}
    assert_raise(C::ParseError){C::Multiply.parse('return')}
  end

  def test_divide
    check C::Divide, <<EOS
1 / 10
----
Divide
    expr1: IntLiteral
        val: 1
    expr2: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::Divide.parse('} void f() {')}
    assert_raise(C::ParseError){C::Divide.parse(';')}
    assert_raise(C::ParseError){C::Divide.parse('int i')}
    assert_raise(C::ParseError){C::Divide.parse('int')}
    assert_raise(C::ParseError){C::Divide.parse('if (0)')}
    assert_raise(C::ParseError){C::Divide.parse('switch (0)')}
    assert_raise(C::ParseError){C::Divide.parse('for (;;)')}
    assert_raise(C::ParseError){C::Divide.parse('goto')}
    assert_raise(C::ParseError){C::Divide.parse('return')}
  end

  def test_mod
    check C::Mod, <<EOS
1 % 10
----
Mod
    expr1: IntLiteral
        val: 1
    expr2: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::Mod.parse('} void f() {')}
    assert_raise(C::ParseError){C::Mod.parse(';')}
    assert_raise(C::ParseError){C::Mod.parse('int i')}
    assert_raise(C::ParseError){C::Mod.parse('int')}
    assert_raise(C::ParseError){C::Mod.parse('if (0)')}
    assert_raise(C::ParseError){C::Mod.parse('switch (0)')}
    assert_raise(C::ParseError){C::Mod.parse('for (;;)')}
    assert_raise(C::ParseError){C::Mod.parse('goto')}
    assert_raise(C::ParseError){C::Mod.parse('return')}
  end

  def test_pre_inc
    check C::PreInc, <<EOS
++i
----
PreInc
    expr: Variable
        name: "i"
EOS
    assert_raise(C::ParseError){C::PreInc.parse('} void f() {')}
    assert_raise(C::ParseError){C::PreInc.parse(';')}
    assert_raise(C::ParseError){C::PreInc.parse('int i')}
    assert_raise(C::ParseError){C::PreInc.parse('int')}
    assert_raise(C::ParseError){C::PreInc.parse('if (0)')}
    assert_raise(C::ParseError){C::PreInc.parse('switch (0)')}
    assert_raise(C::ParseError){C::PreInc.parse('for (;;)')}
    assert_raise(C::ParseError){C::PreInc.parse('goto')}
    assert_raise(C::ParseError){C::PreInc.parse('return')}
  end

  def test_post_inc
    check C::PostInc, <<EOS
i++
----
PostInc
    expr: Variable
        name: "i"
EOS
    assert_raise(C::ParseError){C::PostInc.parse('} void f() {')}
    assert_raise(C::ParseError){C::PostInc.parse(';')}
    assert_raise(C::ParseError){C::PostInc.parse('int i')}
    assert_raise(C::ParseError){C::PostInc.parse('int')}
    assert_raise(C::ParseError){C::PostInc.parse('if (0)')}
    assert_raise(C::ParseError){C::PostInc.parse('switch (0)')}
    assert_raise(C::ParseError){C::PostInc.parse('for (;;)')}
    assert_raise(C::ParseError){C::PostInc.parse('goto')}
    assert_raise(C::ParseError){C::PostInc.parse('return')}
  end

  def test_pre_dec
    check C::PreDec, <<EOS
--i
----
PreDec
    expr: Variable
        name: "i"
EOS
    assert_raise(C::ParseError){C::PreDec.parse('} void f() {')}
    assert_raise(C::ParseError){C::PreDec.parse(';')}
    assert_raise(C::ParseError){C::PreDec.parse('int i')}
    assert_raise(C::ParseError){C::PreDec.parse('int')}
    assert_raise(C::ParseError){C::PreDec.parse('if (0)')}
    assert_raise(C::ParseError){C::PreDec.parse('switch (0)')}
    assert_raise(C::ParseError){C::PreDec.parse('for (;;)')}
    assert_raise(C::ParseError){C::PreDec.parse('goto')}
    assert_raise(C::ParseError){C::PreDec.parse('return')}
  end

  def test_post_dec
    check C::PostDec, <<EOS
i--
----
PostDec
    expr: Variable
        name: "i"
EOS
    assert_raise(C::ParseError){C::PostDec.parse('} void f() {')}
    assert_raise(C::ParseError){C::PostDec.parse(';')}
    assert_raise(C::ParseError){C::PostDec.parse('int i')}
    assert_raise(C::ParseError){C::PostDec.parse('int')}
    assert_raise(C::ParseError){C::PostDec.parse('if (0)')}
    assert_raise(C::ParseError){C::PostDec.parse('switch (0)')}
    assert_raise(C::ParseError){C::PostDec.parse('for (;;)')}
    assert_raise(C::ParseError){C::PostDec.parse('goto')}
    assert_raise(C::ParseError){C::PostDec.parse('return')}
  end

  def test_equal
    check C::Equal, <<EOS
1 == 10
----
Equal
    expr1: IntLiteral
        val: 1
    expr2: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::Equal.parse('} void f() {')}
    assert_raise(C::ParseError){C::Equal.parse(';')}
    assert_raise(C::ParseError){C::Equal.parse('int i')}
    assert_raise(C::ParseError){C::Equal.parse('int')}
    assert_raise(C::ParseError){C::Equal.parse('if (0)')}
    assert_raise(C::ParseError){C::Equal.parse('switch (0)')}
    assert_raise(C::ParseError){C::Equal.parse('for (;;)')}
    assert_raise(C::ParseError){C::Equal.parse('goto')}
    assert_raise(C::ParseError){C::Equal.parse('return')}
  end

  def test_not_equal
    check C::NotEqual, <<EOS
1 != 10
----
NotEqual
    expr1: IntLiteral
        val: 1
    expr2: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::NotEqual.parse('} void f() {')}
    assert_raise(C::ParseError){C::NotEqual.parse(';')}
    assert_raise(C::ParseError){C::NotEqual.parse('int i')}
    assert_raise(C::ParseError){C::NotEqual.parse('int')}
    assert_raise(C::ParseError){C::NotEqual.parse('if (0)')}
    assert_raise(C::ParseError){C::NotEqual.parse('switch (0)')}
    assert_raise(C::ParseError){C::NotEqual.parse('for (;;)')}
    assert_raise(C::ParseError){C::NotEqual.parse('goto')}
    assert_raise(C::ParseError){C::NotEqual.parse('return')}
  end

  def test_less
    check C::Less, <<EOS
1 < 10
----
Less
    expr1: IntLiteral
        val: 1
    expr2: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::Less.parse('} void f() {')}
    assert_raise(C::ParseError){C::Less.parse(';')}
    assert_raise(C::ParseError){C::Less.parse('int i')}
    assert_raise(C::ParseError){C::Less.parse('int')}
    assert_raise(C::ParseError){C::Less.parse('if (0)')}
    assert_raise(C::ParseError){C::Less.parse('switch (0)')}
    assert_raise(C::ParseError){C::Less.parse('for (;;)')}
    assert_raise(C::ParseError){C::Less.parse('goto')}
    assert_raise(C::ParseError){C::Less.parse('return')}
  end

  def test_more
    check C::More, <<EOS
1 > 10
----
More
    expr1: IntLiteral
        val: 1
    expr2: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::More.parse('} void f() {')}
    assert_raise(C::ParseError){C::More.parse(';')}
    assert_raise(C::ParseError){C::More.parse('int i')}
    assert_raise(C::ParseError){C::More.parse('int')}
    assert_raise(C::ParseError){C::More.parse('if (0)')}
    assert_raise(C::ParseError){C::More.parse('switch (0)')}
    assert_raise(C::ParseError){C::More.parse('for (;;)')}
    assert_raise(C::ParseError){C::More.parse('goto')}
    assert_raise(C::ParseError){C::More.parse('return')}
  end

  def test_less_or_equal
    check C::LessOrEqual, <<EOS
1 <= 10
----
LessOrEqual
    expr1: IntLiteral
        val: 1
    expr2: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::LessOrEqual.parse('} void f() {')}
    assert_raise(C::ParseError){C::LessOrEqual.parse(';')}
    assert_raise(C::ParseError){C::LessOrEqual.parse('int i')}
    assert_raise(C::ParseError){C::LessOrEqual.parse('int')}
    assert_raise(C::ParseError){C::LessOrEqual.parse('if (0)')}
    assert_raise(C::ParseError){C::LessOrEqual.parse('switch (0)')}
    assert_raise(C::ParseError){C::LessOrEqual.parse('for (;;)')}
    assert_raise(C::ParseError){C::LessOrEqual.parse('goto')}
    assert_raise(C::ParseError){C::LessOrEqual.parse('return')}
  end

  def test_more_or_equal
    check C::MoreOrEqual, <<EOS
1 >= 10
----
MoreOrEqual
    expr1: IntLiteral
        val: 1
    expr2: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::MoreOrEqual.parse('} void f() {')}
    assert_raise(C::ParseError){C::MoreOrEqual.parse(';')}
    assert_raise(C::ParseError){C::MoreOrEqual.parse('int i')}
    assert_raise(C::ParseError){C::MoreOrEqual.parse('int')}
    assert_raise(C::ParseError){C::MoreOrEqual.parse('if (0)')}
    assert_raise(C::ParseError){C::MoreOrEqual.parse('switch (0)')}
    assert_raise(C::ParseError){C::MoreOrEqual.parse('for (;;)')}
    assert_raise(C::ParseError){C::MoreOrEqual.parse('goto')}
    assert_raise(C::ParseError){C::MoreOrEqual.parse('return')}
  end

  def test_bit_and
    check C::BitAnd, <<EOS
1 & 10
----
BitAnd
    expr1: IntLiteral
        val: 1
    expr2: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::BitAnd.parse('} void f() {')}
    assert_raise(C::ParseError){C::BitAnd.parse(';')}
    assert_raise(C::ParseError){C::BitAnd.parse('int i')}
    assert_raise(C::ParseError){C::BitAnd.parse('int')}
    assert_raise(C::ParseError){C::BitAnd.parse('if (0)')}
    assert_raise(C::ParseError){C::BitAnd.parse('switch (0)')}
    assert_raise(C::ParseError){C::BitAnd.parse('for (;;)')}
    assert_raise(C::ParseError){C::BitAnd.parse('goto')}
    assert_raise(C::ParseError){C::BitAnd.parse('return')}
  end

  def test_bit_or
    check C::BitOr, <<EOS
1 | 10
----
BitOr
    expr1: IntLiteral
        val: 1
    expr2: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::BitOr.parse('} void f() {')}
    assert_raise(C::ParseError){C::BitOr.parse(';')}
    assert_raise(C::ParseError){C::BitOr.parse('int i')}
    assert_raise(C::ParseError){C::BitOr.parse('int')}
    assert_raise(C::ParseError){C::BitOr.parse('if (0)')}
    assert_raise(C::ParseError){C::BitOr.parse('switch (0)')}
    assert_raise(C::ParseError){C::BitOr.parse('for (;;)')}
    assert_raise(C::ParseError){C::BitOr.parse('goto')}
    assert_raise(C::ParseError){C::BitOr.parse('return')}
  end

  def test_bit_xor
    check C::BitXor, <<EOS
1 ^ 10
----
BitXor
    expr1: IntLiteral
        val: 1
    expr2: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::BitXor.parse('} void f() {')}
    assert_raise(C::ParseError){C::BitXor.parse(';')}
    assert_raise(C::ParseError){C::BitXor.parse('int i')}
    assert_raise(C::ParseError){C::BitXor.parse('int')}
    assert_raise(C::ParseError){C::BitXor.parse('if (0)')}
    assert_raise(C::ParseError){C::BitXor.parse('switch (0)')}
    assert_raise(C::ParseError){C::BitXor.parse('for (;;)')}
    assert_raise(C::ParseError){C::BitXor.parse('goto')}
    assert_raise(C::ParseError){C::BitXor.parse('return')}
  end

  def test_bit_not
    check C::BitNot, <<EOS
~i
----
BitNot
    expr: Variable
        name: "i"
EOS
    assert_raise(C::ParseError){C::BitNot.parse('} void f() {')}
    assert_raise(C::ParseError){C::BitNot.parse(';')}
    assert_raise(C::ParseError){C::BitNot.parse('int i')}
    assert_raise(C::ParseError){C::BitNot.parse('int')}
    assert_raise(C::ParseError){C::BitNot.parse('if (0)')}
    assert_raise(C::ParseError){C::BitNot.parse('switch (0)')}
    assert_raise(C::ParseError){C::BitNot.parse('for (;;)')}
    assert_raise(C::ParseError){C::BitNot.parse('goto')}
    assert_raise(C::ParseError){C::BitNot.parse('return')}
  end

  def test_shift_left
    check C::ShiftLeft, <<EOS
1 << 10
----
ShiftLeft
    expr1: IntLiteral
        val: 1
    expr2: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::ShiftLeft.parse('} void f() {')}
    assert_raise(C::ParseError){C::ShiftLeft.parse(';')}
    assert_raise(C::ParseError){C::ShiftLeft.parse('int i')}
    assert_raise(C::ParseError){C::ShiftLeft.parse('int')}
    assert_raise(C::ParseError){C::ShiftLeft.parse('if (0)')}
    assert_raise(C::ParseError){C::ShiftLeft.parse('switch (0)')}
    assert_raise(C::ParseError){C::ShiftLeft.parse('for (;;)')}
    assert_raise(C::ParseError){C::ShiftLeft.parse('goto')}
    assert_raise(C::ParseError){C::ShiftLeft.parse('return')}
  end

  def test_shift_right
    check C::ShiftRight, <<EOS
1 >> 10
----
ShiftRight
    expr1: IntLiteral
        val: 1
    expr2: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::ShiftRight.parse('} void f() {')}
    assert_raise(C::ParseError){C::ShiftRight.parse(';')}
    assert_raise(C::ParseError){C::ShiftRight.parse('int i')}
    assert_raise(C::ParseError){C::ShiftRight.parse('int')}
    assert_raise(C::ParseError){C::ShiftRight.parse('if (0)')}
    assert_raise(C::ParseError){C::ShiftRight.parse('switch (0)')}
    assert_raise(C::ParseError){C::ShiftRight.parse('for (;;)')}
    assert_raise(C::ParseError){C::ShiftRight.parse('goto')}
    assert_raise(C::ParseError){C::ShiftRight.parse('return')}
  end

  def test_and
    check C::And, <<EOS
1 && 10
----
And
    expr1: IntLiteral
        val: 1
    expr2: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::And.parse('} void f() {')}
    assert_raise(C::ParseError){C::And.parse(';')}
    assert_raise(C::ParseError){C::And.parse('int i')}
    assert_raise(C::ParseError){C::And.parse('int')}
    assert_raise(C::ParseError){C::And.parse('if (0)')}
    assert_raise(C::ParseError){C::And.parse('switch (0)')}
    assert_raise(C::ParseError){C::And.parse('for (;;)')}
    assert_raise(C::ParseError){C::And.parse('goto')}
    assert_raise(C::ParseError){C::And.parse('return')}
  end

  def test_or
    check C::Or, <<EOS
1 || 10
----
Or
    expr1: IntLiteral
        val: 1
    expr2: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::Or.parse('} void f() {')}
    assert_raise(C::ParseError){C::Or.parse(';')}
    assert_raise(C::ParseError){C::Or.parse('int i')}
    assert_raise(C::ParseError){C::Or.parse('int')}
    assert_raise(C::ParseError){C::Or.parse('if (0)')}
    assert_raise(C::ParseError){C::Or.parse('switch (0)')}
    assert_raise(C::ParseError){C::Or.parse('for (;;)')}
    assert_raise(C::ParseError){C::Or.parse('goto')}
    assert_raise(C::ParseError){C::Or.parse('return')}
  end

  def test_not
    check C::Not, <<EOS
!i
----
Not
    expr: Variable
        name: "i"
EOS
    assert_raise(C::ParseError){C::Not.parse('} void f() {')}
    assert_raise(C::ParseError){C::Not.parse(';')}
    assert_raise(C::ParseError){C::Not.parse('int i')}
    assert_raise(C::ParseError){C::Not.parse('int')}
    assert_raise(C::ParseError){C::Not.parse('if (0)')}
    assert_raise(C::ParseError){C::Not.parse('switch (0)')}
    assert_raise(C::ParseError){C::Not.parse('for (;;)')}
    assert_raise(C::ParseError){C::Not.parse('goto')}
    assert_raise(C::ParseError){C::Not.parse('return')}
  end

  def test_assign
    check C::Assign, <<EOS
x = 10
----
Assign
    lval: Variable
        name: "x"
    rval: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::Assign.parse('} void f() {')}
    assert_raise(C::ParseError){C::Assign.parse(';')}
    assert_raise(C::ParseError){C::Assign.parse('int i')}
    assert_raise(C::ParseError){C::Assign.parse('int')}
    assert_raise(C::ParseError){C::Assign.parse('if (0)')}
    assert_raise(C::ParseError){C::Assign.parse('switch (0)')}
    assert_raise(C::ParseError){C::Assign.parse('for (;;)')}
    assert_raise(C::ParseError){C::Assign.parse('goto')}
    assert_raise(C::ParseError){C::Assign.parse('return')}
  end

  def test_multiply_assign
    check C::MultiplyAssign, <<EOS
x *= 10
----
MultiplyAssign
    lval: Variable
        name: "x"
    rval: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::MultiplyAssign.parse('} void f() {')}
    assert_raise(C::ParseError){C::MultiplyAssign.parse(';')}
    assert_raise(C::ParseError){C::MultiplyAssign.parse('int i')}
    assert_raise(C::ParseError){C::MultiplyAssign.parse('int')}
    assert_raise(C::ParseError){C::MultiplyAssign.parse('if (0)')}
    assert_raise(C::ParseError){C::MultiplyAssign.parse('switch (0)')}
    assert_raise(C::ParseError){C::MultiplyAssign.parse('for (;;)')}
    assert_raise(C::ParseError){C::MultiplyAssign.parse('goto')}
    assert_raise(C::ParseError){C::MultiplyAssign.parse('return')}
  end

  def test_divide_assign
    check C::DivideAssign, <<EOS
x /= 10
----
DivideAssign
    lval: Variable
        name: "x"
    rval: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::DivideAssign.parse('} void f() {')}
    assert_raise(C::ParseError){C::DivideAssign.parse(';')}
    assert_raise(C::ParseError){C::DivideAssign.parse('int i')}
    assert_raise(C::ParseError){C::DivideAssign.parse('int')}
    assert_raise(C::ParseError){C::DivideAssign.parse('if (0)')}
    assert_raise(C::ParseError){C::DivideAssign.parse('switch (0)')}
    assert_raise(C::ParseError){C::DivideAssign.parse('for (;;)')}
    assert_raise(C::ParseError){C::DivideAssign.parse('goto')}
    assert_raise(C::ParseError){C::DivideAssign.parse('return')}
  end

  def test_mod_assign
    check C::ModAssign, <<EOS
x %= 10
----
ModAssign
    lval: Variable
        name: "x"
    rval: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::ModAssign.parse('} void f() {')}
    assert_raise(C::ParseError){C::ModAssign.parse(';')}
    assert_raise(C::ParseError){C::ModAssign.parse('int i')}
    assert_raise(C::ParseError){C::ModAssign.parse('int')}
    assert_raise(C::ParseError){C::ModAssign.parse('if (0)')}
    assert_raise(C::ParseError){C::ModAssign.parse('switch (0)')}
    assert_raise(C::ParseError){C::ModAssign.parse('for (;;)')}
    assert_raise(C::ParseError){C::ModAssign.parse('goto')}
    assert_raise(C::ParseError){C::ModAssign.parse('return')}
  end

  def test_add_assign
    check C::AddAssign, <<EOS
x += 10
----
AddAssign
    lval: Variable
        name: "x"
    rval: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::AddAssign.parse('} void f() {')}
    assert_raise(C::ParseError){C::AddAssign.parse(';')}
    assert_raise(C::ParseError){C::AddAssign.parse('int i')}
    assert_raise(C::ParseError){C::AddAssign.parse('int')}
    assert_raise(C::ParseError){C::AddAssign.parse('if (0)')}
    assert_raise(C::ParseError){C::AddAssign.parse('switch (0)')}
    assert_raise(C::ParseError){C::AddAssign.parse('for (;;)')}
    assert_raise(C::ParseError){C::AddAssign.parse('goto')}
    assert_raise(C::ParseError){C::AddAssign.parse('return')}
  end

  def test_subtract_assign
    check C::SubtractAssign, <<EOS
x -= 10
----
SubtractAssign
    lval: Variable
        name: "x"
    rval: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::SubtractAssign.parse('} void f() {')}
    assert_raise(C::ParseError){C::SubtractAssign.parse(';')}
    assert_raise(C::ParseError){C::SubtractAssign.parse('int i')}
    assert_raise(C::ParseError){C::SubtractAssign.parse('int')}
    assert_raise(C::ParseError){C::SubtractAssign.parse('if (0)')}
    assert_raise(C::ParseError){C::SubtractAssign.parse('switch (0)')}
    assert_raise(C::ParseError){C::SubtractAssign.parse('for (;;)')}
    assert_raise(C::ParseError){C::SubtractAssign.parse('goto')}
    assert_raise(C::ParseError){C::SubtractAssign.parse('return')}
  end

  def test_shift_left_assign
    check C::ShiftLeftAssign, <<EOS
x <<= 10
----
ShiftLeftAssign
    lval: Variable
        name: "x"
    rval: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::ShiftLeftAssign.parse('} void f() {')}
    assert_raise(C::ParseError){C::ShiftLeftAssign.parse(';')}
    assert_raise(C::ParseError){C::ShiftLeftAssign.parse('int i')}
    assert_raise(C::ParseError){C::ShiftLeftAssign.parse('int')}
    assert_raise(C::ParseError){C::ShiftLeftAssign.parse('if (0)')}
    assert_raise(C::ParseError){C::ShiftLeftAssign.parse('switch (0)')}
    assert_raise(C::ParseError){C::ShiftLeftAssign.parse('for (;;)')}
    assert_raise(C::ParseError){C::ShiftLeftAssign.parse('goto')}
    assert_raise(C::ParseError){C::ShiftLeftAssign.parse('return')}
  end

  def test_shift_right_assign
    check C::ShiftRightAssign, <<EOS
x >>= 10
----
ShiftRightAssign
    lval: Variable
        name: "x"
    rval: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::ShiftRightAssign.parse('} void f() {')}
    assert_raise(C::ParseError){C::ShiftRightAssign.parse(';')}
    assert_raise(C::ParseError){C::ShiftRightAssign.parse('int i')}
    assert_raise(C::ParseError){C::ShiftRightAssign.parse('int')}
    assert_raise(C::ParseError){C::ShiftRightAssign.parse('if (0)')}
    assert_raise(C::ParseError){C::ShiftRightAssign.parse('switch (0)')}
    assert_raise(C::ParseError){C::ShiftRightAssign.parse('for (;;)')}
    assert_raise(C::ParseError){C::ShiftRightAssign.parse('goto')}
    assert_raise(C::ParseError){C::ShiftRightAssign.parse('return')}
  end

  def test_bit_and_assign
    check C::BitAndAssign, <<EOS
x &= 10
----
BitAndAssign
    lval: Variable
        name: "x"
    rval: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::BitAndAssign.parse('} void f() {')}
    assert_raise(C::ParseError){C::BitAndAssign.parse(';')}
    assert_raise(C::ParseError){C::BitAndAssign.parse('int i')}
    assert_raise(C::ParseError){C::BitAndAssign.parse('int')}
    assert_raise(C::ParseError){C::BitAndAssign.parse('if (0)')}
    assert_raise(C::ParseError){C::BitAndAssign.parse('switch (0)')}
    assert_raise(C::ParseError){C::BitAndAssign.parse('for (;;)')}
    assert_raise(C::ParseError){C::BitAndAssign.parse('goto')}
    assert_raise(C::ParseError){C::BitAndAssign.parse('return')}
  end

  def test_bit_xor_assign
    check C::BitXorAssign, <<EOS
x ^= 10
----
BitXorAssign
    lval: Variable
        name: "x"
    rval: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::BitXorAssign.parse('} void f() {')}
    assert_raise(C::ParseError){C::BitXorAssign.parse(';')}
    assert_raise(C::ParseError){C::BitXorAssign.parse('int i')}
    assert_raise(C::ParseError){C::BitXorAssign.parse('int')}
    assert_raise(C::ParseError){C::BitXorAssign.parse('if (0)')}
    assert_raise(C::ParseError){C::BitXorAssign.parse('switch (0)')}
    assert_raise(C::ParseError){C::BitXorAssign.parse('for (;;)')}
    assert_raise(C::ParseError){C::BitXorAssign.parse('goto')}
    assert_raise(C::ParseError){C::BitXorAssign.parse('return')}
  end

  def test_bit_or_assign
    check C::BitOrAssign, <<EOS
x |= 10
----
BitOrAssign
    lval: Variable
        name: "x"
    rval: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::BitOrAssign.parse('} void f() {')}
    assert_raise(C::ParseError){C::BitOrAssign.parse(';')}
    assert_raise(C::ParseError){C::BitOrAssign.parse('int i')}
    assert_raise(C::ParseError){C::BitOrAssign.parse('int')}
    assert_raise(C::ParseError){C::BitOrAssign.parse('if (0)')}
    assert_raise(C::ParseError){C::BitOrAssign.parse('switch (0)')}
    assert_raise(C::ParseError){C::BitOrAssign.parse('for (;;)')}
    assert_raise(C::ParseError){C::BitOrAssign.parse('goto')}
    assert_raise(C::ParseError){C::BitOrAssign.parse('return')}
  end

  def test_pointer
    check C::Pointer, <<EOS
int *
----
Pointer
    type: Int
EOS
    check C::Pointer, <<EOS
const volatile unsigned int*
----
Pointer
    type: Int (const volatile unsigned)
EOS
    assert_raise(C::ParseError){C::Pointer.parse('1);} void f() {(int')}
    assert_raise(C::ParseError){C::Pointer.parse('1); (int')}
    assert_raise(C::ParseError){C::Pointer.parse('void')}
  end

  def test_array
    check C::Array, <<EOS
int[]
----
Array
    type: Int
EOS
    check C::Array, <<EOS
const volatile unsigned int[10]
----
Array
    type: Int (const volatile unsigned)
    length: IntLiteral
        val: 10
EOS
    assert_raise(C::ParseError){C::Array.parse('1);} void f() {(int')}
    assert_raise(C::ParseError){C::Array.parse('1); (int')}
    assert_raise(C::ParseError){C::Array.parse('void')}
  end

  def test_function
    check C::Function, <<EOS
void()
----
Function
    type: Void
EOS
    check C::Function, <<EOS
const volatile unsigned int(int x, int y)
----
Function
    type: Int (const volatile unsigned)
    params:
        - Parameter
            type: Int
            name: "x"
        - Parameter
            type: Int
            name: "y"
EOS
    assert_raise(C::ParseError){C::Function.parse('1);} void f() {(int')}
    assert_raise(C::ParseError){C::Function.parse('1); (int')}
    assert_raise(C::ParseError){C::Function.parse('void')}
  end

  def test_struct
    check C::Struct, <<EOS
struct s
----
Struct
    name: "s"
EOS
    check C::Struct, <<EOS
const struct {int i, j : 4;}
----
Struct (const)
    members:
        - Declaration
            type: Int
            declarators:
                - Declarator
                    name: "i"
                - Declarator
                    name: "j"
                    num_bits: IntLiteral
                        val: 4
EOS
    assert_raise(C::ParseError){C::Struct.parse('1);} void f() {(int')}
    assert_raise(C::ParseError){C::Struct.parse('1); (int')}
    assert_raise(C::ParseError){C::Struct.parse('void')}
  end

  def test_union
    check C::Union, <<EOS
union s
----
Union
    name: "s"
EOS
    check C::Union, <<EOS
const union {int i, j : 4;}
----
Union (const)
    members:
        - Declaration
            type: Int
            declarators:
                - Declarator
                    name: "i"
                - Declarator
                    name: "j"
                    num_bits: IntLiteral
                        val: 4
EOS
    assert_raise(C::ParseError){C::Union.parse('1);} void f() {(int')}
    assert_raise(C::ParseError){C::Union.parse('1); (int')}
    assert_raise(C::ParseError){C::Union.parse('void')}
  end

  def test_enum
    check C::Enum, <<EOS
enum s
----
Enum
    name: "s"
EOS
    check C::Enum, <<EOS
const enum {X = 10, Y, Z}
----
Enum (const)
    members:
        - Enumerator
            name: "X"
            val: IntLiteral
                val: 10
        - Enumerator
            name: "Y"
        - Enumerator
            name: "Z"
EOS
    assert_raise(C::ParseError){C::Enum.parse('1);} void f() {(int')}
    assert_raise(C::ParseError){C::Enum.parse('1); (int')}
    assert_raise(C::ParseError){C::Enum.parse('void')}
  end

  def test_custom_type
    assert_raise(C::ParseError){C::CustomType.parse('1);} void f() {(int')}
    assert_raise(C::ParseError){C::CustomType.parse('1); (int')}
    assert_raise(C::ParseError){C::CustomType.parse('void')}
  end

  def test_void
    check C::Void, <<EOS
const void
----
Void (const)
EOS
    assert_raise(C::ParseError){C::Void.parse('1);} void f() {(int')}
    assert_raise(C::ParseError){C::Void.parse('1); (int')}
    assert_raise(C::ParseError){C::Void.parse('int')}
  end

  def test_int
    check C::Int, <<EOS
const int
----
Int (const)
EOS
    assert_raise(C::ParseError){C::Int.parse('1);} void f() {(int')}
    assert_raise(C::ParseError){C::Int.parse('1); (int')}
    assert_raise(C::ParseError){C::Int.parse('void')}
  end

  def test_float
    check C::Float, <<EOS
const float
----
Float (const)
EOS
    assert_raise(C::ParseError){C::Float.parse('1);} void f() {(int')}
    assert_raise(C::ParseError){C::Float.parse('1); (int')}
    assert_raise(C::ParseError){C::Float.parse('void')}
  end

  def test_char
    check C::Char, <<EOS
const char
----
Char (const)
EOS
    assert_raise(C::ParseError){C::Char.parse('1);} void f() {(int')}
    assert_raise(C::ParseError){C::Char.parse('1); (int')}
    assert_raise(C::ParseError){C::Char.parse('void')}
  end

  def test_bool
    check C::Bool, <<EOS
const _Bool
----
Bool (const)
EOS
    assert_raise(C::ParseError){C::Bool.parse('1);} void f() {(int')}
    assert_raise(C::ParseError){C::Bool.parse('1); (int')}
    assert_raise(C::ParseError){C::Bool.parse('void')}
  end

  def test_complex
    check C::Complex, <<EOS
const _Complex float
----
Complex (const)
EOS
    assert_raise(C::ParseError){C::Complex.parse('1);} void f() {(int')}
    assert_raise(C::ParseError){C::Complex.parse('1); (int')}
    assert_raise(C::ParseError){C::Complex.parse('void')}
  end

  def test_imaginary
    check C::Imaginary, <<EOS
const _Imaginary float
----
Imaginary (const)
EOS
    assert_raise(C::ParseError){C::Imaginary.parse('1);} void f() {(int')}
    assert_raise(C::ParseError){C::Imaginary.parse('1); (int')}
    assert_raise(C::ParseError){C::Imaginary.parse('void')}
  end

  def test_string_literal
    check C::StringLiteral, <<EOS
"hello"
----
StringLiteral
    val: "hello"
EOS
    assert_raise(C::ParseError){C::StringLiteral.parse('} void f() {')}
    assert_raise(C::ParseError){C::StringLiteral.parse(';')}
    assert_raise(C::ParseError){C::StringLiteral.parse('int i')}
    assert_raise(C::ParseError){C::StringLiteral.parse('int')}
    assert_raise(C::ParseError){C::StringLiteral.parse('if (0)')}
    assert_raise(C::ParseError){C::StringLiteral.parse('switch (0)')}
    assert_raise(C::ParseError){C::StringLiteral.parse('for (;;)')}
    assert_raise(C::ParseError){C::StringLiteral.parse('goto')}
    assert_raise(C::ParseError){C::StringLiteral.parse('return')}
  end

  def test_char_literal
    check C::CharLiteral, <<EOS
'x'
----
CharLiteral
    val: "x"
EOS
    assert_raise(C::ParseError){C::CharLiteral.parse('} void f() {')}
    assert_raise(C::ParseError){C::CharLiteral.parse(';')}
    assert_raise(C::ParseError){C::CharLiteral.parse('int i')}
    assert_raise(C::ParseError){C::CharLiteral.parse('int')}
    assert_raise(C::ParseError){C::CharLiteral.parse('if (0)')}
    assert_raise(C::ParseError){C::CharLiteral.parse('switch (0)')}
    assert_raise(C::ParseError){C::CharLiteral.parse('for (;;)')}
    assert_raise(C::ParseError){C::CharLiteral.parse('goto')}
    assert_raise(C::ParseError){C::CharLiteral.parse('return')}
  end

  def test_compound_literal
    check C::CompoundLiteral, <<EOS
(struct s){.x [0] = 10, .y = 20, 30}
----
CompoundLiteral
    type: Struct
        name: "s"
    member_inits:
        - MemberInit
            member:
                - Member
                    name: "x"
                - IntLiteral
                    val: 0
            init: IntLiteral
                val: 10
        - MemberInit
            member:
                - Member
                    name: "y"
            init: IntLiteral
                val: 20
        - MemberInit
            init: IntLiteral
                val: 30
EOS
    check C::CompoundLiteral, <<EOS
{1, 2}
----
CompoundLiteral
    member_inits:
        - MemberInit
            init: IntLiteral
                val: 1
        - MemberInit
            init: IntLiteral
                val: 2
EOS
    assert_raise(C::ParseError){C::CompoundLiteral.parse('} void f() {')}
    assert_raise(C::ParseError){C::CompoundLiteral.parse(';')}
    assert_raise(C::ParseError){C::CompoundLiteral.parse('int i')}
    assert_raise(C::ParseError){C::CompoundLiteral.parse('int')}
    assert_raise(C::ParseError){C::CompoundLiteral.parse('if (0)')}
    assert_raise(C::ParseError){C::CompoundLiteral.parse('switch (0)')}
    assert_raise(C::ParseError){C::CompoundLiteral.parse('for (;;)')}
    assert_raise(C::ParseError){C::CompoundLiteral.parse('goto')}
    assert_raise(C::ParseError){C::CompoundLiteral.parse('return')}
  end

  def test_int_literal
    check C::IntLiteral, <<EOS
1
----
IntLiteral
    val: 1
EOS
    assert_raise(C::ParseError){C::IntLiteral.parse('} void f() {')}
    assert_raise(C::ParseError){C::IntLiteral.parse(';')}
    assert_raise(C::ParseError){C::IntLiteral.parse('int i')}
    assert_raise(C::ParseError){C::IntLiteral.parse('int')}
    assert_raise(C::ParseError){C::IntLiteral.parse('if (0)')}
    assert_raise(C::ParseError){C::IntLiteral.parse('switch (0)')}
    assert_raise(C::ParseError){C::IntLiteral.parse('for (;;)')}
    assert_raise(C::ParseError){C::IntLiteral.parse('goto')}
    assert_raise(C::ParseError){C::IntLiteral.parse('return')}
  end

  def test_float_literal
    check C::FloatLiteral, <<EOS
1.0
----
FloatLiteral
    val: 1.0
EOS
    assert_raise(C::ParseError){C::FloatLiteral.parse('} void f() {')}
    assert_raise(C::ParseError){C::FloatLiteral.parse(';')}
    assert_raise(C::ParseError){C::FloatLiteral.parse('int i')}
    assert_raise(C::ParseError){C::FloatLiteral.parse('int')}
    assert_raise(C::ParseError){C::FloatLiteral.parse('if (0)')}
    assert_raise(C::ParseError){C::FloatLiteral.parse('switch (0)')}
    assert_raise(C::ParseError){C::FloatLiteral.parse('for (;;)')}
    assert_raise(C::ParseError){C::FloatLiteral.parse('goto')}
    assert_raise(C::ParseError){C::FloatLiteral.parse('return')}
  end

  def test_variable
    check C::Variable, <<EOS
x
----
Variable
    name: "x"
EOS
    assert_raise(C::ParseError){C::Variable.parse('} void f() {')}
    assert_raise(C::ParseError){C::Variable.parse(';')}
    assert_raise(C::ParseError){C::Variable.parse('int i')}
    assert_raise(C::ParseError){C::Variable.parse('int')}
    assert_raise(C::ParseError){C::Variable.parse('if (0)')}
    assert_raise(C::ParseError){C::Variable.parse('switch (0)')}
    assert_raise(C::ParseError){C::Variable.parse('for (;;)')}
    assert_raise(C::ParseError){C::Variable.parse('goto')}
    assert_raise(C::ParseError){C::Variable.parse('return')}
  end
end
