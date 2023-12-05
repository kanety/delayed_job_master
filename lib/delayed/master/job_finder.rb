# frozen_string_literal: true

require_relative 'job'

# JobFinder runs SQL query which is almost same as delayed_job_active_record.
# See https://github.com/collectiveidea/delayed_job_active_record/blob/master/lib/delayed/backend/active_record.rb
module Delayed
  module Master
    class JobFinder
      def initialize(master)
        @config = master.config
      end

      def ready_jobs(database, setting, limit)
        database.connect do |model|
          ready_scope(model, setting).limit(limit).pluck(:id, :run_at).map do |id, run_at|
            Job.new(database: database, setting: setting, id: id, run_at: run_at)
          end
        end
      end

      def recent_jobs(database)
        database.connect do |model|
          recent_scope(model).order(:run_at).limit(1).pluck(:id, :run_at).map do |id, run_at|
            Job.new(database: database, id: id, run_at: run_at)
          end
        end
      end

      private

      def ready_scope(model, setting)
        model.where("(run_at <= ? AND (locked_at IS NULL OR locked_at < ?)) AND failed_at IS NULL",
          model.db_time_now,
          model.db_time_now - (setting.max_run_time || Delayed::Worker::DEFAULT_MAX_RUN_TIME)
        ).tap do |jobs|
          jobs.where!("priority >= ?", setting.min_priority) if setting.min_priority
          jobs.where!("priority <= ?", setting.max_priority) if setting.max_priority
          jobs.where!(queue: setting.queues) if setting.queues.present?
        end
      end

      def recent_scope(model)
        model.where("run_at > ? AND run_at < ? AND locked_at IS NULL AND failed_at IS NULL",
          model.db_time_now,
          model.db_time_now + @config.polling_interval,
        )
      end
    end
  end
end
