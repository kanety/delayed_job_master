# frozen_string_literal: true

module Delayed
  module Master
    class Database
      class_attribute :model_cache
      self.model_cache = {}

      attr_accessor :spec_name

      def initialize(spec_name)
        @spec_name = spec_name
      end

      def model
        cache_model do
          define_model
        end
      end

      def with_connection
        model.connection_pool.with_connection do |connection|
          yield connection
        end
      end

      private

      def cache_model
        self.class.model_cache[@spec_name] ||= yield
      end

      def define_model
        model = Class.new(Delayed::Job)
        model_name = "DelayedJob#{@spec_name.capitalize}"
        unless Delayed::Master.const_defined?(model_name)
          Delayed::Master.const_set(model_name, model)
          Delayed::Master.const_get(model_name).establish_connection(@spec_name)
        end
        Delayed::Master.const_get(model_name)
      end

      class << self
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
          new(spec_name).model.connection_pool.with_connection do |connection|
            connection.tables.include?('delayed_jobs')
          end
        end
      end
    end
  end
end
