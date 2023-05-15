module DelayedJobMaster
  class Railtie < Rails::Railtie
    config.after_initialize do
      case DelayedJobMaster.config.listener
      when :postgresql
        require_relative '../delayed/master/postgresql/job_notifier'
        if defined?(Delayed::Backend::ActiveRecord)
          Delayed::Backend::ActiveRecord::Job.include Delayed::Master::Postgresql::JobNotifier
        end
        if defined?(Delayed::Backend::Bulk)
          Delayed::Backend::Bulk.include Delayed::Master::Postgresql::BulkJobNotifier
        end
      end
    end
  end
end
