# frozen_string_literal: true

require_relative 'file_reopener'

module Delayed
  module Master
    class Forker
      def initialize(master)
        @master = master
        @config = master.config
        @databases = master.databases
      end

      def call(worker)
        around_fork(worker) do
          worker.pid = fork do
            after_fork_at_child(worker)
            worker.pid = Process.pid
            worker.instance = create_instance(worker)
            $0 = worker.process_title
            worker.instance.start
          end
        end
      end

      private

      def around_fork(worker)
        @master.logger.info "forking #{worker.name}..."
        @master.run_callbacks(:before_fork, worker)
        @databases.each do |database|
          database.model.connection_pool.disconnect!
        end
        yield
        @master.logger.info "forked #{worker.name} with pid #{worker.pid}"
      end

      def after_fork_at_child(worker)
        FileReopener.reopen
        @master.run_callbacks(:after_fork, worker)
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
