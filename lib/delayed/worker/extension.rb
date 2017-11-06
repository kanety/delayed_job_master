require_relative 'plugins/memory_checker'
require_relative 'plugins/signal_handler'
require_relative 'plugins/status_notifier'

module Delayed
  class Worker
    attr_accessor :master_logger, :max_memory
  end
end
