# frozen_string_literal: true

require_relative 'database'
require_relative 'forker'
require_relative 'job_finder'
require_relative 'sleep'

module Delayed
  module Master
    class JobChecker
      include Sleep

      def initialize(master)
        @master = master
        @config = master.config
        @databases = master.databases
        @callbacks = master.callbacks
        @queues = @databases.map { |database| [database, Queue.new] }.to_h
        @threads = SafeArray.new
        @timer_threads = SafeArray.new
        @job_finder = JobFinder.new(master)
      end

      def start
        @threads << start_scheduler_thread
        @threads += @databases.map do |database|
          start_checker_thread(database)
        end
      end

      def start_scheduler_thread
        Thread.new do
          loop_with_sleep @config.polling_interval do |i|
            if @master.stop?
              stop
              break
            elsif i == 0
              schedule(@databases)
            end
          end
        end
      end

      def start_checker_thread(database)
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

      def start_timer_thread(database, run_at)
        @timer_threads << Thread.new(database, run_at) do |database, run_at|
          interval = run_at.to_f - Time.zone.now.to_f
          sleep interval if interval > 0
          schedule(database)
          @timer_threads.delete(Thread.current)
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
        @timer_threads.each(&:join)
      end

      def shutdown
        @threads.each(&:kill)
        @timer_threads.each(&:kill)
      end

      private

      def check(database)
        @master.logger.debug { "checking jobs @#{database.spec_name}..." }
        check_jobs(database)
        check_recent_jobs(database)
      rescue => e
        @master.logger.warn { "#{e.class}: #{e.message}" }
        @master.logger.debug { e.backtrace.join("\n") }
      end

      def check_jobs(database)
        jobs = find_jobs(database)
        jobs.each do |job|
          @master.logger.info { "found jobs @#{job.database.spec_name} for #{job.setting.worker_info}" }
          fork_worker(job.database, job.setting)
        end
      end

      def find_jobs(database)
        free_settings = count_free_settings
        free_settings.map do |setting, free_count|
          @job_finder.ready_jobs(database, setting, free_count)
        end.flatten
      end

      def count_free_settings
        @config.worker_settings.map do |setting|
          used_count = @master.workers.count { |worker| worker.setting == setting }
          free_count = setting.max_processes - used_count
          [setting, free_count] if free_count > 0
        end.compact.to_h
      end

      def fork_worker(database, setting)
        worker = Worker.new(database: database, setting: setting)
        Forker.new(@master).call(worker)
        @master.workers << worker
        @master.monitoring.schedule(worker)
      end

      def check_recent_jobs(database)
        jobs = @job_finder.recent_jobs(database)
        jobs.each do |job|
          @master.logger.info { "set timer to #{job.run_at.iso8601(6)} @#{job.database.spec_name}" }
          start_timer_thread(job.database, job.run_at)
        end
      end
    end
  end
end
