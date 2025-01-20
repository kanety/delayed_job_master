# frozen_string_literal: true

module Delayed
  module Master
    class WorkerSetting
      SIMPLE_CONFIGS = [:id, :max_processes, :max_threads, :max_memory, :exit_on_timeout,
                        :min_priority, :max_priority, :sleep_delay, :read_ahead, :exit_on_complete,
                        :max_attempts, :max_run_time, :destroy_failed_jobs]
      ARRAY_CONFIGS  = [:queues]

      attr_accessor *SIMPLE_CONFIGS
      attr_accessor *ARRAY_CONFIGS

      def initialize(attrs = {})
        @queues = []
        @max_processes = 1
        @max_threads = 1
        @exit_on_complete = true
        self.attributes = attrs
      end

      def attributes=(attrs = {})
        attrs.each do |key, value|
          send("#{key}=", value)
        end
      end

      def worker_name
        "worker[#{id}]"
      end

      def worker_info
        strs = [worker_name]
        strs << "(#{@queues.join(', ')})" if @queues.present?
        strs.join(' ')
      end

      SIMPLE_CONFIGS.each do |key|
        define_method(key) do |*args|
          if args.size > 0
            instance_variable_set("@#{key}", args[0])
          else
            instance_variable_get("@#{key}")
          end
        end
      end

      ARRAY_CONFIGS.each do |key|
        define_method(key) do |*args|
          if args.size > 0
            instance_variable_set("@#{key}", Array(args[0]))
          else
            instance_variable_get("@#{key}")
          end
        end
      end

      def control(value = nil)
        warn <<-TEXT.squish
          DEPRECATION WARNING: 'control' setting was deprecated. Remove it from your config file. (#{caller[0]})
        TEXT
      end

      def count(value = nil)
        warn <<-TEXT.squish
          DEPRECATION WARNING: 'count' setting was deprecated. Use 'max_processes' instead. (#{caller[0]})
        TEXT
        max_processes value
      end
    end
  end
end
