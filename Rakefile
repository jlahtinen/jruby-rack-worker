unless defined?(JRUBY_VERSION)
  raise "Hey, we're not running within JRuby my dear !"
end

require 'ruby-maven'

PROJECT_NAME = 'jruby-rack-worker'

SRC_DIR = 'src'

MAIN_SRC_DIR = File.join(SRC_DIR, 'main/java')
RUBY_SRC_DIR = File.join(SRC_DIR, 'main/ruby')
TEST_SRC_DIR = File.join(SRC_DIR, 'test/java')

OUT_DIR = 'out'

MAIN_BUILD_DIR = File.join(OUT_DIR, 'classes')
TEST_BUILD_DIR = File.join(OUT_DIR, 'test-classes')
TEST_RESULTS_DIR = File.join(OUT_DIR, 'test-results')

LIB_BASE_DIR = 'lib'

load File.join(RUBY_SRC_DIR, "#{PROJECT_NAME.gsub('-', '/')}", 'version.rb')

def project_version
  JRuby::Rack::Worker::VERSION
end

def out_jar_path
  "#{OUT_DIR}/#{PROJECT_NAME}_#{project_version}.jar"
end

desc "build jar"
task :jar do
  RubyMaven.exec('package', '-DskipTests=true')

  mkdir_p MAIN_BUILD_DIR
  cp Dir["target/*.jar"].first, out_jar_path
end

desc "build gem"
task :gem => [ :jar ] do
  warn "building using JRuby: #{JRUBY_VERSION}" if JRUBY_VERSION > '9.0'

  mkdir_p gem_out = File.join(OUT_DIR, 'gem')
  mkdir_p gem_out_lib = File.join(gem_out, 'lib')

  cp FileList["LICENSE", "README.md"], gem_out
  cp out_jar_path, gem_out_lib

  if (jars = FileList["#{gem_out_lib}/*.jar"].to_a).size > 1
    abort "too many jars! #{jars.map{ |j| File.basename(j) }.inspect}\nrake clean first"
  end

  %w[*.rb jruby/**/*.rb].each do |glob|
    Dir[File.join(RUBY_SRC_DIR, glob)].each do |file|
      cp file, gem_out_lib
    end
  end

  Dir.chdir(gem_out) do
    rm_f gemspec_file = "#{PROJECT_NAME}.gemspec"
    gem_spec = Gem::Specification.new do |spec|
      spec.name = PROJECT_NAME
      spec.version = project_version
      spec.authors = ["Karol Bucek"]
      spec.email = ["self@kares.org"]
      spec.homepage = 'https://github.com/kares/jruby-rack-worker'
      spec.license = 'Apache-2.0'
      spec.summary = 'Threaded Workers with JRuby-Rack'
      spec.description =
        "Implements a thread based worker pattern on top of JRuby-Rack. " +
        "Useful if you'd like to run background workers within your (deployed) " +
        "web-application, concurrently in 'native' threads, instead of using " +
        "separate daemon processes. " +
        "Provides (thread-safe) implementations for popular worker libraries " +
        "such as Resque and Delayed::Job, but one can easily write their own " +
        "'daemon' work processing loop as well."

      spec.add_dependency 'jruby-rack', "~> 1.1.10"
      spec.files = FileList["./**/*"].exclude("*.gem").map{ |f| f.sub(/^\.\//, '') }
      spec.has_rdoc = false
      spec.rubyforge_project = '[none]'
    end
    defined?(Gem::Builder) ? Gem::Builder.new(gem_spec).build : begin
      require 'rubygems/package'; Gem::Package.build(gem_spec)
    end
    File.open(gemspec_file, 'w') { |f| f << gem_spec.to_ruby }
    mv FileList['*.gem'], '..'
  end
end

task :'bundler:setup' do
  begin
    require 'bundler/setup'
  rescue LoadError
    puts "Please install Bundler and run `bundle install` to ensure you have all dependencies"
  end
end

namespace :test do

  task 'dependencies' do
    Rake::Task['jar'].invoke unless File.exists?(out_jar_path)
    RubyMaven.exec('dependency:copy-dependencies', '-DincludeScope=provided', '-P!jruby-dependencies')
  end

  desc "run ruby tests"
  task :ruby do
    Rake::Task['test:dependencies'].invoke
    _ruby_test('src/test/ruby/**/*_test.rb')
  end

  desc "run DJ (ruby) tests only"
  task 'ruby:delayed' do
    Rake::Task['test:dependencies'].invoke
    _ruby_test('src/test/ruby/delayed/**/*_test.rb')
  end

  desc "run Resque (ruby) tests only"
  task 'ruby:resque' do
    Rake::Task['test:dependencies'].invoke
    _ruby_test('src/test/ruby/resque/**/*_test.rb')
  end

  def _ruby_test(test_files)
    test_files = ENV['TEST'] || File.join(test_files)
    test_files = FileList[test_files].map { |path| path.sub('src/test/ruby/', '') }
    ruby "-I", "src/main/ruby:src/test/ruby", "-e", "#{test_files.inspect}.each { |test| require test }"
  end

  desc "run java tests"
  task :java do
    RubyMaven.exec('verify', '-Pjruby-dependencies')
  end
end

desc "run all tests"
task :test => [ 'test:java', 'test:ruby' ]

task :default => :test

desc "clean up"
task :clean do
  rm_rf OUT_DIR
  RubyMaven.exec('clean')
end
