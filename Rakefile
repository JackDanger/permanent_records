require 'bundler'
require 'yaml'
require 'English'
Bundler::GemHelper.install_tasks

CONFIG = YAML.load_file(
  File.expand_path('spec/support/database.yml', File.dirname(__FILE__))
)

def test_database_exists?
  system "psql -l | grep -q #{CONFIG['test'][:database]}"
  $CHILD_STATUS.success?
end

def create_test_database
  system "createdb #{CONFIG['test'][:database]}"
end

namespace :db do
  task :create do
    create_test_database unless test_database_exists?
  end
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new do |t|
  t.options = ['-d']
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:rspec) do |t|
  t.rspec_opts = '-f d -c'
end

task default: [:rspec, :rubocop]
