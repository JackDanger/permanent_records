require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "permanent_records"
    gem.summary = %Q{Soft-delete your ActiveRecord records}
    gem.description = %Q{Never Lose Data. Rather than deleting rows this sets Record#deleted_at and gives you all the scopes you need to work with your data.}
    gem.email = "gems@6brand.com"
    gem.homepage = "http://github.com/JackDanger/permanent_records"
    gem.authors = ["Jack Danger Canty"]
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.ruby_opts << '-rubygems'
  test.pattern = 'test/*_test.rb'
  test.verbose = true
end
task :spec => :test

task :default => :test

