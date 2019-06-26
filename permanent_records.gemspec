# encoding: utf-8
Gem::Specification.new do |s|
  s.name = 'permanent_records'
  s.version = File.read('VERSION')
  s.license = 'MIT'

  s.authors = ['Jack Danger Canty', 'David Sulc', 'Joe Nelson',
               'Trond Arve Nordheim', 'Josh Teneycke', 'Maximilian Herold',
               'Hugh Evans', 'Sergey Gnuskov', 'aq', 'Joel AZEMAR']
  s.summary = 'Soft-delete your ActiveRecord records'
  s.description = <<-EOS
Never Lose Data. Rather than deleting rows this sets Record#deleted_at and
gives you all the scopes you need to work with your data.
EOS
  s.email = 'github@jackcanty.com'
  s.extra_rdoc_files = [
    'LICENSE',
    'README.md'
  ]
  s.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  s.homepage = 'https://github.com/JackDanger/permanent_records'
  s.require_paths = ['lib']

  # For testing against multiple AR versions
  ver = ENV['AR_TEST_VERSION']
  ver = ver.dup.chomp if ver

  s.add_runtime_dependency 'activerecord',  ver || '>= 4.2.0'
  s.add_runtime_dependency 'activesupport', ver || '>= 4.2.0'
  s.add_development_dependency 'database_cleaner', '>= 1.5.1'
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'rake' # For Travis-ci
  s.add_development_dependency 'rspec', '>= 3.5.0'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'sqlite3'
end
