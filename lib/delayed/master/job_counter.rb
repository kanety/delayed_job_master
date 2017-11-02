if defined?(Delayed::Backend::ActiveRecord)
  require_relative 'job_counter/active_record'
else
  raise 'Unsupported backend'
end
