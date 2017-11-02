module Delayed
  class Master
    class WorkerFactory
      def initialize(master, config = {})
        @master = master
        @config = OpenStruct.new(config).freeze
        @callback = Delayed::Master::Callback.new(config)

        @dynamic_worker_configs = @config.worker_configs.select { |wc| wc[:control] == :dynamic }
      end

      def init_workers
        @config.worker_configs.each_with_index do |worker_config, i|
          next if worker_config[:control] == :dynamic

          worker_info = Delayed::Master::WorkerInfo.new(i, worker_config)
          @master.worker_infos << worker_info
          fork_worker(worker_info)
          @master.logger.info "started worker #{worker_info.pid}"
        end
      end

      def monitor
        loop do
          break if @master.stop?
          check_pid
          check_dynamic_worker
          sleep @config.monitor_wait.to_i
        end
      end

      private

      def fork_worker(worker_info)
        @callback.run(:before_fork, worker_info)
        worker_info.pid = fork do
          @callback.run(:after_fork, worker_info)
          $0 = worker_info.title
          worker = create_new_worker(worker_info)
          worker.start
        end
      end

      def create_new_worker(worker_info)
        worker = Delayed::Worker.new(worker_info.config)
        [:max_run_time, :max_attempts].each do |key|
          value = worker_info.config[key]
          Delayed::Worker.send("#{key}=", value) if value
        end
        [:max_memory].each do |key|
          value = worker_info.config[key]
          worker.send("#{key}=", value) if value
        end
        worker.master_logger = @master.logger
        worker
      end

      def check_pid
        pid = wait_pid
        return unless pid
        worker_info = @master.worker_infos.detect { |wi| wi.pid == pid }
        return unless worker_info

        case worker_info.config[:control]
        when :static
          fork_alt_worker(worker_info)
        when :dynamic
          @master.worker_infos.delete(worker_info)
        end
      end

      def wait_pid
        begin
          Process.waitpid(-1, Process::WNOHANG)
        rescue Errno::ECHILD
          nil
        end
      end

      def check_dynamic_worker
        @dynamic_worker_configs.each do |worker_config|
          current_count = @master.worker_infos.count { |wi| wi.config[:queues] == worker_config[:queues] }
          remaining_count = worker_config[:count] - current_count
          if remaining_count > 0 && (job_count = count_job_for_worker(worker_config)) > 0
            [remaining_count, job_count].min.times { fork_new_worker(worker_config) }
          end
        end
      end

      def count_job_for_worker(worker_config)
        Delayed::Master::JobCounter.count(worker_config)
      end

      def fork_new_worker(worker_config)
        worker_info = Delayed::Master::WorkerInfo.new(@master.worker_infos.size, worker_config)
        @master.worker_infos << worker_info

        @master.logger.info "forking dynamic worker..."
        fork_worker(worker_info)
        @master.logger.info "forked worker #{worker_info.pid}"
      end

      def fork_alt_worker(worker_info)
        @master.logger.info "worker #{worker_info.pid} seems to be killed, forking alternative worker..."
        fork_worker(worker_info)
        @master.logger.info "forked worker #{worker_info.pid}"
      end
    end
  end
end
