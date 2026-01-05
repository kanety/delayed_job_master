require_relative 'boot'

require 'active_record/railtie'
require 'active_job/railtie'

require 'delayed_job'
require 'delayed_job_active_record'
require 'delayed_job_bulk'
Bundler.require(*Rails.groups)
require 'delayed/master'

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f

    # fix "NameError: uninitialized constant ActiveJob::QueueAdapters::AbstractAdapter" with rails < 7.2 and delayed_job 4.2
    if ActiveJob.version < Gem::Version.new('7.2.0')
      spec = Gem::Specification.find_by_name('activejob')
      require File.join(spec.gem_dir, 'lib/active_job/queue_adapters/delayed_job_adapter')
    end

    config.active_job.queue_adapter = :delayed_job

    database = ENV['DATABASE'] ? "database_#{ENV['DATABASE']}" : "database"
    database += "_multi" if ENV['DATABASE_CONFIG'] == 'multi'
    config.paths["config/database"] = "config/#{database}.yml"
  end
end

DelayedJobMaster.configure do |config|
  if ENV['DATABASE'].in?([nil, 'postgresql'])
    config.listener = :postgresql
  else
    config.listener = nil
  end
end
