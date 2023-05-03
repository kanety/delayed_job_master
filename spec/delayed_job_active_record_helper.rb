module Delayed	
  module Backend	
    module ActiveRecord	
      class Job < ::ActiveRecord::Base	
        def self.before_fork	
          ::ActiveRecord::Base.clear_all_connections!	
        end	

        def self.after_fork	
          ::ActiveRecord::Base.establish_connection
        end	
      end	
    end	
  end	
end	
