module Delayed
  class Master
    class WorkerInfo
      attr_reader :index, :config
      attr_accessor :pid

      def initialize(index, config = {})
        @index = index
        @config = config
      end

      def title
        titles = ["delayed_job.#{@index}"]
        titles << "(#{@config[:queues].join(',')})" if @config[:queues]
        titles.join(' ')
      end
    end
  end
end
