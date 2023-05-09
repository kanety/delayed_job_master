# frozen_string_literal: true

module Delayed
  module Master
    class Monitoring
      def initialize(master)
        @master = master
        @config = master.config
        @threads = []
        @mon = Monitor.new
      end

      def start
        loop do
          break if @master.stop?
          monitor
          sleep @config.monitor_interval
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
        yield if block_given?
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
    end
  end
end
