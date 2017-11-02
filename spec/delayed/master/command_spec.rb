describe Delayed::Master::Command do
  let(:config_file) { Rails.root.join("config/delayed_job_master.rb") }

  it 'parses help option' do
    expect_any_instance_of(Delayed::Master::Command).to receive(:exit)
    config = Delayed::Master::Command.new(%w(-h)).config
  end

  it 'parses daemon option' do
    config = Delayed::Master::Command.new(%w(--daemon)).config
    expect(config[:daemon]).to eq(true)
    config = Delayed::Master::Command.new(%w(-D)).config
    expect(config[:daemon]).to eq(true)
  end

  it 'parses config option' do
    config = Delayed::Master::Command.new(%W(--config #{config_file})).config
    expect(config[:worker_configs].size).to eq(3)
    config = Delayed::Master::Command.new(%W(-c #{config_file})).config
    expect(config[:worker_configs].size).to eq(3)
  end
end
