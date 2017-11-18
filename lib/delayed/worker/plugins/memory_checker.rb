require 'get_process_mem'

module Delayed
  module Plugins
    class WorkerMemoryChecker < Delayed::Plugin
      callbacks do |lifecycle|
        lifecycle.after(:perform) do |worker, job|
          next unless worker.max_memory
          mem = GetProcessMem.new
          if mem.mb > worker.max_memory
            worker.master_logger.info "shutting down worker #{Process.pid} because it consumes large memory #{mem.mb.to_i} MB..."
            worker.stop
          end
        end
      end
    end
  end
end

Delayed::Worker.plugins << Delayed::Plugins::WorkerMemoryChecker
