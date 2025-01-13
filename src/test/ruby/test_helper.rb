Dir['target/dependency/*.jar'].each { |jar| next if jar =~ /jruby/; $CLASSPATH << jar }
Bundler.require(:default, :test)
module JRuby::Rack::Worker
  JAR_PATH = Dir.glob("out/jruby-rack-worker_*.jar").last
end

require 'jruby/rack/worker'
