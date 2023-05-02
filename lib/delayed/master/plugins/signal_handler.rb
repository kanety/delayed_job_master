# frozen_string_literal: true

module Delayed
  class Master
    module Plugins
      class SignalHandler < Delayed::Plugin
        callbacks do |lifecycle|
          lifecycle.before(:execute) do |worker|
            worker.instance_eval do
              trap(:USR1) do
                Thread.new do
                  master_logger.info "reopening files..."
                  Delayed::Master::Util::FileReopener.reopen
                  master_logger.info "reopened"
                end
              end
              trap(:USR2) do
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
