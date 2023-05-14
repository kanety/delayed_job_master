# frozen_string_literal: true

require_relative 'sleep'

module Delayed
  module Master
    class Monitoring
      include Sleep

      def initialize(master)
        @master = master
        @config = master.config
        @callbacks = master.callbacks
        @threads = []
        @mon = Monitor.new
      end

      def start
        loop_with_sleep @config.monitor_interval do |i|
          if @master.stop?
            break
          elsif i == 0
            @callbacks.call(:monitor, @master) {}
          end 
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

      def wait_pid(worker)
        Process.waitpid(worker.pid)
        @master.logger.debug { "found terminated pid: #{worker.pid}" }
        @master.remove_worker(worker)
      rescue Errno::ECHILD
        @master.logger.warn { "failed to waitpid: #{worker.pid}" }
        @master.remove_worker(worker)
      rescue => e
        @master.logger.warn { "#{e.class}: #{e.message}" }
        @master.logger.debug { e.backtrace.join("\n") }
      end
    end
  end
end
