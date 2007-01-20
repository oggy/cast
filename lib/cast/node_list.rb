######################################################################
#
# NodeList and subclasses.
#
######################################################################

module C
  # Declare all the classes, so we don't have to declare the
  # inheritances later.
  class NodeList < Node; abstract; end
  class NodeArray < NodeList; end
  class NodeChain < NodeList; end

  #
  # Abstract base class of the Node list classes.
  #
  class NodeList
    def self.[](*args)
      new.concat(args)
    end

    include Enumerable
    def size
      length
    end

    def ==(other)
      return false if !other.is_a? C::NodeList

      # none of the NodeList classes here have fields, but there's no
      # reason why one can't subclass one to have fields
      fields.each do |field|
        mine  = self .send(field.reader)
        yours = other.send(field.reader)
        mine == yours or return false
      end

      other = other.to_a
      return false if other.length != self.length
      each_with_index do |node, i|
        return false if node != other[i]
      end
      return true
    end

    def hash
      hash = 0
      each do |node|
        hash ^= node.hash
      end
      return hash
    end

    def to_s
      self.join ', '
    end

    def inspect
      "#{self.class}[#{self.join(', ')}]"
    end

    protected  # -----------------------------------------------------

    #
    # Return `[i, n, splat?]', where if `args' is used as an index to
    # ::Array#[]=, it is equivalent to calling:
    #
    #   val = args.pop
    #   if splat?
    #     array[i, n] = *val
    #   else
    #     array[i, n] = val
    #   end
    #
    def parse_index(*args)
      # what we must do:
      #
      #   -- move numbers into range 0..length-1
      #   -- i..j   -->  i...j+1
      #   -- i...j  -->  i, j-i
      case args.length
      when 1
        arg = args.first
        if arg.is_a? ::Range
          if arg.exclude_end?
            i = wrap_index(arg.begin)
            j = wrap_index(arg.begin)
            return [i, j-1, true]
          else
            i = wrap_index(arg.begin)
            j = wrap_index(arg.begin)
            return [i, j+1-i, true]
          end
        else
          i = wrap_index(arg)
          return [i, 1, false]
        end
      when 2
        return [args[0], args[1], true]
      else
        raise ArgumentError, "wrong number of arguments"
      end
    end

    #
    # Wrap the given index if less than 0, and return it.
    #
    def wrap_index(i)
      i < 0 ? (i + length) : i
    end

    #
    # Prepare the given nodes for addition.  This means:
    #   -- clone any attached nodes as necessary
    #   -- set the nodes' parents to self.
    #
    # `oldnodes' are the nodes that will be replaced.  These aren't
    # cloned the first time they appear in `nodes'.
    #
    # Return the list of nodes to add.
    #
    def add_prep(nodes, oldnodes=nil)
      if oldnodes
        oldnodes = oldnodes.map{|n| n.object_id}
        nodes.map! do |node|
          if node.attached? && oldnodes.delete(node.object_id).nil?
            node = node.clone
          end
          set_parent node, self
          node
        end
      else
        nodes.map! do |node|
          node = node.clone if node.attached?
          set_parent node, self
          node
        end
      end
      return nodes
    end

    #
    # Set the parent of `node' to `val'.
    #
    def set_parent(node, val)
      node.send(:parent=, val)
    end
  end

  class NodeArray
    def assert_invariants(testcase)
      super
      testcase.assert_same(::Array, @array)
      @array.each_with_index do |node, i|
        assert_same(i, node.instance_variable_get(:@parent_index))
      end
    end

    def initialize
      super
      @array = []
    end

    def dup
      ret = super
      ret.instance_variable_set(:@array, [])
      dupes = self.map{|n| n.dup}
      return ret.push(*dupes)
    end

    def clone
      ret = super
      ret.instance_variable_set(:@array, [])
      clones = self.map{|n| n.clone}
      return ret.push(*clones)
    end
  end

  class NodeChain
    def assert_invariants(testcase)
      super
      assert_same(@length.zero?, @first.nil?)
      assert_same(@length.zero?, @last.nil?)
      unless @length.zero?
        assert_same(@first, self[0])
        assert_same(@last, self[@length-1])
        (0...@length.times).each do |i|
          nodeprev = self[i].instance_variable_get(:@prev)
          nodenext = self[i].instance_variable_get(:@next)
          if i == 0
            assert_nil(nodeprev)
          else
            assert_same(self[i-1], nodeprev)
          end

          if i == @length-1
            assert_nil(nodenext)
          else
            assert_same(self[i+1], nodenext)
          end
        end
      end
    end

    def initialize
      super
      @first = nil
      @last  = nil
      @length = 0
    end

    def dup
      ret = super
      ret.instance_variable_set(:@first, nil)
      ret.instance_variable_set(:@last, nil)
      ret.instance_variable_set(:@length, 0)
      dupes = self.map{|n| n.dup}
      ret.push(*dupes)
      return ret
    end

    def clone
      ret = super
      ret.instance_variable_set(:@first, nil)
      ret.instance_variable_set(:@last, nil)
      ret.instance_variable_set(:@length, 0)
      clones = self.map{|n| n.clone}
      ret.push(*clones)
      return ret
    end
  end

  # ------------------------------------------------------------------
  #                    Methods called from children
  # ------------------------------------------------------------------

  class NodeArray
    def node_after(node)
      node.parent.equal? self or
        raise ArgumentError, "node is not a child"
      @array[index = node.instance_variable_get(:@parent_index)+1]
    end

    def node_before(node)
      node.parent.equal? self or
        raise ArgumentError, "node is not a child"
      index = node.instance_variable_get(:@parent_index)
      if index.zero?
        return nil
      else
        return @array[index-1]
      end
    end

    def remove_node(node)
      node.parent.equal? self or
        raise ArgumentError, "node is not a child"
      index = node.instance_variable_get(:@parent_index)
      index.instance_variable_set(:@parent_index, nil)
      removed_(@array[index])
      @array.delete_at(index)
      adjust_indices_(index)
      return self
    end

    def insert_after(node, *newnodes)
      node.parent.equal? self or
        raise ArgumentError, "node is not a child"
      index = node.instance_variable_get(:@parent_index) + 1
      insert(index, *newnodes)
      return self
    end
    def insert_before(node, *newnodes)
      node.parent.equal? self or
        raise ArgumentError, "node is not a child"
      index = node.instance_variable_get(:@parent_index)
      insert(index, *newnodes)
      return self
    end
    def replace_node(oldnode, *newnodes)
      oldnode.parent.equal? self or
        raise ArgumentError, "node is not a child"
      index = oldnode.instance_variable_get(:@parent_index)
      self[index, 1] = newnodes
      return self
    end

    private

    #
    # Adjust the indices of all elements from index `from_i' to the
    # end.
    #
    def adjust_indices_(from_i)
      (from_i...@array.length).each do |i|
        @array[i].instance_variable_set(:@parent_index, i)
      end
    end
    #
    # Called when something was added.
    #
    def added_(*nodes)
      nodes.each do |n|
        n.instance_variable_set(:@parent, self)
      end
    end
    #
    # Called when something was removed.
    #
    def removed_(*nodes)
      nodes.each do |n|
        n.instance_variable_set(:@parent, nil)
      end
    end
  end

  class NodeChain
    def node_after(node)
      node.parent.equal? self or
        raise ArgumentError, "node is not a child"
      return node.instance_variable_get(:@next)
    end
    def node_before(node)
      node.parent.equal? self or
        raise ArgumentError, "node is not a child"
      return node.instance_variable_get(:@prev)
    end
    def remove_node(node)
      node.parent.equal? self or
        raise ArgumentError, "node is not a child"
      node_prev = node.instance_variable_get(:@prev)
      node_next = node.instance_variable_get(:@next)
      removed_(node)
      link2_(node_prev, node_next)
      return self
    end
    def insert_after(node, *newnodes)
      node.parent.equal? self or
        raise ArgumentError, "node is not a child"
      newnodes = add_prep(newnodes)
      node_next = node.instance_variable_get(:@next)
      link_(node, newnodes, node_next)
      added_(*newnodes)
      return self
    end
    def insert_before(node, *newnodes)
      node.parent.equal? self or
        raise ArgumentError, "node is not a child"
      newnodes = add_prep(newnodes)
      node_prev = node.instance_variable_get(:@prev)
      link_(node_prev, newnodes, node)
      added_(*newnodes)
      return self
    end
    def replace_node(oldnode, *newnodes)
      oldnode.parent.equal? self or
        raise ArgumentError, "node is not a child"
      newnodes = add_prep(newnodes, [oldnode])
      prev_node = oldnode.instance_variable_get(:@prev)
      next_node = oldnode.instance_variable_get(:@next)
      link_(prev_node, newnodes, next_node)
      removed_(oldnode)
      added_(*newnodes)
      return self
    end
    #
    # Called when something was added.
    #
    def added_(*newnodes)
      newnodes.each{|n| n.instance_variable_set(:@parent, self)}
      @length += newnodes.length
    end
    #
    # Called when something was removed.
    #
    def removed_(*nodes)
      nodes.each{|n| n.instance_variable_set(:@parent, nil)}
      @length -= nodes.length
    end
  end

  # ------------------------------------------------------------------
  #                           Array methods
  # ------------------------------------------------------------------

  class NodeArray
    %w[
       first
       last
       length
       []
       empty?
       index
       rindex
       values_at
       join
    ].each do |m|
      eval "
      def #{m}(*args, &blk)
        @array.#{m}(*args, &blk)
      end
      "
    end

    %w[
      each
      reverse_each
      each_index
    ].each do |m|
      eval "
      def #{m}(*args, &blk)
        @array.#{m}(*args, &blk)
        return self
      end
      "
    end

    def to_a
      @array.dup
    end
    def push(*nodes)
      nodes = add_prep(nodes)
      i = @array.length
      @array.push(*nodes)
      added_(*nodes)
      adjust_indices_(i)
      return self
    end
    def unshift(*nodes)
      nodes = add_prep(nodes)
      @array.unshift(*nodes)
      added_(*nodes)
      adjust_indices_(0)
      return self
    end
    def pop(*args)
      if args.empty?
        ret = @array.pop
        removed_(ret)
        return ret
      else
        args.length == 1 or
          raise ArgumentError, "wrong number of arguments (#{args.length} for 0..1)"
        arg = args[0]
        arg = @array.length if @array.length < arg
        ret = @array.slice!(-arg, arg)
        removed_ *ret
        return ret
      end
    end
    def shift(*args)
      if args.empty?
        ret = @array.shift
        removed_ ret
      else
        args.length == 1 or
          raise ArgumentError, "wrong number of arguments (#{args.length} for 0..1)"
        arg = args[0]
        arg = @array.length if @array.length < arg
        ret = @array.slice!(0, arg)
        removed_ *ret
      end
      adjust_indices_(0)
      return ret
    end
    def insert(i, *newnodes)
      (0..@array.length).include? i or
        raise IndexError, "index #{i} out of NodeList (length #{@array.length})"
      newnodes = add_prep(newnodes)
      @array.insert(i, *newnodes)
      added_(*newnodes)
      adjust_indices_(i)
      return self
    end
    def <<(newnode)
      newnode = *add_prep([newnode])
      @array << newnode
      added_(newnode)
      adjust_indices_(@array.length - 1)
      return self
    end
    def []=(*args)
      newnodes = args.pop
      i, n, splat = parse_index(*args)
      oldnodes = @array[i, n] or
        raise IndexError, "index #{i} out of NodeList"
      if splat
        newnodes = add_prep(newnodes, oldnodes)
      else
        # newnodes is a single node (not an Array)
        newnodes = add_prep([newnodes], [oldnodes])
      end
      @array[i, n] = newnodes
      if splat
        removed_(*oldnodes)
        added_(*newnodes)
      else
        removed_(oldnodes)
        added_(newnodes)
      end
      adjust_indices_(i)
      return newnodes
    end
    def concat(other)
      other = other.to_a
      other = add_prep(other)
      len = @array.length
      @array.concat(other)
      added_(*other)
      adjust_indices_(len)
      return self
    end
    def delete_at(index)
      if index < @array.length
        ret = @array.delete_at(index)
        removed_(ret)
        adjust_indices_(index)
        return ret
      else
        return nil
      end
    end
    def clear
      nodes = @array.dup
      @array.clear
      removed_(*nodes)
      return self
    end
    def replace(other)
      other = other.to_a
      other = add_prep(other)
      oldnodes = @array.dup
      @array.replace(other)
      removed_(*oldnodes)
      added_(*@array)
      adjust_indices_(0)
      return self
    end
  end

  class NodeChain
    #
    # const methods
    #
    def first(n=nil)
      if n.nil?
        return @first
      else
        n = length if n > length
        node = @first
        ret = ::Array.new(n) do
          r = node
          node = node.instance_variable_get(:@next)
          r
        end
        return ret
      end
    end
    def last(n=nil)
      if n.nil?
        return @last
      else
        n = length if n > length
        node = @last
        ret = ::Array.new(n)
        (n-1).downto(0) do |i|
          ret[i] = node
          node = node.instance_variable_get(:@prev)
        end
        return ret
      end
    end
    def length
      @length
    end
    def each
      node = @first
      until node.nil?
        yield node
        node = node.instance_variable_get(:@next)
      end
      return self
    end
    def reverse_each
      node = @last
      until node.nil?
        yield node
        node = node.instance_variable_get(:@prev)
      end
      return self
    end
    def to_a
      node = @first
      ret = ::Array.new(@length) do
        r = node
        node = node.instance_variable_get(:@next)
        r
      end
      return ret
    end
    def [](*args)
      i, n, splat = parse_index(*args)
      return nil if i >= @length
      node = get_(i)
      if splat
        # return an array of Nodes
        n = length-i if n > length-i
        ret = ::Array.new(n) do
          r = node
          node = node.next
          r
        end
        return ret
      else
        # return a Node
        return node
      end
    end
    def each_index
      @length.times{|i| yield i}
      return self
    end
    def empty?
      @length.zero?
    end
    def index(node)
      curr = @first
      i = 0
      while curr
        return i if curr == node
        curr = curr.instance_variable_get(:@next)
        i += 1
      end
      return nil
    end
    def rindex(node)
      curr = @last
      i = @length - 1
      while curr
        return i if curr == node
        curr = curr.instance_variable_get(:@prev)
        i -= 1
      end
      return nil
    end
    def values_at(*args)
      args.map!{|i| self[i]}
    end
    def join(*args)
      self.to_a.join(*args)
    end

    #
    # non-const methods
    #
    def push(*newnodes)
      newnodes = add_prep(newnodes)
      added_(*newnodes)
      link_(@last, newnodes, nil)
      return self
    end
    def <<(newnode)
      return push(newnode)
    end
    def unshift(*newnodes)
      newnodes = add_prep(newnodes)
      added_(*newnodes)
      link_(nil, newnodes, @first)
      return self
    end
    def pop(n=nil)
      if n
        # return an Array of Nodes
        ret = last(n)
        return ret if ret.empty?
        link2_(ret.first.instance_variable_get(:@prev), nil)
        removed_(*ret)
        return ret
      else
        return nil if empty?
        # return a Node
        ret = @last
        link2_(@last.instance_variable_get(:@prev), nil)
        removed_(ret)
        return ret
      end
    end
    def shift(n=nil)
      if n
        # return an Array of Nodes
        ret = first(n)
        return ret if ret.empty?
        link2_(nil, ret.last.instance_variable_get(:@next))
        removed_(*ret)
        return ret
      else
        return nil if empty?
        # return a Node
        ret = @first
        link2_(nil, @first.instance_variable_get(:@next))
        removed_(ret)
        return ret
      end
    end
    def insert(i, *newnodes)
      (0..@length).include? i or
        raise IndexError, "index #{i} out of NodeList"
      if i == @length
        return push(*newnodes)
      else
        insert_before(self[i], *newnodes)
      end
    end
    def []=(*args)
      newnodes = args.pop
      i, n, splat = parse_index(*args)
      oldnodes = self[i, n] or
        raise IndexError, "index #{i} out of NodeList"
      unless n.zero?
        prev_node = n.instance_variable_get(:@prev)
        next_node = n.instance_variable_get(:@next)
        link2_(prev, next_node)
        removed_(*oldnodes)
      end
      if i == @length
        if splat
          push(*newnodes)
        else
          push(newnodes)
        end
      else
        node = get_(i)
        if splat
          insert_before(node, *newnodes)
        else
          insert_before(node, newnodes)
        end
      end
      return newnodes
    end
    def concat(other)
      return push(*other.to_a)
    end
    def delete_at(index)
      node = self[index]
      remove_node(node)
      return node
    end
    def clear
      each{|n| set_parent(n, nil)}
      @first = @last = nil
      @length = 0
      return self
    end
    def replace(other)
      return clear.push(*other.to_a)
    end

    private
    #
    # Link up `nodes' between `a' and `b'.
    #
    def link_(a, nodes, b)
      if nodes.empty?
        if a.nil?
          @first = b
        else
          a.instance_variable_set(:@next, b)
        end
        if b.nil?
          @last = a
        else
          b.instance_variable_set(:@prev, a)
        end
      else
        # connect `a' and `b'
        first = nodes.first
        if a.nil?
          @first = first
        else
          a.instance_variable_set(:@next, first)
        end
        last = nodes.last
        if b.nil?
          @last = last
        else
          b.instance_variable_set(:@prev, last)
        end
      
        # connect `nodes'
        if nodes.length == 1
          node = nodes[0]
          node.instance_variable_set(:@prev, a)
          node.instance_variable_set(:@next, b)
        else
          first.instance_variable_set(:@next, nodes[ 1])
          first.instance_variable_set(:@prev, a)
          last. instance_variable_set(:@prev, nodes[-2])
          last. instance_variable_set(:@next, b)
          (1...nodes.length-1).each do |i|
            n = nodes[i]
            n.instance_variable_set(:@prev, nodes[i-1])
            n.instance_variable_set(:@next, nodes[i+1])
          end
        end
      end
    end
    #
    # Special case for 2
    #
    def link2_(a, b)
      if a.nil?
        @first = b
      else
        a.instance_variable_set(:@next, b) unless a.nil?
      end
      if b.nil?
        @last = a
      else
        b.instance_variable_set(:@prev, a) unless b.nil?
      end
    end

    #
    # Return the `i'th Node.  Assume `i' is in 0...length.
    #
    def get_(i)
      # return a Node
      if i < (@length >> 1)
        # go from the beginning
        node = @first
        i.times{node = node.next}
      else
        # go from the end
        node = @last
        (@length - 1 - i).times{node = node.prev}
      end
      return node
    end
  end
end
