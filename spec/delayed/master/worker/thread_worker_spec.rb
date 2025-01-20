describe 'Delayed::Master::Worker::ThreadWorker' do
  let(:tester) do
    WorkerTester.new
  end

  before do
    Delayed::Job.delete_all
  end

  context 'multithread' do
    it 'works multithread' do
      tester.start(max_threads: 2) do |worker|
        tester.enqueue_timer_job(queue: 'worker_test', count: 2)
        tester.wait_job_performing
        tester.wait_job_performed
        expect(Delayed::Job.count).to eq(0)
      end
    end
  end

  context 'max_run_time' do
    around(:example) do |example|
      max_run_time = Delayed::Worker.max_run_time
      Delayed::Worker.max_run_time = 1.seconds
      example.run
    ensure
      Delayed::Worker.max_run_time = max_run_time
    end

    it 'stops a worker on timeout error' do
      tester.start(exit_on_timeout: true) do |worker|
        tester.enqueue_timer_job(queue: 'worker_test', count: 5)
        tester.wait_job_performing
        tester.wait_worker_stopped
        expect(Delayed::Job.where.not(last_error: nil).count).to eq(1)
      end
    end
  end
end
