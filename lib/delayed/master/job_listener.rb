# frozen_string_literal: true

module Delayed
  module Master
    class JobListener
      def initialize(master)
      end

      def start
      end

      def wait
      end

      def shutdown
      end

      class << self
        def klass
          case DelayedJobMaster.config.listener
          when :postgresql
            require_relative 'postgresql/job_listener'
            Postgresql::JobListener
          else
            self
          end
        end
      end
    end
  end
end
