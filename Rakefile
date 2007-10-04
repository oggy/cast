# -*- mode: ruby -*-

task :default => :test

require 'rake/testtask'
require 'rake/gempackagetask'

require 'rbconfig'
dlext = (Config::CONFIG['DLEXT'] rescue nil) || 'so'
FILES = FileList['README', 'ChangeLog', '{lib,ext,doc,test}/**/*', 'ext/yylex.c', 'lib/cast/c.tab.rb']

# cast_ext
file 'ext/cast_ext.so' => FileList['ext/*.c', 'ext/yylex.c'] do |t|
  FileUtils.cd 'ext' do
    ruby 'extconf.rb'
    sh 'make'
  end
end

# lexer
file 'ext/yylex.c' => 'ext/yylex.re' do |t|
  sh "re2c #{t.prerequisites[0]} > #{t.name}"
end

# parser
file 'lib/cast/c.tab.rb' => 'lib/cast/c.y' do |t|
  sh "racc #{t.prerequisites[0]}"
end

desc "Build."
task :lib => FileList['lib/cast/*.rb', 'lib/cast/c.tab.rb', 'ext/cast_ext.so']

desc "Run unit tests."
Rake::TestTask.new(:test => :lib) do |t|
  t.libs << 'ext' << 'test'
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end

desc "Run irb with cast loaded."
task :irb => :lib do
  sh 'irb -Ilib:ext -rcast'
end

INSTALL_MAP = {
  File.expand_path('lib/cast')              => "#{Config::CONFIG['sitelibdir']}/cast",
  File.expand_path('lib/cast.rb')           => "#{Config::CONFIG['sitelibdir']}/cast.rb",
  File.expand_path("ext/cast_ext.#{dlext}") => "#{Config::CONFIG['sitearchdir']}/cast_ext.#{dlext}"
}
desc "Build and install."
task :install => [:lib, :uninstall] do
  INSTALL_MAP.each do |src, dst|
    cp_r src, dst
  end
end

desc "Uninstall."
task :uninstall do
  INSTALL_MAP.each do |src, dst|
    rm_r(dst) if File.exist?(dst)
  end
end

# Gem spec
spec = Gem::Specification.new do |s|
  s.name = 'cast'
  s.summary = "C parser and AST constructor."
  s.version = '0.1.0'
  s.author = 'George Ogata'
  s.email = 'george.ogata@gmail.com'
  s.homepage = 'http://cast.rubyforge.org'
  s.rubyforge_project = 'cast'

  s.platform = Gem::Platform::RUBY
  s.extensions << 'ext/extconf.rb'
  s.files = FILES.to_a
  s.autorequire = 'cast'
  s.test_file = 'test/run.rb'
  s.has_rdoc = false
end

# Target: gem
# Target: package
# Target: clobber_package
# Target: repackage
Rake::GemPackageTask.new(spec) do |task|
  task.need_tar = true
  task.need_zip = true
end

desc "Remove temporary files in build process."
task :clean do
  sh 'rm -f ext/*.o'
end

desc "Remove all files built from initial source files (i.e., return source tree to pristine state)."
task :clobber => [:clean, :clobber_package] do
  sh 'rm -f ext/yylex.c'
  sh 'rm -f lib/cast/c.tab.rb'
  sh 'rm -f ext/cast_ext.so'
  sh 'rm -f ext/Makefile'
end
