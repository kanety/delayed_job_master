require 'active_support'

require_relative 'delayed_job_master/version'
require_relative 'delayed_job_master/railtie' if defined?(Rails)

module DelayedJobMaster
  mattr_accessor :config, default: ActiveSupport::InheritableOptions.new
  config.listener = :postgresql if defined?(PG)

  class << self
    def configure
      yield config
    end
  end
end
