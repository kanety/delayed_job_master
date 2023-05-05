# frozen_string_literal: true

require 'get_process_mem'

module Delayed
  class Master
    class Worker
      module Plugins
        class MemoryChecker < Delayed::Plugin
          callbacks do |lifecycle|
            lifecycle.before(:perform) do |worker, job|
              mem = GetProcessMem.new
              worker.master_logger.info "performing #{job.name}, memory: #{mem.mb.to_i} MB"
            end
            lifecycle.after(:perform) do |worker, job|
              mem = GetProcessMem.new
              worker.master_logger.info "performed #{job.name}, memory: #{mem.mb.to_i} MB"
              if worker.max_memory && mem.mb > worker.max_memory
                worker.master_logger.info "shutting down worker #{Process.pid} because it consumes large memory..."
                worker.stop
              end
            end
          end
        end
      end
    end
  end
end
