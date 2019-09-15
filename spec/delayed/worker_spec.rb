describe Delayed::Worker do
  let(:tester) do
    WorkerTester.new
  end

  before do
    [DelayedJobPrimary, DelayedJobSecondary].each do |model|
      model.delete_all
    end
  end

  it 'traps USR1 signals' do
    tester.start do |worker|
      tester.enqueue_timer_job(:primary)
      tester.wait_job_performing

      tester.kill(:USR1)
      tester.wait_job_performed
      expect(DelayedJobPrimary.count).to eq(0)
    end
  end

  it 'traps USR2 signals' do
    tester.start do |worker|
      tester.enqueue_timer_job(:primary)
      tester.wait_job_performing

      tester.kill(:USR2)
      tester.wait_job_performed
      expect(worker.stop?).to eq(true)
    end
  end

  it 'checks memory usage' do
    tester.start do |worker|
      worker.max_memory = 1
      2.times { tester.enqueue_timer_job(:primary) }
      tester.wait_worker_stopped
      expect(DelayedJobPrimary.count).to eq(1)
    end
  end
end
