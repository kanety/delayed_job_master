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
        def adapter
          case DelayedJobMaster.config.listen
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
