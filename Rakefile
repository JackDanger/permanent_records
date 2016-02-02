require 'bundler'
require 'yaml'
Bundler::GemHelper.install_tasks

$config = YAML.load_file File.expand_path('spec/support/database.yml', File.dirname(__FILE__))

def test_database_exists?
  system "psql -l | grep -q #{$config['test'][:database]}"
  $CHILD_STATUS.success?
end

def create_test_database
  system "createdb #{$config['test'][:database]}"
end

namespace :db do
  task :create do
    create_test_database unless test_database_exists?
  end
end

task default: [:spec]

desc 'Run all tests'
task spec: 'db:create' do
  exec 'rspec'
end
