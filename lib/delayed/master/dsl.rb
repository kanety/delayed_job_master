module Delayed
  class Master
    class DSL
      SIMPLE_CONFIGS   = [:working_directory, :log_file, :log_level, :pid_file, :monitor_wait]
      CALLBACK_CONFIGS = [:before_fork, :after_fork]

      attr_reader :config

      def initialize(config_file)
        @config = { worker_configs: [] }
        instance_eval(File.read(config_file))
        @config
      end

      def add_worker
        setting = WorkerSetting.new(control: :static, count: 1)
        yield setting
        setting.config[:exit_on_complete] = true if setting.config[:control] == :dynamic
        @config[:worker_configs] << setting.config
      end

      SIMPLE_CONFIGS.each do |key|
        define_method(key) do |value|
          @config[key] = value
        end
      end

      CALLBACK_CONFIGS.each do |key|
        define_method(key) do |&block|
          @config[key] = block
        end
      end

      class WorkerSetting
        SIMPLE_CONFIGS = [:control, :count, :max_memory,
                          :min_priority, :max_priority, :sleep_delay, :read_ahead, :exit_on_complete,
                          :max_attempts, :max_run_time]
        ARRAY_CONFIGS  = [:queues]

        attr_reader :config

        def initialize(default = {})
          @config = default
        end

        SIMPLE_CONFIGS.each do |key|
          define_method(key) do |value|
            @config[key] = value
          end
        end

        ARRAY_CONFIGS.each do |key|
          define_method(key) do |value|
            @config[key] = Array(value)
          end
        end
      end
    end
  end
end
