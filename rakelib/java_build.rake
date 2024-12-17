require 'ruby-maven'

namespace :java_build do
  compiled_jar_file_path = "target/jruby-rack-worker-#{JRuby::Rack::Worker::VERSION}.jar"

  desc 'test java (mvn test)'
  task :test do
    RubyMaven.exec('test')
  end

  desc 'clean java build (mvn clean)'
  task :clean do
    RubyMaven.exec('clean')
  end

  desc 'builds jar from java source'
  task :package do
    next if File.exist?(compiled_jar_file_path)
    RubyMaven.exec('package')
  end

  desc 'copies built jar to lib folder to be used ruby side'
  task copy_jar: [:package] do
    FileUtils.cp(compiled_jar_file_path, 'lib/')
  end
end
