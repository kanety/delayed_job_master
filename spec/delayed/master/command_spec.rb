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
      expect(config.workers.size).to eq(3)
    end

    it 'parses short option' do
      config = Delayed::Master::Command.new(%W(-c #{config_file})).config
      expect(config.workers.size).to eq(3)
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

  context 'databases' do
    it 'parses long option' do
      config = Delayed::Master::Command.new(%w(--databases=db1,db2)).config
      expect(config.databases).to eq([:db1, :db2])
    end
  end
end
