# frozen_string_literal: true

module Delayed
  class Master
    class Worker
      class ThreadPool
        def initialize(size)
          @size = size
          @queue = SizedQueue.new(@size)
          @queue_delay = 0.1
        end

        def schedule(&block)
          @scheduler = Thread.new do
            loop do
              while @queue.num_waiting == 0
                sleep @queue_delay
              end

              if item = block.call
                @queue.push(item)
                Thread.pass
              else
                @size.times { @queue.push(:exit) }
                break
              end
            end
          end
        end

        def work(&block)
          @threads = @size.times.map do
            Thread.new do
              loop do
                item = @queue.pop
                if item == :exit
                  break
                else
                  block.call(item)
                end
              end
            end
          end
        end

        def wait
          @scheduler.join
          @threads.each(&:join)
        end

        def shutdown
          @scheduler.kill
          @threads.each(&:kill)
          @queue.close
        end
      end
    end
  end
end
