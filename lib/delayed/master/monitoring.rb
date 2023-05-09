# frozen_string_literal: true

require_relative 'forker'
require_relative 'job_checker'

module Delayed
  module Master
    class Monitoring
      def initialize(master)
        @master = master
        @config = master.config
        @threads = []
        @mon = Monitor.new
        @databases = master.databases
        @forker = Forker.new(master)
        @job_checker = JobChecker.new(master)
      end

      def start
        loop do
          break if @master.stop?
          monitor do
            check_queued_jobs
          end
          sleep @config.monitor_wait
        end
      end

      def schedule(worker)
        add_thread(Thread.new do
          wait_pid(worker)
          remove_thread(Thread.current)
        end)
      end

      def add_thread(thread)
        @mon.synchronize do
          @threads << thread
        end
      end

      def remove_thread(thread)
        @mon.synchronize do
          @threads.delete_if { |t| t == thread }
        end
      end

      def wait
        @threads.each(&:join)
      end

      def shutdown
        @threads.each(&:kill)
      end

      private

      def monitor
        @master.run_callbacks(:before_monitor)
        yield
        @master.run_callbacks(:after_monitor)
      rescue => e
        @master.logger.warn "#{e.class}: #{e.message}"
        @master.logger.debug e.backtrace.join("\n")
      end

      def wait_pid(worker)
        Process.waitpid(worker.pid)
        @master.logger.debug "found terminated pid: #{worker.pid}"
        @master.remove_worker(worker)
      rescue Errno::ECHILD
        @master.logger.warn "failed to waitpid: #{worker.pid}"
        @master.remove_worker(worker)
      rescue => e
        @master.logger.warn "#{e.class}: #{e.message}"
        @master.logger.debug e.backtrace.join("\n")
      end

      def check_queued_jobs
        @master.logger.debug "checking jobs..."

        new_workers = @job_checker.call
        new_workers.each do |worker|
          @master.logger.info "found jobs for #{worker.info}"
          @forker.call(worker)
          @master.add_worker(worker)
          schedule(worker)
        end
      end
    end
  end
end
