# frozen_string_literal: true

module Delayed
  module Backend
    module ActiveRecord
      class Job < ::ActiveRecord::Base
        # Remove locked_by from query because all jobs reserved by current process have same locked_by.
        def self.ready_to_run(worker_name, max_run_time)
          where(
            "(run_at <= ? AND (locked_at IS NULL OR locked_at < ?)) AND failed_at IS NULL",
            db_time_now,
            db_time_now - max_run_time
          )
        end

        # Patch for postgresql query.
        def self.reserve_with_scope_using_optimized_postgres(ready_scope, worker, now)
          quoted_name = connection.quote_table_name(table_name)
          subquery    = ready_scope.limit(1).lock(true).select("id").to_sql
          sql         = <<~SQL.squish
            WITH job AS (#{subquery} SKIP LOCKED)
              UPDATE #{quoted_name} AS jobs SET locked_at = ?, locked_by = ? FROM job
              WHERE jobs.id = job.id RETURNING *
          SQL
          reserved    = find_by_sql([sql, now, worker.name])
          reserved[0]
        end

        # Patch for mysql query.
        def self.reserve_with_scope_using_optimized_mysql(ready_scope, worker, now)
          transaction do
            ready_scope.limit(worker.read_ahead).select(:id).lock.detect do |job|
              count = where(id: job.id).update_all(locked_at: now, locked_by: worker.name)
              count == 1 && job.reload
            end
          end
        end
      end
    end
  end
end
