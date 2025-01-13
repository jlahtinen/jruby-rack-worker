source "https://rubygems.org"

gem 'ruby-maven'
gem 'jruby-rack'

group :development do
  gem 'rake'
end

group :test do
  gem 'test-unit'
  gem 'mocha', require: 'mocha/test_unit'
end

group :delayed_job do
  if ENV['delayed_job']
    if ENV['delayed_job'] == 'master'
      gem 'delayed_job', :git => 'git://github.com/collectiveidea/delayed_job.git'
      gem 'delayed_job_active_record', :require => nil
    else
      gem 'delayed_job', version = ENV['delayed_job']
      unless version =~ /~?\s?2\.\d/ # delayed_job_active_record only for DJ >= 3.0
        gem 'delayed_job_active_record', :require => nil
      end
      if version =~ /~?\s?4\.[1]/ # add_dependency "delayed_job", ">= 4.1"
        gem 'delayed_cron_job', :require => nil
      end
    end
  else
    gem 'delayed_job_active_record'
    gem 'delayed_cron_job', :require => nil
  end
  if ENV['activerecord']
    gem 'activerecord', ENV['activerecord'], :require => nil
  else
    gem 'activerecord', :require => nil # for tests
  end
  gem 'activerecord-jdbcsqlite3-adapter', '~> 61.3'
end

group :resque do
  if ENV['resque']
    if ENV['resque'] == 'master'
      gem 'resque', :git => 'git://github.com/resque/resque.git'
    else
      gem 'resque', ENV['resque']
    end
  else
    gem 'resque'
  end
  gem 'json', :require => false # NOTE: required since resque-1.23.0
end

gem 'navvy', :group => :navvy
