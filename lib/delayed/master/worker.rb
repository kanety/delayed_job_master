module Delayed
  class Master
    class Worker
      attr_reader :index, :setting
      attr_accessor :pid

      def initialize(index, setting)
        @index = index
        @setting = setting
      end

      def title
        titles = ["delayed_job.#{@index}"]
        titles << "(#{@setting.queues.join(',')})" if @setting.queues
        titles.join(' ')
      end
    end
  end
end
