require 'rbconfig'

######################################################################
#
# A C preprocessor that wraps the command in Config::CONFIG['CPP'].
#
# Assumes a POSIX-style cpp command line interface, in particular, -I
# and -D options.
#
######################################################################

module C
  class Preprocessor
    class Error < StandardError
    end

    class << self
      attr_accessor :command
    end
    self.command = (defined?(RbConfig) ? RbConfig : Config)::CONFIG['CPP']

    attr_accessor :pwd, :include_path, :macros, :undef_macros

    def initialize
      @include_path = []
      @macros = {}
      @undef_macros = Set.new
    end
    def preprocess(text)
      filename = nil
      temp_file = nil
      Tempfile.open(['cast-preprocessor-input.', '.c'], File.expand_path(pwd || '.')) do |file|
        temp_file = file
        filename = file.path
        file.puts text
      end
      return preprocess_file(filename);
    ensure
      if temp_file
        temp_file.close
        temp_file.unlink
      end
    end
    def preprocess_file(file_name, options={})
      file_name = File.expand_path(file_name)
      dir = File.dirname(file_name)
      stderr_buf = Tempfile.new('cast-preprocessor-stderr.txt')
      FileUtils.cd(dir) do
        output = `#{full_command(file_name)} 2>#{shellquote(stderr_buf.path)}`
        if $? == 0 || options[:force] && !output.empty?
          return output
        else
          raise Error, stderr_buf.read
        end
      end
    ensure
      stderr_buf.close
      stderr_buf.unlink
    end

    private  # -------------------------------------------------------

    def shellquote(arg)
      if arg !~ /[\"\'\\$&<>\(\)|\s]/
        return arg
      elsif arg !~ /\'/
        return "'#{arg}'"
      else
        arg.gsub!(/([\"\\$&<>|])/, '\\\\\\1')
        return "\"#{arg}\""
      end
    end
    def full_command(filename)
      include_args = include_path.map do |path|
        "#{shellquote('-I'+path)}"
      end.join(' ')
      macro_args   = (undef_macros.map{|m| shellquote "-U#{m}"} +
        macros.map do |key, val|
          case key
          when :@imacros
            "-imacros" + shellquote(File.expand_path(val))
          when :@include
            "-include" + shellquote(File.expand_path(val))
          else
            shellquote("-D#{key}#{"=#{val}" if val}")
          end
        end).join(' ')
      filename = shellquote(filename)
      "#{Preprocessor.command} #{include_args} #{macro_args} #{filename}"
    end
  end
end
