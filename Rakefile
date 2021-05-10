require 'bundler/setup'

require 'rake/testtask'
require 'sinew/version'

# load the spec, we use it below
spec = Gem::Specification.load('sinew.gemspec')

#
# testing
# don't forget about TESTOPTS="--verbose" rake
# also: rake install && rm -rf ~/.sinew/www.amazon.com && /usr/local/bin/sinew sample.sinew
#

# test (default)
Rake::TestTask.new { _1.libs << 'test' }
task default: :test

# Watch rb files, run tests whenever something changes
task :watch do
  # https://superuser.com/a/665208 / https://unix.stackexchange.com/a/42288
  system("while true; do find . -name '*.rb' | entr -c -d rake; test $? -gt 128 && break; done")
end

#
# rubocop
#

task :rubocop do
  system('bundle exec rubocop -A .', exception: true)
end

#
# gem
#

task :build do
  system 'gem build --quiet sinew.gemspec', exception: true
end

task install: :build do
  system "gem install --quiet sinew-#{spec.version}.gem", exception: true
end

task release: %i[rubocop test build] do
  system "git tag -a #{spec.version} -m 'Tagging #{spec.version}'", exception: true
  system 'git push --tags', exception: true
  system "gem push sinew-#{spec.version}.gem", exception: true
end
