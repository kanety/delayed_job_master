# frozen_string_literal: true

module Delayed
  module Master
    class SafeArray < Array
      def initialize(*args)
        @mon = Monitor.new
        super
      end

      def <<(*args)
        @mon.synchronize do
          super
        end
      end

      def delete(*args)
        @mon.synchronize do
          super
        end
      end

      def clear
        @mon.synchronize do
          super
        end
      end
    end
  end
end
