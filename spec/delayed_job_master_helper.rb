class BaseTester
  def enqueue_timer_job(database = nil, **options)
    options[:priority] ||= 1
    job = TimerJob.new(2)
    delayed_job_klass(database) do |klass|
      klass.enqueue(ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.new(job.serialize), options)
    end
  end

  def wait_job_performing(database = nil)
    wait_job_performing_for(database, 10)
  end

  def wait_job_performed(database = nil)
    wait_job_performed_for(database, 10)
  end

  def kill(signal)
    Process.kill(signal, Process.pid)
  end

  private

  def delayed_job_klass(database = nil)
    if database
      yield "DelayedJob#{database.capitalize}".constantize
    else
      yield Delayed::Job
    end
  end

  def wait_job_performing_for(database, limit)
    wait_while(limit) do
      puts "wait job performing..."
      delayed_job_klass(database) do |klass|
        klass.where(locked_at: nil).count > 0
      end
    end
  end

  def wait_job_performed_for(database, limit)
    wait_while(limit) do
      puts "wait job performed..."
      delayed_job_klass(database) do |klass|
        klass.where.not(locked_at: nil).count > 0
      end
    end
  end

  def wait_while(limit)
    wait = 0
    while yield && (wait += 1) < limit
      Thread.pass
      sleep 1
      Thread.pass
    end
  end
end

class MasterTester < BaseTester
  def initialize(config_file)
    @master = Delayed::Master.new(['-c', config_file])
  end

  def start
    thread = Thread.new do
      @master.run
    end

    sleep 0.5 until @master.prepared?

    yield @master

    @master.stop
    thread.join
  end
end

class WorkerTester < BaseTester
  def initialize
    require 'delayed/master/worker_extension'
    @worker = Delayed::Worker.new(queues: [], sleep_delay: 1, exit_on_complete: false)
    @worker.master_logger = Logger.new(Rails.root.join("log/delayed_job_master.log"))
  end

  def start(options = {})
    options.each do |key , val|
      @worker.send("#{key}=", val)
    end

    thread = Thread.new do
      @worker.start
    end

    sleep 1

    yield @worker

    @worker.stop
    thread.join
  end

  def wait_worker_stopped
    wait_while(6) do
      !@worker.stop?
    end
  end
end
