## these env vars are to facilitate testing -- see test/run.rb in the
## cast source
extdir = ENV['CAST_EXTDIR'] || ''
libdir = ENV['CAST_LIBDIR'] || 'cast'

extdir += '/' unless extdir.empty?
libdir += '/' unless libdir.empty?

require "#{extdir}cast_ext.so"
require "#{libdir}tempfile.rb"
require "#{libdir}preprocessor.rb"
require "#{libdir}node.rb"
require "#{libdir}node_list.rb"
require "#{libdir}c_nodes.rb"
require "#{libdir}c.tab.rb"
require "#{libdir}parse.rb"
require "#{libdir}to_s.rb"
require "#{libdir}inspect.rb"
