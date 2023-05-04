# frozen_string_literal: true

require_relative 'job_finder'
require_relative 'database'

module Delayed
  class Master
    class JobChecker
      def initialize(master)
        @master = master
        @config = master.config
        @spec_names = @config.databases.presence || Database.spec_names

        extend_after_fork_callback
      end

      def call
        workers = []
        mon = Monitor.new

        threads = @spec_names.map do |spec_name|
          Thread.new(spec_name) do |spec_name|
            find_jobs_in_db(spec_name) do |setting|
              mon.synchronize do
                workers << Worker.new(index: @master.workers.size + workers.size, database: spec_name, setting: setting)
              end
            end
          end
        end

        threads.each(&:join)

        workers
      end

      private

      def extend_after_fork_callback
        @config.after_fork do |master, worker|
          ActiveRecord::Base.establish_connection(worker.database) if worker.database
        end
      end

      def find_jobs_in_db(spec_name)
        finder = JobFinder.new(Database.model_for(spec_name))

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
