# frozen_string_literal: true

module Delayed
  class Master
    class Worker
      attr_accessor :index, :setting, :database
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
        str += " @#{@database}" if @database
        str += " (#{@setting.queues.join(', ')})" if @setting.queues.respond_to?(:join)
        str
      end

      def process_title
        "delayed_job.#{@index}: #{info}"
      end
    end
  end
end
