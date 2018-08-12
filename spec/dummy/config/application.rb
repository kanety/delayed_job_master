require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)
require 'delayed_job_active_record' unless defined?(Delayed::Job)
require 'delayed/master'

module Dummy
  class Application < Rails::Application
  end
end
