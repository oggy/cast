### -*- mode: ruby -*-

require 'rake/gempackagetask'
require 'rubygems'

VERSION = '0.0.1'
FILES = FileList['README', 'install.rb', '{lib,doc,test}/**/*']

spec = Gem::Specification.new do |s|
  s.name = 'cast'
  s.summary = "C parser and AST constructor."
  s.version = VERSION
  s.author = 'George Ogata'
  s.email = 'g_ogata@optushome.com.au'
  s.homepage = 'http://cast.rubyforge.org'
  s.rubyforge_project = 'cast'

  s.platform = Gem::Platform::RUBY
  s.files = FILES.to_a
  s.require_path = 'lib'
  s.autorequire = 'cast'
  s.test_file = 'test/run.rb'
  s.has_rdoc = false
end

### Target: test
task :test do
  cd 'test' do
    sh 'ruby run.rb'
  end
end

### Target: package
### Target: clobber_package
### Target: repackage
Rake::GemPackageTask.new(spec) do |task|
  task.need_tar = true
  task.need_zip = true
end

task :default => [:test]
