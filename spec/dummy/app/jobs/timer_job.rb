class TimerJob < ActiveJob::Base
  def perform(time = 10)
    time.times do
      Thread.pass
      sleep 1
      Thread.pass
    end
  end
end
