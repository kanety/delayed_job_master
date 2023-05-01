# JobFinder runs SQL query which is almost same as delayed_job_active_record.
# See https://github.com/collectiveidea/delayed_job_active_record/blob/master/lib/delayed/backend/active_record.rb
module Delayed
  class Master
    class JobFinder
      def initialize(klass)
        @klass = klass
      end

      def call(setting)
        ready_to_run(setting.max_run_time || Delayed::Worker::DEFAULT_MAX_RUN_TIME).tap do |jobs|
          jobs.where!("priority >= ?", setting.min_priority) if setting.min_priority
          jobs.where!("priority <= ?", setting.max_priority) if setting.max_priority
          jobs.where!(queue: setting.queues) if setting.queues.any?
        end
      end

      private

      def ready_to_run(max_run_time)
        db_time_now = @klass.db_time_now
        @klass.where("(run_at <= ? AND (locked_at IS NULL OR locked_at < ?)) AND failed_at IS NULL", db_time_now, db_time_now - max_run_time)
      end
    end
  end
end
