require "bundler"
require "bundler/setup"

require "rake"
require "rdoc/task"

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
# rdoc
#

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.title = "sinew #{Sinew::VERSION}"
  rdoc.rdoc_files.include("lib/**/*.rb")
end

task :default => :gem

# to test:
# block ; rake install && rm -rf ~/.sinew/www.amazon.com && /usr/local/bin/sinew sample.sinew
