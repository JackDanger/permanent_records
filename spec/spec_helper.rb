
# Include this file in your test by copying the following line to your test:
#   require File.expand_path(File.dirname(__FILE__) + "/test_helper")

$:.unshift File.expand_path '/../lib',      File.dirname(__FILE__)
$:.unshift File.expand_path '../test_lib', File.dirname(__FILE__)
RAILS_ROOT = File.dirname(__FILE__)

require 'active_record'
require 'active_support'
require 'permanent_records'
require 'awesome_print'

module Rails
  def self.env; 'test'end
end

config = YAML::load(IO.read(File.dirname(__FILE__) + '/../test_lib/database.yml'))
require 'logger'
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/../test_lib/debug.log")
ActiveRecord::Base.configurations = config
ActiveRecord::Base.establish_connection

load 'schema.rb' if File.exist?(File.dirname(__FILE__) + "/../test_lib/schema.rb")

test_support = Dir.glob(File.expand_path '../test_lib/*.rb', File.dirname(__FILE__))
test_support.each do |file|
  autoload File.basename(file).chomp('.rb').camelcase.intern, file
end
test_support.each do |file|
  require file
end

require 'database_cleaner'

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
