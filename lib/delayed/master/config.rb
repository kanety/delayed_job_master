module Delayed
  class Master
    class Config
      SIMPLE_CONFIGS   = [:working_directory, :log_file, :log_level, :pid_file, :monitor_wait, :daemon, :databases]
      CALLBACK_CONFIGS = [:before_fork, :after_fork, :before_monitor, :after_monitor]

      attr_reader :data, :workers

      def initialize(file = nil)
        @data = {}
        @workers = []
        read(file) if file
      end

      def worker_settings
        @workers
      end

      def read(file)
        instance_eval(File.read(file), file)
      end

      def add_worker
        worker = WorkerSetting.new(id: @workers.size, count: 1, exit_on_complete: true)
        yield worker
        @workers << worker
      end

      def callbacks
        @data.select { |k, _| CALLBACK_CONFIGS.include?(k) }
      end

      def run_callback(key, *args)
        @data[key].call(*args)
      end

      SIMPLE_CONFIGS.each do |key|
        define_method(key) do |value = nil|
          if value
            @data[key] = value
          else
            @data[key]
          end
        end
      end

      CALLBACK_CONFIGS.each do |key|
        define_method(key) do |&block|
          if block
            @data[key] = block
          else
            @data[key]
          end
        end
      end

      class WorkerSetting
        SIMPLE_CONFIGS = [:id, :count, :max_memory,
                          :min_priority, :max_priority, :sleep_delay, :read_ahead, :exit_on_complete,
                          :max_attempts, :max_run_time, :destroy_failed_jobs]
        ARRAY_CONFIGS  = [:queues]

        attr_reader :data

        def initialize(default = {})
          @data = default
        end

        def control(value = nil)
          puts "DEPRECATION WARNING: deprecated control setting is called from #{caller(1, 1).first}. Remove it from your config file."
        end

        SIMPLE_CONFIGS.each do |key|
          define_method(key) do |value = nil|
            if !value.nil?
              @data[key] = value
            else
              @data[key]
            end
          end
        end

        ARRAY_CONFIGS.each do |key|
          define_method(key) do |value = nil|
            if value
              @data[key] = Array(value)
            else
              @data[key]
            end
          end
        end
      end
    end
  end
end
