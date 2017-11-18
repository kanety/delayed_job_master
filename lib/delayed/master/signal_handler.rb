module Delayed
  class Master
    class SignalHandler
      def initialize(master)
        @master = master
        @logger = master.logger
        @worker_infos = master.worker_infos
      end

      def register
        %w(TERM INT QUIT USR1 USR2).each do |signal|
          trap(signal) do
            Thread.new do
              @logger.info "received #{signal} signal"
              case signal
              when 'TERM', 'INT'
                @master.stop
              when 'QUIT'
                @master.quit
              when 'USR1'
                @master.reopen_files
              when 'USR2'
                @master.restart
              end
            end
          end
        end
      end

      def dispatch(signal)
        @worker_infos.each do |worker_info|
          next unless worker_info.pid
          dispatch_to(signal, worker_info.pid)
        end
      end

      private

      def dispatch_to(signal, pid)
        Process.kill signal, pid
        @logger.info "sent #{signal} signal to worker #{pid}"
      rescue
        @logger.error "failed to send #{signal} signal to worker #{pid}"
      end
    end
  end
end
