describe Delayed::Master::Worker do
  let(:worker) do
    setting = Delayed::Master::WorkerSetting.new(id: 0, queues: ["queue1"])
    Delayed::Master::Worker.new(setting: setting)
  end

  it 'has a process title' do
    expect(worker.process_title).to eq("delayed_job: worker[0] (queue1)")
  end    
end
