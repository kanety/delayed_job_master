describe 'Delayed::Master::Worker::ThreadWorker' do
  let(:tester) do
    WorkerTester.new
  end

  before do
    Delayed::Job.delete_all
  end

  it 'works multithread' do
    tester.start(max_threads: 2) do |worker|
      tester.enqueue_timer_job(queue: 'worker_test', count: 2)
      tester.wait_job_performing
      tester.wait_job_performed
      expect(Delayed::Job.count).to eq(0)
    end
  end
end
