require_relative 'thread_pool'
require_relative 'thread_worker'
require_relative 'plugins/all'
require_relative 'backend/active_record'

module Delayed
  class Worker
    attr_accessor :master_logger
    attr_accessor :max_threads, :max_memory
  end
end
