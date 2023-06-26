# frozen_string_literal: true

require_relative 'file_reopener'

module Delayed
  module Master
    class Forker
      def initialize(master)
        @master = master
        @config = master.config
        @callbacks = master.callbacks
      end

      def call(worker)
        around_fork(worker) do
          @callbacks.run(:before_fork, @master, worker)
          worker.pid = fork do
            @callbacks.run(:after_fork, @master, worker)
            after_fork_at_child(worker)
            worker.pid = Process.pid
            worker.instance = create_instance(worker)
            worker.instance.start
          end
        end
      end

      private

      def around_fork(worker)
        @master.logger.info { "forking #{worker.name}..." }
        yield
        @master.logger.info { "forked #{worker.name} with pid #{worker.pid}" }
      end

      def after_fork_at_child(worker)
        $0 = worker.process_title
        Thread.current.name = 'delayed_job'
        FileReopener.reopen
      end

      def create_instance(worker)
        require_relative 'worker/extension'

        instance = Delayed::Worker.new
        [:max_run_time, :max_attempts, :destroy_failed_jobs].each do |key|
          if (value = worker.setting.send(key))
            Delayed::Worker.send("#{key}=", value)
          end
        end
        [:min_priority, :max_priority, :sleep_delay, :read_ahead, :exit_on_complete, :queues,
         :max_threads, :max_memory, :max_exec_time].each do |key|
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
