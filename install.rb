require 'fileutils'
include FileUtils
require 'rbconfig'

SRC = File.expand_path('lib')
DEST = "#{Config::CONFIG['sitelibdir']}/cast"

opts = {:verbose => true}
if ARGV[0] == 'remove'
  rm_rf DEST, opts
else
  rm_rf DEST, opts
  cp_r SRC, DEST, opts
end
