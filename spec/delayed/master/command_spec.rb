describe Delayed::Master::Command do
  let(:config_file) do
    Rails.root.join("config/delayed_job_master.rb")
  end

  it 'parses help option' do
    expect_any_instance_of(Delayed::Master::Command).to receive(:exit)
    Delayed::Master::Command.new(%w(-h)).config
  end

  context 'daemon' do
    it 'parses long option' do
      config = Delayed::Master::Command.new(%w(--daemon)).config
      expect(config.daemon).to eq(true)
    end

    it 'parses short option' do
      config = Delayed::Master::Command.new(%w(-D)).config
      expect(config.daemon).to eq(true)
    end
  end

  context 'config' do
    it 'parses long option' do
      config = Delayed::Master::Command.new(%W(--config #{config_file})).config
      expect(config.workers.size).to eq(2)
    end

    it 'parses short option' do
      config = Delayed::Master::Command.new(%W(-c #{config_file})).config
      expect(config.workers.size).to eq(2)
    end
  end
end
