######################################################################
#
# Tests for the #render method of each Node.
#
######################################################################

class RenderTest < Test::Unit::TestCase
  def setup
    # refresh the parser so we can change types per test.
    C.default_parser = C::Parser.new
    C.default_parser.type_names << 'T'
  end

  def teardown
    C.default_parser = nil
  end

  #
  # Parse the given string and check that it renders to the same
  # string.
  #
  def check(klass, expected)
    expected = expected.chomp.gsub(/^ *\|/, '')
    node = klass.parse(expected)
    assert_equal(expected, node.to_s)
  end

  # ------------------------------------------------------------------
  #                          TranslationUnit
  # ------------------------------------------------------------------

  def test_translation_unit
    check(C::TranslationUnit, <<-EOS)
      |int i;
      |
      |int j;
      |
      |int f() {
      |}
      |
      |int g() {
      |}
    EOS
  end

  # ------------------------------------------------------------------
  #                            Declaration
  # ------------------------------------------------------------------

  def test_declaration
    check(C::Declaration, <<-EOS)
      |void f();
    EOS
  end
  def test_declaration_with_specifier
    check(C::Declaration, <<-EOS)
      |inline void f();
    EOS
  end
  def test_declaration_with_storage
    check(C::Declaration, <<-EOS)
      |static void f();
    EOS
  end
  def test_declaration_static_with_all
    check(C::Declaration, <<-EOS)
      |inline static void f();
    EOS
  end

  # ------------------------------------------------------------------
  #                             Declarator
  # ------------------------------------------------------------------

  def test_declarator
    check(C::Declarator, <<-EOS)
      |i
    EOS
  end
  def test_declarator_with_indirect_type
    check(C::Declarator, <<-EOS)
      |*i
    EOS
  end
  def test_declarator_with_init
    check(C::Declarator, <<-EOS)
      |i = 1
    EOS
  end
  def test_declarator_with_num_bits
    check(C::Declarator, <<-EOS)
      |i : 1
    EOS
  end

  # ------------------------------------------------------------------
  #                            FunctionDef
  # ------------------------------------------------------------------

  def test_function_def
    check(C::FunctionDef, <<-EOS)
      |void f() {
      |}
    EOS
  end
  def test_function_def_with_storage
    check(C::FunctionDef, <<-EOS)
      |static void f() {
      |}
    EOS
  end
  def test_function_def_with_inline
    check(C::FunctionDef, <<-EOS)
      |inline void f() {
      |}
    EOS
  end
  def test_function_def_with_no_prototype
    check(C::FunctionDef, <<-EOS)
      |static inline void f(i)
      |    int i;
      |{
      |}
    EOS
  end
  def test_function_def_with_indirect_return_type
    check(C::FunctionDef, <<-EOS)
      |static inline void *f(int *i) {
      |}
    EOS
  end
  def test_function_def_with_all
    check(C::FunctionDef, <<-EOS)
      |static inline void *f(i)
      |    int *i;
      |{
      |}
    EOS
  end

  # ------------------------------------------------------------------
  #                             Parameter
  # ------------------------------------------------------------------

  def test_parameter
    check(C::Parameter, <<-EOS)
      |int i
    EOS
  end
  def test_parameter_with_indirect_type
    check(C::Parameter, <<-EOS)
      |int i
    EOS
  end
  def test_parameter_with_no_type
    check(C::Parameter, <<-EOS)
      |i
    EOS
  end
  def test_parameter_with_no_name
    check(C::Parameter, <<-EOS)
      |int
    EOS
  end
  def test_parameter_with_storage
    check(C::Parameter, <<-EOS)
      |register int
    EOS
  end

  # ------------------------------------------------------------------
  #                             Enumerator
  # ------------------------------------------------------------------

  def test_enumerator
    check(C::Enumerator, <<-EOS)
      |i
    EOS
  end
  def test_enumerator_with_val
    check(C::Enumerator, <<-EOS)
      |i = 1
    EOS
  end

  # ------------------------------------------------------------------
  #                               Member
  # ------------------------------------------------------------------

  def test_member_init_member
    check(C::MemberInit, <<-EOS)
      |.foo = 1
    EOS
  end
  def test_member_init_index
    check(C::MemberInit, <<-EOS)
      |[0] = 1
    EOS
  end
  def test_member_init_multi
    check(C::MemberInit, <<-EOS)
      |.foo [0] = 1
    EOS
  end
  def test_member
    check(C::Member, <<-EOS)
      |foo
    EOS
  end

  # ------------------------------------------------------------------
  #                               Block
  # ------------------------------------------------------------------

  # TODO: don't indent unlabelled statements, and have a block
  # unindent labelled statements
  def test_block_empty
    check(C::Block, <<-EOS)
      |    {
      |    }
    EOS
  end
  def test_block_with_statements
    check(C::Block, <<-EOS)
      |    {
      |        ;
      |    }
    EOS
  end
  def test_block_with_declarations
    check(C::Block, <<-EOS)
      |    {
      |        int i;
      |    }
    EOS
  end
  def test_block_with_labelled_statements
    check(C::Block, <<-EOS)
      |    {
      |    one:
      |        ;
      |    }
    EOS
  end
  def test_block_with_labelled_blocks
    check(C::Block, <<-EOS)
      |    {
      |    one:
      |        {
      |        }
      |    }
    EOS
  end
  def test_block_labelled
    check(C::Block, <<-EOS)
      |one:
      |two:
      |    {
      |    }
    EOS
  end

  # ------------------------------------------------------------------
  #                                 If
  # ------------------------------------------------------------------

  def test_if_then_with_statements
    check(C::If, <<-EOS)
      |    if (cond)
      |        ;
    EOS
  end
  def test_if_then_else_with_statements
    check(C::If, <<-EOS)
      |    if (cond)
      |        ;
      |    else
      |        ;
    EOS
  end
  def test_if_then_elsif_then_with_statements
    # TODO: handle else-if towers
    check(C::If, <<-EOS)
      |    if (cond)
      |        ;
      |    else
      |        if (cond)
      |            ;
      |        else
      |            ;
    EOS
  end
  def test_if_with_labelled_statements
    check(C::If, <<-EOS)
      |    if (cond)
      |    one:
      |        ;
      |    else
      |        if (cond)
      |        two:
      |            ;
      |        else
      |        three:
      |            ;
    EOS
  end
  def test_if_then_with_blocks
    check(C::If, <<-EOS)
      |    if (cond) {
      |    }
    EOS
  end
  def test_if_then_else_with_blocks
    check(C::If, <<-EOS)
      |    if (cond) {
      |    } else {
      |    }
    EOS
  end
  def test_if_then_elsif_then_with_blocks
    # TODO: handle else-if towers
    check(C::If, <<-EOS)
      |    if (cond) {
      |    } else
      |        if (cond) {
      |        } else {
      |        }
    EOS
  end
  def test_if_with_labelled_blocks
    check(C::If, <<-EOS)
      |    if (cond)
      |    one:
      |        {
      |        }
      |    else
      |        if (cond)
      |        two:
      |            {
      |            }
      |        else
      |        three:
      |            {
      |            }
    EOS
  end
  def test_if_labelled
    check(C::If, <<-EOS)
      |one:
      |two:
      |    if (cond)
      |        ;
    EOS
  end

  # ------------------------------------------------------------------
  #                               Switch
  # ------------------------------------------------------------------

  def test_switch_with_statement
    check(C::Switch, <<-EOS)
      |    switch (cond)
      |        ;
    EOS
  end
  def test_switch_with_block
    check(C::Switch, <<-EOS)
      |    switch (cond) {
      |    }
    EOS
  end
  def test_switch_with_labelled_statement
    check(C::Switch, <<-EOS)
      |    switch (cond)
      |    one:
      |        ;
    EOS
  end
  def test_switch_with_labelled_block
    check(C::Switch, <<-EOS)
      |    switch (cond)
      |    one:
      |        {
      |        }
    EOS
  end
  def test_switch_labelled
    check(C::Switch, <<-EOS)
      |one:
      |two:
      |    switch (cond) {
      |    }
    EOS
  end

  # ------------------------------------------------------------------
  #                               While
  # ------------------------------------------------------------------

  def test_while_with_statement
    check(C::While, <<-EOS)
      |    while (cond)
      |        ;
    EOS
  end
  def test_while_with_block
    check(C::While, <<-EOS)
      |    while (cond) {
      |    }
    EOS
  end
  def test_while_with_labelled_statement
    check(C::While, <<-EOS)
      |    while (cond)
      |    one:
      |        ;
    EOS
  end
  def test_while_with_labelled_block
    check(C::While, <<-EOS)
      |    while (cond)
      |    one:
      |        {
      |        }
    EOS
  end
  def test_while_labelled
    check(C::While, <<-EOS)
      |one:
      |    while (cond)
      |        ;
    EOS
  end
  def test_do_while_with_statement
    check(C::While, <<-EOS)
      |    do
      |        ;
      |    while (cond);
    EOS
  end
  def test_do_while_with_block
    check(C::While, <<-EOS)
      |    do {
      |    } while (cond);
    EOS
  end
  def test_do_while_with_labelled_statement
    check(C::While, <<-EOS)
      |    do
      |    one:
      |        ;
      |    while (cond);
    EOS
  end
  def test_do_while_with_labelled_block
    check(C::While, <<-EOS)
      |    do
      |    one:
      |        {
      |        }
      |    while (cond);
    EOS
  end
  def test_do_while_labelled
    check(C::While, <<-EOS)
      |one:
      |    do
      |        ;
      |    while (cond);
    EOS
  end

  # ------------------------------------------------------------------
  #                                For
  # ------------------------------------------------------------------

  def test_for_with_no_header_elements
    check(C::For, <<-EOS)
      |    for (;;)
      |        ;
    EOS
  end
  def test_for_with_init_expression
    check(C::For, <<-EOS)
      |    for (i = 0;;)
      |        ;
    EOS
  end
  def test_for_with_init_declaration
    check(C::For, <<-EOS)
      |    for (int i = 0;;)
      |        ;
    EOS
  end
  def test_for_with_cond
    check(C::For, <<-EOS)
      |    for (; i < 10;)
      |        ;
    EOS
  end
  def test_for_with_iter
    check(C::For, <<-EOS)
      |    for (;; ++i)
      |        ;
    EOS
  end
  def test_for_with_all_header_elements
    check(C::For, <<-EOS)
      |    for (i = 0; i < 10; ++i)
      |        ;
    EOS
  end
  def test_for_with_block
    check(C::For, <<-EOS)
      |    for (;;) {
      |    }
    EOS
  end
  def test_for_with_labelled_statement
    check(C::For, <<-EOS)
      |    for (;;)
      |    one:
      |        ;
    EOS
  end
  def test_for_with_labelled_block
    check(C::For, <<-EOS)
      |    for (;;)
      |    one:
      |        {
      |        }
    EOS
  end
  def test_for_labelled
    check(C::For, <<-EOS)
      |one:
      |    for (;;)
      |        ;
    EOS
  end

  # ------------------------------------------------------------------
  #                                Goto
  # ------------------------------------------------------------------

  def test_goto
    check(C::Goto, <<-EOS)
      |    goto one;
    EOS
  end
  def test_goto_labelled
    check(C::Goto, <<-EOS)
      |one:
      |    goto two;
    EOS
  end

  # ------------------------------------------------------------------
  #                              Continue
  # ------------------------------------------------------------------

  def test_continue
    check(C::Continue, <<-EOS)
      |    continue;
    EOS
  end
  def test_continue_labelled
    check(C::Continue, <<-EOS)
      |one:
      |    continue;
    EOS
  end

  # ------------------------------------------------------------------
  #                               Break
  # ------------------------------------------------------------------

  def test_break
    check(C::Break, <<-EOS)
      |    break;
    EOS
  end
  def test_break_labelled
    check(C::Break, <<-EOS)
      |one:
      |    break;
    EOS
  end

  # ------------------------------------------------------------------
  #                               Return
  # ------------------------------------------------------------------

  def test_return_with_expression
    check(C::Return, <<-EOS)
      |    return 0;
    EOS
  end
  def test_return_with_no_expression
    check(C::Return, <<-EOS)
      |    return;
    EOS
  end
  def test_return_labelled
    check(C::Return, <<-EOS)
      |one:
      |    return 0;
    EOS
  end

  # ------------------------------------------------------------------
  #                        ExpressionStatement
  # ------------------------------------------------------------------

  def test_expression_statement
    check(C::ExpressionStatement, <<-EOS)
      |    ;
    EOS
  end
  def test_expression_statement_with_expression
    check(C::ExpressionStatement, <<-EOS)
      |    1;
    EOS
  end
  def test_expression_statement_labelled
    check(C::ExpressionStatement, <<-EOS)
      |one:
      |    1;
    EOS
  end

  # ------------------------------------------------------------------
  #                             PlainLabel
  # ------------------------------------------------------------------
  
  def test_plain_label
    check(C::PlainLabel, <<-EOS)
      |one:
    EOS
  end

  # ------------------------------------------------------------------
  #                              Default
  # ------------------------------------------------------------------

  def test_default
    check(C::Default, <<-EOS)
      |default:
    EOS
  end

  # ------------------------------------------------------------------
  #                              TestCase
  # ------------------------------------------------------------------

  def test_case
    check(C::Case, <<-EOS)
      |case 1:
    EOS
  end

  # ------------------------------------------------------------------
  #                               Comma
  # ------------------------------------------------------------------
  
  def test_comma_two_expressions
    check(C::Comma, <<-EOS)
      |1, 2
    EOS
  end
  def test_comma_three_expressions
    check(C::Comma, <<-EOS)
      |1, 2, 3
    EOS
  end

  # ------------------------------------------------------------------
  #                            Conditional
  # ------------------------------------------------------------------

  def test_conditional
    check(C::Conditional, <<-EOS)
      |a ? b : c
    EOS
  end
  def test_conditional_precedences
    check(C::Or, <<-EOS)
      |a || (b ? c || d : e && f)
    EOS
  end
  def test_conditional_nested
    # TODO: handle else-if towers
    check(C::Conditional, <<-EOS)
      |(a ? b : c) ? (d ? e : f) : (g ? h : i)
    EOS
  end

  # ------------------------------------------------------------------
  #                              Variable
  # ------------------------------------------------------------------

  def test_variable
    check(C::Variable, <<-EOS)
      |x
    EOS
  end

  # ------------------------------------------------------------------
  #                               Index
  # ------------------------------------------------------------------
  
  def test_index
    check(C::Index, <<-EOS)
      |a[0]
    EOS
  end
  def test_index_precedences
    check(C::Index, <<-EOS)
      |(*a)[*a]
    EOS
  end
  def test_index_nested
    check(C::Index, <<-EOS)
      |a[a[0]][0]
    EOS
  end

  # ------------------------------------------------------------------
  #                                Call
  # ------------------------------------------------------------------

  def test_call
    check(C::Call, <<-EOS)
      |a()
    EOS
  end
  def test_call_with_args
    check(C::Call, <<-EOS)
      |a(1, (2, 3))
    EOS
  end
  def test_call_precedences
    check(C::Call, <<-EOS)
      |(*a)(*a)
    EOS
  end
  def test_call_nested
    check(C::Call, <<-EOS)
      |(*a())(a())
    EOS
  end

  # ------------------------------------------------------------------
  #                                Dot
  # ------------------------------------------------------------------

  def test_dot
    check(C::Dot, <<-EOS)
      |a.b
    EOS
  end
  def test_dot_precendences
    check(C::Dot, <<-EOS)
      |(a ? b : c).d
    EOS
  end
  def test_dot_nested
    check(C::Dot, <<-EOS)
      |a.b.c
    EOS
  end

  # ------------------------------------------------------------------
  #                               Arrow
  # ------------------------------------------------------------------

  def test_arrow
    check(C::Arrow, <<-EOS)
      |a->b
    EOS
  end
  def test_arrow_precedences
    check(C::Arrow, <<-EOS)
      |(a ? b : c)->d
    EOS
  end
  def test_arrow_nested
    check(C::Arrow, <<-EOS)
      |a->b->c
    EOS
  end

  # ------------------------------------------------------------------
  #                              PostInc
  # ------------------------------------------------------------------

  def test_post_inc
    check(C::PostInc, <<-EOS)
      |a++
    EOS
  end
  def test_post_inc_precedences
    check(C::PostInc, <<-EOS)
      |(a++ ? b++ : c++)++
    EOS
  end
  def test_post_inc_nested
    check(C::PostInc, <<-EOS)
      |a++++
    EOS
  end

  # ------------------------------------------------------------------
  #                              PostDec
  # ------------------------------------------------------------------

  def test_post_dec
    check(C::PostDec, <<-EOS)
      |a--
    EOS
  end
  def test_post_dec_precedences
    check(C::PostDec, <<-EOS)
      |(a-- ? b-- : c--)--
    EOS
  end
  def test_post_dec_nested
    check(C::PostDec, <<-EOS)
      |a----
    EOS
  end

  # ------------------------------------------------------------------
  #                                Cast
  # ------------------------------------------------------------------
  
  def test_cast
    check(C::Cast, <<-EOS)
      |(int)a
    EOS
  end
  def test_cast_precedences
    check(C::Cast, <<-EOS)
      |(int)((int)a + (int)b)
    EOS
  end
  def test_cast_nested
    check(C::Cast, <<-EOS)
      |(int)(int)a
    EOS
  end

  # ------------------------------------------------------------------
  #                              Address
  # ------------------------------------------------------------------

  def test_address
    check(C::Address, <<-EOS)
      |&a
    EOS
  end
  def test_address_precedences
    check(C::Address, <<-EOS)
      |&(a + 1)
    EOS
  end
  def test_address_nested
    check(C::Address, <<-EOS)
      |& &a
    EOS
  end

  # ------------------------------------------------------------------
  #                            Dereference
  # ------------------------------------------------------------------

  def test_dereference
    check(C::Dereference, <<-EOS)
      |*a
    EOS
  end
  def test_dereference_precedences
    check(C::Dereference, <<-EOS)
      |*(a + 1)
    EOS
  end
  def test_dereference_nested
    check(C::Dereference, <<-EOS)
      |**a
    EOS
  end

  # ------------------------------------------------------------------
  #                               Sizeof
  # ------------------------------------------------------------------

  def test_sizeof
    check(C::Sizeof, <<-EOS)
      |sizeof(a)
    EOS
  end
  def test_sizeof_precedences
    check(C::Index, <<-EOS)
      |(sizeof(a + 1))[b]
    EOS
  end
  def test_sizeof_nested
    check(C::Sizeof, <<-EOS)
      |sizeof(sizeof(a))
    EOS
  end

  # ------------------------------------------------------------------
  #                              Positive
  # ------------------------------------------------------------------

  def test_positive
    check(C::Positive, <<-EOS)
      |+a
    EOS
  end
  def test_positive_precedences
    check(C::Add, <<-EOS)
      |a + +(+a + +b)
    EOS
  end
  def test_positive_nested
    check(C::Positive, <<-EOS)
      |+ +a
    EOS
  end

  # ------------------------------------------------------------------
  #                              Negative
  # ------------------------------------------------------------------

  def test_negative
    check(C::Negative, <<-EOS)
      |-a
    EOS
  end
  def test_negative_precedences
    check(C::Subtract, <<-EOS)
      |a - -(-a - -b)
    EOS
  end
  def test_negative_nested
    check(C::Negative, <<-EOS)
      |- -a
    EOS
  end

  # ------------------------------------------------------------------
  #                               PreInc
  # ------------------------------------------------------------------

  def test_pre_inc
    check(C::PreInc, <<-EOS)
      |++a
    EOS
  end
  def test_pre_inc_precedences
    check(C::Add, <<-EOS)
      |++a + ++(++b + ++c)
    EOS
  end
  def test_pre_inc_nested
    check(C::PreInc, <<-EOS)
      |++++a
    EOS
  end

  # ------------------------------------------------------------------
  #                               PreDec
  # ------------------------------------------------------------------

  def test_pre_dec
    check(C::PreDec, <<-EOS)
      |--a
    EOS
  end
  def test_pre_dec_precedences
    check(C::Subtract, <<-EOS)
      |--a - --(--b - --c)
    EOS
  end
  def test_pre_dec_nested
    check(C::PreDec, <<-EOS)
      |----a
    EOS
  end

  # ------------------------------------------------------------------
  #                               BitNot
  # ------------------------------------------------------------------

  def test_bit_not
    check(C::BitNot, <<-EOS)
      |~a
    EOS
  end
  def test_bit_not_precedences
    check(C::Equal, <<-EOS)
      |~a == (~b | ~c)
    EOS
  end
  def test_bit_not_nested
    check(C::BitNot, <<-EOS)
      |~~a
    EOS
  end

  # ------------------------------------------------------------------
  #                                Not
  # ------------------------------------------------------------------

  def test_not
    check(C::Not, <<-EOS)
      |!a
    EOS
  end
  def test_not_precedences
    check(C::Equal, <<-EOS)
      |!a == !(!b || !c)
    EOS
  end
  def test_not_nested
    check(C::Not, <<-EOS)
      |!!a
    EOS
  end

  # ------------------------------------------------------------------
  #                                Add
  # ------------------------------------------------------------------

  def test_add
    check(C::Add, <<-EOS)
      |a + b
    EOS
  end
  def test_add_precedences
    check(C::Add, <<-EOS)
      |a * b + (c == d)
    EOS
  end
  def test_add_nested
    check(C::Add, <<-EOS)
      |a + b + (c + d)
    EOS
  end

  # ------------------------------------------------------------------
  #                              Subtract
  # ------------------------------------------------------------------

  def test_subtract
    check(C::Subtract, <<-EOS)
      |a - b
    EOS
  end
  def test_subtract_precedences
    check(C::Subtract, <<-EOS)
      |a * b - (c == d)
    EOS
  end
  def test_subtract_nested
    check(C::Subtract, <<-EOS)
      |a - b - (c - d)
    EOS
  end

  # ------------------------------------------------------------------
  #                              Multiply
  # ------------------------------------------------------------------

  def test_multiply
    check(C::Multiply, <<-EOS)
      |a * b
    EOS
  end
  def test_multiply_precedences
    check(C::Multiply, <<-EOS)
      |*a * (b + c)
    EOS
  end
  def test_multiply_nested
    check(C::Multiply, <<-EOS)
      |a * b * (c * d)
    EOS
  end

  # ------------------------------------------------------------------
  #                               Divide
  # ------------------------------------------------------------------

  def test_divide
    check(C::Divide, <<-EOS)
      |a / b
    EOS
  end
  def test_divide_precedences
    check(C::Divide, <<-EOS)
      |*a / (b + c)
    EOS
  end
  def test_divide_nested
    check(C::Divide, <<-EOS)
      |a / b / (c / d)
    EOS
  end

  # ------------------------------------------------------------------
  #                                Mod
  # ------------------------------------------------------------------

  def test_mod
    check(C::Mod, <<-EOS)
      |a % b
    EOS
  end
  def test_mod_precedences
    check(C::Mod, <<-EOS)
      |*a % (b + c)
    EOS
  end
  def test_mod_nested
    check(C::Mod, <<-EOS)
      |a % b % (c % d)
    EOS
  end

  # ------------------------------------------------------------------
  #                               Equal
  # ------------------------------------------------------------------

  def test_equal
    check(C::Equal, <<-EOS)
      |a == b
    EOS
  end
  def test_equal_precedences
    check(C::Equal, <<-EOS)
      |a + b == (c ? d : e)
    EOS
  end
  def test_equal_nested
    check(C::Equal, <<-EOS)
      |a == b == (c == d)
    EOS
  end

  # ------------------------------------------------------------------
  #                              NotEqual
  # ------------------------------------------------------------------

  def test_not_equal
    check(C::NotEqual, <<-EOS)
      |a != b
    EOS
  end
  def test_not_equal_precedences
    check(C::NotEqual, <<-EOS)
      |a + b != (c ? d : e)
    EOS
  end
  def test_not_equal_nested
    check(C::NotEqual, <<-EOS)
      |a != b != (c != d)
    EOS
  end

  # ------------------------------------------------------------------
  #                                Less
  # ------------------------------------------------------------------

  def test_less
    check(C::Less, <<-EOS)
      |a < b
    EOS
  end
  def test_less_precedences
    check(C::Less, <<-EOS)
      |a + b < (c ? d : e)
    EOS
  end
  def test_less_nested
    check(C::Less, <<-EOS)
      |a < b < (c < d)
    EOS
  end

  # ------------------------------------------------------------------
  #                                More
  # ------------------------------------------------------------------

  def test_more
    check(C::More, <<-EOS)
      |a > b
    EOS
  end
  def test_more_precedences
    check(C::More, <<-EOS)
      |a + b > (c ? d : e)
    EOS
  end
  def test_more_nested
    check(C::More, <<-EOS)
      |a > b > (c > d)
    EOS
  end

  # ------------------------------------------------------------------
  #                            LessOrEqual
  # ------------------------------------------------------------------

  def test_less_or_equal
    check(C::LessOrEqual, <<-EOS)
      |a <= b
    EOS
  end
  def test_less_or_equal_precedences
    check(C::LessOrEqual, <<-EOS)
      |a + b <= (c ? d : e)
    EOS
  end
  def test_less_or_equal_nested
    check(C::LessOrEqual, <<-EOS)
      |a <= b <= (c <= d)
    EOS
  end

  # ------------------------------------------------------------------
  #                            MoreOrEqual
  # ------------------------------------------------------------------

  def test_more_or_equal
    check(C::MoreOrEqual, <<-EOS)
      |a >= b
    EOS
  end
  def test_more_or_equal_precedences
    check(C::MoreOrEqual, <<-EOS)
      |a + b >= (c ? d : e)
    EOS
  end
  def test_more_or_equal_nested
    check(C::MoreOrEqual, <<-EOS)
      |a >= b >= (c >= d)
    EOS
  end

  # ------------------------------------------------------------------
  #                               BitAnd
  # ------------------------------------------------------------------

  def test_bit_and
    check(C::BitAnd, <<-EOS)
      |a & b
    EOS
  end
  def test_bit_and_precedences
    check(C::BitAnd, <<-EOS)
      |a + b & (c ? d : e)
    EOS
  end
  def test_bit_and_nested
    check(C::BitAnd, <<-EOS)
      |a & b & (c & d)
    EOS
  end

  # ------------------------------------------------------------------
  #                               BitOr
  # ------------------------------------------------------------------

  def test_bit_or
    check(C::BitOr, <<-EOS)
      |a | b
    EOS
  end
  def test_bit_or_precedences
    check(C::BitOr, <<-EOS)
      |a + b | (c ? d : e)
    EOS
  end
  def test_bit_or_nested
    check(C::BitOr, <<-EOS)
      |a | b | (c | d)
    EOS
  end

  # ------------------------------------------------------------------
  #                               BitXor
  # ------------------------------------------------------------------

  def test_bit_xor
    check(C::BitXor, <<-EOS)
      |a ^ b
    EOS
  end
  def test_bit_xor_precedences
    check(C::BitXor, <<-EOS)
      |a + b ^ (c ? d : e)
    EOS
  end
  def test_bit_xor_nested
    check(C::BitXor, <<-EOS)
      |a ^ b ^ (c ^ d)
    EOS
  end

  # ------------------------------------------------------------------
  #                             ShiftLeft
  # ------------------------------------------------------------------

  def test_shift_left
    check(C::ShiftLeft, <<-EOS)
      |a << b
    EOS
  end
  def test_shift_left_precedences
    check(C::ShiftLeft, <<-EOS)
      |a + b << (c ? d : e)
    EOS
  end
  def test_shift_left_nested
    check(C::ShiftLeft, <<-EOS)
      |a << b << (c << d)
    EOS
  end

  # ------------------------------------------------------------------
  #                             ShiftRight
  # ------------------------------------------------------------------

  def test_shift_right
    check(C::ShiftRight, <<-EOS)
      |a >> b
    EOS
  end
  def test_shift_right_precedences
    check(C::ShiftRight, <<-EOS)
      |a + b >> (c ? d : e)
    EOS
  end
  def test_shift_right_nested
    check(C::ShiftRight, <<-EOS)
      |a >> b >> (c >> d)
    EOS
  end

  # ------------------------------------------------------------------
  #                                And
  # ------------------------------------------------------------------

  def test_and
    check(C::And, <<-EOS)
      |a && b
    EOS
  end
  def test_and_precedences
    check(C::And, <<-EOS)
      |a + b && (c ? d : e)
    EOS
  end
  def test_and_nested
    check(C::And, <<-EOS)
      |a && b && (c && d)
    EOS
  end

  # ------------------------------------------------------------------
  #                                 Or
  # ------------------------------------------------------------------

  def test_or
    check(C::Or, <<-EOS)
      |a || b
    EOS
  end
  def test_or_precedences
    check(C::Or, <<-EOS)
      |a + b || (c ? d : e)
    EOS
  end
  def test_or_nested
    check(C::Or, <<-EOS)
      |a || b || (c || d)
    EOS
  end

  # ------------------------------------------------------------------
  #                               Assign
  # ------------------------------------------------------------------

  def test_assign
    check(C::Assign, <<-EOS)
      |a = b
    EOS
  end
  def test_assign_precedences
    check(C::Assign, <<-EOS)
      |a = b ? c : d
    EOS
  end
  def test_assign_nested
    check(C::Assign, <<-EOS)
      |a = b = (c, d)
    EOS
  end

  # ------------------------------------------------------------------
  #                           MultiplyAssign
  # ------------------------------------------------------------------

  def test_multiply_assign
    check(C::MultiplyAssign, <<-EOS)
      |a *= b
    EOS
  end
  def test_multiply_assign_precedences
    check(C::MultiplyAssign, <<-EOS)
      |a *= b ? c : d
    EOS
  end
  def test_multiply_assign_nested
    check(C::MultiplyAssign, <<-EOS)
      |a *= b *= (c, d)
    EOS
  end

  # ------------------------------------------------------------------
  #                            DivideAssign
  # ------------------------------------------------------------------

  def test_divide_assign
    check(C::DivideAssign, <<-EOS)
      |a /= b
    EOS
  end
  def test_divide_assign_precedences
    check(C::DivideAssign, <<-EOS)
      |a /= b ? c : d
    EOS
  end
  def test_divide_assign_nested
    check(C::DivideAssign, <<-EOS)
      |a /= b /= c
    EOS
  end

  # ------------------------------------------------------------------
  #                             ModAssign
  # ------------------------------------------------------------------

  def test_mod_assign
    check(C::ModAssign, <<-EOS)
      |a %= b
    EOS
  end
  def test_mod_assign_precedences
    check(C::ModAssign, <<-EOS)
      |a %= b ? c : d
    EOS
  end
  def test_mod_assign_nested
    check(C::ModAssign, <<-EOS)
      |a %= b %= (c, d)
    EOS
  end

  # ------------------------------------------------------------------
  #                             AddAssign
  # ------------------------------------------------------------------

  def test_add_assign
    check(C::AddAssign, <<-EOS)
      |a += b
    EOS
  end
  def test_add_assign_precedences
    check(C::AddAssign, <<-EOS)
      |a += b ? c : d
    EOS
  end
  def test_add_assign_nested
    check(C::AddAssign, <<-EOS)
      |a += b += (c, d)
    EOS
  end

  # ------------------------------------------------------------------
  #                           SubtractAssign
  # ------------------------------------------------------------------

  def test_subtract_assign
    check(C::SubtractAssign, <<-EOS)
      |a -= b
    EOS
  end
  def test_subtract_assign_precedences
    check(C::SubtractAssign, <<-EOS)
      |a -= b ? c : d
    EOS
  end
  def test_subtract_assign_nested
    check(C::SubtractAssign, <<-EOS)
      |a -= b -= (c, d)
    EOS
  end

  # ------------------------------------------------------------------
  #                          ShiftLeftAssign
  # ------------------------------------------------------------------

  def test_shift_left_assign
    check(C::ShiftLeftAssign, <<-EOS)
      |a <<= b
    EOS
  end
  def test_shift_left_assign_precedences
    check(C::ShiftLeftAssign, <<-EOS)
      |a <<= b ? c : d
    EOS
  end
  def test_shift_left_assign_nested
    check(C::ShiftLeftAssign, <<-EOS)
      |a <<= b <<= (c, d)
    EOS
  end

  # ------------------------------------------------------------------
  #                          ShiftRightAssign
  # ------------------------------------------------------------------

  def test_shift_right_assign
    check(C::ShiftRightAssign, <<-EOS)
      |a >>= b
    EOS
  end
  def test_shift_right_assign_precedences
    check(C::ShiftRightAssign, <<-EOS)
      |a >>= b ? c : d
    EOS
  end
  def test_shift_right_assign_nested
    check(C::ShiftRightAssign, <<-EOS)
      |a >>= b >>= (c, d)
    EOS
  end

  # ------------------------------------------------------------------
  #                            BitAndAssign
  # ------------------------------------------------------------------

  def test_bit_and_assign
    check(C::BitAndAssign, <<-EOS)
      |a &= b
    EOS
  end
  def test_bit_and_assign_precedences
    check(C::BitAndAssign, <<-EOS)
      |a &= b ? c : d
    EOS
  end
  def test_bit_and_assign_nested
    check(C::BitAndAssign, <<-EOS)
      |a &= b &= (c, d)
    EOS
  end

  # ------------------------------------------------------------------
  #                            BitXorAssign
  # ------------------------------------------------------------------

  def test_bit_xor_assign
    check(C::BitXorAssign, <<-EOS)
      |a ^= b
    EOS
  end
  def test_bit_xor_assign_precedences
    check(C::BitXorAssign, <<-EOS)
      |a ^= b ? c : d
    EOS
  end
  def test_bit_xor_assign_nested
    check(C::BitXorAssign, <<-EOS)
      |a ^= b ^= (c, d)
    EOS
  end

  # ------------------------------------------------------------------
  #                            BitOrAssign
  # ------------------------------------------------------------------

  def test_bit_or_assign
    check(C::BitOrAssign, <<-EOS)
      |a |= b
    EOS
  end
  def test_bit_or_assign_precedences
    check(C::BitOrAssign, <<-EOS)
      |a |= b ? c : d
    EOS
  end
  def test_bit_or_assign_nested
    check(C::BitOrAssign, <<-EOS)
      |a |= b |= (c, d)
    EOS
  end

  # ------------------------------------------------------------------
  #                           StringLiteral
  # ------------------------------------------------------------------

  # TODO: handle unusual characters
  # TODO: handle prefixes (wide)
  def test_string_literal_empty
    check(C::StringLiteral, <<-EOS)
      |""
    EOS
  end
  def test_string_literal_simple
    check(C::StringLiteral, <<-EOS)
      |"hi"
    EOS
  end
  def test_string_literal_complex
    check(C::StringLiteral, <<-EOS)
      |"\0000\0xfff"
    EOS
  end

  # ------------------------------------------------------------------
  #                            CharLiteral
  # ------------------------------------------------------------------

  # TODO: handle unusual characters
  # TODO: handle prefixes (wide)
  def test_char_literal_simple
    check(C::CharLiteral, <<-EOS)
      |'x'
    EOS
  end
  def test_char_literal_complex
    check(C::CharLiteral, <<-EOS)
      |'\0000\0xfff'
    EOS
  end

  # ------------------------------------------------------------------
  #                          CompoundLiteral
  # ------------------------------------------------------------------

  def test_compound_literal_no_type
    check(C::CompoundLiteral, <<-EOS)
      |{
      |    1
      |}
    EOS
  end
  def test_compound_literal_type
    check(C::CompoundLiteral, <<-EOS)
      |(int []) {
      |    1
      |}
    EOS
  end
  def test_compound_literal_one_member
    check(C::CompoundLiteral, <<-EOS)
      |(struct s) {
      |    .one = 1
      |}
    EOS
  end
  def test_compound_literal_two_members
    check(C::CompoundLiteral, <<-EOS)
      |(union u) {
      |    .one = 1,
      |    .two = 2
      |}
    EOS
  end
  def test_compound_literal_nested
    check(C::CompoundLiteral, <<-EOS)
      |(T) {
      |    .one = (T) {
      |        2
      |    }
      |}
    EOS
  end

  # ------------------------------------------------------------------
  #                             IntLiteral
  # ------------------------------------------------------------------

  def test_int_literal_small
    check(C::IntLiteral, <<-EOS)
      |1
    EOS
  end
  # TODO: handle big ints -- this test fails
  def xtest_int_literal_big
    check(C::IntLiteral, <<-EOS)
      |10000000000
    EOS
  end

  # ------------------------------------------------------------------
  #                            FloatLiteral
  # ------------------------------------------------------------------

  # TODO: handle precisions properly -- probably need to store string,
  # or integer,mantissa,exponent separately
  def test_float_literal
    check(C::FloatLiteral, <<-EOS)
      |1.0
    EOS
  end
  def test_float_literal_precise
    check(C::FloatLiteral, <<-EOS)
      |1.0000000001
    EOS
  end

  # ------------------------------------------------------------------
  #                              Pointer
  # ------------------------------------------------------------------

  def test_pointer
    check(C::Pointer, <<-EOS)
      |int *
    EOS
  end
  def test_pointer_precedences
    check(C::Pointer, <<-EOS)
      |int *(*)[]
    EOS
  end
  def test_pointer_nested
    check(C::Pointer, <<-EOS)
      |int **
    EOS
  end

  # ------------------------------------------------------------------
  #                               Array
  # ------------------------------------------------------------------
  def test_array
    check(C::Array, <<-EOS)
      |int []
    EOS
  end
  def test_array_precedences
    check(C::Pointer, <<-EOS)
      |int (*)[]
    EOS
  end
  def test_array_nested
    check(C::Array, <<-EOS)
      |int [][]
    EOS
  end

  # ------------------------------------------------------------------
  #                              Function
  # ------------------------------------------------------------------

  def test_function
    check(C::Function, <<-EOS)
      |int ()
    EOS
  end
  def test_function_no_params
    check(C::Function, <<-EOS)
      |int (void)
    EOS
  end
  def test_function_params
    check(C::Function, <<-EOS)
      |int (int, int)
    EOS
  end
  def test_function_precedences
    check(C::Pointer, <<-EOS)
      |int (*)()
    EOS
  end
  def test_function_nested
    check(C::Function, <<-EOS)
      |int ()()
    EOS
  end

  # ------------------------------------------------------------------
  #                               Struct
  # ------------------------------------------------------------------

  def test_struct_basic
    check(C::Struct, <<-EOS)
      |struct {
      |    int i;
      |}
    EOS
  end
  def test_struct_with_name
    check(C::Struct, <<-EOS)
      |struct s {
      |    int i;
      |}
    EOS
  end
  def test_struct_with_two_members
    check(C::Struct, <<-EOS)
      |struct {
      |    int i;
      |    int j;
      |}
    EOS
  end
  def test_struct_with_all
    check(C::Struct, <<-EOS)
      |struct s {
      |    int i;
      |    int j;
      |}
    EOS
  end

  # ------------------------------------------------------------------
  #                               Union
  # ------------------------------------------------------------------

  def test_union_basic
    check(C::Union, <<-EOS)
      |union {
      |    int i;
      |}
    EOS
  end
  def test_union_with_name
    check(C::Union, <<-EOS)
      |union u {
      |    int i;
      |}
    EOS
  end
  def test_union_with_two_members
    check(C::Union, <<-EOS)
      |union {
      |    int i;
      |    int j;
      |}
    EOS
  end
  def test_union_with_all
    check(C::Union, <<-EOS)
      |union u {
      |    int i;
      |    int j;
      |}
    EOS
  end

  # ------------------------------------------------------------------
  #                                Enum
  # ------------------------------------------------------------------

  def test_enum_basic
    check(C::Enum, <<-EOS)
      |enum {
      |    E1
      |}
    EOS
  end
  def test_enum_with_name
    check(C::Enum, <<-EOS)
      |enum e {
      |    E1
      |}
    EOS
  end
  def test_enum_with_two_members
    check(C::Enum, <<-EOS)
      |enum {
      |    E1,
      |    E2
      |}
    EOS
  end
  def test_enum_with_all
    check(C::Enum, <<-EOS)
      |enum {
      |    E1,
      |    E2
      |}
    EOS
  end

  # ------------------------------------------------------------------
  #                             CustomType
  # ------------------------------------------------------------------

  def test_custom_type_unqualified
    check(C::CustomType, <<-EOS)
      |T
    EOS
  end
  def test_custom_type_qualified
    check(C::CustomType, <<-EOS)
      |const restrict volatile T
    EOS
  end

  # ------------------------------------------------------------------
  #                                Void
  # ------------------------------------------------------------------

  def test_void_unqualified
    check(C::Void, <<-EOS)
      |void
    EOS
  end
  def test_void_qualified
    check(C::Void, <<-EOS)
      |const restrict volatile void
    EOS
  end

  # ------------------------------------------------------------------
  #                                Int
  # ------------------------------------------------------------------

  def test_int_unqualified
    check(C::Int, <<-EOS)
      |int
    EOS
  end
  def test_int_qualified
    check(C::Int, <<-EOS)
      |const restrict volatile int
    EOS
  end
  def test_int_qualified_short
    check(C::Int, <<-EOS)
      |const restrict volatile short int
    EOS
  end
  def test_int_qualified_long
    check(C::Int, <<-EOS)
      |const restrict volatile long int
    EOS
  end
  def test_int_qualified_long_long
    check(C::Int, <<-EOS)
      |const restrict volatile long long int
    EOS
  end

  # ------------------------------------------------------------------
  #                               Float
  # ------------------------------------------------------------------

  def test_float_unqualified
    check(C::Float, <<-EOS)
      |float
    EOS
  end
  def test_float_qualified
    check(C::Float, <<-EOS)
      |const restrict volatile float
    EOS
  end
  def test_float_qualified_double
    check(C::Float, <<-EOS)
      |const restrict volatile double
    EOS
  end
  def test_float_qualified_long_double
    check(C::Float, <<-EOS)
      |const restrict volatile long double
    EOS
  end

  # ------------------------------------------------------------------
  #                                Char
  # ------------------------------------------------------------------

  def test_char_unqualified
    check(C::Char, <<-EOS)
      |char
    EOS
  end
  def test_char_qualified
    check(C::Char, <<-EOS)
      |const restrict volatile char
    EOS
  end
  def test_char_qualified_signed
    check(C::Char, <<-EOS)
      |const restrict volatile signed char
    EOS
  end
  def test_char_qualified_unsigned
    check(C::Char, <<-EOS)
      |const restrict volatile unsigned char
    EOS
  end

  # ------------------------------------------------------------------
  #                                Bool
  # ------------------------------------------------------------------

  def test_bool_unqualified
    check(C::Bool, <<-EOS)
      |_Bool
    EOS
  end
  def test_bool_qualified
    check(C::Bool, <<-EOS)
      |const restrict volatile _Bool
    EOS
  end

  # ------------------------------------------------------------------
  #                              Complex
  # ------------------------------------------------------------------

  def test_complex_unqualified
    check(C::Complex, <<-EOS)
      |_Complex float
    EOS
  end
  def test_complex_qualified
    check(C::Complex, <<-EOS)
      |const restrict volatile _Complex float
    EOS
  end
  def test_complex_qualified_double
    check(C::Complex, <<-EOS)
      |const restrict volatile _Complex double
    EOS
  end
  def test_complex_qualified_long_double
    check(C::Complex, <<-EOS)
      |const restrict volatile _Complex long double
    EOS
  end

  # ------------------------------------------------------------------
  #                             Imaginary
  # ------------------------------------------------------------------

  def test_imaginary_unqualified
    check(C::Imaginary, <<-EOS)
      |_Imaginary float
    EOS
  end
  def test_imaginary_qualified
    check(C::Imaginary, <<-EOS)
      |const restrict volatile _Imaginary float
    EOS
  end
  def test_imaginary_qualified_double
    check(C::Imaginary, <<-EOS)
      |const restrict volatile _Imaginary double
    EOS
  end
  def test_imaginary_qualified_long_double
    check(C::Imaginary, <<-EOS)
      |const restrict volatile _Imaginary long double
    EOS
  end
end
