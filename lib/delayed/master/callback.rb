module Delayed
  class Master
    class Callback
      def initialize(config)
        @callbacks = config.callbacks
      end

      def run(name, *args)
        @callbacks[name].call(*args) if @callbacks[name]
      end
    end
  end
end
