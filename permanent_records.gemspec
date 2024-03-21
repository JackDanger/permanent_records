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

  s.required_ruby_version = '>= 2.7.8'

  s.add_runtime_dependency 'activerecord', '>= 5.2'
  s.add_runtime_dependency 'activesupport', '>= 5.2'

  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'database_cleaner', '>= 1.5.1'
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '>= 3.5.0'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rubocop-performance'
  s.add_development_dependency 'sqlite3'
end
