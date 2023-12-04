# frozen_string_literal: true

module Delayed
  module Master
    class Worker
      module Plugins
        class ExecutionChecker < Delayed::Plugin
          callbacks do |lifecycle|
            lifecycle.before(:execute) do |worker|
              worker.execution_start_at = Time.zone.now
            end

            lifecycle.after(:perform) do |worker, job|
              if worker.max_execution &&
                worker.execution_start_at + worker.max_execution <= Time.zone.now && !worker.stop?
                worker.master_logger.info { "shutting down worker #{Process.pid} because it exceeds max execution" }
                worker.stop
              end
            end
          end
        end
      end
    end
  end
end
