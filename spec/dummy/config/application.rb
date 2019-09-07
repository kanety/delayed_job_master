require_relative 'boot'

require 'active_record/railtie'
require 'active_job/railtie'

Bundler.require(*Rails.groups)
require 'delayed_job_active_record' unless defined?(Delayed::Job)

module Dummy
  class Application < Rails::Application
  end
end
