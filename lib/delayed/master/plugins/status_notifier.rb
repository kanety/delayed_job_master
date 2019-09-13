module Delayed
  class Master
    module Plugins
      class StatusNotifier < Delayed::Plugin
        callbacks do |lifecycle|
          lifecycle.around(:perform) do |worker, job, &block|
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
