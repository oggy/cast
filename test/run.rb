#!/usr/bin/env ruby

Dir.new(Dir.pwd).grep(/^test_/) do |filename|
  require "#{Dir.pwd}/#{filename}"
end
