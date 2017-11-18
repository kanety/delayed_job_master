require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)
require 'delayed_job_active_record' unless defined?(Delayed::Job)
require 'delayed/master'

module Dummy
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
