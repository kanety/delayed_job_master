require 'fileutils'
require 'logger'
require_relative 'master/version'
require_relative 'master/command'
require_relative 'master/callback'
require_relative 'master/worker'
require_relative 'master/worker_pool'
require_relative 'master/signal_handler'
require_relative 'master/job_counter'
require_relative 'master/util/file_reopener'

module Delayed
  class Master
    attr_reader :config, :logger, :workers

    def initialize(argv)
      @config = Command.new(argv).config
      @logger = setup_logger(@config.log_file, @config.log_level)
      @workers = []

      @signal_handler = SignalHandler.new(self)
      @worker_pool = WorkerPool.new(self)
    end

    def run
      load_app
      show_config
      daemonize if @config.daemon

      @logger.info "started master #{Process.pid}"

      handle_pid_file do
        @signal_handler.register
        @prepared = true
        @worker_pool.monitor_while { stop? }
      end

      @logger.info "shut down master"
    end

    def prepared?
      @prepared
    end

    def quit
      @signal_handler.dispatch(:KILL)
      @stop = true
    end

    def stop
      @signal_handler.dispatch(:TERM)
      @stop = true
    end

    def stop?
      @stop == true
    end

    def reopen_files
      @signal_handler.dispatch(:USR1)
      @logger.info "reopening files..."
      Util::FileReopener.reopen
      @logger.info "reopened"
    end

    def restart
      @signal_handler.dispatch(:USR2)
      @logger.info "restarting master..."
      exec(*([$0] + ARGV))
    end

    private

    def setup_logger(log_file, log_level)
      FileUtils.mkdir_p(File.dirname(log_file))
      logger = Logger.new(log_file)
      logger.level = log_level
      logger
    end
  
    def load_app
      require File.join(@config.working_directory, 'config', 'environment')
      require_relative 'worker_extension'
    end

    def daemonize
      Process.daemon(true)
    end

    def handle_pid_file
      create_pid_file
      yield
      remove_pid_file
    end

    def create_pid_file
      FileUtils.mkdir_p(File.dirname(@config.pid_file))
      File.write(@config.pid_file, Process.pid)
    end

    def remove_pid_file
      File.delete(@config.pid_file) if File.exist?(@config.pid_file)
    end

    def show_config
      @config.worker_settings.each do |setting|
        puts "#{setting.count} worker for '#{setting.queues.join(',')}'"
      end
    end
  end
end
