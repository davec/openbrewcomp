# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rtex}
  s.version = "2.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Bruce Williams, Wiebe Cazemier"]
  s.date = %q{2009-02-26}
  s.default_executable = %q{rtex}
  s.description = %q{LaTeX preprocessor for PDF generation; Rails plugin}
  s.email = %q{bruce@codefluency.com}
  s.executables = ["rtex"]
  s.extra_rdoc_files = ["bin/rtex", "CHANGELOG", "lib/rtex/document.rb", "lib/rtex/escaping.rb", "lib/rtex/framework/merb.rb", "lib/rtex/framework/rails.rb", "lib/rtex/tempdir.rb", "lib/rtex/version.rb", "lib/rtex.rb", "README.rdoc", "README_RAILS.rdoc"]
  s.files = ["bin/rtex", "CHANGELOG", "init.rb", "lib/rtex/document.rb", "lib/rtex/escaping.rb", "lib/rtex/framework/merb.rb", "lib/rtex/framework/rails.rb", "lib/rtex/tempdir.rb", "lib/rtex/version.rb", "lib/rtex.rb", "Manifest", "rails/init.rb", "Rakefile", "README.rdoc", "README_RAILS.rdoc", "test/document_test.rb", "test/filter_test.rb", "test/fixtures/first.tex", "test/fixtures/first.tex.erb", "test/fixtures/fragment.tex.erb", "test/fixtures/text.textile", "test/tempdir_test.rb", "test/test_helper.rb", "vendor/instiki/LICENSE", "vendor/instiki/redcloth_for_tex.rb", "rtex.gemspec"]
  s.has_rdoc = true
  s.homepage = %q{http://rtex.rubyforge.org}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Rtex", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rtex}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{LaTeX preprocessor for PDF generation; Rails plugin}
  s.test_files = ["test/document_test.rb", "test/filter_test.rb", "test/tempdir_test.rb", "test/test_helper.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<Shoulda>, [">= 0"])
      s.add_development_dependency(%q<echoe>, [">= 0"])
    else
      s.add_dependency(%q<Shoulda>, [">= 0"])
      s.add_dependency(%q<echoe>, [">= 0"])
    end
  else
    s.add_dependency(%q<Shoulda>, [">= 0"])
    s.add_dependency(%q<echoe>, [">= 0"])
  end
end
