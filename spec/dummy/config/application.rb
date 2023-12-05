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

    config.active_job.queue_adapter = :delayed_job

    database = ENV['DATABASE'] ? "database_#{ENV['DATABASE']}" : "database"
    database += "_multi" if ENV['DATABASE_CONFIG'] == 'multi'
    config.paths["config/database"] = "config/#{database}.yml"

    config.after_initialize do
      if ENV['DATABASE_CONFIG'] == 'multi'
        ActiveRecord::Base.connects_to(shards: {
          shard1: { writing: :primary, reading: :primary },
          shard2: { writing: :secondary, reading: :secondary }
        })
      end
    end
  end
end

DelayedJobMaster.configure do |config|
  if ENV['DATABASE'].in?([nil, 'postgresql'])
    config.listener = :postgresql
  else
    config.listener = nil
  end
end
