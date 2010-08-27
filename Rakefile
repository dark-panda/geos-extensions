# -*- ruby -*-

require 'rubygems'
require 'rake/testtask'

desc 'Test Geos extensions'
Rake::TestTask.new(:test) do |t|
	t.libs << 'lib'
	t.pattern = 'test/**/*_test.rb'
	t.verbose = false
end

