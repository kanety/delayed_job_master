module DelayedJob
  class << self
    def [](spec_name)
      spec_name ||= :primary
      model = Class.new(Delayed::Job)
      model_name = spec_name.capitalize
      unless DelayedJob.const_defined?(model_name)
        DelayedJob.const_set(model_name, model)
        DelayedJob.const_get(model_name).establish_connection(spec_name)
      end
      DelayedJob.const_get(model_name)
    end
  end
end

class BaseTester
  def enqueue_timer_job(database = nil, **options)
    options[:priority] ||= 1
    model = DelayedJob[database]
    model.transaction do
      count = options.delete(:count) || 1
      count.times do
        TimerJob.set(options).perform_later(2)
      end
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

  def wait_job_performing_for(database, limit)
    wait_while(limit) do
      puts "wait job performing..."
      model = DelayedJob[database]
      model.where(locked_at: nil).count > 0
    end
  end

  def wait_job_performed_for(database, limit)
    wait_while(limit) do
      puts "wait job performed..."
      model = DelayedJob[database]
      model.where.not(locked_at: nil).count > 0
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

  def wait_worker_terminated
    wait_while(6) do
      puts "wait worker terminated..."
      @master.workers.count != 0
    end
  end
end

class WorkerTester < BaseTester
  def initialize
    require 'delayed/master/worker/extension'
    @worker = Delayed::Worker.new(sleep_delay: 1, exit_on_complete: false, queues: ['worker_test'])
    @worker.master_logger = Logger.new(Rails.root.join("log/delayed_job_master.log"))
  end

  def start(options = {})
    options.each do |key , val|
      @worker.send("#{key}=", val)
    end

    thread = Thread.new do
      @worker.start
    end

    yield @worker

    @worker.stop
    thread.join
  end

  def wait_worker_stopped
    wait_while(6) do
      puts "wait worker stopped..."
      !@worker.stop?
    end
  end
end
