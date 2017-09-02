require 'fileutils'
require 'logger'
require 'timeout'
require 'delayed_job'
require_relative 'util'
require_relative 'master/version'
require_relative 'master/command'
require_relative 'master/dsl'
require_relative 'worker/info'
require_relative 'worker_plugins/all'

module Delayed
  class Worker
    attr_accessor :master_logger, :max_memory
  end

  class Master
    attr_reader :configs, :pid_file, :logger, :worker_infos

    def initialize(argv)
      @configs = Delayed::Master::Command.new(argv).configs
      @pid_file = @configs[:pid_file]
      @logger = setup_logger(@configs[:log_file], @configs[:log_level])
      @worker_infos = setup_worker_infos(@configs[:worker_configs])

      @signal_handler = SignalHandler.new(self)
      @worker_factory = WorkerFactory.new(self)
      @worker_monitor = WorkerMonitor.new(self, @worker_factory)
    end

    def run
      daemonize if @configs[:daemon]

      create_pid_file
      @logger.info "started master #{Process.pid}"

      @signal_handler.register
      @worker_factory.fork_workers
      @prepared = true

      @worker_monitor.run

      remove_pid_file
      @logger.info "shut down master"
    end

    def prepared?
      @prepared
    end

    def stop
      @signal_handler.dispatch('TERM')
      @stop = true
    end

    def stop?
      @stop
    end

    def reopen_files
      @signal_handler.dispatch('USR1')
      @logger.info "reopening files..."
      Delayed::Util.reopen_files
      @logger.info "reopened"
    end

    def restart
      @signal_handler.dispatch('USR2')
      @logger.info "restarting master..."
      exec(*([$0] + ARGV))
    end

    def kill_workers
      @signal_handler.dispatch('KILL')
    end

    def wait_workers
      Process.waitall
    end

    private

    def setup_logger(log_file, log_level)
      FileUtils.mkdir_p(File.dirname(log_file))
      logger = Logger.new(log_file)
      logger.level = log_level
      logger
    end

    def setup_worker_infos(worker_configs)
      worker_configs.map.with_index do |config, i|
        Delayed::Worker::Info.new(i, config)
      end
    end

    def create_pid_file
      FileUtils.mkdir_p(File.dirname(@pid_file))
      File.write(@pid_file, Process.pid)
    end

    def remove_pid_file
      File.delete(@pid_file) if File.exist?(@pid_file)
    end

    def daemonize
      Process.daemon(true)
    end

    class SignalHandler
      def initialize(master)
        @master = master
        @logger = @master.logger
      end

      def register
        %w(TERM INT USR1 USR2).each do |signal|
          trap(signal) do
            Thread.new do
              @logger.info "received #{signal} signal"
              case signal
              when 'TERM', 'INT'
                @master.stop
              when 'USR1'
                @master.reopen_files
              when 'USR2'
                @master.restart
              end
            end
          end
        end
      end

      def dispatch(signal)
        @master.worker_infos.each do |worker_info|
          next unless worker_info.pid
          begin
            Process.kill signal, worker_info.pid
            @logger.info "sent #{signal} signal to worker #{worker_info.pid}"
          rescue
            @logger.error "failed to send #{signal} signal to worker #{worker_info.pid}"
          end
        end
      end
    end

    class WorkerFactory
      def initialize(master)
        @master = master
        @logger = @master.logger
        @before_fork = @master.configs[:before_fork]
        @after_fork = @master.configs[:after_fork]
      end

      def fork_workers
        @master.worker_infos.each do |worker_info|
          fork_worker(worker_info)
          @logger.info "started worker #{worker_info.pid}"
        end
      end

      def fork_worker(worker_info)
        run_callback(@before_fork, worker_info)
        worker_info.pid = fork do
          run_callback(@after_fork, worker_info)
          $0 = worker_info.title
          worker = create_new_worker(worker_info)
          worker.start
        end
      end

      private

      def run_callback(calback, worker_info)
        calback.call(@master, worker_info) if calback
      end

      def create_new_worker(worker_info)
        worker = Delayed::Worker.new(worker_info.configs)
        [:max_run_time, :max_attempts].each do |key|
          value = worker_info.configs[key]
          Delayed::Worker.send("#{key}=", value) if value
        end
        [:max_memory].each do |key|
          value = worker_info.configs[key]
          worker.send("#{key}=", value) if value
        end
        worker.master_logger = @logger
        worker
      end
    end

    class WorkerMonitor
      def initialize(master, worker_factory)
        @master = master
        @logger = master.logger
        @worker_factory = worker_factory
        @monitor_wait = @master.configs[:monitor_wait]
      end

      def run
        loop do
          break if @master.stop?
          if (pid = wait_pid)
            fork_new_worker_for(pid)
          end
          sleep @monitor_wait.to_i
        end
      end

      private

      def wait_pid
        begin
          Process.waitpid(-1, Process::WNOHANG)
        rescue Errno::ECHILD
          nil
        end
      end

      def fork_new_worker_for(pid)
        worker_info = @master.worker_infos.detect { |wi| wi.pid == pid }
        return unless worker_info

        @logger.info "worker #{worker_info.pid} seems to be killed, forking new worker..."
        @worker_factory.fork_worker(worker_info)
        @logger.info "forked: #{worker_info.pid}"
      end
    end
  end
end
