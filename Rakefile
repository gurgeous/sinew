require "bundler"
require "bundler/setup"
require "rake"
require "rake/testtask"

$LOAD_PATH << File.expand_path("../lib", __FILE__)
require "sinew/version"

#
# gem
#

task :gem => :build
task :build do
  system "gem build --quiet sinew.gemspec"
end

task :install => :build do
  system "sudo gem install --quiet sinew-#{Sinew::VERSION}.gem"
end

task :release => :build do
  system "git tag -a #{Sinew::VERSION} -m 'Tagging #{Sinew::VERSION}'"
  system "git push --tags"
  system "gem push sinew-#{Sinew::VERSION}.gem"
end

#
# minitest
#

Rake::TestTask.new(:test) do |test|
  test.libs << "test"
end

task :default => :test

# to test:
# block ; rake install && rm -rf ~/.sinew/www.amazon.com && /usr/local/bin/sinew sample.sinew
