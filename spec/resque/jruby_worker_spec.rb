require 'resque/version'
require 'resque/jruby_worker'

RSpec.describe Resque::JRubyWorker do
  let(:default_worker) { Resque::JRubyWorker.new('*') }

  it 'new fails without a queue arg' do
    expect { Resque::JRubyWorker.new }.to raise_error(Resque::NoQueueError)
  end

  it 'new does not fail with a queue arg' do
    expect(Resque::JRubyWorker.new('*')).to be
  end

  it 'loops on work and does not change $0' do
    pending 'original rescue startup changes $0'
    bin_name = File.basename($0)
    expect(bin_name).to eq('rspec')
    begin
      default_worker.work
    rescue StandardError
    end
    bin_name = File.basename($0)
    expect(bin_name).to eq('rspec')
  end
end
