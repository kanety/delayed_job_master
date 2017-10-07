module Delayed
  class WorkerInfo
    attr_reader :index, :configs
    attr_accessor :pid

    def initialize(index, configs = {})
      @index = index
      @configs = configs
    end

    def title
      titles = ["delayed_job.#{@index}"]
      titles << "(#{@configs[:queues].join(',')})" if @configs[:queues]
      titles.join(' ')
    end
  end
end
