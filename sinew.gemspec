$LOAD_PATH.unshift("#{__dir__}/lib")

require "sinew/version"

Gem::Specification.new do |s|
  s.name = "sinew"
  s.version = Sinew::VERSION
  s.authors = ["Adam Doppelt", "Nathan Kriege"]
  s.email = ["amd@gurge.com"]

  s.summary = "Sinew - structured web crawling using recipes."
  s.description = "Crawl web sites easily using ruby recipes, with caching and nokogiri."
  s.homepage = "http://github.com/gurgeous/sinew"
  s.license = "MIT"
  s.required_ruby_version = ">= 3.1"

  # what's in the gem?
  s.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { _1.match(%r{^test/}) }
  end
  s.bindir = "bin"
  s.executables = s.files.grep(%r{^#{s.bindir}/}) { File.basename(_1) }
  s.require_paths = ["lib"]

  # gem dependencies
  s.add_dependency "amazing_print"
  s.add_dependency "faraday"
  s.add_dependency "faraday-encoding"
  s.add_dependency "faraday-rate_limiter"
  s.add_dependency "faraday-retry"
  s.add_dependency "hashie"
  s.add_dependency "httpdisk"
  s.add_dependency "nokogiri"
  s.add_dependency "slop"
  s.add_dependency "sterile"
end
