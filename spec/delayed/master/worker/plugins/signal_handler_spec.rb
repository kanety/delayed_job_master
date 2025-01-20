describe 'Delayed::Master::Worker::Plugins::SignalHandler' do
  let(:tester) do
    WorkerTester.new
  end

  before do
    Delayed::Job.delete_all
  end

  it 'traps USR1' do
    tester.start do |worker|
      tester.enqueue_timer_job(queue: 'worker_test')
      tester.wait_job_performing

      tester.kill(:USR1)
      tester.wait_job_performed
      expect(Delayed::Job.count).to eq(0)
    end
  end

  it 'traps USR2' do
    tester.start do |worker|
      tester.enqueue_timer_job(queue: 'worker_test')
      tester.wait_job_performing

      tester.kill(:USR2)
      tester.wait_job_performed
      expect(worker.stop?).to eq(true)
    end
  end
end
