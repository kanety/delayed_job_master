# frozen_string_literal: true

module Delayed
  module Master
    class WorkerSetting
      SIMPLE_CONFIGS = [:id, :max_processes, :max_threads, :max_memory,
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
        ActiveSupport::Deprecation.warn <<-TEXT.squish
          deprecated 'control' setting was used. Remove it from your config file.
        TEXT
      end

      def count(value = nil)
        ActiveSupport::Deprecation.warn <<-TEXT.squish
          deprecated 'count' setting was used. Use 'max_processes' instead.
        TEXT
        max_processes value
      end
    end
  end
end
