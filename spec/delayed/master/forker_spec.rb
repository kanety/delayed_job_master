describe Delayed::Master::Forker do
  let(:master) do
    Delayed::Master.new(['-c', Rails.root.join("config/delayed_job_master.rb").to_s])
  end

  let(:forker) do
    Delayed::Master::Forker.new(master)
  end

  let(:worker) do
    Delayed::Master::Worker.new(database: master.databases.first, setting: master.config.worker_settings.first)
  end

  it 'forks a worker' do
    proc_title = $0

    allow_any_instance_of(Delayed::Master::Forker).to receive(:fork).once { |&block| block.call; 1 }
    allow_any_instance_of(Delayed::Worker).to receive(:start).once

    forker.call(worker)
    expect(worker.pid).to eq(1)

    $0 = proc_title
  end
end
