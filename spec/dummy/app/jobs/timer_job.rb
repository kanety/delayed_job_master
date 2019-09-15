class TimerJob < ActiveJob::Base
  def perform(time = 10)
    sleep time
  end
end
