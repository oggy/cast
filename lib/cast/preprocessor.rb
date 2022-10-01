require 'rbconfig'
require 'shellwords'

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

    attr_accessor :pwd, :include_path, :macros

    def initialize(quiet: false)
      @include_path = []
      @macros = {}
      @quiet = quiet
    end
    def preprocess(text)
      filename = nil
      output = nil
      Tempfile.open(['cast-preprocessor-input.', '.c']) do |file|
        filename = file.path
        file.puts text
	file.flush
        output = `#{full_command(filename)} #{'2> /dev/null' if @quiet}`
      end
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

    def full_command(filename)
      include_args = include_path.map { |path| "-I#{path}" }
      macro_args = macros.sort.map { |key, val| "-D#{key}" + (val ? "=#{val}" : '') }
      [*Preprocessor.command.shellsplit, *include_args, *macro_args, filename].shelljoin
    end
  end
end
