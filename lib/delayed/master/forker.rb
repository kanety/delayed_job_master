module Delayed
  class Master
    class Forker
      def initialize(master)
        @master = master
        @config = master.config
      end

      def new_worker(setting, spec_name)
        worker = Delayed::Master::Worker.new(@master.workers.size, setting)
        @master.workers << worker

        @master.logger.info "forking worker[#{setting.id}]..."
        fork_worker(worker, spec_name)
        @master.logger.info "forked worker[#{setting.id}] with pid #{worker.pid}"
      end

      private

      def fork_worker(worker, spec_name)
        @config.run_callback(:before_fork, @master, worker, spec_name)
        worker.pid = fork do
          worker.pid = Process.pid
          worker.instance = create_instance(worker)
          @config.run_callback(:after_fork, @master, worker, spec_name)
          $0 = worker.title
          worker.instance.start
        end
      end

      def create_instance(worker)
        require_relative 'worker_extension'

        instance = Delayed::Worker.new(worker.setting.data)
        [:max_run_time, :max_attempts, :destroy_failed_jobs].each do |key|
          if (value = worker.setting.send(key))
            Delayed::Worker.send("#{key}=", value)
          end
        end
        [:max_memory].each do |key|
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
