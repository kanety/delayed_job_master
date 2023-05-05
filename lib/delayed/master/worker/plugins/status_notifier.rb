# frozen_string_literal: true

module Delayed
  class Master
    class Worker
      module Plugins
        class StatusNotifier < Delayed::Plugin
          callbacks do |lifecycle|
            lifecycle.around(:execute) do |worker, job, &block|
              title = $0
              $0 = "#{title} [BUSY]"
              ret = block.call
              $0 = title
              ret
            end
          end
        end
      end
    end
  end
end
