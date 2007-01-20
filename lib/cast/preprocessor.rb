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
    self.command = Config::CONFIG['CPP']

    attr_accessor :pwd, :include_path, :macros

    def initialize
      @include_path = []
      @macros = {}
    end
    def preprocess(text)
      filename = nil
      Tempfile.open('cast-preprocessor-input.',
                    File.expand_path(pwd || '.'), '.c') do |file|
        filename = file.path
        file.puts text
      end
      output = `#{full_command(filename)} 2>&1`
      if $? == 0
        return output
      else
        raise Error, output
      end
    end
    def preprocess_file(file_name)
      file_name = File.expand_path(file_name)
      dir = File.dirname(file_name)
      FileUtils.cd(dir) do
        return preprocess(File.read(file_name))
      end
    end

    private  # -------------------------------------------------------

    def shellquote(arg)
      if arg !~ /[\"\'\\$&<>|\s]/
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
      macro_args   = macros.sort.map do |key, val|
        shellquote("-D#{key}" + (val ? "=#{val}" : ''))
      end.join(' ')
      filename = shellquote(filename)
      "#{Preprocessor.command} #{include_args} #{macro_args} #{filename}"
    end
  end
end
