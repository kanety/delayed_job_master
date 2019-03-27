# JobCounter depends on delayed_job_mongoid.
# See https://github.com/collectiveidea/delayed_job_mongoid/blob/master/lib/delayed/backend/mongoid.rb
module Delayed
  class Master
    class JobCounter
      class << self
        def count(setting)
          right_now = Delayed::Job.db_time_now
          jobs = reservation_criteria(right_now, setting.max_run_time || Delayed::Worker::DEFAULT_MAX_RUN_TIME)
          jobs = jobs.gte(priority: setting.min_priority.to_i) if setting.min_priority
          jobs = jobs.lte(priority: setting.max_priority.to_i) if setting.max_priority
          jobs = jobs.any_in(queue: setting.queues) if setting.queues.any?
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
