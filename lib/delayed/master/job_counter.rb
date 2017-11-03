case Delayed::Worker.backend.to_s
when 'Delayed::Backend::ActiveRecord::Job'
  require_relative 'job_counter/active_record'
when 'Delayed::Backend::Mongoid::Job'
  require_relative 'job_counter/mongoid'
else
  raise "Unsupported backend: #{Delayed::Worker.backend}"
end
