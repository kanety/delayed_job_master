module Delayed
  class Master
    class ThreadPool
      def initialize(size)
        @size = size
        @threads = []
      end

      def start(&block)
        @threads = @size.times.map { create_thread(&block) }
      end

      def wait
        @threads.each { |t| t.join }
      end

      def shutdown
        @threads.each { |t| t.kill }
        @threads = []
      end

      private

      def create_thread(&block)
        Thread.start do
          loop do
            break if block.call == :exit
          end
        end
      end
    end
  end
end
