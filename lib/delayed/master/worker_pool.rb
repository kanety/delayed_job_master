module Delayed
  class Master
    class WorkerPool
      def initialize(master, config = {})
        @master = master
        @logger = master.logger
        @worker_infos = master.worker_infos

        @config = OpenStruct.new(config).freeze
        @static_worker_configs, @dynamic_worker_configs = @config.worker_configs.partition { |wc| wc[:control] == :static }

        @callback = Delayed::Master::Callback.new(config)
      end

      def init
        @static_worker_configs.each_with_index do |config, i|
          worker_info = Delayed::Master::WorkerInfo.new(i, config)
          @worker_infos << worker_info
          fork_worker(worker_info)
          @logger.info "started worker #{worker_info.pid}"
        end

        @prepared = true
        debug_worker_infos
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

      def fork_worker(worker_info)
        @callback.run(:before_fork, @master, worker_info)
        worker_info.pid = fork do
          @callback.run(:after_fork, @master, worker_info)
          $0 = worker_info.title
          worker = create_new_worker(worker_info)
          worker.start
        end
      end

      def create_new_worker(worker_info)
        worker = Delayed::Worker.new(worker_info.config)
        [:max_run_time, :max_attempts, :destroy_failed_jobs].each do |key|
          if worker_info.config.key?(key)
            Delayed::Worker.send("#{key}=", worker_info.config[key])
          end
        end
        [:max_memory].each do |key|
          value = worker_info.config[key]
          worker.send("#{key}=", value) if value
        end
        worker.master_logger = @logger
        worker
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
        worker_info = @worker_infos.detect { |wi| wi.pid == pid }
        return unless worker_info

        case worker_info.config[:control]
        when :static
          fork_alt_worker(worker_info)
        when :dynamic
          @worker_infos.delete(worker_info)
        end
      end

      def wait_pid
        Process.waitpid(-1, Process::WNOHANG)
      rescue Errno::ECHILD
        nil
      end

      def check_dynamic_worker
        @dynamic_worker_configs.each do |worker_config|
          current_count = @worker_infos.count { |wi| wi.config[:queues] == worker_config[:queues] }
          remaining_count = worker_config[:count] - current_count
          if remaining_count > 0 && (job_count = count_job_for_worker(worker_config)) > 0
            [remaining_count, job_count].min.times do
              fork_dynamic_worker(worker_config)
            end
          end
        end
      end

      def count_job_for_worker(worker_config)
        Delayed::Master::JobCounter.count(worker_config)
      end

      def fork_dynamic_worker(worker_config)
        worker_info = Delayed::Master::WorkerInfo.new(@worker_infos.size, worker_config)
        @worker_infos << worker_info

        @logger.info "forking dynamic worker..."
        fork_worker(worker_info)
        @logger.info "forked worker #{worker_info.pid}"

        debug_worker_infos
      end

      def fork_alt_worker(worker_info)
        @logger.info "worker #{worker_info.pid} seems to be killed, forking alternative worker..."
        fork_worker(worker_info)
        @logger.info "forked worker #{worker_info.pid}"

        debug_worker_infos
      end

      def debug_worker_infos
        @worker_infos.each do |worker_info|
          @logger.debug "#{worker_info.pid}: #{worker_info.title}"
        end
      end
    end
  end
end
