describe Delayed::Master::Command do
  let(:config_file) { Rails.root.join("config/delayed_job_master.rb") }

  it 'parses help option' do
    expect_any_instance_of(Delayed::Master::Command).to receive(:exit)
    configs = Delayed::Master::Command.new(%w(-h)).configs
  end

  it 'parses daemon option' do
    configs = Delayed::Master::Command.new(%w(--daemon)).configs
    expect(configs[:daemon]).to eq(true)
    configs = Delayed::Master::Command.new(%w(-D)).configs
    expect(configs[:daemon]).to eq(true)
  end

  it 'parses config option' do
    configs = Delayed::Master::Command.new(%W(--config #{config_file})).configs
    expect(configs[:worker_configs].size).to eq(2)
    configs = Delayed::Master::Command.new(%W(-c #{config_file})).configs
    expect(configs[:worker_configs].size).to eq(2)
  end
end
