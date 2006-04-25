###
### ##################################################################
###
### Tests for Node core functionality.
###
### ##################################################################
###

Chain = C::NodeChain

###
### Some Node classes.
###
class X < C::Node
  child :a
  initializer :a
end
class Y < C::Node
  child :a
  child :b
  initializer :a, :b
end
class Z < C::Node
  child :a
  field :b
  child :c
  field :d
  child :e
  initializer :a, :b, :c, :d, :e
end
class W < C::Node
  field :a
  field :b, 0
  initializer :a, :b
end
class V < C::Node
  child :a, lambda{C::NodeArray.new}
  initializer :a
end

class NodeInitializeTest < Test::Unit::TestCase
  ###
  ### ----------------------------------------------------------------
  ###                            initialize
  ### ----------------------------------------------------------------
  ###

  def test_initialize_w
    w = W.new
    assert_nil(w.a)
    assert_same(0, w.b)

    w = W.new(1, true)
    assert_same(1, w.a)
    assert_same(true, w.b)

    w = W.new(1, :b => true)
    assert_same(1, w.a)
    assert_same(true, w.b)

    w = W.new(:a => 1, :b => true)
    assert_same(1, w.a)
    assert_same(true, w.b)
  end

  def test_initialize_v
    v = V.new
    assert_same_list([], v.a)
    assert_same(C::NodeArray, v.a.class)

    v = V.new(C::NodeChain[])
    assert_same_list([], v.a)
    assert_same(C::NodeChain, v.a.class)
  end

  def test_initialize_attached
    x1, x2 = 2.of{X.new}
    list = C::NodeArray[x1, x2]
    z = Z.new(x1, x2)
    assert_same_list([x1, x2], list)
    assert_copy(x1, z.a)
    assert_same(x2, z.b)
  end

  ###
  ### ----------------------------------------------------------------
  ###                           Node.new_at
  ### ----------------------------------------------------------------
  ###
  def test_new_at
    pos = C::Node::Pos.new('somefile', 5, 10)
    xa = X.new
    x = X.new_at(pos, xa)
    assert_same(pos, x.pos)
    assert_same(xa, x.a)
  end
end

class NodeEqualTest < Test::Unit::TestCase
  def str
    "(struct s){.a = 1, [2] = {3, 4}, .b [5] = 6, 7}"
  end
  def node
    ma = C::Member.new('a')
    mb = C::Member.new('b')
    one   = C::IntLiteral.new(1)
    two   = C::IntLiteral.new(2)
    three = C::IntLiteral.new(3)
    four  = C::IntLiteral.new(4)
    five  = C::IntLiteral.new(5)
    six   = C::IntLiteral.new(6)
    seven = C::IntLiteral.new(7)
    
    mi0 = C::MemberInit.new(Chain[ma], one)
    mi10 = C::MemberInit.new(nil, three)
    mi11 = C::MemberInit.new(nil, four)
    mi1 = C::MemberInit.new(Chain[two],
                            C::CompoundLiteral.new(nil, Chain[mi10, mi11]))
    mi2 = C::MemberInit.new(Chain[mb, five], six)
    mi3 = C::MemberInit.new(nil, seven)

    c = C::CompoundLiteral.new(C::Struct.new('s'),
                               Chain[mi0, mi1, mi2, mi3])
    return c
  end

  ###
  ### ----------------------------------------------------------------
  ###                            ==, eql?
  ### ----------------------------------------------------------------
  ###
  def test_eq
    ## copy should be equal
    assert_equal(node, node)
    assert(node.eql?(node))

    ## change any one field and it should be not_equal
    n = node
    n.type = nil
    assert_not_equal(node, n)
    assert(!node.eql?(n))

    n = node
    n.member_inits[0].member[0] = C::Member.new('c')
    assert_not_equal(node, n)
    assert(!node.eql?(n))
    copy = node.dup

    n = node
    n.member_inits[2].member[1] = C::IntLiteral.new(8)
    assert_not_equal(node, n)
    assert(!node.eql?(n))

    ## add a member's init and it should be not_equal
    n = node
    n.member_inits[3].init = C::IntLiteral.new(9)
    assert_not_equal(node, n)
    assert(!node.eql?(n))

    ## change a member's init and it should be not_equal
    n = node
    n.member_inits[0].init = C::IntLiteral.new(10)
    assert_not_equal(node, n)
    assert(!node.eql?(n))

    ## add a member specifier and it should be not_equal
    n = node
    n.member_inits[3].member = Chain[C::Member.new('d')]
    assert_not_equal(node, n)
    assert(!node.eql?(n))

    ## pop a member and it should be not_equal
    n = node
    n.member_inits.pop
    assert_not_equal(node, n)
    assert(!node.eql?(n))

    ## assign a field a copy of what's there and it should still be
    ## equal
    n = node
    n.member_inits[0].member[0] = C::Member.new('a')
    assert_equal(node, n)
    assert(node.eql?(n))

    n = node
    n.member_inits[0].init = C::IntLiteral.new(1)
    assert_equal(node, n)
    assert(node.eql?(n))
  end

  ###
  ### ----------------------------------------------------------------
  ###                               hash
  ### ----------------------------------------------------------------
  ###
  def test_hash
    ## copy should be equal
    assert_equal(node.hash, node.hash)

    ## should be equal after assigning to a field a copy of what's
    ## there
    n = node
    n.member_inits[0].member[0] = C::Member.new('a')
    assert_equal(node.hash, n.hash)

    n = node
    n.member_inits[0].init = C::IntLiteral.new(1)
    assert_equal(node.hash, n.hash)
  end
end

class NodeCopyTest < Test::Unit::TestCase
  def setup
    ## (struct s){.a = 1, [2] = {3, 4}, .b [5] = 6, 7}



    @c_t_n = 's'
    @c_t   = C::Struct.new(@c_t_n)

    @c_mis0_m0_n = 'a'
    @c_mis0_m0   = C::Member.new(@c_mis0_m0_n)
    @c_mis0_m    = Chain[@c_mis0_m0]
    @c_mis0_i    = C::IntLiteral.new(1)
    @c_mis0      = C::MemberInit.new(@c_mis0_m, @c_mis0_i)

    @c_mis1_m0       = C::IntLiteral.new(2)
    @c_mis1_m        = Chain[@c_mis1_m0]
    @c_mis1_i_mis0_i = C::IntLiteral.new(3)
    @c_mis1_i_mis0   = C::MemberInit.new(nil, @c_mis1_i_mis0_i)
    @c_mis1_i_mis1_i = C::IntLiteral.new(4)
    @c_mis1_i_mis1   = C::MemberInit.new(nil, @c_mis1_i_mis1_i)
    @c_mis1_i_mis    = Chain[@c_mis1_i_mis0, @c_mis1_i_mis1]
    @c_mis1_i        = C::CompoundLiteral.new(nil, @c_mis1_i_mis)
    @c_mis1          = C::MemberInit.new(@c_mis1_m, @c_mis1_i)

    @c_mis2_m0_n
    @c_mis2_m0 = C::Member.new(@c_mis2_m0_n)
    @c_mis2_m1 = C::IntLiteral.new(5)
    @c_mis2_m  = Chain[@c_mis2_m0, @c_mis2_m1]
    @c_mis2_i  = C::IntLiteral.new(6)
    @c_mis2    = C::MemberInit.new(@c_mis2_m, @c_mis2_i)

    @c_mis3_i = C::IntLiteral.new(7)
    @c_mis3   = C::MemberInit.new(nil, @c_mis3_i)
    @c_mis    = Chain[@c_mis0, @c_mis1, @c_mis2, @c_mis3]

    @c = C::CompoundLiteral.new(@c_t, @c_mis)

    class << @c
      def new_method
        100
      end
    end
    class << @c_mis1_i_mis0
      def new_method
        100
      end
    end

    @d = c.dup
    @e = c.clone
  end
  attr_accessor :c, :d, :e

  ###
  ### ----------------------------------------------------------------
  ###                            dup, clone
  ### ----------------------------------------------------------------
  ###
  def check_node value
    cres = yield(c)
    dres = yield(d)
    eres = yield(e)
    assert_same(value, cres)
    if value.is_a? C::Node
      assert_copy(value, dres)
      assert_copy(value, eres)
    else
      assert_same(value, dres)
      assert_same(value, eres)
    end
    assert_raise(NoMethodError){dres.new_method}
    case value.object_id
    when @c.object_id, @c_mis1_i_mis0.object_id
      assert_same(100, eres.new_method)
    else
      assert_raise(NoMethodError){eres.new_method}
    end
  end

  def test_copy
    ## each element should be equal, but not the same, except for
    ## immediate values
    ##
    ## (struct s){.a = 1, [2] = {3, 4}, .b [5] = 6, 7}
    assert_tree(c)
    assert_tree(d)
    assert_tree(e)
    check_node(@c              ){|x| x}
    check_node(@c_t            ){|x| x.type}
    check_node(@c_t_n          ){|x| x.type.name}
    check_node(nil             ){|x| x.type.members}
    check_node(@c_mis          ){|x| x.member_inits}
    check_node(@c_mis0         ){|x| x.member_inits[0]}
    check_node(@c_mis0_m       ){|x| x.member_inits[0].member}
    check_node(@c_mis0_m0      ){|x| x.member_inits[0].member[0]}
    check_node(@c_mis0_m0_n    ){|x| x.member_inits[0].member[0].name}
    check_node(@c_mis0_i       ){|x| x.member_inits[0].init}
    check_node(1               ){|x| x.member_inits[0].init.val}
    check_node(@c_mis1         ){|x| x.member_inits[1]}
    check_node(@c_mis1_m       ){|x| x.member_inits[1].member}
    check_node(@c_mis1_m0      ){|x| x.member_inits[1].member[0]}
    check_node(2               ){|x| x.member_inits[1].member[0].val}
    check_node(@c_mis1_i       ){|x| x.member_inits[1].init}
    check_node(nil             ){|x| x.member_inits[1].init.type}
    check_node(@c_mis1_i_mis   ){|x| x.member_inits[1].init.member_inits}
    check_node(@c_mis1_i_mis0  ){|x| x.member_inits[1].init.member_inits[0]}
    check_node(nil             ){|x| x.member_inits[1].init.member_inits[0].member}
    check_node(@c_mis1_i_mis0_i){|x| x.member_inits[1].init.member_inits[0].init}
    check_node(3               ){|x| x.member_inits[1].init.member_inits[0].init.val}
    check_node(@c_mis1_i_mis1  ){|x| x.member_inits[1].init.member_inits[1]}
    check_node(nil             ){|x| x.member_inits[1].init.member_inits[1].member}
    check_node(@c_mis1_i_mis1_i){|x| x.member_inits[1].init.member_inits[1].init}
    check_node(4               ){|x| x.member_inits[1].init.member_inits[1].init.val}
    check_node(@c_mis2         ){|x| x.member_inits[2]}
    check_node(@c_mis2_m       ){|x| x.member_inits[2].member}
    check_node(@c_mis2_m0      ){|x| x.member_inits[2].member[0]}
    check_node(@c_mis2_m0_n    ){|x| x.member_inits[2].member[0].name}
    check_node(@c_mis2_m1      ){|x| x.member_inits[2].member[1]}
    check_node(5               ){|x| x.member_inits[2].member[1].val}
    check_node(@c_mis2_i       ){|x| x.member_inits[2].init}
    check_node(6               ){|x| x.member_inits[2].init.val}
    check_node(@c_mis3         ){|x| x.member_inits[3]}
    check_node(nil             ){|x| x.member_inits[3].member}
    check_node(@c_mis3_i       ){|x| x.member_inits[3].init}
    check_node(7               ){|x| x.member_inits[3].init.val}
  end
end

class NodeWalkTest < Test::Unit::TestCase
  ###
  ### Collect and return the args yielded to `node.send(method)' as an
  ### Array, each element of which is an array of args yielded.
  ###
  ### Also, assert that the return value of the method is `exp'.
  ###
  def yields method, node, exp
    ret = []
    out = node.send(method) do |*args|
      ret << args
      yield *args if block_given?
    end
    assert_same(exp, out)
    return ret
  end

  ###
  ### Assert exp and out are equal, where elements are compared with
  ### Array#same_list?.  That is, exp[i].same_list?(out[i]) for all i.
  ###
  def assert_equal_yields exp, out
    if exp.zip(out).all?{|a,b| a.same_list?(b)}
      assert(true)
    else
      flunk("walk not equal: #{walk_str(out)} (expected #{walk_str(exp)})")
    end
  end
  def walk_str walk
    walk.is_a? ::Array or
      raise "walk_str: expected ::Array"
    if walk.empty?
      return '[]'
    else
      s = StringIO.new
      s.puts '['
      walk.each do |args|
        args.map! do |arg|
          if arg.is_a? C::Node
            argstr = arg.class.name << ' (' << arg.object_id.to_s <<
              "): " << arg.to_s
          else
            argstr = arg.inspect
          end
          if argstr.length > 50
            argstr[48..-1] = '...'
          end
          argstr
        end
        s.puts "    [#{args.join(', ')}]"
      end
      s.puts ']'
      return s.string
    end
  end

  ###
  ### ----------------------------------------------------------------
  ###                 depth_first, reverse_depth_first
  ### ----------------------------------------------------------------
  ###
  def check_depth_firsts node, exp
    ## depth_first
    out = yields(:depth_first, node, node)
    assert_equal_yields exp, out

    ## reverse_depth_first
    exp = exp.reverse.map! do |ev, node|
      if ev == :ascending
        [:descending, node]
      else
        [:ascending, node]
      end
    end
    out = yields(:reverse_depth_first, node, node)
    assert_equal_yields exp, out
  end

  def test_depth_first
    ## empty node
    d = C::Int.new
    d.longness = 1
    check_depth_firsts(d,
                       [[:descending, d], [:ascending, d]])

    ## one-storey -- populate both the list child and nonlist child
    d = C::Declaration.new(C::Int.new)
    d.declarators << C::Declarator.new
    d.declarators[0].name = 'one'
    d.declarators << C::Declarator.new
    d.declarators[1].name = 'two'
    check_depth_firsts(d,
                       [
                         [:descending, d],
                           [:descending, d.type], [:ascending, d.type],
                           [:descending, d.declarators],
                             [:descending, d.declarators[0]], [:ascending, d.declarators[0]],
                             [:descending, d.declarators[1]], [:ascending, d.declarators[1]],
                           [:ascending, d.declarators],
                         [:ascending, d]
                       ])

    ## multi-layer
    d.declarators[0].indirect_type = C::Function.new
    d.declarators[0].indirect_type.params = Chain[]
    d.declarators[0].indirect_type.params << C::Parameter.new(C::Int.new, 'i')
    d.declarators[0].indirect_type.params << C::Parameter.new(C::Float.new, 'f')
    check_depth_firsts(d,
                       [
                         [:descending, d],
                           [:descending, d.type], [:ascending, d.type],
                           [:descending, d.declarators],
                             [:descending, d.declarators[0]],
                               [:descending, d.declarators[0].indirect_type],
                                 [:descending, d.declarators[0].indirect_type.params],
                                   [:descending, d.declarators[0].indirect_type.params[0]],
                                     [:descending, d.declarators[0].indirect_type.params[0].type], [:ascending, d.declarators[0].indirect_type.params[0].type],
                                   [:ascending, d.declarators[0].indirect_type.params[0]],
                                   [:descending, d.declarators[0].indirect_type.params[1]],
                                     [:descending, d.declarators[0].indirect_type.params[1].type], [:ascending, d.declarators[0].indirect_type.params[1].type],
                                   [:ascending, d.declarators[0].indirect_type.params[1]],
                                 [:ascending, d.declarators[0].indirect_type.params],
                               [:ascending, d.declarators[0].indirect_type],
                             [:ascending, d.declarators[0]],
                             [:descending, d.declarators[1]], [:ascending, d.declarators[1]],
                           [:ascending, d.declarators],
                         [:ascending, d]
                       ])
  end

  def check_depth_first_prunes pruned_nodes, node, exp
    ## depth_first
    out = yields(:depth_first, node, node) do |ev, node|
      if ev.equal? :descending
        if pruned_nodes.any?{|n| n.equal? node}
          throw :prune
        end
      end
    end
    assert_equal_yields exp, out
    ##
    ret = catch :prune do
      node.depth_first do |ev, node|
        throw :prune, :x if ev.equal? :ascending
      end
      :oops
    end
    assert_same(:x, ret)

    ## reverse_depth_first
    exp = exp.reverse.map! do |ev, node|
      if ev.equal? :ascending
        [:descending, node]
      else
        [:ascending, node]
      end
    end
    out = yields(:reverse_depth_first, node, node) do |ev, node|
      if ev.equal? :descending
        if pruned_nodes.any?{|n| n.equal? node}
          throw :prune
        end
      end
    end
    assert_equal_yields exp, out
    ##
    ret = catch :prune do
      node.reverse_depth_first do |ev, node|
        throw :prune, :x if ev.equal? :ascending
      end
      :oops
    end
    assert_same(:x, ret)
  end

  def test_depth_first_prune
    ## empty node
    d = C::Int.new
    d.longness = 1
    check_depth_first_prunes([d], d,
                       [[:descending, d], [:ascending, d]])

    ## one-storey -- populate both the list child and nonlist child
    d = C::Declaration.new(C::Int.new)
    d.declarators << C::Declarator.new
    d.declarators[0].name = 'one'
    d.declarators << C::Declarator.new
    d.declarators[1].name = 'two'
    check_depth_first_prunes([d.declarators], d,
                       [
                         [:descending, d],
                           [:descending, d.type], [:ascending, d.type],
                           [:descending, d.declarators], [:ascending, d.declarators],
                         [:ascending, d]
                       ])

    ## multi-layer
    d.type = C::Struct.new('S')
    d.type.members = Chain[]
    d.type.members << C::Declaration.new(C::Int.new)
    d.type.members[0].declarators << C::Declarator.new(nil, 'x')
    d.declarators[0].indirect_type = C::Function.new
    d.declarators[0].indirect_type.params = Chain[]
    d.declarators[0].indirect_type.params << C::Parameter.new(C::Int.new, 'i')
    d.declarators[0].indirect_type.params << C::Parameter.new(C::Float.new, 'f')
    check_depth_first_prunes([d.type.members, d.declarators[0]], d,
                       [
                         [:descending, d],
                           [:descending, d.type],
                             [:descending, d.type.members], [:ascending, d.type.members],
                           [:ascending, d.type],
                           [:descending, d.declarators],
                             [:descending, d.declarators[0]], [:ascending, d.declarators[0]],
                             [:descending, d.declarators[1]], [:ascending, d.declarators[1]],
                           [:ascending, d.declarators],
                         [:ascending, d]
                       ])
  end

  ###
  ### ----------------------------------------------------------------
  ###                        each, reverse_each
  ### ----------------------------------------------------------------
  ###

  def iter_str iter
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
  def check_each node, exp
    exp.map!{|n| [n]}

    out = yields(:each, node, node)
    assert_equal_yields exp, out

    out = yields(:reverse_each, node, node)
    exp.reverse!
    assert_equal_yields exp, out
  end
  def test_each
    ## empty
    parent = X.new
    check_each(parent, [])

    ## one child
    x1 = X.new
    parent = X.new(x1)
    check_each(parent, [x1])

    ## two children
    x1, x2 = 2.of{X.new}
    parent = Y.new(x1, x2)
    check_each(parent, [x1, x2])

    ## three with some nil and some fields
    x1, x2, x3, x4, x5 = 5.of{X.new}
    parent = Z.new(x1, x2, nil, x4, x5)
    check_each(parent, [x1, x5])
  end

  ###
  ### ----------------------------------------------------------------
  ###                    preorder, reverse_preorder
  ###                   postorder, reverse_postorder
  ### ----------------------------------------------------------------
  ###

  def check_preorder node, exp
    exp.map!{|n| [n]}

    out = yields(:preorder, node, node)
    assert_equal_yields exp, out

    out = yields(:reverse_postorder, node, node)
    exp.reverse!
    assert_equal_yields exp, out
  end
  def check_postorder node, exp
    exp.map!{|n| [n]}

    out = yields(:postorder, node, node)
    assert_equal_yields exp, out

    out = yields(:reverse_preorder, node, node)
    exp.reverse!
    assert_equal_yields exp, out
  end
  def test_preorder
    ## empty node
    d = C::Int.new
    d.longness = 1
    check_preorder(d, [d])

    ## one-storey -- populate both the list child and nonlist child
    d = C::Declaration.new(C::Int.new)
    d.declarators << C::Declarator.new
    d.declarators[0].name = 'one'
    d.declarators << C::Declarator.new
    d.declarators[1].name = 'two'
    check_preorder(d,
                   [
                     d,
                     d.type,
                     d.declarators,
                     d.declarators[0],
                     d.declarators[1]
                   ])

    ## multi-layer
    d.declarators[0].indirect_type = C::Function.new
    d.declarators[0].indirect_type.params = Chain[]
    d.declarators[0].indirect_type.params << C::Parameter.new(C::Int.new, 'i')
    d.declarators[0].indirect_type.params << C::Parameter.new(C::Float.new, 'f')
    check_preorder(d,
                   [
                     d,
                     d.type,
                     d.declarators,
                     d.declarators[0],
                     d.declarators[0].indirect_type,
                     d.declarators[0].indirect_type.params,
                     d.declarators[0].indirect_type.params[0],
                     d.declarators[0].indirect_type.params[0].type,
                     d.declarators[0].indirect_type.params[1],
                     d.declarators[0].indirect_type.params[1].type,
                     d.declarators[1]
                   ])
  end
  def test_postorder
    ## empty node
    d = C::Int.new
    d.longness = 1
    check_preorder(d, [d])

    ## one-storey -- populate both the list child and nonlist child
    d = C::Declaration.new(C::Int.new)
    d.declarators << C::Declarator.new
    d.declarators[0].name = 'one'
    d.declarators << C::Declarator.new
    d.declarators[1].name = 'two'
    check_postorder(d,
                    [
                     d.type,
                     d.declarators[0],
                     d.declarators[1],
                     d.declarators,
                     d
                    ])

    ## multi-layer
    d.declarators[0].indirect_type = C::Function.new
    d.declarators[0].indirect_type.params = Chain[]
    d.declarators[0].indirect_type.params << C::Parameter.new(C::Int.new, 'i')
    d.declarators[0].indirect_type.params << C::Parameter.new(C::Float.new, 'f')
    check_postorder(d,
                    [
                     d.type,
                     d.declarators[0].indirect_type.params[0].type,
                     d.declarators[0].indirect_type.params[0],
                     d.declarators[0].indirect_type.params[1].type,
                     d.declarators[0].indirect_type.params[1],
                     d.declarators[0].indirect_type.params,
                     d.declarators[0].indirect_type,
                     d.declarators[0],
                     d.declarators[1],
                     d.declarators,
                     d
                    ])
  end
  def check_preorder_prune method, pruned_nodes, root, exp
    exp.map!{|n| [n]}

    out = yields(method, root, root) do |node|
      if pruned_nodes.any?{|n| n.equal? node}
        throw :prune
      end
    end
    assert_equal_yields exp, out
  end

  def test_preorder_prune
    ## empty node
    d = C::Int.new
    d.longness = 1
    check_preorder_prune(:preorder, [d], d, [d])
    check_preorder_prune(:reverse_preorder, [d], d, [d])

    ## one-storey -- populate both the list child and nonlist child
    d = C::Declaration.new(C::Int.new)
    d.declarators << C::Declarator.new
    d.declarators[0].name = 'one'
    d.declarators << C::Declarator.new
    d.declarators[1].name = 'two'
    check_preorder_prune(:preorder, [d.declarators], d,
                         [
                           d,
                           d.type,
                           d.declarators,
                         ])
    check_preorder_prune(:reverse_preorder, [d.declarators], d,
                                 [
                                   d,
                                   d.declarators,
                                   d.type,
                                 ])

    ## multi-layer
    d.type = C::Struct.new('S')
    d.type.members = Chain[]
    d.type.members << C::Declaration.new(C::Int.new)
    d.type.members[0].declarators << C::Declarator.new(nil, 'x')
    d.declarators[0].indirect_type = C::Function.new
    d.declarators[0].indirect_type.params = Chain[]
    d.declarators[0].indirect_type.params << C::Parameter.new(C::Int.new, 'i')
    d.declarators[0].indirect_type.params << C::Parameter.new(C::Float.new, 'f')
    check_preorder_prune(:preorder, [d.type.members, d.declarators[0]], d,
                         [
                           d,
                           d.type,
                           d.type.members,
                           d.declarators,
                           d.declarators[0],
                           d.declarators[1]
                         ])
    check_preorder_prune(:reverse_preorder, [d.type.members, d.declarators[0]], d,
                                 [
                                   d,
                                   d.declarators,
                                   d.declarators[1],
                                   d.declarators[0],
                                   d.type,
                                   d.type.members
                                 ])
  end

  ###
  ### ----------------------------------------------------------------
  ###                 next, prev, list_next, list_prev
  ### ----------------------------------------------------------------
  ###

  def test_next_prev
    ## list parent
    i1 = C::Int.new
    i2 = C::Int.new
    list = Chain[i1, i2]
    assert_same(i2, i1.next)
    assert_nil(i2.next)
    assert_same(i1, i2.prev)
    assert_nil(i1.prev)

    ## node parent
    i1 = C::IntLiteral.new(1)
    i2 = C::IntLiteral.new(2)
    a = C::Add.new(i1, i2)
    assert_same(i2, i1.next)
    assert_nil(i2.next)
    assert_same(i1, i2.prev)
    assert_nil(i1.prev)

    ## no parent
    i = C::Int.new
    assert_raise(C::Node::NoParent){i.next}
    assert_raise(C::Node::NoParent){i.prev}
  end

  def test_list_next_prev
    ## list parent
    i1 = C::Int.new
    i2 = C::Int.new
    list = Chain[i1, i2]
    assert_same(i2, i1.list_next)
    assert_nil(i2.list_next)
    assert_same(i1, i2.list_prev)
    assert_nil(i1.list_prev)

    ## node parent
    i1 = C::IntLiteral.new(1)
    i2 = C::IntLiteral.new(2)
    a = C::Add.new(i1, i2)
    assert_raise(C::Node::BadParent){i1.list_next}
    assert_raise(C::Node::BadParent){i2.list_next}
    assert_raise(C::Node::BadParent){i1.list_prev}
    assert_raise(C::Node::BadParent){i2.list_prev}

    ## no parent
    i = C::Int.new
    assert_raise(C::Node::NoParent){i.list_next}
    assert_raise(C::Node::NoParent){i.list_prev}
  end
end

class NodeTreeTest < Test::Unit::TestCase
  def setup
    ## @c = "(int){[1] = 10,
    ##             .x = 20,
    ##             [2] .y = 30
    ##            }
    @c = C::CompoundLiteral.new
    c.type = C::Int.new
    c.member_inits << C::MemberInit.new
    c.member_inits[0].member = C::NodeChain.new
    c.member_inits[0].member << C::IntLiteral.new(1)
    c.member_inits[0].init = C::IntLiteral.new(10)
    c.member_inits << C::MemberInit.new
    c.member_inits[1].member = C::NodeChain.new
    c.member_inits[1].member << C::Member.new('x')
    c.member_inits[1].init = C::IntLiteral.new(20)
    c.member_inits << C::MemberInit.new
    c.member_inits[2].member = C::NodeChain.new
    c.member_inits[2].member << C::IntLiteral.new(2)
    c.member_inits[2].member << C::Member.new('y')
    c.member_inits[2].init = C::IntLiteral.new(30)
  end
  attr_reader :c

  def test_empty
    ast = C::TranslationUnit.new
    assert_tree(ast)
  end
  def test_basic
    assert_tree(c)
  end

  def test_assign_field
    c.type.unsigned = true
    assert_tree(c)
    assert_same(true, c.type.unsigned?)
    c.type.unsigned = false
    assert_tree(c)
    assert_same(false, c.type.unsigned?)
  end
  def test_assign_child
    c.type = nil
    assert_tree(c)
    assert_nil(c.type)
    f = C::Float.new
    c.type = f
    assert_tree(c)
    assert_same(f, c.type)
  end
  def test_assign_list
    old_list = c.member_inits[2].member
    new_list = C::NodeChain[C::IntLiteral.new(4), C::Member.new('a')]
    c.member_inits[2].member = new_list
    assert_tree(c)
    assert_tree(old_list)
    assert_same(new_list, c.member_inits[2].member)
  end
  def test_assign_attached
    f = C::Float.new
    c2 = C::CompoundLiteral.new
    c2.type = f

    c.type = f
    assert_same(f, c2.type)
    assert_copy(f, c.type)
    assert_tree(c)
    assert_tree(c2)
  end

  def test_detach_node
    d = c.type.detach
    assert_tree(c)
    assert_tree(d)
  end

  def test_detach_list_element
    member_one = c.member_inits[1]
    member_two = c.member_inits[2]
    d = c.member_inits[0].detach
    assert_tree(c)
    assert_tree(d)
    assert_same_list([member_one, member_two], c.member_inits)
  end

  def test_detach_list
    d = c.member_inits.detach
    assert_tree(c)
    assert_tree(d)
  end

  def test_node_replace_with
    i = C::Int.new
    t = c.type
    assert_same(c.type, c.type.replace_with(i))
    assert_tree(c)
    assert_tree(t)
    assert_same(i, c.type)

    assert_same(c.type, c.type.replace_with(nil))
    assert_tree(c)
    assert_nil(c.type)
  end
  def test_node_replace_with_none
    t = c.type
    assert_same(c.type, c.type.replace_with)
    assert_tree(c)
    assert_tree(t)
    assert_nil(c.type)
  end
  def test_node_replace_with_many
    mi = c.member_inits[0]
    mis = [c.member_inits[0], c.member_inits[1], c.member_inits[2]]

    mi1 = C::MemberInit.new
    mi1.init = C::IntLiteral.new(1)
    mi2 = C::MemberInit.new
    mi2.init = C::IntLiteral.new(2)

    assert_same(mi, mi.replace_with(mi1, mi2))
    assert_tree(c)
    assert_tree(mi)
    assert_same_list([mi1, mi2, mis[1], mis[2]], c.member_inits)

    assert_raise(C::Node::NoParent){mi.replace_with(nil)}
    i1 = C::Int.new
    i2 = C::Int.new
    assert_raise(ArgumentError){c.type.replace_with(i1, i2)}
  end

  def test_node_swap_with
    ## swap with itself -- attached
    x = X.new
    parent = X.new(x)
    assert_same(x, x.swap_with(x))
    assert_same(parent, x.parent)
    assert_same(x, parent.a)

    ## swap with itself -- detached
    x = X.new
    assert_same(x, x.swap_with(x))
    assert_nil(x.parent)

    ## both attached
    x = X.new
    y = X.new
    xp = X.new(x)
    yp = X.new(y)
    assert_same(x, x.swap_with(y))
    assert_same(xp, y.parent)
    assert_same(x, yp.a)
    assert_same(yp, x.parent)
    assert_same(y, xp.a)

    ## only receiver attached
    x = X.new
    y = X.new
    xp = X.new(x)
    assert_same(x, x.swap_with(y))
    assert_nil(x.parent)
    assert_same(xp, y.parent)
    assert_same(y, xp.a)

    ## only arg attached
    x = X.new
    y = X.new
    yp = X.new(y)
    assert_same(x, x.swap_with(y))
    assert_same(yp, x.parent)
    assert_same(x, yp.a)
    assert_nil(y.parent)

    ## neither attached
    x = X.new
    y = X.new
    assert_same(x, x.swap_with(y))
    assert_nil(x.parent)
    assert_nil(y.parent)
  end

  ###
  ### ----------------------------------------------------------------
  ###                     insert_next, insert_prev
  ### ----------------------------------------------------------------
  ###
  def test_node_insert_next_detached
    x1, x2 = 2.of{X.new}
    assert_raise(C::Node::NoParent){x1.insert_next}
    assert_nil(x1.parent)
    assert_raise(C::Node::NoParent){x1.insert_next(x2)}
    assert_nil(x1.parent)
    assert_nil(x2.parent)
  end
  def test_node_insert_next_nonlist_parent
    parent = X.new
    x1, x2 = 2.of{X.new}
    parent.a = x1
    assert_raise(C::Node::BadParent){x1.insert_next}
    assert_same(parent, x1.parent)
    assert_raise(C::Node::BadParent){x1.insert_next(x2)}
    assert_same(parent, x1.parent)
    assert_nil(x2.parent)
  end
  def test_node_insert_next_none
    x1 = X.new
    parent = Chain[x1]
    assert_same(x1, x1.insert_next)
    assert_same_list([x1], parent)
  end
  def test_node_insert_next_many
    x1, x2, x3, x4 = 4.of{X.new}
    parent = Chain[x1]
    assert_same(x1, x1.insert_next(x2, x3, x4))
    assert_same_list([x1, x2, x3, x4], parent)
  end

  def test_node_insert_prev_detached
    a1, a2 = 2.of{X.new}
    assert_raise(C::Node::NoParent){a1.insert_prev}
    assert_nil(a1.parent)
    assert_raise(C::Node::NoParent){a1.insert_prev(a2)}
    assert_nil(a1.parent)
    assert_nil(a2.parent)
  end
  def test_node_insert_prev_nonlist_parent
    parent = X.new
    x1, x2 = 2.of{X.new}
    parent.a = x1
    assert_raise(C::Node::BadParent){x1.insert_prev}
    assert_same(parent, x1.parent)
    assert_raise(C::Node::BadParent){x1.insert_prev(x2)}
    assert_same(parent, x1.parent)
    assert_nil(x2.parent)
  end
  def test_node_insert_prev_none
    x1 = X.new
    parent = Chain[x1]
    assert_same(x1, x1.insert_prev)
    assert_same_list([x1], parent)
  end
  def test_node_insert_prev_many
    x1, x2, x3, x4 = 4.of{X.new}
    parent = Chain[x1]
    assert_same(x1, x1.insert_prev(x2, x3, x4))
    assert_same_list([x2, x3, x4, x1], parent)
  end

  ###
  ### ----------------------------------------------------------------
  ###                     node_after, node_before
  ### ----------------------------------------------------------------
  ###

  def test_node_after_before
    ## node not a child
    x1, x2 = 2.of{X.new}
    parent = X.new(x1)
    assert_raise(ArgumentError){parent.node_after(x2)}
    assert_raise(ArgumentError){parent.node_before(x2)}

    x1, x2 = 2.of{X.new}
    parent = Z.new(nil, x1, nil, x2, nil)
    assert_raise(ArgumentError){parent.node_after(x1)}
    assert_raise(ArgumentError){parent.node_after(x2)}
    assert_raise(ArgumentError){parent.node_before(x1)}
    assert_raise(ArgumentError){parent.node_before(x2)}

    ## one child
    x = X.new
    parent = X.new(x)
    assert_nil(parent.node_after(x))
    assert_nil(parent.node_before(x))

    ## two children
    x1 = X.new
    x2 = X.new
    parent = Y.new(x1, x2)
    assert_same(x2, parent.node_after(x1))
    assert_nil(parent.node_after(x2))
    assert_same(x1, parent.node_before(x2))
    assert_nil(parent.node_before(x1))

    ## skip over stuff in the middle
    x1, x2, x3, x4, x5 = 5.of{X.new}
    parent = Z.new(x1, x2, nil, x4, x5)
    assert_same(x5, parent.node_after(x1))
    assert_nil(parent.node_after(x5))
    assert_same(x1, parent.node_before(x5))
    assert_nil(parent.node_before(x1))

    ## skip over stuff at the end
    x1, x2, x3, x4, x5 = 5.of{X.new}
    parent = Z.new(nil, x2, x3, x4, nil)
    assert_nil(parent.node_after(x3))
    assert_nil(parent.node_before(x3))
  end

  def test_remove_node
    ## node not a child
    x1, x2, x3 = 3.of{X.new}
    parent = Z.new(x1, x2)
    assert_raise(ArgumentError){parent.remove_node(x2)}
    assert_raise(ArgumentError){parent.remove_node(x3)}

    ## one child
    x = X.new
    parent = X.new(x)
    assert_same(parent, parent.remove_node(x))
    assert_tree(parent)
    assert_tree(x)

    ## two children
    x1, x2 = 2.of{X.new}
    parent = Y.new(x1, x2)
    assert_same(parent, parent.remove_node(x2))
    assert_tree(parent)
    assert_tree(x2)
    assert_same(x1, parent.a)
    assert_nil(parent.b)
  end

  def test_replace_node
    ## node not a child
    x1, x2, x3, x4 = 3.of{X.new}
    parent = Z.new(x1, x2)
    assert_raise(ArgumentError){parent.replace_node(x2, x4)}
    assert_raise(ArgumentError){parent.replace_node(x3, x4)}

    ## no newnode
    x = X.new
    parent = X.new(x)
    assert_same(parent, parent.replace_node(x))
    assert_tree(parent)
    assert_tree(x)
    assert_nil(parent.a)

    ## >1 newnode
    x1, x2, x3 = 3.of{X.new}
    parent = X.new(x1)
    assert_raise(ArgumentError){parent.replace_node(x1, x2, x3)}

    ## one child
    x1, x2 = 2.of{X.new}
    parent = X.new(x1)
    assert_same(parent, parent.replace_node(x1, x2))
    assert_tree(parent)
    assert_tree(x1)
    assert_same(x2, parent.a)
    ##
    assert_same(parent, parent.replace_node(x2, nil))
    assert_tree(parent)
    assert_tree(x2)
    assert_nil(parent.a)

    ## two children
    x1, x2, x3 = 3.of{X.new}
    parent = Y.new(x1, x2)
    assert_same(parent, parent.replace_node(x2, x3))
    assert_tree(parent)
    assert_tree(x2)
    assert_same(x3, parent.b)
    ##
    assert_same(parent, parent.replace_node(x3, nil))
    assert_tree(parent)
    assert_tree(x3)
    assert_nil(parent.b)
  end
end
