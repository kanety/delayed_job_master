# frozen_string_literal: true

module Delayed
  class Master
    class DatabaseDetector
      def initialize
      end

      def call
        load_spec_names.select { |spec_name| has_delayed_job_table?(spec_name) }
      end

      private

      def load_spec_names
        configs = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env)
        configs.reject!(&:replica?)
        if Rails::VERSION::MAJOR == 6
          configs.map { |c| c.spec_name.to_sym }
        else
          configs.map { |c| c.name.to_sym }
        end
      end

      def has_delayed_job_table?(spec_name)
        ActiveRecord::Base.establish_connection(spec_name)
        ActiveRecord::Base.connection.tables.include?('delayed_jobs')
      end
    end
  end
end
