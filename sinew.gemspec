$LOAD_PATH.unshift("#{__dir__}/lib")

require 'sinew/version'

Gem::Specification.new do |s|
  s.name        = 'sinew'
  s.version     = Sinew::VERSION
  s.platform    = Gem::Platform::RUBY
  s.license     = 'MIT'
  s.authors     = [ 'Adam Doppelt' ]
  s.email       = [ 'amd@gurge.com' ]
  s.homepage    = 'http://github.com/gurgeous/sinew'
  s.summary     = 'Sinew - structured web crawling using recipes.'
  s.description = 'Crawl web sites easily using ruby recipes, with caching and nokogiri.'
  s.required_ruby_version = '~> 2.7'

  s.rubyforge_project = 'sinew'

  s.add_runtime_dependency 'awesome_print', '~> 1.8'
  s.add_runtime_dependency 'faraday', '~> 1.4'
  s.add_runtime_dependency 'faraday-encoding', '~> 0'
  s.add_runtime_dependency 'htmlentities', '~> 4.3'
  s.add_runtime_dependency 'httparty', '~> 0.16'
  s.add_runtime_dependency 'httpdisk', '~> 0'
  s.add_runtime_dependency 'nokogiri', '~> 1.8'
  s.add_runtime_dependency 'scripto', '~> 0'
  s.add_runtime_dependency 'slop', '~> 4.6'
  s.add_runtime_dependency 'stringex', '~> 2.8'
  s.add_development_dependency 'minitest', '~> 5.11'
  s.add_development_dependency 'rake', '~> 12.3'
  s.add_development_dependency 'webmock', '~> 3.4'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = [ 'lib' ]
end
