require_relative 'lib/jruby/rack/worker/version'

Gem::Specification.new do |spec|
  spec.name = 'jruby-rack-worker' # Replace with the actual project name
  spec.version = JRuby::Rack::Worker::VERSION
  spec.authors = ['Karol Bucek']
  spec.email = ['self@kares.org']
  spec.homepage = 'https://github.com/kares/jruby-rack-worker'
  spec.license = 'Apache-2.0'
  spec.summary = 'Threaded Workers with JRuby-Rack'
  spec.description =
    'Implements a thread based worker pattern on top of JRuby-Rack. ' \
      "Useful if you'd like to run background workers within your (deployed) " \
      "web-application, concurrently in 'native' threads, instead of using " \
      'separate daemon processes. ' \
      'Provides (thread-safe) implementations for popular worker libraries ' \
      'such as Resque and Delayed::Job, but one can easily write their own ' \
      "'daemon' work processing loop as well."
  spec.files = Dir['lib/**/*']
  spec.add_dependency 'jruby-rack', '> 1.1.10'
end
