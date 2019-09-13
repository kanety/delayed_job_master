class TimerJob
  class << self
    def run(time = 10)
      sleep time
    end
  end
end

class Monitor
  class << self
    def wait_job_performing(limit)
      wait_while(limit) do
        Delayed::Job.where(locked_at: nil).count > 0
      end
    end
  
    def wait_job_performed(limit)
      wait_while(limit) do
        Delayed::Job.where.not(locked_at: nil).count > 0
      end
    end

    def wait_while(limit)
      wait = 0
      while yield && (wait += 0.5) < limit
        Thread.pass
        sleep 0.5
      end
    end
  end
end

class MasterTester
  def initialize(config_file)
    @master = Delayed::Master.new(['-c', config_file])
  end

  def start
    thread = Thread.new { @master.run }
  
    sleep 0.5 until @master.prepared?

    yield @master

    @master.stop
    thread.join
  end

  def enqueue_timer_job(options = {})
    TimerJob.delay(options).run(3)
  end

  def wait_job_performing
    Monitor.wait_job_performing(6)
  end

  def wait_job_performed
    Monitor.wait_job_performed(6)
  end

  def kill(signal)
    Process.kill(signal, Process.pid)
  end
end

class WorkerTester
  def initialize
    require 'delayed/worker_extension'
    @worker = Delayed::Worker.new(queues: [], sleep_delay: 1, exit_on_complete: false)
    @worker.master_logger = Logger.new(Rails.root.join("log/delayed_job_master.log"))
  end

  def start
    thread = Thread.new { @worker.start }
    sleep 1

    yield @worker

    @worker.stop
    thread.join
  end

  def enqueue_timer_job(options = {})
    TimerJob.delay(options).run(3)
  end

  def wait_job_performing
    Monitor.wait_job_performing(6)
  end

  def wait_job_performed
    Monitor.wait_job_performed(6)
  end

  def wait_worker_stopped
    Monitor.wait_while(6) do
      !@worker.stop?
    end
  end

  def kill(signal)
    Process.kill(signal, Process.pid)
  end
end
