# JobCounter depends on delayed_job_mongoid.
# See https://github.com/collectiveidea/delayed_job_mongoid/blob/master/lib/delayed/backend/mongoid.rb
module Delayed
  class Master
    class JobCounter
      class << self
        def count(config)
          right_now = Delayed::Job.db_time_now
          jobs = reservation_criteria(right_now, config[:max_run_time] || Delayed::Worker::DEFAULT_MAX_RUN_TIME)
          jobs = jobs.gte(priority: config[:min_priority].to_i) if config[:min_priority]
          jobs = jobs.lte(priority: config[:max_priority].to_i) if config[:max_priority]
          jobs = jobs.any_in(queue: config[:queues]) if config[:queues].any?
          jobs.count
        end

        private

        def reservation_criteria(right_now, max_run_time)
          criteria = Delayed::Job.where(
            run_at: { '$lte' => right_now },
            failed_at: nil
          ).any_of(
            { locked_at: nil },
            locked_at: { '$lt' => (right_now - max_run_time) }
          )

          criteria
        end
      end
    end
  end
end
