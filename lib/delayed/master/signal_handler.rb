module Delayed
  class Master
    class SignalHandler
      def initialize(master)
        @master = master
      end

      def register
        %w(TERM INT QUIT USR1 USR2).each do |signal|
          trap(signal) do
            Thread.new do
              @master.logger.info "received #{signal} signal"
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
        @master.worker_infos.each do |worker_info|
          next unless worker_info.pid
          begin
            Process.kill signal, worker_info.pid
            @master.logger.info "sent #{signal} signal to worker #{worker_info.pid}"
          rescue
            @master.logger.error "failed to send #{signal} signal to worker #{worker_info.pid}"
          end
        end
      end
    end
  end
end
