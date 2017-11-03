# JobCounter depends on delayed_job_active_record.
# See https://github.com/collectiveidea/delayed_job_active_record/blob/master/lib/delayed/backend/active_record.rb
module Delayed
  class Master
    class JobCounter
      class << self
        def count(config)
          jobs = ready_to_run(config[:max_run_time] || Delayed::Worker::DEFAULT_MAX_RUN_TIME)
          jobs.where!("priority >= ?", config[:min_priority]) if config[:min_priority]
          jobs.where!("priority <= ?", config[:max_priority]) if config[:max_priority]
          jobs.where!(queue: config[:queues]) if config[:queues].any?
          jobs.count
        end

        private

        def ready_to_run(max_run_time)
          db_time_now = Delayed::Job.db_time_now
          Delayed::Job.where("(run_at <= ? AND (locked_at IS NULL OR locked_at < ?)) AND failed_at IS NULL", db_time_now, db_time_now - max_run_time)
        end
      end
    end
  end
end
