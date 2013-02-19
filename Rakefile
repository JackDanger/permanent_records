require 'bundler'
Bundler::GemHelper.install_tasks

namespace :db do
  task :create do
    `createdb permanent_records`
  end
end

desc 'Run all tests'
task :spec => 'db:create' do
  exec 'rspec'
end
