# frozen_string_literal: true

require_relative 'safe_array'
require_relative 'sleep'

module Delayed
  module Master
    class Monitoring
      include Sleep

      def initialize(master)
        @master = master
        @config = master.config
        @callbacks = master.callbacks
        @threads = SafeArray.new
      end

      def start
        @threads << Thread.new do
          loop_with_sleep @config.monitor_interval do |i|
            if @master.stop?
              break
            elsif i == 0
              @callbacks.call(:monitor, @master) {}
            end
          end
        end
      end

      def schedule(worker)
        @threads << Thread.new do
          wait_pid(worker)
          @threads.delete(Thread.current)
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
        @master.workers.delete(worker)
      rescue Errno::ECHILD
        @master.logger.warn { "failed to waitpid: #{worker.pid}" }
        @master.workers.delete(worker)
      rescue => e
        @master.logger.warn { "#{e.class}: #{e.message}" }
        @master.logger.debug { e.backtrace.join("\n") }
      end
    end
  end
end
