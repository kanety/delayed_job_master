# frozen_string_literal: true

# JobFinder runs SQL query which is almost same as delayed_job_active_record.
# See https://github.com/collectiveidea/delayed_job_active_record/blob/master/lib/delayed/backend/active_record.rb
module Delayed
  class Master
    class JobFinder
      def initialize(klass)
        @klass = klass
      end

      def call(setting, limit)
        scope(setting).limit(limit).pluck(:id)
      end

      def count(setting)
        scope(setting).count
      end

      private

      def scope(setting)
        @klass.ready_to_run(nil, setting.max_run_time || Delayed::Worker::DEFAULT_MAX_RUN_TIME).tap do |jobs|
          jobs.where!("priority >= ?", setting.min_priority) if setting.min_priority
          jobs.where!("priority <= ?", setting.max_priority) if setting.max_priority
          jobs.where!(queue: setting.queues) unless setting.queues.empty?
        end
      end
    end
  end
end
