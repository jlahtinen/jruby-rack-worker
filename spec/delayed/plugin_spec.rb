require 'delayed_job'
require 'delayed/jruby_worker'

RSpec.describe 'plugins' do
  context 'lifecycle' do
    before(:all) { Delayed::Worker.reset } # another specs maybe has initialized worker already
    let!(:lifecycle) { Delayed::Lifecycle.new } # make sure lifecycle is created before expections (use let! not let)
    before { expect(Delayed::Lifecycle).to receive(:new).once { lifecycle } }
    after { Delayed::Worker.reset }

    it 'only one lifecycle instance is created' do
      threads =
        3.times.map { Thread.new { expect(Delayed::JRubyWorker.lifecycle).to be(Delayed::JRubyWorker.lifecycle) } }
      threads.each(&:join)
    end

    it 'setup lifecycle does guard for lifecycle creation' do
      threads =
        5.times.map do
          Thread.new do
            Delayed::JRubyWorker.new
            Delayed::Worker.new
          end
        end
      threads.each(&:join)
    end
  end

  context 'integration' do
    let(:backend) { double('backend') }
    let(:cronjob) do
      double(
        'cronjob',
        name: 'cronjobname',
        id: 'jobid',
        queue: 'jobqueue',
        max_run_time: nil,
        max_attempts: nil,
        reschedule_at: nil,
        unlock: nil,
        save!: nil
      )
    end
    let(:cronjobdata) { { 'locked' => false, 'invokes' => [] } }
    let(:mutex) { Mutex.new }

    before do
      Delayed::JRubyWorker.backend = backend
      allow(backend).to receive(:clear_locks!) do
        cronjobdata['locks_cleared'] = Time.now
      end
      allow(backend).to receive(:reserve) do
        mutex.synchronize do
          next if cronjobdata['locked']
          next if cronjobdata['destoyed']
          cronjobdata['locked'] = true
          cronjob
        end
      end
      allow(cronjob).to receive(:invoke_job) {
        begin
          cronjobdata['invokes'] << Time.now
          raise 'first try' if cronjobdata['invokes'].size == 1
        ensure
          cronjobdata['locked'] = false
        end
      }
      allow(cronjob).to receive(:error=) { |error| cronjobdata['error'] = error }
      allow(cronjob).to receive(:destroy) { mutex.synchronize { cronjobdata['destoyed'] = Time.now } }
      allow(cronjob).to receive(:attempts) { cronjobdata['attempts'] || 0 }
      allow(cronjob).to receive(:attempts=) { |count| cronjobdata['attempts'] = count }
      allow(cronjob).to receive(:run_at=).with(nil) { cronjobdata['run_at'] = Time.now }
    end

    it 'works' do
      worker = Delayed::JRubyWorker.new({ sleep_delay: 0.10 })
      worker_thread = Thread.new { worker.start }

      [2, Time.now].tap do |timeout, start_time|
        sleep 1 while cronjobdata['run_at'].nil? && (Time.now - start_time) < timeout
      end
      expect(worker.stop?).to be_falsey

      expect(cronjobdata['run_at']).to be > cronjobdata['invokes'].first
      expect(cronjobdata['invokes'].size).to eq 2

      worker.stop
      [2, Time.now].tap do |timeout, start_time|
        sleep 1 while cronjobdata['locks_cleared'].nil? && (Time.now - start_time) < timeout
      end
      expect(worker.stop?).to be_truthy
      worker_thread.join(10)
    end
  end
end
