# frozen_string_literal: true

module Delayed
  module Master
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
        strs = [@setting.worker_info]
        strs << "@#{@database.shard}" if @database
        strs.join(' ')
      end

      def process_title
        "delayed_job: #{info}"
      end
    end
  end
end
