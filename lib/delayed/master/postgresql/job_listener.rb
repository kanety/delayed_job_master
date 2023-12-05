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
                if @master.stop?
                  break
                else
                  listen(database)
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

        def listen(database)
          database.checkout_connection do |connection|
            listen_connection(database, connection) do
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

        def listen_connection(database, connection)
          @master.logger.info { "listening @#{database.shard}..." }
          identity = "#{connection.shard}.delayed_job_master"
          connection.execute("LISTEN #{quote(identity)}")
          yield
        rescue => e
          @master.logger.warn { "#{e.class}: #{e.message}" }
          @master.logger.debug { e.backtrace.join("\n") }
        ensure
          @master.logger.info { "unlisten @#{database.shard}" }
          connection.execute("UNLISTEN #{quote(identity)}")
        end

        def wait_for_notify(database, connection)
          connection.raw_connection.wait_for_notify(1) do |_event, _pid, _payload|
            @master.logger.info { "received notification @#{database.shard}" }
            @master.job_checker.schedule(database)
          end
        end

        def quote(identity)
          ActiveRecord::Base.connection.quote_column_name(identity)
        end
      end
    end
  end
end
