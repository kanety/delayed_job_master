describe Delayed::Master::JobFinder do
  let(:job_finder) do
    Delayed::Master::JobFinder.new(Delayed::Job)
  end

  let(:setting) do
    Delayed::Master::WorkerSetting.new(queues: %w(queue1))
  end

  before do
    1000.times { TimerJob.set(queue: 'queue1').perform_later }
  end

  after do
    Delayed::Job.delete_all
  end

  it 'benchmarks' do
    Benchmark.bmbm do |r|
      r.report 'count' do
        100.times { job_finder.call(setting).count }
      end
      r.report 'limit' do
        100.times { job_finder.call(setting).limit(1).pluck(:id) }
      end
    end
  end
end
