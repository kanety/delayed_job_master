require 'active_support'

require_relative 'delayed_job_master/railtie' if defined?(Rails)

module DelayedJobMaster
  mattr_accessor :config, default: ActiveSupport::InheritableOptions.new
  config.listen = defined?(PG) ? :postgresql : false

  class << self
    def configure
      yield config
    end
  end
end
