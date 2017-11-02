module Delayed
  class Master
    class JobCounter
      class << self
        def count(config)
          now = Delayed::Job.db_time_now
          jobs = Delayed::Job.where(failed_at: nil)
                             .where("run_at <= ?", now)
                             .where("locked_at IS NULL OR locked_at < ?", now - (config[:max_run_time] || Delayed::Worker::DEFAULT_MAX_RUN_TIME))
          jobs.where!("priority >= ?", config[:min_priority]) if config[:min_priority]
          jobs.where!("priority <= ?", config[:max_priority]) if config[:max_priority]
          jobs.where!(queue: config[:queues]) if config[:queues].any?
          jobs.count
        end
      end
    end
  end
end
