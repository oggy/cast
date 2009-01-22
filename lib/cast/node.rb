######################################################################
#
# Node core functionality.
#
######################################################################

module C
  #
  # Abstract base class for all AST nodes.
  #
  class Node
    #
    # Called by the test suite to ensure all invariants are true.
    #
    def assert_invariants(testcase)
      fields.each do |field|
        if val = send(field.reader)
          assert_same(self, node.parent, "field.reader is #{field.reader}")
          if field.child?
            assert_same(field, val.instance_variable_get(:@parent_field), "field.reader is #{field.reader}")
          end
        end
      end
    end

    #
    # Like self.new, but the first argument is taken as the position
    # of the Node.
    #
    def self.new_at(pos, *args)
      ret = new(*args)
      ret.pos = pos
      return ret
    end

    #
    # True iff both are of the same class, and all fields are #==.
    #
    def ==(other)
      return false if !other.is_a? self.class

      fields.all? do |field|
        mine  = self .send(field.reader)
        yours = other.send(field.reader)
        mine == yours
      end
    end

    #
    # Same as #==.
    #
    def eql?(other)
      return self == other
    end

    #
    # #hash, as defined in Object.
    #
    def hash
      fields.inject(0) do |hash, field|
        val = send(field.reader)
        hash ^= val.hash
      end
    end

    #
    # As defined for ::Object, but children are recursively `#dup'ed.
    #
    def dup
      ret = super
      ret.instance_variable_set(:@parent, nil)
      fields.each do |field|
        next if !field.child?
        val = instance_variable_get(field.var)
        val = val.dup unless val.nil?
        ret.instance_variable_set(field.var, nil)
        ret.send(field.writer, val)
      end
      return ret
    end

    #
    # As defined for ::Object, but children are recursively `#clone'd.
    #
    def clone
      ret = super
      ret.instance_variable_set(:@parent, nil)
      fields.each do |field|
        next if !field.child?
        val = instance_variable_get(field.var)
        val = val.clone unless val.nil?
        ret.instance_variable_set(field.var, nil)
        ret.send(field.writer, val)
      end
      return ret
    end

    # ----------------------------------------------------------------
    #                          Tree traversal
    # ----------------------------------------------------------------

    include Enumerable

    #
    # Yield each child in field order.
    #
    def each(&blk)
      fields.each do |field|
        if field.child?
          val = self.send(field.reader)
          yield val unless val.nil?
        end
      end
      return self
    end

    #
    # Yield each child in reverse field order.
    #
    def reverse_each(&blk)
      fields.reverse_each do |field|
        if field.child?
          val = self.send(field.reader)
          yield val unless val.nil?
        end
      end
      return self
    end

    #
    # Perform a depth-first walk of the AST, yielding on recursively
    # on each child node:
    #
    #   - (:descending, node) just prior to descending into `node'
    #   - (:ascending, node) just after ascending from `node'
    #
    # If the block throws :prune while descending, the children of the
    # node that was passed to that block will not be visited.
    #
    def depth_first(&blk)
      catch :prune do
        yield :descending, self
        each{|n| n.depth_first(&blk)}
      end
      yield :ascending, self
      return self
    end

    #
    # Perform a reverse depth-first walk of the AST, yielding on each
    # node:
    #
    #   - (:descending, node) just prior to descending into `node'
    #   - (:ascending, node) just after ascending from `node'
    #
    # If the block throws :prune while descending, the children of the
    # node that was passed to that block will not be visited.
    #
    def reverse_depth_first(&blk)
      catch :prune do
        yield :descending, self
        reverse_each{|n| n.reverse_depth_first(&blk)}
      end
      yield :ascending, self
      return self
    end

    #
    # Perform a preorder walk of the AST, yielding each node in turn.
    # Return self.
    #
    # If the block throws :prune, the children of the node that was
    # passed to that block will not be visited.
    #
    def preorder(&blk)
      catch :prune do
        yield self
        each{|n| n.preorder(&blk)}
      end
      return self
    end

    #
    # Perform a reverse preorder walk of the AST, yielding each node
    # in turn.  Return self.
    #
    # If the block throws :prune, the children of the node that was
    # passed to that block will not be visited.
    #
    def reverse_preorder(&blk)
      catch :prune do
        yield self
        reverse_each{|n| n.reverse_preorder(&blk)}
      end
      return self
    end

    #
    # Perform a postorder walk of the AST, yielding each node in turn.
    # Return self.
    #
    def postorder(&blk)
      each{|n| n.postorder(&blk)}
      yield self
      return self
    end

    #
    # Perform a reverse postorder walk of the AST, yielding each node
    # in turn.  Return self.
    #
    def reverse_postorder(&blk)
      reverse_each{|n| n.reverse_postorder(&blk)}
      yield self
      return self
    end

    # ----------------------------------------------------------------
    #                   Node tree-structure methods
    # ----------------------------------------------------------------

    class BadParent < StandardError; end
    class NoParent < BadParent; end

    #
    # The Node's parent.
    #
    attr_accessor :parent
    private :parent=

    #
    # The position in the source file the construct this node
    # represents appears at.
    #
    attr_accessor :pos

    #
    # Return the sibling Node that comes after this in preorder
    # sequence.
    #
    # Raises NoParent if there's no parent.
    #
    def next
      @parent or raise NoParent
      return @parent.node_after(self)
    end

    #
    # Return the sibling Node that comes after this in the parent
    # NodeList.
    #
    # Raises:
    #   -- NoParent if there's no parent
    #   -- BadParent if the parent is otherwise not a NodeList
    #
    def list_next
      @parent or raise NoParent
      @parent.NodeList? or raise BadParent
      return @parent.node_after(self)
    end

    #
    # Return the sibling Node that comes before this in preorder
    # sequence.
    #
    # Raises NoParent if there's no parent.
    #
    def prev
      @parent or raise NoParent
      return @parent.node_before(self)
    end

    #
    # Return the sibling Node that comes before this in the parent
    # NodeList.
    #
    # Raises:
    #   -- NoParent if there's no parent
    #   -- BadParent if the parent is otherwise not a NodeList
    #
    def list_prev
      @parent or raise NoParent
      @parent.NodeList? or raise BadParent
      return @parent.node_before(self)
    end

    #
    # Detach this Node from the tree and return it.
    #
    # Raises NoParent if there's no parent.
    #
    def detach
      @parent or raise NoParent
      @parent.remove_node(self)
      return self
    end

    #
    # Replace this Node in the tree with the given node(s).  Return
    # this node.
    #
    # Raises:
    #   -- NoParent if there's no parent
    #   -- BadParent if the parent is otherwise not a NodeList, and
    #      more than one node is given.
    #
    def replace_with(*nodes)
      @parent or raise NoParent
      @parent.replace_node(self, *nodes)
      return self
    end

    #
    # Swap this node with `node' in their trees.  If either node is
    # detached, the other will become detached as a result of calling
    # this method.
    #
    def swap_with node
      return self if node.equal? self
      if self.attached?
        if node.attached?
          # both attached -- use placeholder
          placeholder = Default.new
          my_parent = @parent
          my_parent.replace_node(self, placeholder)
          node.parent.replace_node(node, self)
          my_parent.replace_node(placeholder, node)
        else
          # only `self' attached
          @parent.replace_node(self, node)
        end
      else
        if node.attached?
          # only `node' attached
          node.parent.replace_node(node, self)
        else
          # neither attached -- nothing to do
        end
      end
      return self
    end

    #
    # Insert `newnodes' before this node.  Return this node.
    #
    # Raises:
    #   -- NoParent if there's no parent
    #   -- BadParent if the parent is otherwise not a NodeList
    #
    def insert_prev(*newnodes)
      @parent or raise NoParent
      @parent.NodeList? or raise BadParent
      @parent.insert_before(self, *newnodes)
      return self
    end

    #
    # Insert `newnodes' after this node.  Return this node.
    #
    # Raises:
    #   -- NoParent if there's no parent
    #   -- BadParent if the parent is otherwise not a NodeList
    #
    def insert_next(*newnodes)
      @parent or raise NoParent
      @parent.NodeList? or raise BadParent
      @parent.insert_after(self, *newnodes)
      return self
    end

    #
    # Return true if this Node is detached (i.e., #parent is nil),
    # false otherwise.
    #
    # This is equal to !attached?
    #
    def detached?
      @parent.nil?
    end

    #
    # Return true if this Node is attached (i.e., #parent is nonnil),
    # false otherwise.
    #
    # This is equal to !detached?
    #
    def attached?
      !@parent.nil?
    end

    # ----------------------------------------------------------------
    #                       Subclass management
    # ----------------------------------------------------------------

    #
    # The direct subclasses of this class (an Array of Class).
    #
    attr_reader :subclasses

    #
    # Return all classes which have this class somewhere in its
    # ancestry (an Array of Class).
    #
    def self.subclasses_recursive
      ret = @subclasses.dup
      @subclasses.each{|c| ret.concat(c.subclasses_recursive)}
      return ret
    end

    #
    # Callback defined in Class.
    #
    def self.inherited(klass)
      @subclasses << klass
      klass.instance_variable_set(:@subclasses, [])
      klass.instance_variable_set(:@fields    , [])
    end

    #
    # Declare this class as abstract.
    #
    def self.abstract
    end

    # set the instance vars for Node
    @subclasses = []
    @fields     = []

    # --------------------------------------------------------------
    #
    #                             Fields
    #
    # Fields are interesting attributes, that are, e.g., compared in
    # `==', and copied in `dup' and `clone'.  "Child" fields are also
    # yielded in a traversal.  For each field, a setter and getter is
    # created, and the corresponding instance variable is set in
    # `initialize'.
    #
    # Child fields are declared using Node.child; other fields are
    # declared using Node.field.
    #
    # --------------------------------------------------------------

    private  # -------------------------------------------------------

    #
    # Add the Field `newfield' to the list of fields for this class.
    #
    def self.add_field(newfield)
      # add the newfield to @fields, and set the index
      fields = @fields
      newfield.index = fields.length
      fields << newfield
      # getter
      # define_method(newfield.reader) do
      #   instance_variable_get(newfield.var)
      # end
      eval "def #{newfield.reader}; #{newfield.var}; end"
      # setter
      if newfield.child?
        define_method(newfield.writer) do |val|
          old = send(newfield.reader)
          return if val.equal? old
          # detach the old Node
          old = self.send(newfield.reader)
          unless old.nil?
            old.instance_variable_set(:@parent, nil)
          end
          # copy val if needed
          val = val.clone if !val.nil? && val.attached?
          # set
          self.instance_variable_set(newfield.var, val)
          # attach the new Node
          unless val.nil?
            val.instance_variable_set(:@parent, self)
            val.instance_variable_set(:@parent_field, newfield)
          end
        end
      else
        define_method(newfield.writer) do |val|
          instance_variable_set(newfield.var, val)
        end
      end
    end
    def self.fields
      @fields
    end

    #
    # Define an initialize method.  The initialize method sets the
    # fields named in `syms' from the arguments given to it.  The
    # initialize method also takes named parameters (i.e., an optional
    # Hash as the last argument), which may be used to set fields not
    # even named in `syms'.  The syms in the optional Hash are the
    # values of the `init_key' members of the corresponding Field
    # objects.
    #
    # As an example for this Node class:
    #
    #   class X < Node
    #     field :x
    #     field :y
    #     child :z
    #     initializer :z, :y
    #   end
    #
    # ...X.new can be called in any of these ways:
    #
    #   X.new                           # all fields set to default
    #   X.new(1)                        # .z = 1
    #   X.new(1, 2)                     # .z = 1, .y = 2
    #   X.new(:x = 1, :y => 2, :z => 3) # .x = 1, .y = 2, .z = 3
    #   X.new(1, :x => 2)               # .z = 1, .x = 2
    #   X.new(1, :z => 2)               # undefined behaviour!
    #   ...etc.
    #
    def self.initializer(*syms)
      define_method(:initialize) do |*args|
        # pop off the opts hash
        opts = args.last.is_a?(::Hash) ? args.pop : {}

        # add positional args to opts
        args.each_with_index do |arg, i|
          opts[syms[i]] = arg
        end

        # set field values
        fields.each do |field|
          key = field.init_key
          if opts.key?(key)
            send(field.writer, opts[key])
          else
            send(field.writer, field.make_default)
          end
        end

        # pos, parent
        @pos    = nil
        @parent = nil
      end
    end

    public  # --------------------------------------------------------

    #
    # Declare a field with the given name and default value.
    #
    def self.field(name, default=:'no default')
      if default == :'no default'
        if name.to_s[-1] == ??
          default = false
        else
          default = nil
        end
      end

      # if the field exists, just update its default, otherwise, add
      # a new field
      self.fields.each do |field|
        if field.reader == name
          field.default = default
          return
        end
      end
      add_field Field.new(name, default)
    end

    #
    # Declare a child with the given name and default value.  The
    # default value is cloned when used (unless cloning is
    # unnecessary).
    #
    def self.child(name, default=nil)
      field = Field.new(name, default)
      field.child = true
      add_field field
    end

    #
    # Return the list of fields this object has.  Don't modify the
    # returned array!
    #
    def fields
      self.class.fields
    end

    def method_missing(meth, *args, &blk)
      # respond to `Module?'
      methstr = meth.to_s
      if methstr =~ /^([A-Z].*)\?$/ && C.const_defined?($1)
        klass = C.const_get($1)
        if klass.is_a?(::Module)
          return self.is_a?(klass)
        end
      end

      begin
        super
      rescue NoMethodError => e
        e.set_backtrace(caller)
        raise e
      end
    end

    # ----------------------------------------------------------------
    #                         Child management
    # ----------------------------------------------------------------

    public  # --------------------------------------------------------

    #
    # Return the Node that comes after the given Node in tree
    # preorder.
    #
    def node_after(node)
      node.parent.equal? self or
        raise ArgumentError, "node is not a child"
      fields = self.fields
      i = node.instance_variable_get(:@parent_field).index + 1
      (i...fields.length).each do |i|
        f = fields[i]
        if f.child? && (val = self.send(f.reader))
          return val
        end
      end
      return nil
    end

    #
    # Return the Node that comes before the given Node in tree
    # preorder.
    #
    def node_before(node)
      node.parent.equal? self or
        raise ArgumentError, "node is not a child"
      fields = self.fields
      i = node.instance_variable_get(:@parent_field).index - 1
      i.downto(0) do |i|
        f = fields[i]
        if f.child? && (val = self.send(f.reader))
          return val
        end
      end
      return nil
    end

    #
    # Remove the given Node.
    #
    def remove_node(node)
      node.parent.equal? self or
        raise ArgumentError, "node is not a child"
      field = node.instance_variable_get(:@parent_field)
      node.instance_variable_set(:@parent, nil)
      node.instance_variable_set(:@parent_field, nil)
      self.instance_variable_set(field.var, nil)
      return self
    end

    #
    # Replace `node' with `newnode'.
    #
    def replace_node(node, newnode=nil)
      node.parent.equal? self or
        raise ArgumentError, "node is not a child"
      field = node.instance_variable_get(:@parent_field)
      self.send(field.writer, newnode)
      return self
    end

    # ----------------------------------------------------------------
    #                           Node::Field
    # ----------------------------------------------------------------

    private  # -------------------------------------------------------

    class Field
      attr_accessor :var, :reader, :writer, :init_key, :index,
                    :default

      #
      # True if this field is a child field, false otherwise.
      #
      attr_writer :child
      def child?
        @child
      end

      #
      # Create a default value for this field.  This differs from
      # #default in that if it's a Proc, it is called and the result
      # returned.
      #
      def make_default
        if @default.respond_to? :call
          @default.call
        else
          @default
        end
      end

      def initialize(name, default)
        name = name.to_s

        @child  = false
        @reader = name.to_sym
        @default = default

        if name[-1] == ?? then name[-1] = '' end
        @init_key = name.to_sym
        @var      = "@#{name}".to_sym
        @writer   = "#{name}=".to_sym
      end
    end

    public  # -------------------------------------------------------

    #
    # A position in a source file.  All Nodes may have one in their
    # #pos attribute.
    #
    class Pos
      attr_accessor :filename, :line_num, :col_num
      def initialize(filename, line_num, col_num)
        @filename = filename
        @line_num = line_num
        @col_num  = col_num
      end
      def to_s
        (@filename ? "#@filename:" : '') << "#@line_num:#@col_num"
      end
      def <=>(x)
        return nil if self.filename != x.filename
        return (self.line_num <=> x.line_num).nonzero? ||
          self.col_num <=> x.col_num
      end
      include Comparable
    end
  end
end
