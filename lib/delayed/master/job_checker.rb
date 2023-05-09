# frozen_string_literal: true

require_relative 'job_finder'
require_relative 'database'

module Delayed
  module Master
    class JobChecker
      def initialize(master)
        @master = master
        @config = master.config
        @databases = master.databases
      end

      def call
        workers = []
        mon = Monitor.new

        threads = @databases.map do |database|
          Thread.new(database) do |database|
            check(database).each do |setting|
              mon.synchronize do
                workers << Worker.new(database: database, setting: setting)
              end
            end
          end
        end

        threads.each(&:join)

        workers
      end

      private

      def check(database)
        settings = detect_free_worker_settings(database)
        return if settings.blank?

        check_jobs(database, settings)
      end

      def detect_free_worker_settings(database)
        workers = @master.workers.select { |worker| worker.database.spec_name == database.spec_name }
        workers = workers.group_by(&:setting)
        @config.worker_settings.each_with_object([]) do |setting, array|
          free_count = setting.max_processes - workers[setting].to_a.size
          array << [setting, free_count] if free_count > 0
        end
      end

      def check_jobs(database, settings)
        finder = JobFinder.new(database.model)

        settings.each_with_object([]) do |(setting, free_count), array|
          job_ids = finder.call(setting, free_count)
          if job_ids.size > 0
            [free_count, job_ids.size].min.times do
              array << setting
            end
          end
        end
      end
    end
  end
end
