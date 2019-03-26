describe Delayed::Master::WorkerInfo do
  subject(:worker_info) do
    Delayed::Master::WorkerInfo.new(1, queues: ["queue1"])
  end

  it 'has a title' do
    expect(worker_info.title).to eq("delayed_job.1 (queue1)")
  end    
end
