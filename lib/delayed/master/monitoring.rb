# frozen_string_literal: true

require_relative 'forker'
require_relative 'job_checker' if defined?(Delayed::Backend::ActiveRecord)

module Delayed
  class Master
    class Monitoring
      def initialize(master)
        @master = master
        @config = master.config
        @forker = Forker.new(master)
        @job_checker = JobChecker.new(master)
      end

      def monitor_while(&block)
        loop do
          break if block.call
          monitor do
            check_terminated
            check_queued_jobs
          end
          sleep @config.monitor_wait.to_i
        end
      end

      private

      def monitor
        @config.run_callback(:before_monitor, @master)
        yield
        @config.run_callback(:after_monitor, @master)
      rescue Exception => e
        @master.logger.warn "#{e.class}: #{e.message} at #{__FILE__}: #{__LINE__}"
      end

      def check_terminated
        if (pid = terminated_pid)
          @master.logger.debug "found terminated pid: #{pid}"
          @master.workers.reject! { |worker| worker.pid == pid }
        end
      end

      def terminated_pid
        Process.waitpid(-1, Process::WNOHANG)
      rescue Errno::ECHILD
        nil
      end

      def check_queued_jobs
        @master.logger.debug "checking jobs..."

        new_workers = @job_checker.check
        new_workers.each do |worker|
          @master.logger.info "found jobs for #{worker.info}"
          @forker.new_worker(worker)
        end
      end
    end
  end
end
