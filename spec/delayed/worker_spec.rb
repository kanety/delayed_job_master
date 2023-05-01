describe Delayed::Worker do
  let(:tester) do
    WorkerTester.new
  end

  before do
    Delayed::Job.delete_all
  end

  it 'traps USR1' do
    tester.start do |worker|
      tester.enqueue_timer_job
      tester.wait_job_performing

      tester.kill(:USR1)
      tester.wait_job_performed
      expect(Delayed::Job.count).to eq(0)
    end
  end

  it 'traps USR2' do
    tester.start do |worker|
      tester.enqueue_timer_job
      tester.wait_job_performing

      tester.kill(:USR2)
      tester.wait_job_performed
      expect(worker.stop?).to eq(true)
    end
  end

  it 'checks memory usage' do
    tester.start(max_memory: 1) do |worker|
      2.times { tester.enqueue_timer_job }
      tester.wait_job_performing
      tester.wait_worker_stopped
      expect(Delayed::Job.count).to eq(1)
    end
  end

  it 'works multithread' do
    tester.start(max_threads: 2) do |worker|
      2.times { tester.enqueue_timer_job }
      tester.wait_job_performing
      tester.wait_job_performed
      expect(Delayed::Job.count).to eq(0)
    end
  end
end
