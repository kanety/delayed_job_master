module Delayed
  module Backend
    module ActiveRecord
      class Job < ::ActiveRecord::Base
        def self.before_fork
          ::ActiveRecord::Base.clear_active_connections!
        end

        def self.after_fork
          ::ActiveRecord::Base.connection.verify!
        end
      end
    end
  end
end
