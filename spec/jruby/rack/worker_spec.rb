require 'jruby/rack/worker'
require 'jruby/rack/worker/env'

RSpec.describe 'JRuby::Worker' do
  it 'has version' do
    expect(JRuby::Rack::Worker::VERSION).to be
    expect(JRuby::Rack::Worker::VERSION).to_not be_frozen
  end

  it 'JAR_PATH is defined absolutely' do
    jar_path = JRuby::Rack::Worker::JAR_PATH
    expect(jar_path).to be
    version = JRuby::Rack::Worker::VERSION
    expected_jar_path = "lib/jruby-rack-worker-#{version}.jar"
    expect(jar_path).to eq File.expand_path(expected_jar_path)
  end

  context 'env' do
    context 'empty env' do
      it 'cotanins fale and nil' do
        expect(JRuby::Rack::Worker::ENV.key?(:foo)).to eq(false)
        expect(JRuby::Rack::Worker::ENV[:foo]).to be_nil
      end
    end
    context 'env.foo set' do
      before { JRuby::Rack::Worker::ENV['foo'] = 'bar' }
      after { JRuby::Rack::Worker::ENV['foo'] = nil }

      it 'resolves key when set' do
        expect(JRuby::Rack::Worker::ENV['foo']).to be
        expect(JRuby::Rack::Worker::ENV['foo']).to eq 'bar'
        expect(JRuby::Rack::Worker::ENV[:foo]).to eq 'bar'
      end
    end
    context 'global env is set' do
      before do
        ::ENV['foo'] = 'bar'
        JRuby::Rack::Worker.send(:remove_const, :ENV)
        load 'jruby/rack/worker/env.rb'
      end
      after do
        ::ENV['foo'] = nil
        JRuby::Rack::Worker.send(:remove_const, :ENV)
        load 'jruby/rack/worker/env.rb'
      end

      it 'resolves key when set' do
        expect(JRuby::Rack::Worker::ENV['foo']).to be
        expect(JRuby::Rack::Worker::ENV['foo']).to eq 'bar'
        expect(JRuby::Rack::Worker::ENV[:foo]).to eq 'bar'
      end

      it 'does not change global env values' do
        JRuby::Rack::Worker::ENV['foo'] = 'LOCAL_VALUE'
        expect(::ENV['foo']).to eq 'bar'
      end

      it 'uses set local values over global values' do
        local_value = 'LOCAL_VALUE'
        JRuby::Rack::Worker::ENV['foo'] = local_value.dup
        expect(JRuby::Rack::Worker::ENV['foo']).to eq local_value
      end

      context 'servlet_context' do
        let(:worker_manager) { double('worker_manager') }
        let(:initParameterName) { 'someInitParameterName' }
        let(:initParameterValue) { 'someInitParameterValue' }

        before do
          $worker_manager = worker_manager
          expect(worker_manager).to receive(:getParameter).with(initParameterName) { initParameterValue }
        end
        after { $worker_manager = nil }

        it 'resolves key from worker manager' do
          expect(JRuby::Rack::Worker::ENV[initParameterName]).to eq initParameterValue
        end
      end
    end
  end
end
