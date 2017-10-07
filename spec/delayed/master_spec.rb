describe Delayed::Master do
  subject(:master) {
    Delayed::Master.new(['-c', Rails.root.join("config/delayed_job_master.rb").to_s])
  }

  def start_master_thread(master, wait_worker = true)
    thread = Thread.new do
      master.run
      master.kill_workers
      master.wait_workers
    end

    sleep(1) until master.prepared? if wait_worker

    thread
  end

  it 'has a version number' do
    expect(Delayed::Master::VERSION).not_to be nil
  end

  it 'runs a master' do
    thread = start_master_thread(master)

    master.stop
    thread.join

    worker_count = master.worker_infos.count { |wi| wi.pid }
    expect(worker_count).to eq(2)
  end

  it 'restarts a killed worker' do
    thread = start_master_thread(master)

    pids = master.worker_infos.map(&:pid)
    pids.each { |pid| Process.kill('KILL', pid) }
    sleep 3

    master.stop
    thread.join

    new_pids = master.worker_infos.map(&:pid)
    expect(pids).not_to eq(new_pids)
  end

  it 'forks workers' do
    proc_title = $0
    allow_any_instance_of(Delayed::Master::WorkerFactory).to receive(:fork).twice { |&block| block.call }
    allow_any_instance_of(Delayed::Worker).to receive(:start).twice

    thread = start_master_thread(master, false)

    master.stop
    thread.join
    
    $0 = proc_title
  end

  %w(USR1 USR2 TERM QUIT).each do |signal|
    it "traps #{signal} signals" do
      thread = start_master_thread(master)

      expect(master).to receive(:exec) if signal == 'USR2'

      Process.kill(signal, Process.pid)

      master.stop
      thread.join
    end
  end
end
