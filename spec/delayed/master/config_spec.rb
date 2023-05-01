describe Delayed::Master::Config do
  let(:config) do
    Delayed::Master::Config.new
  end

  context 'master setting' do
    it 'sets a integer value' do
      config.monitor_wait 10
      expect(config.monitor_wait).to eq(10)
    end

    it 'sets a boolean value' do
      config.daemon false
      expect(config.daemon).to eq(false)
    end
  end

  context 'worker setting' do
    it 'add a worker' do
      config.add_worker do |worker|
      end
      expect(config.worker_settings.size).to eq(1)
      expect(config.worker_settings[0].queues).to eq([])
      expect(config.worker_settings[0].max_processes).to eq(1)
      expect(config.worker_settings[0].max_threads).to eq(1)
    end

    it 'sets an array value' do
      config.add_worker do |worker|
        worker.queues %w(queue)
      end
      expect(config.worker_settings[0].queues).to eq(%w(queue))
    end

    it 'sets a boolean value' do
      config.add_worker do |worker|
        worker.exit_on_complete false
      end
      expect(config.worker_settings[0].exit_on_complete).to eq(false)
    end
  end
end
