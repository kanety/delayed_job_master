# frozen_string_literal: true

require_relative 'worker_setting'

module Delayed
  module Master
    class Config
      SIMPLE_CONFIGS   = [:daemon, :working_directory, :log_file, :log_level, :pid_file,
                          :monitor_interval, :polling_interval, :databases]
      CALLBACK_CONFIGS = [:before_fork, :after_fork,
                          :before_monitor, :after_monitor, :around_monitor,
                          :before_polling, :after_polling, :around_polling]

      attr_accessor *SIMPLE_CONFIGS
      attr_accessor *CALLBACK_CONFIGS
      attr_reader :workers

      def initialize(file = nil)
        @daemon = false
        @working_directory = Dir.pwd
        @pid_file = "#{@working_directory}/tmp/pids/delayed_job_master.pid"
        @log_file = "#{@working_directory}/log/delayed_job_master.log"
        @log_level = :info
        @monitor_interval = 5
        @polling_interval = 30
        @databases = []
        CALLBACK_CONFIGS.each do |name|
          send("#{name}=", [])
        end
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

      SIMPLE_CONFIGS.each do |key|
        define_method(key) do |*args|
          if args.size > 0
            instance_variable_set("@#{key}", args[0])
          else
            instance_variable_get("@#{key}")
          end
        end
      end

      CALLBACK_CONFIGS.each do |key|
        define_method(key) do |&block|
          if block
            instance_variable_get("@#{key}") << block
          else
            instance_variable_get("@#{key}")
          end
        end
      end

      def monitor_wait(value = nil)
        warn <<-TEXT.squish
          DEPRECATION WARNING: 'monitor_wait' setting was deprecated. Use 'monitor_interval' instead. (#{caller[0]})
        TEXT
        @monitor_interval = @polling_interval = value
      end

      def abstract_texts
        texts = []
        texts << "databases: #{@databases.join(', ')}" if @databases.present?
        texts += @workers.map do |worker|
          str = "worker[#{worker.id}]: #{worker.max_processes} processes, #{worker.max_threads} threads"
          str += " (#{worker.queues.join(', ')})" if worker.queues.present?
          str
        end
        texts
      end
    end
  end
end
