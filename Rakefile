require 'bundler'
require 'yaml'
Bundler::GemHelper.install_tasks

$config = YAML::load_file File.expand_path('spec/support/database.yml', File.dirname(__FILE__))

def test_database_exists?
  system "psql -l | grep -q #{$config['test'][:database]}"
  $?.success?
end

def create_test_database
  system "createdb #{$config['test'][:database]}"
end

namespace :db do
  task :create do
    create_test_database unless test_database_exists?
  end
end

desc 'Run all tests'
task :spec => 'db:create' do
  ['3.0.0', '3.2.12'].each do |version|
    ENV['AR_TEST_VERSION'] = version
    system 'bundle'

    confirmed_version = `bundle exec gem list activerecord | grep 'activerecord ('`
    puts "\n*** Testing using #{confirmed_version}"
    system 'bundle exec rspec'
    exit 1 unless $?.success?
  end
end
