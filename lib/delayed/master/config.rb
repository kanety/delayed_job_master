# frozen_string_literal: true

require_relative 'worker_setting'

module Delayed
  class Master
    class Config
      SIMPLE_CONFIGS   = [:working_directory, :log_file, :log_level, :pid_file, :monitor_wait, :daemon, :databases]
      CALLBACK_CONFIGS = [:before_fork, :after_fork, :before_monitor, :after_monitor]

      attr_accessor *SIMPLE_CONFIGS
      attr_accessor *CALLBACK_CONFIGS
      attr_reader :workers

      def initialize(file = nil)
        @workers = []
        read(file) if file
      end

      def read(file)
        instance_eval(File.read(file), file)
      end

      def worker_settings
        @workers
      end

      def add_worker
        worker = WorkerSetting.new(id: @workers.size)
        yield worker if block_given?
        @workers << worker
        worker
      end

      def run_callback(key, *args)
        send(key)&.call(*args)
      end

      SIMPLE_CONFIGS.each do |key|
        define_method(key) do |*args|
          if args.size > 0
            send("#{key}=", args[0])
          else
            instance_variable_get("@#{key}")
          end
        end
      end

      CALLBACK_CONFIGS.each do |key|
        define_method(key) do |&block|
          if block
            send("#{key}=", block)
          else
            instance_variable_get("@#{key}")
          end
        end
      end
    end
  end
end
