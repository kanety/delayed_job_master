# frozen_string_literal: true

module Delayed
  module Master
    class Worker
      module Plugins
        class SignalHandler < Delayed::Plugin
          callbacks do |lifecycle|
            lifecycle.before(:execute) do |worker|
              worker.instance_eval do
                Signal.trap(:USR1) do
                  Thread.new do
                    master_logger.info "reopening files..."
                    Delayed::Master::FileReopener.reopen
                    master_logger.info "reopened"
                  end
                end
                Signal.trap(:USR2) do
                  Thread.new do
                    $0 = "#{$0} [OLD]"
                    master_logger.info "shutting down worker #{Process.pid}..."
                    stop
                  end
                end
              end
            end
            lifecycle.after(:execute) do |worker|
              worker.master_logger.info "shut down worker #{Process.pid}"
            end
          end
        end
      end
    end
  end
end
