class SecondaryDelayedJob < Delayed::Job
  establish_connection :secondary
end
