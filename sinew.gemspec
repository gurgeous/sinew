$LOAD_PATH << File.expand_path("../lib", __FILE__)

require "sinew/version"

Gem::Specification.new do |s|
  s.name        = "sinew"
  s.version     = Sinew::VERSION
  s.platform    = Gem::Platform::RUBY
  s.license     = "MIT"
  s.authors     = ["Adam Doppelt"]
  s.email       = ["amd@gurge.com"]
  s.homepage    = "http://github.com/gurgeous/sinew"
  s.summary     = "Sinew - structured web crawling using recipes."
  s.description = "Crawl web sites easily using ruby recipes, with caching and nokogiri."

  s.rubyforge_project = "sinew"

  s.add_runtime_dependency "activesupport", "~> 3.0"
  s.add_runtime_dependency "awesome_print"
  s.add_runtime_dependency "htmlentities"
  s.add_runtime_dependency "nokogiri"
  s.add_runtime_dependency "stringex", "~> 2.0"
  s.add_runtime_dependency "trollop"
  s.add_development_dependency "rake"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
