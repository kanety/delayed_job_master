require_relative 'job_counter'

module Delayed
  class Master
    class JobChecker
      def initialize(master)
        @master = master
        @config = master.config
        @spec_names = target_spec_names

        define_models
        extend_after_fork_callback
      end

      def check
        workers = []
        mon = Monitor.new

        threads = @spec_names.map do |spec_name|
          Thread.new(spec_name) do |spec_name|
            find_jobs_in_db(spec_name) do |setting|
              mon.synchronize do
                workers << Worker.new(index: @master.workers.size + workers.size, database: spec_name, setting: setting)
              end
            end
          end
        end

        threads.each(&:join)

        workers
      end

      private

      def define_models
        @spec_names.each do |spec_name|
          klass = Class.new(Delayed::Job)
          klass_name = "DelayedJob#{spec_name.capitalize}"
          unless defined? klass_name
            Delayed::Master.const_set(klass_name, klass)
            Delayed::Master.const_get(klass_name).establish_connection(spec_name)
          end
        end
      end

      def model_for(spec_name)
        Delayed::Master.const_get("DelayedJob#{spec_name.capitalize}")
      end

      def extend_after_fork_callback
        prc = @config.after_fork
        @config.after_fork do |master, worker|
          prc.call(master, worker)
          if worker.database && ActiveRecord::Base.connection_pool.spec.name != worker.database.to_s
            ActiveRecord::Base.establish_connection(worker.database)
          end
        end
      end

      def target_spec_names
        if @config.databases.nil? || @config.databases.empty?
          load_spec_names
        else
          @config.databases
        end
      end

      def load_spec_names
        if Rails::VERSION::MAJOR >= 6
          ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).map { |c| c.spec_name.to_sym }
        else
          Rails.env.to_sym
        end
      end

      def find_jobs_in_db(spec_name)
        counter = JobCounter.new(model_for(spec_name))

        @config.worker_settings.each do |setting|
          count = @master.workers.count { |worker| worker.setting.queues == setting.queues }
          slot = setting.count - count
          if slot > 0 && (job_count = counter.count(setting)) > 0
            [slot, job_count].min.times do
              yield setting
            end
          end
        end
      end
    end
  end
end
