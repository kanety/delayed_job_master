# frozen_string_literal: true

module Delayed
  module Master
    module Postgresql
      class JobListener < Delayed::Master::JobListener
        def initialize(master)
          @master = master
          @config = master.config
          @databases = master.databases
          @threads = []
        end

        def start
          @threads = @databases.map do |database|
            Thread.new(database) do |database|
              loop do
                break if @master.stop?
                database.with_connection do |connection|
                  listen(database, connection) do
                    loop do
                      if @master.stop?
                        break
                      else
                        wait_for_notify(database, connection)
                      end
                    end
                  end
                end
              end
            end
          end
        end

        def wait
          @threads.each(&:join)
        end

        def shutdown
          @threads.each(&:kill)
        end

        private

        def listen(database, connection)
          @master.logger.info { "listening @#{database.spec_name}..." }
          connection.execute("LISTEN delayed_job_master")
          yield
        rescue => e
          @master.logger.warn { "#{e.class}: #{e.message}" }
          @master.logger.debug { e.backtrace.join("\n") }
        ensure
          @master.logger.info { "unlisten @#{database.spec_name}" }
          connection.execute("UNLISTEN delayed_job_master")
        end

        def wait_for_notify(database, connection)
          connection.raw_connection.wait_for_notify(@config.monitor_interval) do |_event, _pid, _payload|
            @master.logger.info { "received notification @#{database.spec_name}" }
            @master.job_checker.schedule(database)
          end
        end
      end
    end
  end
end
