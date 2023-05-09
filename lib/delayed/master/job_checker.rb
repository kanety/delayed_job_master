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
      end

      def start
        @thread = Thread.new do
          loop do
            if @master.stop?
              break
            else
              @databases.each do |database|
                check(database)
              end
            end
            sleep @config.polling_interval
          end
        end
      end

      def wait
        @thread&.join
      end

      def shutdown
        @thread&.kill
      end

      private

      def check(database)
        settings = detect_free_worker_settings(database)
        return if settings.blank?

        @master.logger.debug "checking jobs @#{database.spec_name}..."
        check_jobs(database, settings).each do |setting|
          worker = Worker.new(database: database, setting: setting)
          @master.logger.info "found jobs for #{worker.info}"
          Forker.new(@master).call(worker)
          @master.add_worker(worker)
          @master.monitoring.schedule(worker)
        end
      rescue => e
        @master.logger.warn "#{e.class}: #{e.message}"
        @master.logger.debug e.backtrace.join("\n")
      end

      def detect_free_worker_settings(database)
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
    end
  end
end
