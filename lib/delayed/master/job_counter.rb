case Delayed::Worker.backend.to_s
when 'Delayed::Backend::ActiveRecord::Job'
  require_relative 'job_counter/active_record'
else
  raise "Unsupported backend: #{Delayed::Worker.backend}"
end
