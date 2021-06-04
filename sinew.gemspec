$LOAD_PATH.unshift("#{__dir__}/lib")

require 'sinew/version'

Gem::Specification.new do |s|
  s.name = 'sinew'
  s.version = Sinew::VERSION
  s.authors = ['Adam Doppelt', 'Nathan Kriege']
  s.email = ['amd@gurge.com']

  s.summary = 'Sinew - structured web crawling using recipes.'
  s.description = 'Crawl web sites easily using ruby recipes, with caching and nokogiri.'
  s.homepage = 'http://github.com/gurgeous/sinew'
  s.license = 'MIT'
  s.required_ruby_version = '>= 2.7'

  # what's in the gem?
  s.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { _1.match(%r{^test/}) }
  end
  s.bindir = 'bin'
  s.executables = s.files.grep(%r{^#{s.bindir}/}) { File.basename(_1) }
  s.require_paths = ['lib']

  # gem dependencies
  s.add_dependency 'amazing_print', '~> 1.3'
  s.add_dependency 'faraday', '~> 1.4'
  s.add_dependency 'faraday-encoding', '~> 0'
  s.add_dependency 'faraday-rate_limiter', '~> 0.0'
  s.add_dependency 'httpdisk', '~> 0'
  s.add_dependency 'nokogiri', '~> 1.11'
  s.add_dependency 'slop', '~> 4.8'
  s.add_dependency 'sterile', '~> 1.0'
end
