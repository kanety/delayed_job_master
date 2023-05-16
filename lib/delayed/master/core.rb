# frozen_string_literal: true

require 'fileutils'
require 'logger'
require_relative 'safe_array'
require_relative 'command'
require_relative 'worker'
require_relative 'database'
require_relative 'callbacks'
require_relative 'monitoring'
require_relative 'job_checker'
require_relative 'job_listener'
require_relative 'signaler'
require_relative 'file_reopener'

module Delayed
  module Master
    class Core
      attr_reader :config, :logger, :databases, :callbacks, :workers
      attr_reader :monitoring, :job_checker, :job_listener

      def initialize(argv)
        @config = Command.new(argv).config
        @logger = setup_logger(@config.log_file, @config.log_level)
        @workers = SafeArray.new

        @databases = Database.all(@config.databases)
        @callbacks = Callbacks.new(@config)
        @monitoring = Monitoring.new(self)
        @job_checker = JobChecker.new(self)
        @job_listener = JobListener.klass.new(self)
        @signaler = Signaler.new(self)
      end

      def run
        print_config
        daemonize if @config.daemon

        @logger.info { "started master #{Process.pid}".tap { |msg| puts msg } }

        handle_pid_file do
          @signaler.register
          @prepared = true

          start
          wait
          shutdown
        end

        @logger.info { "shut down master" }
      end

      def start
        @job_checker.start
        @job_listener.start
        @monitoring.start
      end

      def wait
        @job_checker.wait
        @job_listener.wait
        @monitoring.wait
      end

      def shutdown
        @job_checker.shutdown
        @job_listener.shutdown
        @monitoring.shutdown
      end

      def prepared?
        @prepared
      end

      def quit
        @signaler.dispatch(:KILL)
        shutdown
        @workers.clear
        @stop = true
      end

      def stop
        @signaler.dispatch(:TERM)
        shutdown
        @workers.clear
        @stop = true
      end

      def graceful_stop
        @signaler.dispatch(:TERM)
        @stop = true
      end

      def stop?
        @stop == true
      end

      def reopen_files
        @signaler.dispatch(:USR1)
        @logger.info { "reopening files..." }
        FileReopener.reopen
        @logger.info { "reopened" }
      end

      def restart
        @signaler.dispatch(:USR2)
        @logger.info { "restarting master..." }
        exec(*([$0] + ARGV))
      end

      private

      def setup_logger(log_file, log_level)
        FileUtils.mkdir_p(File.dirname(log_file)) if log_file.is_a?(String)
        logger = Logger.new(log_file)
        logger.level = log_level
        logger
      end

      def print_config
        @config.abstract_texts.each do |text|
          @logger.info { text }
        end
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
    end
  end
end
