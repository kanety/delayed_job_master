# frozen_string_literal: true

# JobFinder runs SQL query which is almost same as delayed_job_active_record.
# See https://github.com/collectiveidea/delayed_job_active_record/blob/master/lib/delayed/backend/active_record.rb
module Delayed
  module Master
    class JobFinder
      def initialize(master)
        @config = master.config
      end

      def call(database, setting)
        ready_scope(database, setting).limit(setting.max_processes).pluck(:id)
      end

      def next_run_at(database)
        recent_scope(database).order(:run_at).limit(1).pluck(:run_at).first
      end

      private

      def ready_scope(database, setting)
        model = database.model
        model.where("(run_at <= ? AND (locked_at IS NULL OR locked_at < ?)) AND failed_at IS NULL",
          model.db_time_now,
          model.db_time_now - (setting.max_run_time || Delayed::Worker::DEFAULT_MAX_RUN_TIME)
        ).tap do |jobs|
          jobs.where!("priority >= ?", setting.min_priority) if setting.min_priority
          jobs.where!("priority <= ?", setting.max_priority) if setting.max_priority
          jobs.where!(queue: setting.queues) if setting.queues.present?
        end
      end

      def recent_scope(database)
        model = database.model
        model.where("run_at > ? AND run_at < ? AND locked_at IS NULL AND failed_at IS NULL",
          model.db_time_now,
          model.db_time_now + @config.polling_interval,
        )
      end
    end
  end
end
