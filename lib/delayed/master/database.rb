# frozen_string_literal: true

module Delayed
  class Master
    class Database
      attr_accessor :spec_name

      def initialize(spec_name)
        @spec_name = spec_name
      end

      def model
        cache_model do
          define_model
        end
      end

      private

      def cache_model
        self.class.models[@spec_name] ||= yield
      end

      def define_model
        klass = Class.new(Delayed::Job)
        klass_name = "DelayedJob#{@spec_name.capitalize}"
        unless Delayed::Master.const_defined?(klass_name)
          Delayed::Master.const_set(klass_name, klass)
          Delayed::Master.const_get(klass_name).establish_connection(@spec_name)
        end
        Delayed::Master.const_get(klass_name)
      end

      class << self
        class_attribute :models
        self.models = {}

        def all(spec_names = nil)
          spec_names = spec_names.presence || spec_names_with_delayed_job_table
          spec_names.map { |spec_name| new(spec_name) }
        end

        private

        def spec_names_with_delayed_job_table
          @spec_names_with_delayed_job_table ||= spec_names_without_replica.select do |spec_name|
            exist_delayed_job_table?(spec_name)
          end
        end

        def spec_names_without_replica
          configs = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env)
          configs.reject(&:replica?).map do |c|
            c.respond_to?(:name) ? c.name.to_sym : c.spec_name.to_sym
          end
        end

        def exist_delayed_job_table?(spec_name)
          klass = if Delayed::Master.const_defined?('ARBase')
              Delayed::Master.const_get('ARBase')
            else
              Class.new(ActiveRecord::Base).tap do |klass|
                Delayed::Master.const_set('ARBase', klass)
              end
            end
          klass.establish_connection(spec_name)
          klass.connection.tables.include?('delayed_jobs')
        end
      end
    end
  end
end
