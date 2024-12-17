require 'delayed_job'
require 'jruby/rack/worker'
require 'delayed/jruby_worker'
require 'logger'
require 'stringio'
require 'socket'

RSpec.describe Delayed::JRubyWorker do
  before(:all) { JRuby::Rack::Worker.load_jar }

  let(:logger) { Logger.new(StringIO.new) }
  let(:delayed_job_backend) { double('delayed_job_backend') }
  let(:worker) { Delayed::JRubyWorker.new({}) }
  let(:sleep_worker) { Delayed::JRubyWorker.new(sleep_delay: 11, exit_on_complete: false) }
  let(:exit_worker) { Delayed::JRubyWorker.new(exit_on_complete: true) }
  let(:use_at_exit) { false }

  before(:each) do
    Delayed::Worker.logger = logger
    Delayed::Worker.backend = delayed_job_backend

    allow(worker).to receive(:loop)
    allow(worker).to receive(:at_exit) unless use_at_exit

    allow(delayed_job_backend).to receive(:clear_locks!)
  end

  describe '#new' do
    it 'works with a hash' do
      expect { Delayed::JRubyWorker.new({}) }.not_to raise_error
    end
  end

  describe '#name' do
    it 'includes thread name' do
      name = java.lang.Thread.currentThread.name
      expect(worker.name).to match(/#{name}/)
    end

    it 'can be changed and reset' do
      expect(worker.name).not_to be_nil
      worker.name = 'foo-bar'
      expect(worker.name).to eq('foo-bar')
      worker.name = nil
      expect(worker.name).to match(/^host:.*?thread:.*?/)
    end
  end

  describe '#start' do
    it 'loops on start' do
      expect(worker).to receive(:loop).once
      worker.start
    end

    it 'traps signals on start' do
      expect(worker).to receive(:trap).at_least(:once)
      worker.start

      # TODO: test this like old did
      # assert_equal worker.class, new_worker.method(:trap).owner
    end

    it 'sets up an at_exit hook' do
      expect(worker).to receive(:at_exit).once
      worker.start
    end

    context 'use at_exit' do
      let(:use_at_exit) { true }
      it 'clears locks and exits via at_exit hook' do
        expect(delayed_job_backend).to receive(:clear_locks!).with(worker.name)
        at_exit_block = nil
        at_exit_args = nil

        expect(worker).to receive(:at_exit) do |*args, &block|
          at_exit_args = args
          at_exit_block = block
        end

        worker.start
        worker.instance_exec(*at_exit_args, &at_exit_block)
        expect(worker.stop?).to be true
      end
    end
  end

  describe '#name_prefix' do
    it 'includes prefix, host, pid, and thread' do
      thread_worker = nil
      name_inside_thread = nil
      lock = java.lang.Object.new
      thread =
        java.lang.Thread.new do
          thread_worker = Delayed::JRubyWorker.new({})
          thread_worker.name_prefix = 'PREFIX '
          name_inside_thread = thread_worker.name
          lock.synchronized { lock.notify }
        end
      thread.name = 'worker_2'
      thread.start
      lock.synchronized { lock.wait }

      parts = name_inside_thread.split(' ')
      expect(parts.length).to eq(4)
      expect(parts[0]).to eq('PREFIX')
      expect(parts[1]).to eq('host:' + Socket.gethostname)
      expect(parts[2]).to eq('pid:' + Process.pid.to_s)
      expect(parts[3]).to eq('thread:worker_2')
    end
  end

  describe '#to_s' do
    it 'is the same as worker name' do
      worker.name_prefix = '42'
      expect(worker.to_s).to eq(worker.name)
    end
  end

  # TODO: is this needed?
  it 'performs the reserved job on start' do
  end

  context 'class options replaced with thread-local ones' do
    let(:lock) { java.lang.Object.new }
    let(:exit_on_cmplt) { Delayed::Worker.respond_to?(:exit_on_complete) }

    it 'replaces class options with thread-local ones' do
      worker = nil
      failure = nil

      thread =
        java.lang.Thread.new do
          begin
            worker = Delayed::JRubyWorker.new(sleep_delay: 11, exit_on_complete: false)
            expect(worker.class.sleep_delay).to eq(11)
            expect(worker.class.exit_on_complete).to eq(false) if exit_on_cmplt

            expect(Delayed::Worker.sleep_delay).to eq(5)
            expect(Delayed::Worker.delay_jobs).to eq(true)
            expect(Delayed::Worker.exit_on_complete).to be_nil if exit_on_cmplt

            expect(worker.class.delay_jobs).to eq(true)
            expect(worker.class.max_attempts).to eq(25)

            expect(worker.class.sleep_delay).to eq(11)
            expect(worker.class.exit_on_complete).to eq(false) if exit_on_cmplt

            worker = Delayed::JRubyWorker.new(exit_on_complete: true)
            expect(worker.class.sleep_delay).to eq(11)
            expect(worker.class.exit_on_complete).to eq(true) if exit_on_cmplt

            expect(Delayed::Worker.exit_on_complete).to be_nil if exit_on_cmplt
          rescue => e
            failure = e
          ensure
            lock.synchronized { lock.notify }
          end
        end

      expect(Delayed::Worker.sleep_delay).to eq(5)
      expect(Delayed::Worker.delay_jobs).to eq(true)
      expect(Delayed::Worker.exit_on_complete).to be_nil if exit_on_cmplt

      thread.start
      lock.synchronized { lock.wait }
      raise failure unless failure.nil?

      expect(Delayed::Worker.sleep_delay).to eq(5)
      expect(Delayed::Worker.exit_on_complete).to be_nil if exit_on_cmplt
    end
  end
end
