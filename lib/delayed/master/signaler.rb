module Delayed
  class Master
    class Signaler
      def initialize(master)
        @master = master
      end

      def register
        signals = [[:TERM, :stop], [:INT, :stop], [:QUIT, :quit], [:USR1, :reopen_files], [:USR2, :restart]]
        signals.each do |signal, method|
          register_signal(signal, method)
        end
      end

      def dispatch(signal)
        @master.workers.each do |worker|
          next unless worker.pid
          dispatch_to(signal, worker.pid)
        end
      end

      private

      def register_signal(signal, method)
        trap(signal) do
          Thread.new do
            @master.logger.info "received #{signal} signal"
            @master.public_send(method)
          end
        end
      end

      def dispatch_to(signal, pid)
        Process.kill(signal, pid)
        @master.logger.info "sent #{signal} signal to worker #{pid}"
      rescue
        @master.logger.error "failed to send #{signal} signal to worker #{pid}"
      end
    end
  end
end
