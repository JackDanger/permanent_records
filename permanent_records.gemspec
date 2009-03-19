Gem::Specification.new do |s|
  s.name = %q{permanent_records}
  s.version = "1.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jack Danger Canty"]
  s.date = %q{2009-03-19}
  s.email = ["gems@6brand.com"]
  s.extra_rdoc_files = ["Manifest.txt"]
  s.files = ["MIT-LICENSE", "Manifest.txt", "README", "Rakefile", "init.rb", "install.rb", "lib/permanent_records.rb", "tasks/permanent_records_tasks.rake", "test/cached_values_test.rb", "test/database.yml", "test/hole.rb", "test/kitty.rb", "test/mole.rb", "test/muskrat.rb", "test/permanent_records_test.rb", "test/schema.rb", "test/test_helper.rb", "uninstall.rb"]
  s.has_rdoc = true
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{permanent_records}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Soft-delete your ActiveRecord data.}
  s.test_files = ["test/test_helper.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<hoe>, [">= 1.11.0"])
    else
      s.add_dependency(%q<hoe>, [">= 1.11.0"])
    end
  else
    s.add_dependency(%q<hoe>, [">= 1.11.0"])
  end
end
