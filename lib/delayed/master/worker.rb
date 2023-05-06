# frozen_string_literal: true

module Delayed
  class Master
    class Worker
      attr_accessor :setting, :database
      attr_accessor :pid, :instance

      def initialize(attrs = {})
        attrs.each do |k, v|
          send("#{k}=", v)
        end
      end

      def name
        "worker[#{@setting.id}]"
      end

      def info
        str = name
        str += " @#{@database.spec_name}" if @database
        str += " (#{@setting.queues.join(', ')})" if @setting.queues.present?
        str
      end

      def process_title
        "delayed_job: #{info}"
      end
    end
  end
end
