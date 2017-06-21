require 'bundler'
require 'yaml'
require 'English'
Bundler::GemHelper.install_tasks

version = File.read('./VERSION').chomp
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

task :pandoc do
  system('pandoc -s -r markdown -w rst README.md -o README.rst')
end

task publish: [:pandoc, :rubocop, :rspec] do
  # Ensure the gem builds
  system('gem build permanent_records.gemspec') &&
    # And we didn't leave anything (aside from the gem) uncommitted
    !system('git status -s | egrep -v .') &&
    system('git push') &&
    system("gem push permanent_records-#{version}.gem")
end

task default: [:rspec, :rubocop]
