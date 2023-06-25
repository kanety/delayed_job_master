# frozen_string_literal: true

# JobFinder runs SQL query which is almost same as delayed_job_active_record.
# See https://github.com/collectiveidea/delayed_job_active_record/blob/master/lib/delayed/backend/active_record.rb
module Delayed
  module Master
    class JobFinder
      def initialize(master)
        @config = master.config
      end

      def call(databases, setting, limit)
        jobs = SafeArray.new

        threads = databases.map do |database|
          Thread.new(database) do |database|
            database.with_connection do
              ready_scope(database, setting).limit(limit).pluck(:id, :run_at).each do |id, run_at|
                jobs << Job.new(database: database, setting: setting, id: id, run_at: run_at)
              end
            end
          end
        end

        threads.each(&:join)
        threads.each(&:kill)

        jobs.sort_by(&:run_at).take(limit)
      end

      def next_jobs(databases)
        jobs = SafeArray.new

        threads = databases.map do |database|
          Thread.new(database) do |database|
            database.with_connection do
              run_at = recent_scope(database).order(:run_at).limit(1).pluck(:run_at).first
              jobs << Job.new(database: database, run_at: run_at) if run_at
            end
          end
        end

        threads.each(&:join)
        threads.each(&:kill)

        jobs.sort_by(&:run_at)
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
