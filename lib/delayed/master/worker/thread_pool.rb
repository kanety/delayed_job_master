# frozen_string_literal: true

module Delayed
  module Master
    class Worker
      class ThreadPool
        def initialize(worker, size)
          @worker = worker
          @size = size
          @queue = SizedQueue.new(@size)
          @queue_delay = 0.5
        end

        def schedule
          @scheduler = Thread.new do
            Delayed::Worker.lifecycle.run_callbacks(:thread, @worker) do
              loop do
                while @queue.num_waiting == 0
                  sleep @queue_delay
                end

                if item = yield
                  @queue.push(item)
                  Thread.pass
                else
                  @size.times { @queue.push(:exit) }
                  break
                end
              end
            end
          end
        end

        def work
          @threads = @size.times.map do
            Thread.new do
              Delayed::Worker.lifecycle.run_callbacks(:thread, @worker) do
                loop do
                  item = @queue.pop
                  if item == :exit
                    break
                  else
                    yield item
                  end
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
