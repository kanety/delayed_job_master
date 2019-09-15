class DelayedJobSecondary < Delayed::Job
  establish_connection :secondary
end
