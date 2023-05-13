# frozen_string_literal: true

module Delayed
  module Master
    class Worker
      module Plugins
        class ExecutorWrapper < Delayed::Plugin
          callbacks do |lifecycle|
            lifecycle.around(:thread) do |worker, &block|
              if defined?(Rails)
                Rails.application.executor.wrap do
                  block.call
                end
              else
                block.call
              end
            end
          end
        end
      end
    end
  end
end
