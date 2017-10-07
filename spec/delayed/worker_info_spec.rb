describe Delayed::WorkerInfo do
  subject(:worker_info) { Delayed::WorkerInfo.new(1, queues: ["queue1"]) }

  it 'has a title' do
    expect(worker_info.title).to eq("delayed_job.1 (queue1)")
  end    
end
