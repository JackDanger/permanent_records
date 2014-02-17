
# Include this file in your test by copying the following line to your test:
#   require File.expand_path(File.dirname(__FILE__) + "/test_helper")

lib     = Pathname.new File.expand_path('../../lib',       File.dirname(__FILE__))
support = Pathname.new File.expand_path('../spec/support', File.dirname(__FILE__))
$:.unshift lib
$:.unshift support
RAILS_ROOT = File.dirname(__FILE__)

require 'active_record'
require 'active_support'
require 'permanent_records'
require 'awesome_print'

module Rails
  def self.env; 'test'end
end

if I18n.config.respond_to?(:enforce_available_locales)
  I18n.config.enforce_available_locales = true
end

require 'logger'
ActiveRecord::Base.logger = Logger.new support.join("debug.log")
ActiveRecord::Base.configurations = YAML::load_file support.join('database.yml')
ActiveRecord::Base.establish_connection

load 'schema.rb' if File.exist?(support.join('schema.rb'))

Dir.glob(support.join('*.rb')).each do |file|
  autoload File.basename(file).chomp('.rb').camelcase.intern, file
end.each do |file|
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
