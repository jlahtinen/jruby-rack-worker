require_relative 'lib/jruby/rack/worker/version'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

# see rakelib/*.rake

desc 'Cleans earliar builds'
task clean: ['java_build:clean'] do
  FileUtils.rm_f(Dir.glob('lib/jruby-rack-worker*.jar'))
end

desc 'Builds if clean'
task :build do
  next if File.exist?('target')

  Rake::Task['java_build:copy_jar'].invoke
end

desc 'Cleans earlier builds and creates a new build. After build project is in a state gem can be built'
task clean_build: %i[clean build] do
end

task test: ['spec'] do
end

task test_all: %w[java_build:test test] do
end

task default: :test_all
