module Delayed
  class Master
    class WorkerPool
      def initialize(master, config)
        @master = master
        @config = config

        @logger = master.logger
        @workers = master.workers

        @static_settings, @dynamic_settings = config.workers.partition { |conf| conf.control == :static }
        @callback = Delayed::Master::Callback.new(config)
      end

      def init
        @static_settings.each_with_index do |setting, i|
          worker = Delayed::Master::Worker.new(i, setting)
          @workers << worker
          fork_worker(worker)
          @logger.info "started worker #{worker.pid}"
        end

        @prepared = true
        print_workers
      end

      def monitor_while(&block)
        loop do
          break if block.call
          monitor do
            check_pid
            check_dynamic_worker
          end
          sleep @config.monitor_wait.to_i
        end
      end

      def prepared?
        @prepared
      end

      private

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
        instance.master_logger = @logger
        instance
      end

      def monitor
        @callback.run(:before_monitor, @master)
        yield
        @callback.run(:after_monitor, @master)
      rescue Exception => e
        @logger.warn "#{e.class}: #{e.message} at #{__FILE__}: #{__LINE__}"
      end

      def check_pid
        pid = wait_pid
        return unless pid
        worker = @workers.detect { |worker| worker.pid == pid }
        return unless worker

        case worker.setting.control
        when :static
          fork_alt_worker(worker)
        when :dynamic
          @workers.delete(worker)
        end
      end

      def wait_pid
        Process.waitpid(-1, Process::WNOHANG)
      rescue Errno::ECHILD
        nil
      end

      def check_dynamic_worker
        @dynamic_settings.each do |setting|
          current_count = @workers.count { |worker| worker.setting.queues == setting.queues }
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
        worker = Delayed::Master::Worker.new(@workers.size, setting)
        @workers << worker

        @logger.info "forking dynamic worker..."
        fork_worker(worker)
        @logger.info "forked worker #{worker.pid}"

        print_workers
      end

      def fork_alt_worker(worker)
        @logger.info "worker #{worker.pid} seems to be killed, forking alternative worker..."
        fork_worker(worker)
        @logger.info "forked worker #{worker.pid}"

        print_workers
      end

      def print_workers
        @workers.each do |worker|
          @logger.debug "#{worker.pid}: #{worker.title}"
        end
      end
    end
  end
end
