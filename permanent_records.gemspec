Gem::Specification.new do |s|
  s.name = 'permanent_records'
  s.version = File.read('VERSION')
  s.license = 'MIT'

  s.authors = ['Jack Danger Canty', 'David Sulc', 'Joe Nelson',
               'Trond Arve Nordheim', 'Josh Teneycke', 'Maximilian Herold',
               'Hugh Evans', 'Sergey Gnuskov', 'aq', 'Joel AZEMAR']
  s.summary = 'Soft-delete your ActiveRecord records'
  s.description = <<-DESCRIPTION
    Never Lose Data. Rather than deleting rows this sets Record#deleted_at and
    gives you all the scopes you need to work with your data.
  DESCRIPTION
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

  s.add_runtime_dependency 'activerecord',  ver || '>= 5.0.0'
  s.add_runtime_dependency 'activesupport', ver || '>= 5.0.0'
  s.add_development_dependency 'database_cleaner', '>= 1.5.1'
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'rake' # For Travis-ci
  s.add_development_dependency 'rspec', '>= 3.5.0'
  s.add_development_dependency 'rubocop', '~> 0.68.0' # freeze to ensure ruby 2.2 compatibility
  s.add_development_dependency 'rubocop-performance'
  s.add_development_dependency 'sqlite3', '~> 1.3.13' # freeze to ensure specs are working
end
