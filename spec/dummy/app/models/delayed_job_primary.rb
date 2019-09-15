class DelayedJobPrimary < Delayed::Job
  establish_connection :primary
end
