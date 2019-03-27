describe Delayed::Master::Worker do
  subject(:worker) do
    setting = Delayed::Master::Config::WorkerSetting.new(queues: ["queue1"])
    Delayed::Master::Worker.new(1, setting)
  end

  it 'has a title' do
    expect(worker.title).to eq("delayed_job.1 (queue1)")
  end    
end
