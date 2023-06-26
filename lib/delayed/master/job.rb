# frozen_string_literal: true

module Delayed
  module Master
    class Job
      attr_accessor :database, :setting, :id, :run_at

      def initialize(attrs = {})
        attrs.each do |k, v|
          send("#{k}=", v)
        end
      end
    end
  end
end
