require_relative 'boot'

require 'active_record/railtie'
require 'active_job/railtie'

require 'delayed_job'
require 'delayed_job_active_record'
Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.active_job.queue_adapter = :delayed_job

    if Rails::VERSION::MAJOR >= 6
      config.paths["config/database"] = "config/database_rails6.yml"
    else
      config.paths["config/database"] = "config/database_rails5.yml"
    end
  end
end
