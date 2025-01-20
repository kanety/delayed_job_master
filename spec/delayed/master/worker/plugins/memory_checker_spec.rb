describe 'Delayed::Master::Worker::Plugins::MemoryChecker' do
  let(:tester) do
    WorkerTester.new
  end

  before do
    Delayed::Job.delete_all
  end

  it 'checks memory usage' do
    tester.start(max_memory: 1) do |worker|
      tester.enqueue_timer_job(queue: 'worker_test', count: 2)
      tester.wait_worker_stopped
      expect(Delayed::Job.count).to eq(1)
    end
  end
end
