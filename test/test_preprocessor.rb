## publicize the private methods so we can test them easily
class C::Preprocessor
  public :shellquote, :full_command
  self.command = 'cpp -E'
end
class PreprocessorTest < Test::Unit::TestCase
  attr_accessor :cpp
  def setup
    @cpp = C::Preprocessor.new
    @cpp.include_path << 'dir1' << 'dir 2'
    @cpp.macros['V'] = nil
    @cpp.macros['I'] = 5
    @cpp.macros['S'] = '"blah"'
    @cpp.macros['SWAP(a,b)'] = 'a ^= b ^= a ^= b'
    FileUtils.rm_rf(TEST_DIR)
    FileUtils.mkdir_p(TEST_DIR)
  end
  def teardown
    FileUtils.rm_rf(TEST_DIR)
  end
  def test_shellquote
    assert_equal('a', cpp.shellquote('a'))
    assert_equal("'a b'", cpp.shellquote('a b'))
    assert_equal("'a$b'", cpp.shellquote('a$b'))
    assert_equal("'a\"b'", cpp.shellquote("a\"b"))
    assert_equal("'\\'", cpp.shellquote("\\"))
    assert_equal("\"a'b\"", cpp.shellquote("a'b"))
    assert_equal("\"a\\\\\\$\\\"'\"", cpp.shellquote("a\\$\"'"))
  end
  def test_full_command
    assert_equal("cpp -E -Idir1 '-Idir 2' -DI=5 '-DS=\"blah\"' " <<
                   "'-DSWAP(a,b)=a ^= b ^= a ^= b' -DV 'a file.c'",
                 cpp.full_command('a file.c'))
  end
  def test_preprocess
    output = cpp.preprocess("I S SWAP(x, y)")
    assert_match(/5/, output)
    assert_match(/"blah"/, output)
    assert_match(/x \^= y \^= x \^= y/, output)
  end
  def test_preprocess_include
    one_h = "#{TEST_DIR}/one.h"
    two_h = "#{TEST_DIR}/foo/two.h"
    File.open(one_h, 'w'){|f| f.puts "int one = 1;"}
    FileUtils.mkdir(File.dirname(two_h))
    File.open(two_h, 'w'){|f| f.puts "int two = 2;"}
    output = nil
    FileUtils.cd(TEST_DIR) do
      output = cpp.preprocess(<<EOS)
#include "one.h"
#include "foo/two.h"
int three = 3;
EOS
    end
    assert_match(/int one = 1;/, output)
    assert_match(/int two = 2;/, output)
    assert_match(/int three = 3;/, output)
  end
  def test_preprocess_file
    one_h = "#{TEST_DIR}/one.h"
    two_h = "#{TEST_DIR}/foo/two.h"
    main_c = "#{TEST_DIR}/main.c"
    File.open(one_h, 'w'){|f| f.puts "int one = 1;"}
    FileUtils.mkdir(File.dirname(two_h))
    File.open(two_h, 'w'){|f| f.puts "int two = 2;"}
    File.open(main_c, 'w'){|f| f.puts <<EOS}
#include "one.h"
#include "foo/two.h"
int three = 3;
EOS
    output = cpp.preprocess_file(main_c)
    assert_match(/int one = 1;/, output)
    assert_match(/int two = 2;/, output)
    assert_match(/int three = 3;/, output)
  end
end
