# frozen_string_literal: true

require_relative 'database'
require_relative 'forker'
require_relative 'job_finder'

module Delayed
  module Master
    class JobChecker
      def initialize(master)
        @master = master
        @config = master.config
        @databases = master.databases
        @callbacks = master.callbacks
        @queues = @databases.map { |database| [database, Queue.new] }.to_h
        @threads = []
      end

      def start
        @threads << Thread.new do
          loop do
            if @master.stop?
              stop
              break
            else
              schedule(@databases)
            end
            sleep @config.polling_interval
          end
        end

        @threads += @databases.map do |database|
          Thread.new(database) do |database|
            loop do
              if @queues[database].pop == :stop
                break
              else
                @callbacks.call(:polling, @master, database) do
                  check(database)
                end
              end
            end
          end
        end
      end

      def stop
        @databases.each do |database|
          queue = @queues[database]
          queue.clear
          queue.push(:stop)
        end
      end

      def schedule(databases)
        Array(databases).each do |database|
          queue = @queues[database]
          queue.push(database) if queue.size == 0
        end
      end

      def wait
        @threads.each(&:join)
      end

      def shutdown
        @threads.each(&:kill)
      end

      private

      def check(database)
        free_settings = detect_free_settings(database)
        return if free_settings.blank?

        @master.logger.debug "checking jobs @#{database.spec_name}..."
        settings = check_jobs(database, free_settings)
        fork_workers(database, settings)
      rescue => e
        @master.logger.warn "#{e.class}: #{e.message}"
        @master.logger.debug e.backtrace.join("\n")
      end

      def detect_free_settings(database)
        @config.worker_settings.each_with_object([]) do |setting, array|
          used_count = @master.workers.count { |worker| worker.setting.queues == setting.queues }
          free_count = setting.max_processes - used_count
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

      def fork_workers(database, settings)
        settings.each do |setting|
          worker = Worker.new(database: database, setting: setting)
          @master.logger.info "found jobs for #{worker.info}"
          Forker.new(@master).call(worker)
          @master.add_worker(worker)
          @master.monitoring.schedule(worker)
        end
      end
    end
  end
end
