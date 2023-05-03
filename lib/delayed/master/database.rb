# frozen_string_literal: true

module Delayed
  class Master
    class Database
      cattr_accessor :spec_names
      cattr_accessor :models
      @models = {}

      class << self
        def spec_names
          @spec_names || spec_names_without_replica.select do |spec_name|
            model_for(spec_name).connection.tables.include?('delayed_jobs')
          end
        end

        def model_for(spec_name)
          cache_model(spec_name) do
            define_model(spec_name)
          end
        end

        private

        def spec_names_without_replica
          configs = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env)
          configs.reject!(&:replica?)
          if Rails::VERSION::MAJOR == 6
            configs.map { |c| c.spec_name.to_sym }
          else
            configs.map { |c| c.name.to_sym }
          end
        end

        def cache_model(spec_name)
          @models[spec_name] ||= yield
        end

        def define_model(spec_name)
          klass = Class.new(Delayed::Job)
          klass_name = "DelayedJob#{spec_name.capitalize}"
          unless Delayed::Master.const_defined?(klass_name)
            Delayed::Master.const_set(klass_name, klass)
            Delayed::Master.const_get(klass_name).establish_connection(spec_name)
          end
          Delayed::Master.const_get(klass_name)
        end
      end
    end
  end
end
