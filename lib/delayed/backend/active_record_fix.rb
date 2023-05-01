module Delayed
  module Backend
    module ActiveRecord
      class Job < ::ActiveRecord::Base
        # Ignore matching worker_name to locked_by.
        def self.ready_to_run(worker_name, max_run_time)
          where(
            "(run_at <= ? AND (locked_at IS NULL OR locked_at < ?)) AND failed_at IS NULL",
            db_time_now,
            db_time_now - max_run_time
          )
        end
      end
    end
  end
end
