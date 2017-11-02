require 'fileutils'
require 'logger'
require 'ostruct'
require_relative 'util/file_reopener'
require_relative 'master/version'
require_relative 'master/command'
require_relative 'master/callback'
require_relative 'master/worker_info'
require_relative 'master/worker_factory'
require_relative 'master/signal_handler'

module Delayed
  class Master
    attr_reader :config, :logger, :worker_infos

    def initialize(argv)
      config = Command.new(argv).config
      @config = OpenStruct.new(config).freeze
      @logger = setup_logger(@config.log_file, @config.log_level)
      @worker_infos = []

      @signal_handler = SignalHandler.new(self)
      @worker_factory = WorkerFactory.new(self, config)
      load_app
    end

    def run
      daemonize if @config.daemon

      create_pid_file
      @logger.info "started master #{Process.pid}"

      @signal_handler.register
      @worker_factory.init_workers

      @prepared = true

      @worker_factory.monitor

      remove_pid_file
      @logger.info "shut down master"
    end

    def load_app
      require File.join(@config.working_directory, 'config', 'environment')
      require_relative 'master/job_counter'
      require_relative 'worker/extension'
    end

    def prepared?
      @prepared
    end

    def quit
      kill_workers
      @stop = true
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
      Delayed::Util::FileReopener.reopen
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

    def create_pid_file
      FileUtils.mkdir_p(File.dirname(@config.pid_file))
      File.write(@config.pid_file, Process.pid)
    end

    def remove_pid_file
      File.delete(@config.pid_file) if File.exist?(@config.pid_file)
    end

    def daemonize
      Process.daemon(true)
    end
  end
end
