######################################################################
#
# Tests for NodeList classes.
#
######################################################################

#
# NodeListTest classes are abstract, inherited by classes which define
# List() to return a NodeList class.  The tests defined in
# NodeListTest subclasses are therefore used to test all NodeList
# classes.
#
module NodeListTest
  @@submodules = []
  def self.submodules
    @@submodules
  end
  def self.included(m)
    @@submodules << m
  end
  def setup
    # []
    @empty = _List[]

    # [a]
    a = C::Int.new
    @one = _List[a]
    @one_els = [a]

    # [a, b]
    a, b = 2.of{C::Int.new}
    @two = _List[a, b]
    @two_els = [a, b]

    # [a, b, c]
    a, b, c = 3.of{C::Int.new}
    @three = _List[a, b, c]
    @three_els = [a, b, c]

    # [a, b, c, d]
    a, b, c, d = 4.of{C::Int.new}
    @four = _List[a, b, c, d]
    @four_els = [a, b, c, d]

    # [[a,b], [c,d], [e,f], [g,h]]
    a, b, c, d, e, f, g, h = 8.of{C::Int.new}
    l0 = _List[a,b]
    l1 = _List[c,d]
    l2 = _List[e,f]
    l3 = _List[g,h]
    @two_by_four = _List[l0, l1, l2, l3]
    @two_by_four_els = [l0, l1, l2, l3, a, b, c, d, e, f, g, h]

    # [a, [b,c], [d, [e], [], [[]]]]
    a, b, c, d, e = 5.of{C::Int.new}
    l1  = _List[b,c]
    l21 = _List[e]
    l22 = _List[]
    l230 = _List[]
    l23 = _List[l230]
    l2  = _List[d, l21, l22, l23]
    @big = _List[a, l1, l2]
    @big_els = [l1, l2, l21, l22, l23, l230, a, b, c, d, e]
  end

  attr_accessor *%w[empty empty_els
                    one   one_els
                    two   two_els
                    three three_els
                    four  four_els
                    two_by_four two_by_four_els
                    big   big_els
                   ]
end

module NodeListInitializeTest
  include NodeListTest
  def test_initialize
    list = _List.new
    assert_equal(0, list.length)
  end

  def test_from_attached
    a1, a2, a3, a4 = 4.of{C::Int.new}
    a = _List[a1, a2, a3, a4]

    b = _List[a1, a2, a3, a4]
    assert_same_list([a1, a2, a3, a4], a)
    assert_equal(4, b.length)
    assert_copy(a1, b[0])
    assert_copy(a2, b[1])
    assert_copy(a3, b[2])
    assert_copy(a4, b[3])
  end
end

#
# Tests dup, clone.
#
module NodeListCopyTest
  include NodeListTest
  def test_copy
    # empty
    a = empty
    b = empty.dup
    c = empty.clone
    #
    assert_copy a, b
    #
    assert_copy a, c

    # one
    a = one
    b = one.dup
    c = one.clone
    #
    assert_copy a, b
    assert_copy a[0], b[0]
    #
    assert_copy a, c
    assert_copy a[0], c[0]

    # two
    a = two
    b = two.dup
    c = two.clone
    #
    assert_copy a, b
    assert_copy a[0], b[0]
    assert_copy a[1], b[1]
    #
    assert_copy a, c
    assert_copy a[0], c[0]
    assert_copy a[1], c[1]

    # three
    a = three
    b = three.dup
    c = three.clone
    #
    assert_copy a, b
    assert_copy a[0], b[0]
    assert_copy a[1], b[1]
    assert_copy a[2], b[2]
    #
    assert_copy a, c
    assert_copy a[0], c[0]
    assert_copy a[1], c[1]
    assert_copy a[2], c[2]

    # four
    a = four
    b = four.dup
    c = four.clone
    #
    assert_copy a, b
    assert_copy a[0], b[0]
    assert_copy a[1], b[1]
    assert_copy a[2], b[2]
    assert_copy a[3], b[3]
    #
    assert_copy a, c
    assert_copy a[0], c[0]
    assert_copy a[1], c[1]
    assert_copy a[2], c[2]
    assert_copy a[3], c[3]

    # two_by_four
    a = two_by_four
    b = two_by_four.dup
    c = two_by_four.clone
    #
    assert_copy a, b
    assert_copy a[0], b[0]
    assert_copy a[1], b[1]
    assert_copy a[2], b[2]
    assert_copy a[3], b[3]
    assert_copy a[0][0], b[0][0]
    assert_copy a[0][1], b[0][1]
    assert_copy a[1][0], b[1][0]
    assert_copy a[1][1], b[1][1]
    assert_copy a[2][0], b[2][0]
    assert_copy a[2][1], b[2][1]
    assert_copy a[3][0], b[3][0]
    assert_copy a[3][1], b[3][1]
    #
    assert_copy a, c
    assert_copy a[0], c[0]
    assert_copy a[1], c[1]
    assert_copy a[2], c[2]
    assert_copy a[3], c[3]
    assert_copy a[0][0], c[0][0]
    assert_copy a[0][1], c[0][1]
    assert_copy a[1][0], c[1][0]
    assert_copy a[1][1], c[1][1]
    assert_copy a[2][0], c[2][0]
    assert_copy a[2][1], c[2][1]
    assert_copy a[3][0], c[3][0]
    assert_copy a[3][1], c[3][1]

    # big -- [a, [b,c], [d, [e], [], [[]]]]
    a = big
    b = big.dup
    c = big.clone
    #
    assert_copy a, b
    assert_copy a[0], b[0]
    assert_copy a[1], b[1]
    assert_copy a[2], b[2]
    assert_copy a[1][0], b[1][0]
    assert_copy a[1][1], b[1][1]
    assert_copy a[2][0], b[2][0]
    assert_copy a[2][1], b[2][1]
    assert_copy a[2][1][0], b[2][1][0]
    assert_copy a[2][2], b[2][2]
    assert_copy a[2][3], b[2][3]
    assert_copy a[2][3][0], b[2][3][0]
    #
    assert_copy a, c
    assert_copy a[0], c[0]
    assert_copy a[1], c[1]
    assert_copy a[2], c[2]
    assert_copy a[1][0], c[1][0]
    assert_copy a[1][1], c[1][1]
    assert_copy a[2][0], c[2][0]
    assert_copy a[2][1], c[2][1]
    assert_copy a[2][1][0], c[2][1][0]
    assert_copy a[2][2], c[2][2]
    assert_copy a[2][3], c[2][3]
    assert_copy a[2][3][0], c[2][3][0]
  end
end

#
# Tests ==, eql?, hash.
#
module NodeListEqualTest
  include NodeListTest
  def assert_eq(a, b)
    assert(a == b)
    assert(a.eql?(b))
    assert(a.hash == b.hash)
  end
  def assert_not_eq(a, b)
    assert(!(a == b))
    assert(!a.eql?(b))
  end
  def test_eq
    assert_eq(empty, empty)
    assert_eq(one, one)
    assert_eq(two, two)
    assert_eq(three, three)
    assert_eq(four, four)
    assert_eq(two_by_four, two_by_four)
    assert_eq(big, big)

    assert_not_eq(empty, one)
    assert_not_eq(one, empty)
    assert_not_eq(one, two)
    assert_not_eq(two, one)
    assert_not_eq(two, three)
    assert_not_eq(three, two)

    # []
    empty2 = _List[]
    assert_eq(empty, empty2)

    # [a]
    a = C::Int.new
    one2 = _List[a]
    assert_eq(one, one2)

    # [a, b]
    a, b = 2.of{C::Int.new}
    two2 = _List[a, b]
    assert_eq(two, two2)

    # [a, b, c]
    a, b, c = 3.of{C::Int.new}
    three2 = _List[a, b, c]
    assert_eq(three, three2)

    # [a, b, c, d]
    a, b, c, d = 4.of{C::Int.new}
    four2 = _List[a, b, c, d]
    assert_eq(four, four2)

    # [[a,b], [c,d], [e,f], [g,h]]
    a, b, c, d, e, f, g, h = 8.of{C::Int.new}
    l0 = _List[a,b]
    l1 = _List[c,d]
    l2 = _List[e,f]
    l3 = _List[g,h]
    two_by_four2 = _List[l0, l1, l2, l3]
    assert_eq(two_by_four, two_by_four2)

    # [a, [b,c], [d, [e], [], [[]]]]
    a, b, c, d, e = 5.of{C::Int.new}
    l1  = _List[b,c]
    l21 = _List[e]
    l22 = _List[]
    l230 = _List[]
    l23 = _List[l230]
    l2  = _List[d, l21, l22, l23]
    big2 = _List[a, l1, l2]
    assert_eq(big, big2)
  end
end

module NodeListWalkTest
  include NodeListTest
  #
  # Collect and return the args yielded to `node.send(method)' as an
  # Array, each element of which is an array of args yielded.
  #
  def yields(method, node, exp)
    ret = []
    out = node.send(method) do |*args|
      ret << args
    end
    assert_same(exp, out)
    return ret
  end

  #
  # Assert exp and out are equal, where elements are compared with
  # Array#same_list?.  That is, exp[i].same_list?(out[i]) for all i.
  #
  def assert_equal_yields(exp, out)
    if exp.zip(out).all?{|a,b| a.same_list?(b)}
      assert(true)
    else
      flunk("walk not equal: #{walk_str(out)} (expected #{walk_str(exp)})")
    end
  end
  def walk_str(walk)
    walk.is_a? ::Array or
      raise "walk_str: expected ::Array"
    if walk.empty?
      return '[]'
    else
      s = StringIO.new
      s.puts '['
      walk.each do |(ev, node)|
        nodestr = node.class.name << '(' << node.object_id.to_s << "): " << node.to_s
        if nodestr.length > 70
          nodestr[68..-1] = '...'
        end
        s.puts "    [#{ev.to_s.rjust(10)}, #{nodestr}]"
      end
      s.puts ']'
      return s.string
    end
  end

  # ------------------------------------------------------------------
  #                         each, reverse_each
  # ------------------------------------------------------------------

  def iter_str(iter)
    iter.is_a? ::Array or
      raise "iter_str: expected ::Array"
    if iter.empty?
      return '[]'
    else
      s = StringIO.new
      s.puts '['
      iter.each do |node|
        nodestr = node.class.name << '(' << node.object_id.to_s << "): " << node.to_s
        if nodestr.length > 70
          nodestr[68..-1] = '...'
        end
        s.puts "    #{nodestr}"
      end
      s.puts ']'
      return s.string
    end
  end
  def check_iter(node, exp)
    exp.map!{|n| [n]}

    out = yields(:each, node, node)
    assert_equal_yields exp, out

    out = yields(:reverse_each, node, node)
    exp.reverse!
    assert_equal_yields exp, out
  end

  def test_each
    # empty
    check_iter(empty, [])

    # one
    a = *one_els
    check_iter(one, [a])

    # two
    a, b = *two_els
    check_iter(two, [a, b])

    # three
    a, b, c = *three_els
    check_iter(three, [a, b, c])

    # four
    a, b, c, d = *four_els
    check_iter(four, [a, b, c, d])

    # two_by_four
    l0, l1, l2, l3, a, b, c, d, e, f, g, h = *two_by_four_els
    check_iter(two_by_four, [l0, l1, l2, l3])

    # big
    l1, l2, l21, l22, l23, l230, a, b, c, d, e = *big_els
    check_iter(big, [a, l1, l2])
  end

  # ------------------------------------------------------------------
  #                             each_index
  # ------------------------------------------------------------------

  def test_each_index
    # empty
    assert_equal([], yields(:each_index, empty, empty))

    # one
    assert_equal([[0]], yields(:each_index, one, one))

    # two
    assert_equal([[0], [1]], yields(:each_index, two, two))

    # two_by_four
    assert_equal([[0], [1], [2], [3]], yields(:each_index, two_by_four, two_by_four))

    # big
    assert_equal([[0], [1], [2]], yields(:each_index, big, big))
  end
end

#
# Tests:
#   -- node_before
#   -- node_after
#   -- remove_node
#   -- insert_before
#   -- insert_after
#   -- replace_node
#
module NodeListChildManagementTests
  include NodeListTest
  def check_not_child(list, node)
    n = C::Int.new
    assert_raise(ArgumentError, list.node_before(node))
    assert_raise(ArgumentError, list.node_after(node))
    assert_raise(ArgumentError, list.remove_node(node))
    assert_raise(ArgumentError, list.insert_after(node, n))
    assert_raise(ArgumentError, list.insert_before(node, n))
    assert_raise(ArgumentError, list.replace_node(node, n))
  end

  def check_list(list, *nodes)
    afters = nodes.dup
    afters.shift
    afters.push(nil)

    befores = nodes.dup
    befores.pop
    befores.unshift(nil)

    assert_equal(list.length, nodes.length)
    nodes.each_index do |i|
      assert_same(nodes[i], list[i], "at index #{i}")
      assert_same(list, nodes[i].parent, "at index #{i}")
      # node_after
      assert_same(afters[i], list.node_after(nodes[i]), "at index #{i} (expected id=#{afters[i].object_id}, got id=#{list.node_after(nodes[i]).object_id})")
      # node_before
      assert_same(befores[i], list.node_before(nodes[i]), "at index #{i}")
    end
  end

  # ------------------------------------------------------------------
  #                    insert_before, insert_after
  # ------------------------------------------------------------------

  def test_insert_one_into_one
    a1, a2 = 2.of{C::Int.new}
    b1, b2 = 2.of{C::Int.new}
    a = _List[a1]
    b = _List[b1]

    # beginning
    assert_same(b, b.insert_before(b1, b2))
    check_list(b, b2, b1)

    # end
    assert_same(a, a.insert_after(a1, a2))
    check_list(a, a1, a2)
  end

  def test_insert_two_into_one
    a1, a2, a3 = 3.of{C::Int.new}
    b1, b2, b3 = 3.of{C::Int.new}
    a = _List[a1]
    b = _List[b1]

    # beginning
    assert_same(a, a.insert_before(a1, a2, a3))
    check_list(a, a2, a3, a1)

    # end
    assert_same(b, b.insert_after(b1, b2, b3))
    check_list(b, b1, b2, b3)
  end

  def test_insert_three_into_one
    a1, a2, a3, a4 = 4.of{C::Int.new}
    b1, b2, b3, b4 = 4.of{C::Int.new}
    a = _List[a1]
    b = _List[b1]

    # beginning
    assert_same(a, a.insert_before(a1, a2, a3, a4))
    check_list(a, a2, a3, a4, a1)

    # end
    assert_same(b, b.insert_after(b1, b2, b3, b4))
    check_list(b, b1, b2, b3, b4)
  end

  def test_insert_many_into_one
    a1, a2, a3, a4, a5 = 5.of{C::Int.new}
    b1, b2, b3, b4, b5 = 5.of{C::Int.new}
    a = _List[a1]
    b = _List[b1]

    # beginning
    assert_same(a, a.insert_before(a1, a2, a3, a4, a5))
    check_list(a, a2, a3, a4, a5, a1)

    # end
    assert_same(b, b.insert_after(b1, b2, b3, b4, b5))
    check_list(b, b1, b2, b3, b4, b5)
  end

  def insert_one_into_two
    a1, a2, a3 = 3.of{C::Int.new}
    b1, b2, b3 = 3.of{C::Int.new}
    c1, c2, c3 = 3.of{C::Int.new}
    d1, d2, d3 = 3.of{C::Int.new}
    a = _List[a1, a2]
    b = _List[b1, b2]
    c = _List[c1, c2]
    d = _List[d1, d2]

    # beginning
    assert_same(a, a.insert_before(a1, a3))
    check_list(a, a3, a1, a2)

    # end
    assert_same(b, b.insert_after(b2, b3))
    check_list(b, b1, b2, b3)

    # middle (after)
    assert_same(c, c.insert_after(c1, c3))
    check_list(c, c1, c3, c2)

    # middle (before)
    assert_same(d, d.insert_before(d2, d3))
    check_list(d, d1, d3, d2)
  end

  def test_insert_two_into_two
    a1, a2, a3, a4 = 4.of{C::Int.new}
    b1, b2, b3, b4 = 4.of{C::Int.new}
    c1, c2, c3, c4 = 4.of{C::Int.new}
    d1, d2, d3, d4 = 4.of{C::Int.new}
    a = _List[a1, a2]
    b = _List[b1, b2]
    c = _List[c1, c2]
    d = _List[d1, d2]

    # beginning
    assert_same(a, a.insert_before(a1, a3, a4))
    check_list(a, a3, a4, a1, a2)

    # end
    assert_same(b, b.insert_after(b2, b3, b4))
    check_list(b, b1, b2, b3, b4)

    # middle (after)
    assert_same(c, c.insert_after(c1, c3, c4))
    check_list(c, c1, c3, c4, c2)

    # middle (before)
    assert_same(d, d.insert_before(d2, d3, d4))
    check_list(d, d1, d3, d4, d2)
  end

  def test_insert_three_into_two
    a1, a2, a3, a4, a5 = 5.of{C::Int.new}
    b1, b2, b3, b4, b5 = 5.of{C::Int.new}
    c1, c2, c3, c4, c5 = 5.of{C::Int.new}
    d1, d2, d3, d4, d5 = 5.of{C::Int.new}
    a = _List[a1, a2]
    b = _List[b1, b2]
    c = _List[c1, c2]
    d = _List[d1, d2]

    # beginning
    assert_same(a, a.insert_before(a1, a3, a4, a5))
    check_list(a, a3, a4, a5, a1, a2)

    # end
    assert_same(b, b.insert_after(b2, b3, b4, b5))
    check_list(b, b1, b2, b3, b4, b5)

    # middle (after)
    assert_same(c, c.insert_after(c1, c3, c4, c5))
    check_list(c, c1, c3, c4, c5, c2)

    # middle (before)
    assert_same(d, d.insert_before(d2, d3, d4, d5))
    check_list(d, d1, d3, d4, d5, d2)
  end

  def test_insert_many_into_two
    a1, a2, a3, a4, a5, a6 = 6.of{C::Int.new}
    b1, b2, b3, b4, b5, b6 = 6.of{C::Int.new}
    c1, c2, c3, c4, c5, c6 = 6.of{C::Int.new}
    d1, d2, d3, d4, d5, d6 = 6.of{C::Int.new}
    a = _List[a1, a2]
    b = _List[b1, b2]
    c = _List[c1, c2]
    d = _List[d1, d2]

    # beginning
    assert_same(a, a.insert_before(a1, a3, a4, a5, a6))
    check_list(a, a3, a4, a5, a6, a1, a2)

    # end
    assert_same(b, b.insert_after(b2, b3, b4, b5, b6))
    check_list(b, b1, b2, b3, b4, b5, b6)

    # middle (after)
    assert_same(c, c.insert_after(c1, c3, c4, c5, c6))
    check_list(c, c1, c3, c4, c5, c6, c2)

    # middle (before)
    assert_same(d, d.insert_before(d2, d3, d4, d5, d6))
    check_list(d, d1, d3, d4, d5, d6, d2)
  end

  def test_insert_attached
    # one (before)
    a1 = C::Int.new
    b1 = C::Int.new
    a = _List[a1]
    b = _List[b1]
    assert_same(a, a.insert_before(a1, b1))
    assert_same_list([b1], b)
    assert_equal(2, a.length)
    assert_copy(b1, a[0])
    assert_same(a1, a[1])

    # one (after)
    a1 = C::Int.new
    b1 = C::Int.new
    a = _List[a1]
    b = _List[b1]
    assert_same(a, a.insert_after(a1, b1))
    assert_same_list([b1], b)
    assert_equal(2, a.length)
    assert_same(a1, a[0])
    assert_copy(b1, a[1])

    # many (before)
    a1 = C::Int.new
    b1, b2, b3, b4 = 4.of{C::Int.new}
    a = _List[a1]
    b = _List[b1, b2, b3, b4]
    assert_same(a, a.insert_before(a1, b1, b2, b3, b4))
    assert_same_list([b1, b2, b3, b4], b)
    assert_equal(5, a.length)
    assert_copy(b1, a[0])
    assert_copy(b2, a[1])
    assert_copy(b3, a[2])
    assert_copy(b4, a[3])
    assert_same(a1, a[4])

    # many (after)
    a1 = C::Int.new
    b1, b2, b3, b4 = 4.of{C::Int.new}
    a = _List[a1]
    b = _List[b1, b2, b3, b4]
    assert_same(a, a.insert_after(a1, b1, b2, b3, b4))
    assert_same_list([b1, b2, b3, b4], b)
    assert_equal(5, a.length)
    assert_same(a1, a[0])
    assert_copy(b1, a[1])
    assert_copy(b2, a[2])
    assert_copy(b3, a[3])
    assert_copy(b4, a[4])
  end

  # ------------------------------------------------------------------
  #                            remove_node
  # ------------------------------------------------------------------

  def test_remove_one_from_one
    a1 = C::Int.new
    a = _List[a1]

    assert_same(a, a.remove_node(a1))
    check_list(a)
    assert_nil(a1.parent)
  end

  def test_remove_one_from_two
    a1, a2 = 2.of{C::Int.new}
    b1, b2 = 2.of{C::Int.new}
    a = _List[a1, a2]
    b = _List[b1, b2]

    # beginning
    assert_same(a, a.remove_node(a1))
    check_list(a, a2)
    assert_nil(a1.parent)

    # end
    assert_same(b, b.remove_node(b2))
    check_list(b, b1)
    assert_nil(b2.parent)
  end

  def test_remove_one_from_three
    a1, a2, a3 = 3.of{C::Int.new}
    b1, b2, b3 = 3.of{C::Int.new}
    c1, c2, c3 = 3.of{C::Int.new}
    a = _List[a1, a2, a3]
    b = _List[b1, b2, b3]
    c = _List[c1, c2, c3]

    # beginning
    assert_same(a, a.remove_node(a1))
    check_list(a, a2, a3)
    assert_nil(a1.parent)

    # end
    assert_same(b, b.remove_node(b3))
    check_list(b, b1, b2)
    assert_nil(b3.parent)

    # middle
    assert_same(c, c.remove_node(c2))
    check_list(c, c1, c3)
    assert_nil(c2.parent)
  end

  def test_remove_one_from_many
    a1, a2, a3, a4 = 4.of{C::Int.new}
    b1, b2, b3, b4 = 4.of{C::Int.new}
    c1, c2, c3, c4 = 4.of{C::Int.new}

    a = _List[a1, a2, a3, a4]
    b = _List[b1, b2, b3, b4]
    c = _List[c1, c2, c3, c4]

    # beginning
    assert_same(a, a.remove_node(a1))
    check_list(a, a2, a3, a4)
    assert_nil(a1.parent)

    # end
    assert_same(b, b.remove_node(b4))
    check_list(b, b1, b2, b3)
    assert_nil(b4.parent)

    # middle
    assert_same(c, c.remove_node(c2))
    check_list(c, c1, c3, c4)
    assert_nil(c2.parent)
  end

  # ------------------------------------------------------------------
  #                            replace_node
  # ------------------------------------------------------------------

  def test_replace_with_none_in_one
    a1 = C::Int.new
    a = _List[a1]
    assert_same(a, a.replace_node(a1))
    check_list(a)
    assert_nil(a1.parent)
  end

  def test_replace_with_none_in_two
    a1, a2 = 2.of{C::Int.new}
    b1, b2 = 2.of{C::Int.new}
    a = _List[a1, a2]
    b = _List[b1, b2]

    # beginning
    assert_same(a, a.replace_node(a1))
    check_list(a, a2)
    assert_nil(a1.parent)

    # end
    assert_same(b, b.replace_node(b2))
    check_list(b, b1)
    assert_nil(b2.parent)
  end

  def test_replace_with_none_in_three
    a1, a2, a3 = 3.of{C::Int.new}
    b1, b2, b3 = 3.of{C::Int.new}
    c1, c2, c3 = 3.of{C::Int.new}
    a = _List[a1, a2, a3]
    b = _List[b1, b2, b3]
    c = _List[c1, c2, c3]

    # beginning
    assert_same(a, a.replace_node(a1))
    check_list(a, a2, a3)
    assert_nil(a1.parent)

    # end
    assert_same(b, b.replace_node(b3))
    check_list(b, b1, b2)
    assert_nil(b3.parent)

    # middle
    assert_same(c, c.replace_node(c2))
    check_list(c, c1, c3)
    assert_nil(c2.parent)
  end

  def test_replace_with_one_in_one
    a1, a2 = 2.of{C::Int.new}
    a = _List[a1]

    assert_same(a, a.replace_node(a1, a2))
    check_list(a, a2)
    assert_nil(a1.parent)
  end

  def test_replace_with_one_in_two
    a1, a2, a3 = 3.of{C::Int.new}
    b1, b2, b3 = 3.of{C::Int.new}
    a = _List[a1, a2]
    b = _List[b1, b2]

    # beginning
    assert_same(a, a.replace_node(a1, a3))
    check_list(a, a3, a2)
    assert_nil(a1.parent)

    # end
    assert_same(b, b.replace_node(b2, b3))
    check_list(b, b1, b3)
    assert_nil(b2.parent)
  end

  def test_replace_with_one_in_three
    a1, a2, a3, a4 = 4.of{C::Int.new}
    b1, b2, b3, b4 = 4.of{C::Int.new}
    c1, c2, c3, c4 = 4.of{C::Int.new}
    a = _List[a1, a2, a3]
    b = _List[b1, b2, b3]
    c = _List[c1, c2, c3]

    # beginning
    assert_same(a, a.replace_node(a1, a4))
    check_list(a, a4, a2, a3)
    assert_nil(a1.parent)

    # end
    assert_same(b, b.replace_node(b3, b4))
    check_list(b, b1, b2, b4)
    assert_nil(b3.parent)

    # middle
    assert_same(c, c.replace_node(c2, c4))
    check_list(c, c1, c4, c3)
    assert_nil(c2.parent)
  end

  def test_replace_with_two_in_one
    a1, a2, a3 = 3.of{C::Int.new}
    a = _List[a1]

    assert_same(a, a.replace_node(a1, a2, a3))
    check_list(a, a2, a3)
    assert_nil(a1.parent)
  end

  def test_replace_with_two_in_two
    a1, a2, a3, a4 = 4.of{C::Int.new}
    b1, b2, b3, b4 = 4.of{C::Int.new}
    a = _List[a1, a2]
    b = _List[b1, b2]

    # beginning
    assert_same(a, a.replace_node(a1, a3, a4))
    check_list(a, a3, a4, a2)
    assert_nil(a1.parent)

    # end
    assert_same(b, b.replace_node(b2, b3, b4))
    check_list(b, b1, b3, b4)
    assert_nil(b2.parent)
  end

  def test_replace_with_two_in_three
    a1, a2, a3, a4, a5 = 5.of{C::Int.new}
    b1, b2, b3, b4, b5 = 5.of{C::Int.new}
    c1, c2, c3, c4, c5 = 5.of{C::Int.new}
    a = _List[a1, a2, a3]
    b = _List[b1, b2, b3]
    c = _List[c1, c2, c3]

    # beginning
    assert_same(a, a.replace_node(a1, a4, a5))
    check_list(a, a4, a5, a2, a3)
    assert_nil(a1.parent)

    # end
    assert_same(b, b.replace_node(b3, b4, b5))
    check_list(b, b1, b2, b4, b5)
    assert_nil(b3.parent)

    # middle
    assert_same(c, c.replace_node(c2, c4, c5))
    check_list(c, c1, c4, c5, c3)
    assert_nil(c2.parent)
  end

  def test_replace_with_three_in_one
    a1, a2, a3, a4 = 4.of{C::Int.new}
    a = _List[a1]

    assert_same(a, a.replace_node(a1, a2, a3, a4))
    check_list(a, a2, a3, a4)
    assert_nil(a1.parent)
  end

  def test_replace_with_three_in_two
    a1, a2, a3, a4, a5 = 5.of{C::Int.new}
    b1, b2, b3, b4, b5 = 5.of{C::Int.new}
    a = _List[a1, a2]
    b = _List[b1, b2]

    # beginning
    assert_same(a, a.replace_node(a1, a3, a4, a5))
    check_list(a, a3, a4, a5, a2)
    assert_nil(a1.parent)

    # end
    assert_same(b, b.replace_node(b2, b3, b4, b5))
    check_list(b, b1, b3, b4, b5)
    assert_nil(b2.parent)
  end

  def test_replace_with_three_in_three
    a1, a2, a3, a4, a5, a6 = 6.of{C::Int.new}
    b1, b2, b3, b4, b5, b6 = 6.of{C::Int.new}
    c1, c2, c3, c4, c5, c6 = 6.of{C::Int.new}
    a = _List[a1, a2, a3]
    b = _List[b1, b2, b3]
    c = _List[c1, c2, c3]

    # beginning
    assert_same(a, a.replace_node(a1, a4, a5, a6))
    check_list(a, a4, a5, a6, a2, a3)
    assert_nil(a1.parent)

    # end
    assert_same(b, b.replace_node(b3, b4, b5, b6))
    check_list(b, b1, b2, b4, b5, b6)
    assert_nil(b3.parent)

    # middle
    assert_same(c, c.replace_node(c2, c4, c5, c6))
    check_list(c, c1, c4, c5, c6, c3)
    assert_nil(c2.parent)
  end

  def test_replace_with_many_in_one
    a1, a2, a3, a4, a5 = 5.of{C::Int.new}
    a = _List[a1]

    assert_same(a, a.replace_node(a1, a2, a3, a4, a5))
    check_list(a, a2, a3, a4, a5)
    assert_nil(a1.parent)
  end

  def test_replace_with_many_in_two
    a1, a2, a3, a4, a5, a6 = 6.of{C::Int.new}
    b1, b2, b3, b4, b5, b6 = 6.of{C::Int.new}
    a = _List[a1, a2]
    b = _List[b1, b2]

    # beginning
    assert_same(a, a.replace_node(a1, a3, a4, a5, a6))
    check_list(a, a3, a4, a5, a6, a2)
    assert_nil(a1.parent)

    # end
    assert_same(b, b.replace_node(b2, b3, b4, b5, b6))
    check_list(b, b1, b3, b4, b5, b6)
    assert_nil(b2.parent)
  end

  def test_replace_with_many_in_three
    a1, a2, a3, a4, a5, a6, a7 = 7.of{C::Int.new}
    b1, b2, b3, b4, b5, b6, b7 = 7.of{C::Int.new}
    c1, c2, c3, c4, c5, c6, c7 = 7.of{C::Int.new}
    a = _List[a1, a2, a3]
    b = _List[b1, b2, b3]
    c = _List[c1, c2, c3]

    # beginning
    assert_same(a, a.replace_node(a1, a4, a5, a6, a7))
    check_list(a, a4, a5, a6, a7, a2, a3)
    assert_nil(a1.parent)

    # end
    assert_same(b, b.replace_node(b3, b4, b5, b6, b7))
    check_list(b, b1, b2, b4, b5, b6, b7)
    assert_nil(b3.parent)

    # middle
    assert_same(c, c.replace_node(c2, c4, c5, c6, c7))
    check_list(c, c1, c4, c5, c6, c7, c3)
    assert_nil(c2.parent)
  end

  def test_replace_with_attached
    # one
    a1 = C::Int.new
    a = _List[a1]
    b1 = C::Int.new
    b = _List[b1]
    assert_same(a, a.replace_node(a1, b1))
    assert_copy(b1, a[0])
    assert_nil(a1.parent)

    # many
    a1 = C::Int.new
    a = _List[a1]
    b1, b2, b3, b4 = 4.of{C::Int.new}
    b = _List[b1, b2, b3, b4]
    assert_same(a, a.replace_node(a1, b1, b2, b3, b4))
    assert_copy(b1, a[0])
    assert_copy(b2, a[1])
    assert_copy(b3, a[2])
    assert_copy(b4, a[3])
    assert_nil(a1.parent)
  end

  def test_replace_with_duplicated
    # one
    a1, a2 = 2.of{C::Int.new}
    a = _List[a1]
    assert_same(a, a.replace_node(a1, a2, a2))
    assert_same(2, a.length)
    assert_same(a2, a[0])
    assert_copy(a2, a[1])

    # many
    a1, a2, a3, a4 = 4.of{C::Int.new}
    a = _List[a1, a2, a3]
    assert_same(a, a.replace_node(a1, a2, a4, a2, a4))
    assert_same(6, a.length)
    assert_copy(a2, a[0])
    assert_same(a4, a[1])
    assert_copy(a2, a[2])
    assert_copy(a4, a[3])
    assert_same(a2, a[4])
    assert_same(a3, a[5])
  end

  def test_replace_with_replaced
    # one
    a1 = C::Int.new
    a = _List[a1]
    assert_same(a, a.replace_node(a1, a1))
    assert_same_list([a1], a)

    # many -- some are the replaced node
    a1, a2, a3 = 3.of{C::Int.new}
    a = _List[a1]
    assert_same(a, a.replace_node(a1, a1, a2, a3, a1))
    assert_same(4, a.length)
    assert_same(a1, a[0])
    assert_same(a2, a[1])
    assert_same(a3, a[2])
    assert_copy(a1, a[3])

    # many -- all are the replaced node
    a1 = C::Int.new
    a = _List[a1]
    assert_same(a, a.replace_node(a1, a1, a1, a1))
    assert_same(3, a.length)
    assert_same(a1, a[0])
    assert_copy(a1, a[1])
    assert_copy(a1, a[2])
  end
end

module NodeListArrayQueryTests
  include NodeListTest

  # ------------------------------------------------------------------
  #                            first, last
  # ------------------------------------------------------------------

  def test_first
    # empty
    a = _List[]
    assert_nil(a.first)

    # one
    a1 = C::Int.new
    a = _List[a1]
    assert_same(a1, a.first)
    assert_same_list([  ], a.first(0))
    assert_same_list([a1], a.first(1))
    assert_same_list([a1], a.first(2))

    # two
    a1, a2 = 2.of{C::Int.new}
    a = _List[a1, a2]
    assert_same(a1, a.first)
    assert_same_list([      ], a.first(0))
    assert_same_list([a1    ], a.first(1))
    assert_same_list([a1, a2], a.first(2))
    assert_same_list([a1, a2], a.first(3))

    # three
    ret = a.first(3)
    a1, a2, a3 = 3.of{C::Int.new}
    a = _List[a1, a2, a3]
    assert_same(a1, a.first)
    assert_same_list([          ], a.first(0))
    assert_same_list([a1        ], a.first(1))
    assert_same_list([a1, a2    ], a.first(2))
    assert_same_list([a1, a2, a3], a.first(3))
    assert_same_list([a1, a2, a3], a.first(4))

    # negative array size
    assert_raise(ArgumentError){a.first(-1)}
  end

  def test_last
    # empty
    a = _List[]
    assert_nil(a.last)

    # one
    a1 = C::Int.new
    a = _List[a1]
    assert_same(a1, a.last)
    assert_same_list([  ], a.last(0))
    assert_same_list([a1], a.last(1))
    assert_same_list([a1], a.last(2))

    # two
    a1, a2 = 2.of{C::Int.new}
    a = _List[a1, a2]
    assert_same(a2, a.last)
    assert_same_list([      ], a.last(0))
    assert_same_list([    a2], a.last(1))
    assert_same_list([a1, a2], a.last(2))
    assert_same_list([a1, a2], a.last(3))

    # three
    ret = a.last(3)
    a1, a2, a3 = 3.of{C::Int.new}
    a = _List[a1, a2, a3]
    assert_same(a3, a.last)
    assert_same_list([          ], a.last(0))
    assert_same_list([        a3], a.last(1))
    assert_same_list([    a2, a3], a.last(2))
    assert_same_list([a1, a2, a3], a.last(3))
    assert_same_list([a1, a2, a3], a.last(4))

    # negative array size
    assert_raise(ArgumentError){a.last(-1)}
  end

  # ------------------------------------------------------------------
  #                               empty?
  # ------------------------------------------------------------------

  def test_empty
    assert(_List[].empty?)
    assert(!_List[C::Int.new].empty?)
    assert(!_List[_List[]].empty?)
  end

  # ------------------------------------------------------------------
  #                                to_a
  # ------------------------------------------------------------------

  def test_to_a
    # empty
    r = empty.to_a
    assert_same(::Array, r.class)
    assert_same_list([], r)

    # one
    a = *one_els
    r = one.to_a
    assert_same(::Array, r.class)
    assert_same_list([a], r)

    # two
    a, b = *two_els
    r = two.to_a
    assert_same(::Array, r.class)
    assert_same_list([a, b], r)

    # three
    a, b, c = *three_els
    r = three.to_a
    assert_same(::Array, r.class)
    assert_same_list([a, b, c], r)

    # four
    a, b, c, d = *four_els
    r = four.to_a
    assert_same(::Array, r.class)
    assert_same_list([a, b, c, d], r)

    # two_by_four
    l0, l1, l2, l3, a, b, c, d, e, f, g, h = *two_by_four_els
    r = two_by_four.to_a
    assert_same(::Array, r.class)
    assert_same_list([l0, l1, l2, l3], r)

    # big
    l1, l2, l21, l22, l23, l230, a, b, c, d, e = *big_els
    r = big.to_a
    assert_same(::Array, r.class)
    assert_same_list([a, l1, l2], r)
  end

  # ------------------------------------------------------------------
  #                           index, rindex
  # ------------------------------------------------------------------

  def test_index
    # empty
    empty = _List[]
    assert_nil(empty.index(C::Int.new))
    assert_nil(empty.index(nil))
    #
    assert_nil(empty.rindex(C::Int.new))
    assert_nil(empty.rindex(nil))

    # one
    a = C::Int.new(1)
    list = _List[a]
    #
    assert_equal(0, list.index(a))
    assert_equal(0, list.index(C::Int.new(1)))
    assert_nil(list.index(C::Int.new))
    assert_nil(list.index(nil))
    #
    assert_equal(0, list.rindex(a))
    assert_nil(list.rindex(C::Int.new))
    assert_nil(list.rindex(nil))

    # two
    a = C::Int.new(1)
    b = C::Int.new(2)
    list = _List[a, b]
    #
    assert_equal(0, list.index(a))
    assert_equal(1, list.index(b))
    assert_nil(list.index(C::Int.new))
    assert_nil(list.index(nil))
    #
    assert_equal(0, list.rindex(a))
    assert_equal(1, list.rindex(b))
    assert_nil(list.rindex(C::Int.new))
    assert_nil(list.rindex(nil))

    # nested -- [a, [b]]
    a = C::Int.new(1)
    b = C::Int.new(2)
    l1 = _List[b]
    list = _List[a, l1]
    #
    assert_equal(0, list.index(a))
    assert_equal(1, list.index(l1))
    assert_equal(1, list.index(_List[C::Int.new(2)]))
    assert_equal(nil, list.index([b]))
    assert_nil(list.index([a]))
    assert_nil(list.index(C::Int.new))
    assert_nil(list.index(nil))
    #
    assert_equal(0, list.rindex(a))
    assert_equal(1, list.rindex(l1))
    assert_equal(1, list.rindex(_List[b]))
    assert_nil(list.rindex([a]))
    assert_nil(list.rindex(C::Int.new))
    assert_nil(list.rindex(nil))

    # repeated
    a1, a2, a3 = 3.of{C::Int.new(-1)}
    b1, b2, b3 = 3.of{C::Int.new(1)}
    list = _List[a1, b1, a2, b2, a3, b3]
    #
    assert_equal(0, list.index(a1))
    assert_equal(0, list.index(a2))
    assert_equal(0, list.index(a3))
    assert_equal(1, list.index(b1))
    assert_equal(1, list.index(b2))
    assert_equal(1, list.index(b3))
    assert_nil(list.index(C::Int.new))
    assert_nil(list.index(nil))
    #
    assert_equal(4, list.rindex(a1))
    assert_equal(4, list.rindex(a2))
    assert_equal(4, list.rindex(a3))
    assert_equal(5, list.rindex(b1))
    assert_equal(5, list.rindex(b2))
    assert_equal(5, list.rindex(b3))
    assert_nil(list.rindex(C::Int.new))
    assert_nil(list.rindex(nil))
  end

  # ------------------------------------------------------------------
  #                             values_at
  # ------------------------------------------------------------------

  def test_values_at
    # empty
    assert_same_list([], empty.values_at())
    assert_same_list([nil], empty.values_at(1))
    assert_same_list([nil], empty.values_at(-1))

    # one
    a = *one_els
    assert_same_list([], one.values_at())
    assert_same_list([a], one.values_at(0))
    assert_same_list([a], one.values_at(-1))
    assert_same_list([nil, a], one.values_at(1, -1))

    # big -- [a, [b,c], [d, [e], [], [[]]]]
    l1, l2, l21, l22, l23, l230, a, b, c, d, e = *big_els
    assert_same_list([], big.values_at())
    assert_same_list([l2], big.values_at(-1))
    assert_same_list([a, nil], big.values_at(-3, 3))
    assert_same_list([a, l1, l2], big.values_at(0, -2, -1))
  end

  # ------------------------------------------------------------------
  #                                join
  # ------------------------------------------------------------------

  class N < C::Node
    def initialize(s)
      @s = s
    end
    def to_s
      @s.dup
    end
  end
  def test_join
    # empty
    list = _List[]
    assert_equal('', list.join)
    assert_equal('', list.join('.'))

    # one
    a = N.new('a')
    list = _List[a]
    assert_equal('a', list.join)
    assert_equal('a', list.join('.'))

    # two
    a = N.new('a')
    b = N.new('b')
    list = _List[a, b]
    assert_equal('ab', list.join)
    assert_equal('a.b', list.join('.'))

    # two_by_two
    a = N.new('a')
    b = N.new('b')
    c = N.new('c')
    d = N.new('d')
    l0 = _List[a, b]
    l1 = _List[c, d]
    list = _List[l0, l1]
    assert_equal('a, bc, d', list.join)
    assert_equal('a, b|c, d', list.join('|'))
  end
end

module NodeListModifierTests
  include NodeListTest
  def test_push_none
    # empty
    list = _List[]
    assert_same(list, list.push)
    assert_same_list([], list)

    # one
    a = C::Int.new
    list = _List[a]
    assert_same(list, list.push)
    assert_same_list([a], list)

    # two
    a, b = 2.of{C::Int.new}
    list = _List[a, b]
    assert_same(list, list.push)
    assert_same_list([a, b], list)

    # three
    a, b, c = 3.of{C::Int.new}
    list = _List[a, b, c]
    assert_same(list, list.push)
    assert_same_list([a, b, c], list)
  end

  def test_push_one
    # empty
    a = C::Int.new
    list = _List[]
    assert_same(list, list.push(a))
    assert_same_list([a], list)

    # one
    a, b = 2.of{C::Int.new}
    list = _List[a]
    assert_same(list, list.push(b))
    assert_same_list([a, b], list)

    # two
    a, b, c = 3.of{C::Int.new}
    list = _List[a, b]
    assert_same(list, list.push(c))
    assert_same_list([a, b, c], list)

    # three
    a, b, c, d = 4.of{C::Int.new}
    list = _List[a, b, c]
    assert_same(list, list.push(d))
    assert_same_list([a, b, c, d], list)
  end

  def test_push_two
    # empty
    a, b = 2.of{C::Int.new}
    list = _List[]
    assert_same(list, list.push(a, b))
    assert_same_list([a, b], list)

    # one
    a, b, c = 3.of{C::Int.new}
    list = _List[a]
    assert_same(list, list.push(b, c))
    assert_same_list([a, b, c], list)

    # two
    a, b, c, d = 4.of{C::Int.new}
    list = _List[a, b]
    assert_same(list, list.push(c, d))
    assert_same_list([a, b, c, d], list)

    # three
    a, b, c, d, e = 5.of{C::Int.new}
    list = _List[a, b, c]
    assert_same(list, list.push(d, e))
    assert_same_list([a, b, c, d, e], list)
  end

  def test_push_three
    # empty
    a, b, c = 3.of{C::Int.new}
    list = _List[]
    assert_same(list, list.push(a, b, c))
    assert_same_list([a, b, c], list)

    # one
    a, b, c, d = 4.of{C::Int.new}
    list = _List[a]
    assert_same(list, list.push(b, c, d))
    assert_same_list([a, b, c, d], list)

    # two
    a, b, c, d, e = 5.of{C::Int.new}
    list = _List[a, b]
    assert_same(list, list.push(c, d, e))
    assert_same_list([a, b, c, d, e], list)

    # three
    a, b, c, d, e, f = 6.of{C::Int.new}
    list = _List[a, b, c]
    assert_same(list, list.push(d, e, f))
    assert_same_list([a, b, c, d, e, f], list)
  end

  def test_push_attached
    # one
    a1 = C::Int.new
    b1 = C::Int.new
    a = _List[a1]
    b = _List[b1]
    assert_same(a, a.push(b1))
    assert_same_list([b1], b)
    assert_equal(2, a.length)
    assert_same(a1, a[0])
    assert_copy(b1, a[1])

    # many
    a1 = C::Int.new
    b1, b2, b3, b4 = 4.of{C::Int.new}
    a = _List[a1]
    b = _List[b1, b2, b3, b4]
    assert_same(a, a.push(b1, b2, b3, b4))
    assert_same_list([b1, b2, b3, b4], b)
    assert_equal(5, a.length)
    assert_same(a1, a[0])
    assert_copy(b1, a[1])
    assert_copy(b2, a[2])
    assert_copy(b3, a[3])
    assert_copy(b4, a[4])
  end

  def test_unshift_none
    # empty
    list = _List[]
    assert_same(list, list.unshift)
    assert_same_list([], list)

    # one
    a = C::Int.new
    list = _List[a]
    assert_same(list, list.unshift)
    assert_same_list([a], list)

    # two
    a, b = 2.of{C::Int.new}
    list = _List[a, b]
    assert_same(list, list.unshift)
    assert_same_list([a, b], list)

    # three
    a, b, c = 3.of{C::Int.new}
    list = _List[a, b, c]
    assert_same(list, list.unshift)
    assert_same_list([a, b, c], list)
  end

  def test_unshift_one
    # empty
    a = C::Int.new
    list = _List[]
    assert_same(list, list.unshift(a))
    assert_same_list([a], list)

    # one
    a, b = 2.of{C::Int.new}
    list = _List[a]
    assert_same(list, list.unshift(b))
    assert_same_list([b, a], list)

    # two
    a, b, c = 3.of{C::Int.new}
    list = _List[a, b]
    assert_same(list, list.unshift(c))
    assert_same_list([c, a, b], list)

    # three
    a, b, c, d = 4.of{C::Int.new}
    list = _List[a, b, c]
    assert_same(list, list.unshift(d))
    assert_same_list([d, a, b, c], list)
  end

  def test_unshift_two
    # empty
    a, b = 2.of{C::Int.new}
    list = _List[]
    assert_same(list, list.unshift(a, b))
    assert_same_list([a, b], list)

    # one
    a, b, c = 3.of{C::Int.new}
    list = _List[a]
    assert_same(list, list.unshift(b, c))
    assert_same_list([b, c, a], list)

    # two
    a, b, c, d = 4.of{C::Int.new}
    list = _List[a, b]
    assert_same(list, list.unshift(c, d))
    assert_same_list([c, d, a, b], list)

    # three
    a, b, c, d, e = 5.of{C::Int.new}
    list = _List[a, b, c]
    assert_same(list, list.unshift(d, e))
    assert_same_list([d, e, a, b, c], list)
  end

  def test_unshift_three
    # empty
    a, b, c = 3.of{C::Int.new}
    list = _List[]
    assert_same(list, list.unshift(a, b, c))
    assert_same_list([a, b, c], list)

    # one
    a, b, c, d = 4.of{C::Int.new}
    list = _List[a]
    assert_same(list, list.unshift(b, c, d))
    assert_same_list([b, c, d, a], list)

    # two
    a, b, c, d, e = 5.of{C::Int.new}
    list = _List[a, b]
    assert_same(list, list.unshift(c, d, e))
    assert_same_list([c, d, e, a, b], list)

    # three
    a, b, c, d, e, f = 6.of{C::Int.new}
    list = _List[a, b, c]
    assert_same(list, list.unshift(d, e, f))
    assert_same_list([d, e, f, a, b, c], list)
  end

  def test_unshift_attached
    # one
    a1 = C::Int.new
    b1 = C::Int.new
    a = _List[a1]
    b = _List[b1]
    assert_same(a, a.unshift(b1))
    assert_same_list([b1], b)
    assert_equal(2, a.length)
    assert_copy(b1, a[0])
    assert_same(a1, a[1])

    # many
    a1 = C::Int.new
    b1, b2, b3, b4 = 4.of{C::Int.new}
    a = _List[a1]
    b = _List[b1, b2, b3, b4]
    assert_same(a, a.unshift(b1, b2, b3, b4))
    assert_same_list([b1, b2, b3, b4], b)
    assert_equal(5, a.length)
    assert_copy(b1, a[0])
    assert_copy(b2, a[1])
    assert_copy(b3, a[2])
    assert_copy(b4, a[3])
    assert_same(a1, a[4])
  end

  def test_pop
    # empty
    list = _List[]
    assert_same(nil, list.pop)
    assert_same_list([], list)

    # one
    a = C::Int.new
    list = _List[a]
    assert_same(a, list.pop)
    assert_same_list([], list)
    assert_nil(a.parent)

    # two
    a, b = 2.of{C::Int.new}
    list = _List[a, b]
    assert_same(b, list.pop)
    assert_same_list([a], list)
    assert_nil(b.parent)

    # three
    a, b, c = 3.of{C::Int.new}
    list = _List[a, b, c]
    assert_same(c, list.pop)
    assert_same_list([a, b], list)
    assert_nil(c.parent)
  end

  def test_pop_none
    # empty
    list = _List[]
    ret = list.pop(0)
    assert_same_list([], ret)
    assert_same_list([], list)

    # one
    a = C::Int.new
    list = _List[a]
    ret = list.pop(0)
    assert_same_list([], ret)
    assert_same_list([a], list)

    # two
    a, b = 2.of{C::Int.new}
    list = _List[a, b]
    ret = list.pop(0)
    assert_same_list([], ret)
    assert_same_list([a, b], list)

    # three
    a, b, c = 3.of{C::Int.new}
    list = _List[a, b, c]
    ret = list.pop(0)
    assert_same_list([], ret)
    assert_same_list([a, b, c], list)
  end

  def test_pop_one
    # empty
    list = _List[]
    ret = list.pop(1)
    assert_same_list([], ret)
    assert_same_list([], list)

    # one
    a = C::Int.new
    list = _List[a]
    ret = list.pop(1)
    assert_same_list([a], ret)
    assert_same_list([], list)
    assert_nil(a.parent)

    # two
    a, b = 2.of{C::Int.new}
    list = _List[a, b]
    ret = list.pop(1)
    assert_same_list([b], ret)
    assert_same_list([a], list)
    assert_nil(b.parent)

    # three
    a, b, c = 3.of{C::Int.new}
    list = _List[a, b, c]
    ret = list.pop(1)
    assert_same_list([c], ret)
    assert_same_list([a, b], list)
    assert_nil(c.parent)
  end

  def test_pop_two
    # empty
    list = _List[]
    ret = list.pop(2)
    assert_same_list([], ret)
    assert_same_list([], list)

    # one
    a = C::Int.new
    list = _List[a]
    ret = list.pop(2)
    assert_same_list([a], ret)
    assert_same_list([], list)
    assert_nil(a.parent)

    # two
    a, b = 2.of{C::Int.new}
    list = _List[a, b]
    ret = list.pop(2)
    assert_same_list([a, b], ret)
    assert_same_list([], list)
    assert_nil(a.parent)
    assert_nil(b.parent)

    # three
    a, b, c = 3.of{C::Int.new}
    list = _List[a, b, c]
    ret = list.pop(2)
    assert_same_list([b, c], ret)
    assert_same_list([a], list)
    assert_nil(b.parent)
    assert_nil(c.parent)
  end

  def test_pop_bad
    # too many args
    a, b = 2.of{C::Int.new}
    list = _List[a, b]
    assert_raise(ArgumentError){list.pop(1, 2)}
    assert_same_list([a, b], list)
    assert_same(list, a.parent)
    assert_same(list, b.parent)
  end

  def test_shift
    # empty
    list = _List[]
    ret = list.shift
    assert_nil(ret)
    assert_same_list([], list)

    # one
    a = C::Int.new
    list = _List[a]
    ret = list.shift
    assert_same(a, ret)
    assert_same_list([], list)
    assert_nil(a.parent)

    # two
    a, b = 2.of{C::Int.new}
    list = _List[a, b]
    ret = list.shift
    assert_same(a, ret)
    assert_same_list([b], list)
    assert_nil(a.parent)

    # three
    a, b, c = 3.of{C::Int.new}
    list = _List[a, b, c]
    ret = list.shift
    assert_same(a, ret)
    assert_same_list([b, c], list)
    assert_nil(a.parent)
  end

  def test_shift_none
    # empty
    list = _List[]
    ret = list.shift(0)
    assert_same_list([], ret)
    assert_same_list([], list)

    # one
    a = C::Int.new
    list = _List[a]
    ret = list.shift(0)
    assert_same_list([], ret)
    assert_same_list([a], list)

    # two
    a, b = 2.of{C::Int.new}
    list = _List[a, b]
    ret = list.shift(0)
    assert_same_list([], ret)
    assert_same_list([a, b], list)

    # three
    a, b, c = 3.of{C::Int.new}
    list = _List[a, b, c]
    ret = list.shift(0)
    assert_same_list([], ret)
    assert_same_list([a, b, c], list)
  end

  def test_shift_one
    # empty
    list = _List[]
    ret = list.shift(1)
    assert_same_list([], ret)
    assert_same_list([], list)

    # one
    a = C::Int.new
    list = _List[a]
    ret = list.shift(1)
    assert_same_list([a], ret)
    assert_same_list([], list)
    assert_nil(a.parent)

    # two
    a, b = 2.of{C::Int.new}
    list = _List[a, b]
    ret = list.shift(1)
    assert_same_list([a], ret)
    assert_same_list([b], list)
    assert_nil(a.parent)

    # three
    a, b, c = 3.of{C::Int.new}
    list = _List[a, b, c]
    ret = list.shift(1)
    assert_same_list([a], ret)
    assert_same_list([b, c], list)
    assert_nil(a.parent)
  end

  def test_shift_two
    # empty
    list = _List[]
    ret = list.shift(2)
    assert_same_list([], ret)
    assert_same_list([], list)

    # one
    a = C::Int.new
    list = _List[a]
    ret = list.shift(2)
    assert_same_list([a], ret)
    assert_same_list([], list)
    assert_nil(a.parent)

    # two
    a, b = 2.of{C::Int.new}
    list = _List[a, b]
    ret = list.shift(2)
    assert_same_list([a, b], ret)
    assert_same_list([], list)
    assert_nil(a.parent)
    assert_nil(b.parent)

    # three
    a, b, c = 3.of{C::Int.new}
    list = _List[a, b, c]
    ret = list.shift(2)
    assert_same_list([a, b], ret)
    assert_same_list([c], list)
    assert_nil(a.parent)
    assert_nil(b.parent)
  end

  def test_shift_bad
    # too many args
    a, b = 2.of{C::Int.new}
    list = _List[a, b]
    assert_raise(ArgumentError){list.shift(1, 2)}
    assert_same_list([a, b], list)
    assert_same(list, a.parent)
    assert_same(list, b.parent)
  end

  # ------------------------------------------------------------------
  #                               insert
  # ------------------------------------------------------------------

  def test_insert_one_into_one
    a1, a2 = 2.of{C::Int.new}
    b1, b2 = 2.of{C::Int.new}
    a = _List[a1]
    b = _List[b1]

    # beginning
    a.insert(0, a2)
    assert_same_list([a2, a1], a)

    # end
    b.insert(1, b2)
    assert_same_list([b1, b2], b)
  end

  def test_insert_two_into_one
    a1, a2, a3 = 3.of{C::Int.new}
    b1, b2, b3 = 3.of{C::Int.new}
    a = _List[a1]
    b = _List[b1]

    # beginning
    a.insert(0, a2, a3)
    assert_same_list([a2, a3, a1], a)

    # end
    b.insert(1, b2, b3)
    assert_same_list([b1, b2, b3], b)
  end

  def test_insert_three_into_one
    a1, a2, a3, a4 = 4.of{C::Int.new}
    b1, b2, b3, b4 = 4.of{C::Int.new}
    a = _List[a1]
    b = _List[b1]

    # beginning
    a.insert(0, a2, a3, a4)
    assert_same_list([a2, a3, a4, a1], a)

    # end
    b.insert(1, b2, b3, b4)
    assert_same_list([b1, b2, b3, b4], b)
  end

  def test_insert_many_into_one
    a1, a2, a3, a4, a5 = 5.of{C::Int.new}
    b1, b2, b3, b4, b5 = 5.of{C::Int.new}
    a = _List[a1]
    b = _List[b1]

    # beginning
    a.insert(0, a2, a3, a4, a5)
    assert_same_list([a2, a3, a4, a5, a1], a)

    # end
    b.insert(1, b2, b3, b4, b5)
    assert_same_list([b1, b2, b3, b4, b5], b)
  end

  def insert_one_into_two
    a1, a2, a3 = 3.of{C::Int.new}
    b1, b2, b3 = 3.of{C::Int.new}
    c1, c2, c3 = 3.of{C::Int.new}
    a = _List[a1, a2]
    b = _List[b1, b2]
    c = _List[c1, c2]

    # beginning
    a.insert(0, a3)
    assert_same_list([a3, a1, a2], a)

    # end
    b.insert(2, b3)
    assert_same_list([b1, b2, b3], b)

    # middle
    c.insert1(c1, c3)
    assert_same_list([c1, c3, c2], c)
  end

  def test_insert_two_into_two
    a1, a2, a3, a4 = 4.of{C::Int.new}
    b1, b2, b3, b4 = 4.of{C::Int.new}
    c1, c2, c3, c4 = 4.of{C::Int.new}
    d1, d2, d3, d4 = 4.of{C::Int.new}
    a = _List[a1, a2]
    b = _List[b1, b2]
    c = _List[c1, c2]

    # beginning
    a.insert(0, a3, a4)
    assert_same_list([a3, a4, a1, a2], a)

    # end
    b.insert(2, b3, b4)
    assert_same_list([b1, b2, b3, b4], b)

    # middle
    c.insert(1, c3, c4)
    assert_same_list([c1, c3, c4, c2], c)
  end

  def test_insert_three_into_two
    a1, a2, a3, a4, a5 = 5.of{C::Int.new}
    b1, b2, b3, b4, b5 = 5.of{C::Int.new}
    c1, c2, c3, c4, c5 = 5.of{C::Int.new}
    a = _List[a1, a2]
    b = _List[b1, b2]
    c = _List[c1, c2]

    # beginning
    a.insert(0, a3, a4, a5)
    assert_same_list([a3, a4, a5, a1, a2], a)

    # end
    b.insert(2, b3, b4, b5)
    assert_same_list([b1, b2, b3, b4, b5], b)

    # middle
    c.insert(1, c3, c4, c5)
    assert_same_list([c1, c3, c4, c5, c2], c)
  end

  def test_insert_many_into_two
    a1, a2, a3, a4, a5, a6 = 6.of{C::Int.new}
    b1, b2, b3, b4, b5, b6 = 6.of{C::Int.new}
    c1, c2, c3, c4, c5, c6 = 6.of{C::Int.new}
    a = _List[a1, a2]
    b = _List[b1, b2]
    c = _List[c1, c2]

    # beginning
    a.insert(0, a3, a4, a5, a6)
    assert_same_list([a3, a4, a5, a6, a1, a2], a)

    # end
    b.insert(2, b3, b4, b5, b6)
    assert_same_list([b1, b2, b3, b4, b5, b6], b)

    # middle (after)
    c.insert(1, c3, c4, c5, c6)
    assert_same_list([c1, c3, c4, c5, c6, c2], c)
  end

  def test_insert_attached
    # one
    a1 = C::Int.new
    b1 = C::Int.new
    a = _List[a1]
    b = _List[b1]
    assert_same(a, a.insert(1, b1))
    assert_same_list([b1], b)
    assert_same(a1, a[0])
    assert_copy(b1, a[1])

    # many
    a1 = C::Int.new
    b1, b2, b3, b4 = 4.of{C::Int.new}
    a = _List[a1]
    b = _List[b1, b2, b3, b4]
    assert_same(a, a.insert(0, b1, b2, b3, b4))
    assert_same_list([b1, b2, b3, b4], b)
    assert_copy(b1, a[0])
    assert_copy(b2, a[1])
    assert_copy(b3, a[2])
    assert_copy(b4, a[3])
    assert_same(a1, a[4])
  end

  # ------------------------------------------------------------------
  #                               concat
  # ------------------------------------------------------------------

  def test_concat_zero_on_zero
    a = _List[]
    b = _List[]

    assert_same(a, a.concat(b))
    assert_same_list([], b)
    assert_same_list([], a)
  end

  def test_concat_zero_on_one
    a1 = C::Int.new
    a = _List[a1]
    b = _List[]

    assert_same(a, a.concat(b))
    assert_same_list([], b)
    assert_same_list([a1], a)
  end

  def test_concat_zero_on_two
    a1, a2 = 2.of{C::Int.new}
    a = _List[a1, a2]
    b = _List[]

    assert_same(a, a.concat(b))
    assert_same_list([], b)
    assert_equal(2, a.length)
    assert_same_list([a1, a2], a)
  end

  def test_concat_one_on_zero
    b1 = C::Int.new
    a = _List[]
    b = _List[b1]

    assert_same(a, a.concat(b))
    assert_same_list([b1], b)
    #
    assert_equal(1, a.length)
    assert_copy(b1, a[0])
  end

  def test_concat_one_on_one
    a1 = C::Int.new
    b1 = C::Int.new
    a = _List[a1]
    b = _List[b1]

    assert_same(a, a.concat(b))
    assert_same_list([b1], b)
    #
    assert_equal(2, a.length)
    assert_same(a1, a[0])
    assert_copy(b1, a[1])
  end

  def test_concat_one_on_two
    a1, a2 = 2.of{C::Int.new}
    b1 = C::Int.new
    a = _List[a1, a2]
    b = _List[b1]

    assert_same(a, a.concat(b))
    assert_same_list([b1], b)
    #
    assert_equal(3, a.length)
    assert_same(a1, a[0])
    assert_same(a2, a[1])
    assert_copy(b1, a[2])
  end

  def test_concat_two_on_zero
    b1, b2 = 2.of{C::Int.new}
    a = _List[]
    b = _List[b1, b2]

    assert_same(a, a.concat(b))
    assert_same_list([b1, b2], b)
    #
    assert_equal(2, a.length)
    assert_copy(b1, a[0])
    assert_copy(b2, a[1])
  end

  def test_concat_two_on_one
    a1 = C::Int.new
    b1, b2 = 2.of{C::Int.new}
    a = _List[a1]
    b = _List[b1, b2]

    assert_same(a, a.concat(b))
    assert_same_list([b1, b2], b)
    #
    assert_equal(3, a.length)
    assert_same(a1, a[0])
    assert_copy(b1, a[1])
    assert_copy(b2, a[2])
  end

  def test_concat_two_on_two
    a1, a2 = 2.of{C::Int.new}
    b1, b2 = 2.of{C::Int.new}
    a = _List[a1, a2]
    b = _List[b1, b2]

    assert_same(a, a.concat(b))
    assert_same_list([b1, b2], b)
    #
    assert_equal(4, a.length)
    assert_same(a1, a[0])
    assert_same(a2, a[1])
    assert_copy(b1, a[2])
    assert_copy(b2, a[3])
  end

  # ------------------------------------------------------------------
  #                             delete_at
  # ------------------------------------------------------------------

  def test_delete_at_one
    a1 = C::Int.new
    a = _List[a1]

    assert_same(a1, a.delete_at(0))
    assert_nil(a1.parent)
    assert_same_list([], a)
  end

  def test_delete_at_two
    # delete_at 0
    a1, a2 = 2.of{C::Int.new}
    a = _List[a1, a2]
    assert_same(a1, a.delete_at(0))
    assert_nil(a1.parent)
    assert_same_list([a2], a)

    # delete_at 1
    a1, a2 = 2.of{C::Int.new}
    a = _List[a1, a2]
    assert_same(a2, a.delete_at(1))
    assert_nil(a2.parent)
    assert_same_list([a1], a)
  end

  def test_delete_at_three
    # delete at 0
    a1, a2, a3 = 3.of{C::Int.new}
    a = _List[a1, a2, a3]
    assert_same(a1, a.delete_at(0))
    assert_nil(a1.parent)
    assert_same_list([a2, a3], a)

    # delete at 1
    a1, a2, a3 = 3.of{C::Int.new}
    a = _List[a1, a2, a3]
    assert_same(a2, a.delete_at(1))
    assert_nil(a2.parent)
    assert_same_list([a1, a3], a)

    # delete at 2
    a1, a2, a3 = 3.of{C::Int.new}
    a = _List[a1, a2, a3]
    assert_same(a3, a.delete_at(2))
    assert_nil(a3.parent)
    assert_same_list([a1, a2], a)
  end

  def test_delete_at_four
    # delete at 1
    a1, a2, a3, a4 = 4.of{C::Int.new}
    a = _List[a1, a2, a3, a4]
    assert_same(a2, a.delete_at(1))
    assert_nil(a2.parent)
    assert_same_list([a1, a3, a4], a)
  end

  # ------------------------------------------------------------------
  #                               clear
  # ------------------------------------------------------------------

  def test_clear_empty
    assert_same(empty, empty.clear)
    assert_same_list([], empty)
  end

  def test_clear_one
    a = one_els
    assert_same(one, one.clear)
    assert_same_list([], one)
    assert_nil(one.parent)
  end

  def test_clear_two
    a, b = *two_els
    assert_same(two, two.clear)
    assert_same_list([], two)
    assert_nil(a.parent)
    assert_nil(b.parent)
  end

  def test_clear_three
    a, b, c = *three_els
    assert_same(three, three.clear)
    assert_same_list([], three)
    assert_nil(a.parent)
    assert_nil(b.parent)
    assert_nil(c.parent)
  end

  def test_clear_big
    l1, l2, l21, l22, l23, l230, a, b, c, d, e = *big_els
    assert_same(big, big.clear)
    assert_same_list([], big)
    assert_nil(a.parent)
    assert_nil(l1.parent)
    assert_nil(l2.parent)
  end

  # ------------------------------------------------------------------
  #                              replace
  # ------------------------------------------------------------------

  def test_replace_none_with_none
    a = _List[]
    b = []

    assert_same(a, a.replace(b))
    assert_same_list([], a)
  end

  def test_replace_none_with_one
    b1 = C::Int.new
    a = _List[]
    b = [b1]

    assert_same(a, a.replace(b))
    assert_same_list([b1], a)
  end

  def test_replace_none_with_two
    b1, b2 = 2.of{C::Int.new}
    a = _List[]
    b = [b1, b2]

    assert_same(a, a.replace(b))
    assert_same_list([b1, b2], a)
  end

  def test_replace_one_with_none
    a1 = C::Int.new
    a = _List[a1]
    b = _List[]

    assert_same(a, a.replace(b))
    assert_same_list([], a)
    assert_nil(a1.parent)
  end

  def test_replace_one_with_one
    a1 = C::Int.new
    b1 = C::Int.new
    a = _List[a1]
    b = [b1]

    assert_same(a, a.replace(b))
    assert_same_list([b1], a)
    assert_nil(a1.parent)
  end

  def test_replace_one_with_two
    a1 = C::Int.new
    b1, b2 = 2.of{C::Int.new}
    a = _List[a1]
    b = [b1, b2]

    assert_same(a, a.replace(b))
    assert_same_list([b1, b2], a)
    assert_nil(a1.parent)
  end

  def test_replace_two_with_none
    a1, a2 = 2.of{C::Int.new}
    a = _List[a1, a2]
    b = _List[]

    assert_same(a, a.replace(b))
    assert_same_list([], a)
    assert_nil(a1.parent)
    assert_nil(a2.parent)
  end

  def test_replace_two_with_one
    a1, a2 = 2.of{C::Int.new}
    b1 = C::Int.new
    a = _List[a1, a2]
    b = [b1]

    assert_same(a, a.replace(b))
    assert_same_list([b1], a)
    assert_nil(a1.parent)
    assert_nil(a2.parent)
  end

  def test_replace_two_with_two
    a1, a2 = 2.of{C::Int.new}
    b1, b2 = 2.of{C::Int.new}
    a = _List[a1, a2]
    b = [b1, b2]

    assert_same(a, a.replace(b))
    assert_same_list([b1, b2], a)
    assert_nil(a1.parent)
    assert_nil(a2.parent)
  end

  def test_replace_with_attached
    # one
    a1 = C::Int.new
    a = _List[a1]
    b1 = C::Int.new
    b = _List[b1]
    assert_same(a, a.replace(b))
    assert_same_list([b1], b)
    assert_equal(1, a.length)
    assert_copy(b1, a[0])

    # many
    a1 = C::Int.new
    a = _List[a1]
    b1, b2, b3, b4 = 4.of{C::Int.new}
    b = _List[b1, b2, b3, b4]
    assert_same(a, a.replace(b))
    assert_same_list([b1, b2, b3, b4], b)
    assert_equal(4, a.length)
    assert_copy(b1, a[0])
    assert_copy(b2, a[1])
    assert_copy(b3, a[2])
    assert_copy(b4, a[3])
  end
end

# Make concrete test classes.
NodeListTest.submodules.each do |test_module|
  test_module.name =~ /^NodeList/ or
    raise "NodeListTest submodule name does not start with 'NodeList': #{test_module.name}"

  %w[NodeArray NodeChain].each do |list_class|
    test_class = test_module.name.sub(/^NodeList/, list_class)
    eval "
      class #{test_class} < Test::Unit::TestCase
        def _List
          C::#{list_class}
        end
        include #{test_module}
      end
    "
  end
end
