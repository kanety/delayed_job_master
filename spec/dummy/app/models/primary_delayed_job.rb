class PrimaryDelayedJob < Delayed::Job
  establish_connection :primary
end
