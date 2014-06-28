source 'https://rubygems.org'

ver = ENV['AR_TEST_VERSION']
ver = ver.dup.chomp if ver

gem 'activerecord', ver
gem 'activesupport', ver

group :test do
  gem 'rake'
  gem 'sqlite3'
  gem 'pry'
  gem 'awesome_print'
  gem 'database_cleaner'
  gem 'rspec'
end
