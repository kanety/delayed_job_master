require_relative 'boot'

require 'active_record/railtie'
require 'active_job/railtie'

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.active_job.queue_adapter = :delayed_job
    config.active_record.legacy_connection_handling = false if Rails.gem_version > Gem::Version.new('6.1')

    database = ENV['DATABASE'] ? "database_#{ENV['DATABASE']}" : "database"
    database += "_multi" if ENV['DATABASE_CONFIG'] == 'multi'
    config.paths["config/database"] = "config/#{database}.yml"
  end
end
