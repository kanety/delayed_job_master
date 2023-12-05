describe Delayed::Master::Command do
  let(:config_file) do
    Rails.root.join("config/delayed_job_master.rb")
  end

  it 'parses help option' do
    expect_any_instance_of(Delayed::Master::Command).to receive(:exit)
    Delayed::Master::Command.new(%w(-h)).config
  end

  context 'config' do
    it 'parses long option' do
      config = Delayed::Master::Command.new(%W(--config #{config_file})).config
      expect(config.workers.size).to eq(4)
    end

    it 'parses short option' do
      config = Delayed::Master::Command.new(%W(-c #{config_file})).config
      expect(config.workers.size).to eq(4)
    end
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

  context 'working_directory' do
    it 'parses long option' do
      config = Delayed::Master::Command.new(%w(--working-directory=dir)).config
      expect(config.working_directory).to eq('dir')
    end
  end

  context 'pid_file' do
    it 'parses long option' do
      config = Delayed::Master::Command.new(%w(--pid-file=file)).config
      expect(config.pid_file).to eq('file')
    end
  end

  context 'log_file' do
    it 'parses long option' do
      config = Delayed::Master::Command.new(%w(--log-file=file)).config
      expect(config.log_file).to eq('file')
    end
  end

  context 'log_level' do
    it 'parses long option' do
      config = Delayed::Master::Command.new(%w(--log-level=level)).config
      expect(config.log_level).to eq(:level)
    end
  end

  context 'monitor_interval' do
    it 'parses long option' do
      config = Delayed::Master::Command.new(%w(--monitor-interval=10)).config
      expect(config.monitor_interval).to eq(10)
    end
  end

  context 'polling_interval' do
    it 'parses long option' do
      config = Delayed::Master::Command.new(%w(--polling-interval=10)).config
      expect(config.polling_interval).to eq(10)
    end
  end

  context 'shards' do
    it 'parses long option' do
      config = Delayed::Master::Command.new(%w(--shards=shard1,shard2)).config
      expect(config.shards).to eq([:shard1, :shard2])
    end
  end
end
