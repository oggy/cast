require 'ritual'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
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
desc "Prepares gem for execution (generates files and compiles extenstion)"
task :compile => [:ext, 'lib/cast/c.tab.rb']
task 'gem:build' => ['ext/yylex.c', 'lib/cast/c.tab.rb']
CLEAN.include('ext/yylex.c', 'lib/cast/c.tab.rb')
