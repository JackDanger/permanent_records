# Include this file in your test by copying the following line to your test:
#   require File.expand_path(File.dirname(__FILE__) + "/test_helper")

$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'rubygems'
require 'test/unit'
require 'active_record'
require 'active_record/fixtures'
require File.expand_path(File.dirname(__FILE__) + '/../lib/permanent_records')

require File.expand_path(File.dirname(__FILE__) + "/../test_lib/muskrat")

config = YAML::load(IO.read(File.dirname(__FILE__) + '/../test_lib/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/../test_lib/debug.log")
ActiveRecord::Base.establish_connection(config[ENV['DB'] || 'sqlite3'])

load(File.dirname(__FILE__) + "/../test_lib/schema.rb") if File.exist?(File.dirname(__FILE__) + "/../test_lib/schema.rb")

class ActiveSupport::TestCase #:nodoc:
  include ActiveRecord::TestFixtures
  # def create_fixtures(*table_names)
  #   if block_given?
  #     Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names) { yield }
  #   else
  #     Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names)
  #   end
  # end

  self.fixture_path = File.dirname(__FILE__) + "/fixtures/"
  $LOAD_PATH.unshift(fixture_path)

  # Turn off transactional fixtures if you're working with MyISAM tables in MySQL
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where you otherwise would need people(:david)
  self.use_instantiated_fixtures  = false

  # Add more helper methods to be used by all tests here...
  def monitor_for(class_name)
    result = class_name
    result += '.unscoped' if ActiveRecord::VERSION::MAJOR >= 3
    result += '.count'
  end
end
