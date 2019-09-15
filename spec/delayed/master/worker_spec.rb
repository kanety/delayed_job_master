describe Delayed::Master::Worker do
  let(:worker) do
    setting = Delayed::Master::Config::WorkerSetting.new(id: 0, queues: ["queue1"])
    Delayed::Master::Worker.new(1, setting)
  end

  it 'has a title' do
    expect(worker.title).to eq("delayed_job.1: worker[0] (queue1)")
  end    
end
