# frozen_string_literal: true

module Delayed
  module Master
    class Database
      class_attribute :model_cache
      self.model_cache = {}

      attr_accessor :shard

      def initialize(shard)
        @shard = shard
      end

      def connect
        ActiveRecord::Base.connected_to(shard: shard) do
          yield Delayed::Job
        end
      end

      def with_connection
        connect do |model|
          model.connection_pool.with_connection do |connection|
            yield connection
          end
        end
      end

      def checkout_connection
        connect do |model|
          connection = model.connection_pool.checkout
          begin
            yield connection
          ensure
            model.connection_pool.checkin(connection)
          end
        end
      end

      def spec_name
        pool = ActiveRecord::Base.connection_handler.connection_pools(:writing).detect { |pool| pool.shard == shard }
        pool.db_config.name.to_sym
      end

      private

      class << self
        def all(shards = nil)
          shards = shards.presence || shards_with_delayed_job_table
          shards.map { |shard| new(shard) }
        end

        private

        def shards_with_delayed_job_table
          @shards_with_delayed_job_table ||= writing_shards.select do |shard|
            exist_delayed_job_table?(shard)
          end
        end

        def writing_shards
          ActiveRecord::Base.connection_handler.connection_pools(:writing).map(&:shard)
        end

        def exist_delayed_job_table?(shard)
          new(shard).with_connection do |connection|
            connection.tables.include?('delayed_jobs')
          end
        end
      end
    end
  end
end
