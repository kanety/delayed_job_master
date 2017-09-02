module Delayed
  class Master
    class DSL
      SIMPLE_CONFIGS   = [:log_file, :log_level, :pid_file, :monitor_wait]
      CALLBACK_CONFIGS = [:before_fork, :after_fork]

      attr_reader :configs

      def initialize(config_file)
        @configs = { worker_configs: [] }
        instance_eval(File.read(config_file))
        @configs
      end

      def add_worker
        setting = WorkerSetting.new
        yield setting
        @configs[:worker_configs] << setting.configs
      end

      SIMPLE_CONFIGS.each do |key|
        define_method(key) do |value|
          @configs[key] = value
        end
      end

      CALLBACK_CONFIGS.each do |key|
        define_method(key) do |&block|
          @configs[key] = block
        end
      end

      class WorkerSetting
        SIMPLE_CONFIGS = [:min_priority, :max_priority, :sleep_delay, :read_ahead, :exit_on_complete,
                          :max_attempts, :max_run_time, :max_memory]
        ARRAY_CONFIGS  = [:queues]

        attr_reader :configs

        def initialize
          @configs = {}
        end

        SIMPLE_CONFIGS.each do |key|
          define_method(key) do |value|
            @configs[key] = value
          end
        end

        ARRAY_CONFIGS.each do |key|
          define_method(key) do |value|
            @configs[key] = Array(value)
          end
        end
      end
    end
  end
end
