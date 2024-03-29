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
  s.add_dependency "amazing_print", "~> 1.5"
  s.add_dependency "faraday", "~> 2.7"
  s.add_dependency "faraday-encoding", "~> 0.0"
  s.add_dependency "faraday-rate_limiter", "~> 0.0"
  s.add_dependency "faraday-retry", "~> 2.0"
  s.add_dependency "hashie", "~> 5.0"
  s.add_dependency "httpdisk", "~> 1.0"
  s.add_dependency "nokogiri", "~> 1.15"
  s.add_dependency "slop", "~> 4.10"
  s.add_dependency "sterile", "~> 1.0"
end
