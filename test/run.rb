#!/usr/bin/env ruby

require 'test/unit'
require 'stringio'
require 'fileutils'

# require cast
CAST_ROOT = File.expand_path('..', File.dirname(__FILE__))
ENV['CAST_EXTDIR'] = "#{CAST_ROOT}/ext"
ENV['CAST_LIBDIR'] = "#{CAST_ROOT}/lib/cast"
require "#{CAST_ROOT}/lib/cast.rb"

# a dir to cd into for creating files and such
TEST_DIR = "#{CAST_ROOT}/test/var"

###
### ------------------------------------------------------------------
###                        Helpers for testing
### ------------------------------------------------------------------
###

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
  INDENT = '    '
  ###
  ### Assert that the given string is parsed as expected.  The given
  ### string is of the format:
  ###
  ### <program>
  ### ----
  ### <expected inspect string>
  ###
  ### The <program> part is yielded to obtain the AST.
  ###
  def check_ast test_data
    inp, exp = test_data.split(/^----+\n/)
    ast = yield(inp)
    assert_tree(ast)
    assert(ast.is_a?(C::Node))
    assert_equal_inspect_strs(exp, ast.inspect)
  end
  ###
  ### Assert that the given Node#inspect strings are equal.
  ###
  def assert_equal_inspect_strs exp, out
    ## remove EOL space
    out = out.gsub(/ *$/, '')
    exp = exp.gsub(/ *$/, '')

    ## normalize BOL space
    exp.gsub!(%r'^#{INDENT}*') do |s|
      levels = s.length / INDENT.length
      C::Node::INSPECT_TAB*levels
    end

    ## compare
    msg = "Debug strings unequal:\n#{juxtapose('Expected', exp, 'Output', out)}"
    assert_block(msg){out == exp}
  end
  ###
  ### Return a string of `s1' and `s2' side by side with a dividing
  ### line in between indicating differences.  `h1' and `h2' are the
  ### column headings.
  ###
  def juxtapose h1, s1, h2, s2
    s1 = s1.map{|line| line.chomp}
    s2 = s2.map{|line| line.chomp}
    rows = [s1.length, s2.length].max
    wl = s1.map{|line| line.length}.max
    wr = s2.map{|line| line.length}.max
    ret = ''
    ret << "#{('-'*wl)}----#{'-'*wr}\n"
    ret << "#{h1.ljust(wl)} || #{h2}\n"
    ret << "#{('-'*wl)}-++-#{'-'*wr}\n"
    (0...rows).each do |i|
      if i >= s1.length
        ret << "#{' '*wl}  > #{s2[i]}\n"
      elsif i >= s2.length
        ret << "#{s1[i].ljust(wl)} <\n"
      elsif s1[i] == s2[i]
        ret << "#{s1[i].ljust(wl)} || #{s2[i]}\n"
      else
        ret << "#{s1[i].ljust(wl)} <> #{s2[i]}\n"
      end
    end
    ret << "#{('-'*wl)}----#{'-'*wr}\n"
    return ret
  end
  ###
  ### Assert that an exception of the given class is raised, and that
  ### the message matches the given regex.
  ###
  def assert_error klass, re
    ex = nil
    assert_raise(klass) do
      begin
        yield
      rescue Exception => ex
        raise
      end
    end
    assert_match(re, ex.message)
  end
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
end

###
### ------------------------------------------------------------------
###                                Main
### ------------------------------------------------------------------
###

if $0 == __FILE__
  Dir["#{CAST_ROOT}/test/test_*"].each do |filename|
    require filename
  end
end
