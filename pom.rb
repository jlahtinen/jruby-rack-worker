# frozen_string_literal: true

load File.join(basedir, 'lib/jruby/rack/worker/version.rb')

project do
  model_version '4.0.0'

  group_id 'org.kares.jruby.rack'
  artifact_id 'jruby-rack-worker'
  version JRuby::Rack::Worker::VERSION
  packaging 'jar'

  properties(
    'project.build.sourceEncoding' => 'UTF-8',
    'project.reporting.outputEncoding' => 'UTF-8',
    'polyglot.dump.pom' => 'pom.xml',
    'polyglot.dump.readonly' => true
  )

  dependencies do
    dependency do
      group_id 'org.jruby'
      artifact_id 'jruby'
      version '9.4.8.0'
      scope 'provided'
    end

    dependency do
      group_id 'javax.servlet'
      artifact_id 'servlet-api'
      version '2.4'
      scope 'provided'
    end

    dependency do
      group_id 'org.jruby.rack'
      artifact_id 'jruby-rack'
      version '1.2.2'
      scope 'provided'
    end

    # Test dependencies
    dependency do
      group_id 'junit'
      artifact_id 'junit'
      version '4.11'
      scope 'test'
    end

    dependency do
      group_id 'org.mockito'
      artifact_id 'mockito-all'
      version '1.9.5'
      scope 'test'
    end
  end
end
