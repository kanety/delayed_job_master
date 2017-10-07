describe Delayed::Worker do
  subject(:worker) {
    worker = Delayed::Worker.new(queues: [])
    worker.max_memory = 1
    worker.master_logger = Logger.new(Rails.root.join("log/delayed_job_master.log"))
    worker
  }
  before {
    Delayed::Job.delete_all
  }

  def enqueue_job
    [nil].delay.pop
  end

  def start_worker_thread(worker)
    thread = Thread.new { worker.start }
    sleep 1
    thread
  end

  it 'checks memory usage' do
    enqueue_job
    worker.work_off
    expect(Delayed::Job.count).to eq(0)
  end

  it 'traps signals' do
    thread = start_worker_thread(worker)

    %w(USR1 USR2).each do |signal|
      Process.kill(signal, Process.pid)
    end

    worker.stop
    thread.join
  end
end
