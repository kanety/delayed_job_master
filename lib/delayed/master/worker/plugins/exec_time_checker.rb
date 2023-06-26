# frozen_string_literal: true

module Delayed
  module Master
    class Worker
      module Plugins
        class ExecTimeChecker < Delayed::Plugin
          callbacks do |lifecycle|
            lifecycle.before(:execute) do |worker|
              worker.exec_start_at = Time.zone.now
            end

            lifecycle.after(:perform) do |worker, job|
              if worker.max_exec_time &&
                worker.exec_start_at + worker.max_exec_time <= Time.zone.now && !worker.stop?
                worker.master_logger.info { "shutting down worker #{Process.pid} because it exceeds max execution time" }
                worker.stop
              end
            end
          end
        end
      end
    end
  end
end
