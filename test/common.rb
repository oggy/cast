$: << File.expand_path('../lib')
require 'cast'
require 'test/unit'

if true
  class C::Node
    def pretty_print q
      q.text self.to_debug
    end
  end
end

class Array
  def same_list? other
    self.length == other.length or
      return false
    self.zip(other).all? do |mine, yours|
      mine.equal? yours or
        return false
    end
  end
end

class Integer
  ###
  ### Return a `self'-element array containing the result of the given
  ### block.
  ###
  def of &blk
    Array.new(self, &blk)
  end
end

module Test::Unit::Assertions
  ###
  ### Assert that the given ast's nodes' parents are correct, and
  ### there aren't non-Nodes where there shouldn't be.
  ###
  def assert_tree ast
    meth = 'unknown method'
    caller.each do |line|
      if line =~ /in `(test_.*?)'/  #`
        meth = $1
        break
      end
    end
    filename = "#{self.class}_#{meth}.out"
    begin
      assert_tree1(ast, nil)
      assert(true)
    rescue BadTreeError => e
      require 'pp'
      open("#{filename}", 'w'){|f| PP.pp(ast, f)}
      flunk("#{e.message}.  Output dumped to `#{filename}'.")
    end
  end
  ###
  def assert_tree1 x, parent
    if x.is_a? C::Node
      parent.equal? x.parent or
        raise BadTreeError, "#{x.class}:0x#{(x.id << 1).to_s(16)} has #{x.parent ? 'wrong' : 'no'} parent"
      x.fields.each do |field|
        next if !field.child?
        val = x.send(field.reader)
        next if val.nil?
        val.is_a? C::Node or
          raise BadTreeError, "#{x.class}:0x#{(x.id << 1).to_s(16)} is a non-Node child"
        assert_tree1(val, x)
      end
    end
  end
  class BadTreeError < StandardError; end
  ###
  ### Assert that `arg' is a C::NodeList.
  ###
  def assert_list arg
    assert_kind_of(C::NodeList, arg)
  end
  ###
  ### Assert that `arg' is an empty C::NodeList.
  ###
  def assert_empty_list arg
    assert_list arg
    assert(arg.empty?)
  end
  ###
  ### Assert that the elements of exp are the same as those of out,
  ### and are in the same order.
  ###
  def assert_same_list exp, out
    assert_equal(exp.length, out.length, "Checking length")
    (0...exp.length).each do |i|
      assert_same(exp[i], out[i], "At index #{i} (of 0...#{exp.length})")
    end
  end
  ###
  ### Assert that out is ==, but not the same as exp (i.e., it is a
  ### copy).
  ###
  def assert_copy exp, out
    assert_not_same exp, out
    assert_equal exp, out
  end
  ###
  ### Assert the invariants of `node'.
  ###
  def assert_invariants node
    node.assert_invariants(self)
  end
  ###
  ### Return a not-too-trivial C program string.
  ###
  def prog
    return <<EOS
int main(int argc, char **argv) {
  struct S {
    int i, j;
    float f, g;
  } x;
  x.i = (int)argv[2][5];
  return 0;
}
EOS
  end
end

module CheckAst
  INDENT = '    '

  ParseError = C::ParseError

  def check_ast test_data
    inp, exp = test_data.split(/^----+\n/)
    ast = yield(inp)
    assert_tree(ast)
    assert ast.is_a?(C::Node)
    out = ast.to_debug
    assert_equal_debug_strs(exp, out)
  end

  def assert_equal_debug_strs exp, out
    ## remove EOL space
    out = out.gsub(/ *$/, '')
    exp = exp.gsub(/ *$/, '')

    ## normalize BOL space
    exp.gsub!(%r'^#{INDENT}*') do |s|
      levels = s.length / INDENT.length
      C::Node::TO_DEBUG_TAB*levels
    end

    ## compare
    meth = 'unknown method'
    caller.each do |line|
      if line =~ /in `(test_.*?)'/  #`
        meth = $1
        break
      end
    end

    filename_prefix = "#{self.class}_#{meth}"

    assert_block("Debug strings unequal.  Output dumped to #{filename_prefix}.{exp,out}") do
      if out == exp
        true
      else
        classname = self.class.name.split(/::/)[-1]
        open("#{filename_prefix}.out", 'w'){|f| f.print(out)}
        open("#{filename_prefix}.exp", 'w'){|f| f.print(exp)}
        false
      end
    end
  end
end
