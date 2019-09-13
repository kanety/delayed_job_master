module Delayed
  class Master
    class WorkerPool
      def initialize(master)
        @master = master
        @config = master.config
        @callback = Delayed::Master::Callback.new(master.config)
      end

      def monitor_while(&block)
        loop do
          break if block.call
          monitor do
            check_killed_pid
            check_queued_jobs
          end
          sleep @config.monitor_wait.to_i
        end
      end

      private

      def monitor
        @callback.run(:before_monitor, @master)
        yield
        @callback.run(:after_monitor, @master)
      rescue Exception => e
        @master.logger.warn "#{e.class}: #{e.message} at #{__FILE__}: #{__LINE__}"
      end

      def check_killed_pid
        if (pid = killed_pid)
          @master.workers.reject! { |worker| worker.pid == pid }
        end
      end

      def killed_pid
        Process.waitpid(-1, Process::WNOHANG)
      rescue Errno::ECHILD
        nil
      end

      def check_queued_jobs
        @config.worker_settings.each do |setting|
          current_count = @master.workers.count { |worker| worker.setting.queues == setting.queues }
          remaining_count = setting.count - current_count
          if remaining_count > 0 && (job_count = count_job(setting)) > 0
            [remaining_count, job_count].min.times do
              fork_dynamic_worker(setting)
            end
          end
        end
      end

      def count_job(setting)
        Delayed::Master::JobCounter.count(setting)
      end

      def fork_dynamic_worker(setting)
        worker = Delayed::Master::Worker.new(@master.workers.size, setting)
        @master.workers << worker

        @master.logger.info "forking dynamic worker..."
        fork_worker(worker)
        @master.logger.info "forked worker #{worker.pid}"

        print_workers
      end

      def fork_worker(worker)
        @callback.run(:before_fork, @master, worker)
        worker.pid = fork do
          worker.pid = Process.pid
          worker.instance = create_instance(worker)
          @callback.run(:after_fork, @master, worker)
          $0 = worker.title
          worker.instance.start
        end
      end

      def create_instance(worker)
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

      def print_workers
        @master.workers.each do |worker|
          @master.logger.debug "#{worker.pid}: #{worker.title}"
        end
      end
    end
  end
end
