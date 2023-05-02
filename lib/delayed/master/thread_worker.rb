# frozen_string_literal: true

# Overrides Delayed::Worker to support multithread.
# See original code at https://github.com/collectiveidea/delayed_job/blob/master/lib/delayed/worker.rb
module Delayed
  class Master
    module ThreadWorker
      def work_off(num = 100)
        if multithread?
          work_off_for_multithread
        else
          super
        end
      end

      def multithread?
        @max_threads.to_i > 1
      end

      def work_off_for_multithread
        success = 0
        failure = 0

        monitor = Monitor.new
        thread_pool = ThreadPool.new(@max_threads)

        thread_pool.schedule do
          if stop?
            next nil
          else
            next reserve_job
          end
        end

        thread_pool.work do |job|
          case run_one_job(job)
          when true
            monitor.synchronize { success += 1 }
          when false
            monitor.synchronize { failure += 1 }
          end
        end

        thread_pool.wait
        thread_pool.shutdown

        [success, failure]
      end

      def run_one_job(job)
        self.class.lifecycle.run_callbacks(:perform, self, job) { run(job) }
      end
    end
  end
end

Delayed::Worker.prepend Delayed::Master::ThreadWorker
