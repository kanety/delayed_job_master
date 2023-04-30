require_relative 'boot'

require 'active_record/railtie'
require 'active_job/railtie'

require 'delayed_job'
require 'delayed_job_active_record'
Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.active_job.queue_adapter = :delayed_job

    database = ENV['DATABASE'] ? "database_#{ENV['DATABASE']}" : "database"
    database << "_multi" if ENV['DATABASE_CONFIG'] == 'multi'
    config.paths["config/database"] = "config/#{database}.yml"
  end
end
