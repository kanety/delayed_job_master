# Overrides Delayed::Worker to support multithread.
# See original code at https://github.com/collectiveidea/delayed_job/blob/master/lib/delayed/worker.rb
module Delayed
  class Master
    module ThreadWorker
      def name
        if multi_thread?
          @_prefix_name ||= "#{@name_prefix}host:#{Socket.gethostname} pid:#{Process.pid}" rescue "#{@name_prefix}pid:#{Process.pid}"
          "#{@_prefix_name} tid:#{Thread.current.object_id}"
        else
          super
        end
      end

      def work_off(num = 100)
        if multi_thread?
          work_off_multi_thread
        else
          super
        end
      end

      def multi_thread?
        @max_threads.to_i > 1
      end

      def work_off_multi_thread
        success = 0
        failure = 0

        monitor = Monitor.new
        thread_pool = ThreadPool.new(@max_threads)

        thread_pool.start do
          case reserve_and_run_one_job
          when true
            monitor.synchronize { success += 1 }
          when false
            monitor.synchronize { failure += 1 }
          else
            next :exit
          end
          next :exit if stop?
        end

        thread_pool.wait
        thread_pool.shutdown

        [success, failure]
      end
    end
  end
end

Delayed::Worker.prepend Delayed::Master::ThreadWorker
