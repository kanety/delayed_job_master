# frozen_string_literal: true

require_relative 'lifecycle'
require_relative 'thread_pool'
require_relative 'thread_worker'
require_relative 'plugins/all'
require_relative 'backend/active_record' if defined?(Delayed::Backend::ActiveRecord)

module Delayed
  class Worker
    attr_accessor :master_logger
    attr_accessor :max_threads, :max_memory, :exit_on_timeout
  end
end
