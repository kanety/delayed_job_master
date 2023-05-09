# frozen_string_literal: true

module Delayed
  module Master
    class Forker
      def initialize(master)
        @master = master
        @config = master.config
      end

      def call(worker)
        @master.run_callbacks(:before_fork, worker)
        worker.pid = fork do
          worker.pid = Process.pid
          worker.instance = create_instance(worker)
          @master.run_callbacks(:after_fork, worker)
          $0 = worker.process_title
          worker.instance.start
        end
      end

      private

      def create_instance(worker)
        require_relative 'worker/extension'

        instance = Delayed::Worker.new
        [:max_run_time, :max_attempts, :destroy_failed_jobs].each do |key|
          if (value = worker.setting.send(key))
            Delayed::Worker.send("#{key}=", value)
          end
        end
        [:min_priority, :max_priority, :sleep_delay, :read_ahead, :exit_on_complete, :queues,
         :max_threads, :max_memory].each do |key|
          if (value = worker.setting.send(key))
            instance.send("#{key}=", value)
          end
        end
        instance.master_logger = @master.logger
        instance
      end
    end
  end
end
