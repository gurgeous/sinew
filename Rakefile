require 'bundler/setup'
require 'rake/testtask'

# load the spec, we use it below
spec = Gem::Specification.load('sinew.gemspec')

#
# testing
# don't forget about TESTOPTS="--verbose" rake
# also: rake install && rm -rf ~/.sinew/www.amazon.com && /usr/local/bin/sinew sample.sinew
#

# test (default)
Rake::TestTask.new
task default: :test

# Watch rb files, run tests whenever something changes
task :watch do
  sh "find . -name '*.rb' -o -name '*.sinew' | entr -c rake"
end

#
# pry
#

task :pry do
  sh 'pry -I lib -r sinew.rb'
end

#
# rubocop
#

task :rubocop do
  sh 'bundle exec rubocop -A .'
end

#
# gem
#

task :build do
  sh 'gem build --quiet sinew.gemspec'
end

task install: :build do
  sh "gem install --quiet sinew-#{spec.version}.gem"
end

task release: %i[rubocop test build] do
  sh "git tag -a #{spec.version} -m 'Tagging #{spec.version}'"
  sh 'git push --tags'
  sh "gem push sinew-#{spec.version}.gem"
end
