# frozen_string_literal: true

require_relative 'job_finder'
require_relative 'database'

module Delayed
  class Master
    class JobChecker
      def initialize(master)
        @master = master
        @config = master.config
        @databases = Database.all(@config.databases)
      end

      def call
        workers = []
        mon = Monitor.new

        threads = @databases.map do |database|
          Thread.new(database) do |database|
            find_jobs_in_db(database) do |setting|
              mon.synchronize do
                workers << Worker.new(index: @master.workers.size + workers.size, database: database, setting: setting)
              end
            end
          end
        end

        threads.each(&:join)

        workers
      end

      private

      def find_jobs_in_db(database)
        finder = JobFinder.new(database.model)

        @config.worker_settings.each do |setting|
          count = @master.workers.count { |worker| worker.setting.queues == setting.queues }
          slot = setting.max_processes - count
          if slot > 0 && (job_ids = finder.call(setting, slot)).size > 0
            [slot, job_ids.size].min.times do
              yield setting
            end
          end
        end
      end
    end
  end
end
