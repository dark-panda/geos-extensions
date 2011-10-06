
# -*- ruby -*-

require 'rubygems'
require 'rubygems/package_task'
require 'rake/testtask'
require 'rdoc/task'

if RUBY_VERSION >= '1.9'
  begin
    gem 'psych'
  rescue Exception => e
    # it's okay, fall back on the bundled psych
  end
end

$:.push 'lib'

version = File.read('VERSION') rescue ''

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "geos-extensions"
    gem.summary = "Extensions for the GEOS library."
    gem.description = gem.summary
    gem.email = "code@zoocasa.com"
    gem.homepage = "http://github.com/zoocasa/geos-extensions"
    gem.authors =    [ "J Smith" ]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

desc 'Test GEOS interface'
Rake::TestTask.new(:test) do |t|
  t.test_files = FileList['test/**/*_tests.rb']
  t.verbose = false
end

desc 'Build docs'
Rake::RDocTask.new do |t|
  require 'rdoc'
  t.main = 'README.rdoc'
  t.title = "Geos Extensions #{version}"
  t.rdoc_dir = 'doc'
  t.rdoc_files.include('README.rdoc', 'MIT-LICENSE', 'lib/**/*.rb')
end

