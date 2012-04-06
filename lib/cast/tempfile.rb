######################################################################
#
# Alternative to the standard ruby tempfile library, which lets you
# specify a filename suffix.
#
######################################################################

require 'delegate'
require 'tmpdir'
require 'tempfile'

#
# Setting the extension of a temp file has only been possible since
# Ruby 1.8.7.
#
module C
  if RUBY_VERSION >= '1.8.7'
    Tempfile = ::Tempfile
  else
    class Tempfile < ::Tempfile
      def initialize(basename, tmpdir=Dir::tmpdir)
        if basename.is_a?(::Array)
          basename, @suffix = *basename
        end
        super(basename, tmpdir)
      end

      def make_tmpname(basename, n)
        sprintf('%s%d.%d%s', basename, $$, n, @suffix)
      end
    end
  end
end
