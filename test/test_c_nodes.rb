######################################################################
#
# Tests for miscellaneous methods specific to individual Node classes.
#
######################################################################

class MiscTests < Test::Unit::TestCase

  # ------------------------------------------------------------------
  #                    Declarator#declaration type
  # ------------------------------------------------------------------

  def test_declarator_declaration
    tor = C::Declarator.new(nil, 'x')
    assert_nil(tor.declaration)

    list = C::NodeArray[tor]
    assert_nil(tor.declaration)

    tion = C::Declaration.new(C::Int.new, list)
    assert_same(tion, tor.declaration)

    list.detach
    assert_nil(tor.declaration)
  end

  def test_declarator_type
    # int i, *j, k[], l(), *m[10];
    decl = C::Declaration.new(C::Int.new)
    decl.declarators << C::Declarator.new(nil, 'i')
    decl.declarators << C::Declarator.new(C::Pointer.new, 'j')
    decl.declarators << C::Declarator.new(C::Array.new, 'k')
    decl.declarators << C::Declarator.new(C::Function.new, 'l')
    arr = C::Array.new(C::Pointer.new, C::IntLiteral.new(10))
    decl.declarators << C::Declarator.new(arr, 'm')

    assert_equal_inspect_strs(decl.declarators[0].type.inspect, <<EOS)
Int
EOS
    assert_equal_inspect_strs(decl.declarators[1].type.inspect, <<EOS)
Pointer
    type: Int
EOS
    assert_equal_inspect_strs(decl.declarators[2].type.inspect, <<EOS)
Array
    type: Int
EOS
    assert_equal_inspect_strs(decl.declarators[3].type.inspect, <<EOS)
Function
    type: Int
EOS
    assert_equal_inspect_strs(decl.declarators[4].type.inspect, <<EOS)
Array
    type: Pointer
        type: Int
    length: IntLiteral
        val: 10
EOS
  end

  # ------------------------------------------------------------------
  #                      DirectType, IndirectType
  # ------------------------------------------------------------------

  def test_type_direct_type
    d = C::Int.new
    t = C::Pointer.new(d)
    assert_same(d, t.direct_type)

    d = C::Float.new
    t = C::Pointer.new(C::Pointer.new(d))
    assert_same(d, t.direct_type)

    d = C::Struct.new('S')
    t = C::Array.new(d)
    assert_same(d, t.direct_type)

    d = C::CustomType.new('T')
    t = C::Function.new(d)
    assert_same(d, t.direct_type)

    t = C::Pointer.new(nil)
    assert_nil(t.direct_type)

    t = C::Int.new
    assert_same(t, t.direct_type)
  end

  def test_type_indirect_type
    d = C::Int.new
    t = C::Pointer.new(d)
    assert_equal(C::Pointer.new, t.indirect_type)

    d = C::Float.new
    t = C::Pointer.new(C::Pointer.new(d))
    assert_equal(C::Pointer.new(C::Pointer.new), t.indirect_type)

    d = C::Struct.new('S')
    t = C::Array.new(d, C::IntLiteral.new(10))
    assert_equal(C::Array.new(nil, C::IntLiteral.new(10)), t.indirect_type)

    d = C::CustomType.new('T')
    t = C::Function.new(d)
    assert_equal(C::Function.new, t.indirect_type)

    t = C::Pointer.new(nil)
    assert_copy(t, t.indirect_type)

    t = C::Int.new
    assert_nil(t.indirect_type)
  end

  def test_type_set_direct_type
    d = C::Int.new
    t = C::Pointer.new(d)
    x = C::Int.new
    t.direct_type = x
    assert_same(x, t.type)

    d = C::Float.new
    t = C::Pointer.new(C::Pointer.new(d))
    x = C::Float.new
    t.direct_type = x
    assert_same(x, t.type.type)

    d = C::Struct.new('S')
    t = C::Array.new(d)
    x = C::Struct.new('T')
    t.direct_type = x
    assert_same(x, t.type)

    d = C::CustomType.new('T')
    t = C::Function.new(d)
    x = C::Void.new
    t.direct_type = x
    assert_same(x, t.type)

    t = C::Pointer.new(nil)
    x = C::Imaginary.new
    t.direct_type = x
    assert_same(x, t.type)

    t = C::Int.new
    x = C::Void.new
    assert_raise(NoMethodError){t.direct_type = x}
  end

  # ------------------------------------------------------------------
  #                     CharLiteral StringLiteral
  # ------------------------------------------------------------------

  def test_char_literal_wide
    c = C::CharLiteral.new('abc', 'L')
    assert(c.wide?)
    assert_equal('L', c.prefix)

    c.prefix = nil
    assert(!c.wide?)
    assert_nil(c.prefix)

    c.prefix = 'x'
    assert(!c.wide?)
    assert_equal('x', c.prefix)

    c.wide = false
    assert(!c.wide?)
    assert_equal('x', c.prefix)

    c.wide = true
    assert(c.wide?)
    assert_equal('L', c.prefix)

    c.wide = false
    assert(!c.wide?)
    assert_equal(nil, c.prefix)
  end
  def test_string_literal_wide
    s = C::StringLiteral.new('abc', 'L')
    assert(s.wide?)
    assert_equal('L', s.prefix)

    s.prefix = nil
    assert(!s.wide?)
    assert_nil(s.prefix)

    s.prefix = 'x'
    assert(!s.wide?)
    assert_equal('x', s.prefix)

    s.wide = false
    assert(!s.wide?)
    assert_equal('x', s.prefix)

    s.wide = true
    assert(s.wide?)
    assert_equal('L', s.prefix)

    s.wide = false
    assert(!s.wide?)
    assert_equal(nil, s.prefix)
  end
end
