require 'ritual'
require 'rake/testtask'

task default: :test

Rake::TestTask.new(test: [:ext, 'lib/cast/c.tab.rb']) do |t|
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb']
  t.warning = false
end

extension

file 'ext/cast.so' => FileList['ext/*.c', 'ext/yylex.c'] do |t|
  FileUtils.cd 'ext' do
    ruby 'extconf.rb'
    sh 'make'
  end
end

file 'ext/yylex.c' => 'ext/yylex.re' do |t|
  sh "re2c #{t.prerequisites[0]} > #{t.name}"
end

file 'lib/cast/c.tab.rb' => 'lib/cast/c.y' do |t|
  sh "racc #{t.prerequisites[0]}"
end

task :ext => 'ext/yylex.c'
task 'gem:build' => ['ext/yylex.c', 'lib/cast/c.tab.rb']
CLEAN.include('ext/yylex.c', 'lib/cast/c.tab.rb')
