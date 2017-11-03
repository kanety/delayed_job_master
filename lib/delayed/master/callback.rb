module Delayed
  class Master
    class Callback
      def initialize(config = {})
        @config = config.select { |k, _| [:before_fork, :after_fork].include?(k) }
      end

      def run(name, *args)
        @config[name].call(*args) if @config[name]
      end
    end
  end
end
