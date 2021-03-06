describe Delayed::Master do
  let(:tester) do
    MasterTester.new(Rails.root.join("config/delayed_job_master.rb").to_s)
  end

  before do
    [DelayedJobPrimary, DelayedJobSecondary].each do |model|
      model.delete_all
    end
  end

  context 'signal' do
    it 'traps TERM' do
      tester.start do |master|
        tester.enqueue_timer_job(:primary, queue: 'queue1')
        tester.wait_job_performing
        expect(master.workers.size).to eq(1)

        tester.kill(:TERM)
        tester.wait_job_performed
        expect(master.stop?).to eq(true)
      end
    end

    it 'traps INT' do
      tester.start do |master|
        tester.enqueue_timer_job(:primary, queue: 'queue1')
        tester.wait_job_performing
        expect(master.workers.size).to eq(1)

        tester.kill(:INT)
        tester.wait_job_performed
        expect(master.stop?).to eq(true)
      end
    end

    it 'traps QUIT' do
      tester.start do |master|
        tester.enqueue_timer_job(:primary, queue: 'queue1')
        tester.wait_job_performing
        expect(master.workers.size).to eq(1)

        tester.kill(:QUIT)
        tester.wait_job_performed
        expect(master.stop?).to eq(true)
      end
    end

    it 'traps USR1' do
      tester.start do |master|
        tester.enqueue_timer_job(:primary, queue: 'queue1')
        tester.wait_job_performing
        expect(master.workers.size).to eq(1)

        tester.kill(:USR1)
        tester.wait_job_performed
        expect(master.stop?).to eq(false)
      end
    end

    it 'traps USR2' do
      tester.start do |master|
        tester.enqueue_timer_job(:primary, queue: 'queue1')
        tester.wait_job_performing
        expect(master.workers.size).to eq(1)

        allow(master).to receive(:exec).and_return(nil)
        tester.kill(:USR2)
        tester.wait_job_performed
        expect(master).to have_received(:exec).once
      end
    end
  end

  context 'workers' do
    it 'runs a worker' do
      proc_title = $0

      allow_any_instance_of(Delayed::Master::Forker).to receive(:fork).twice { |&block| block.call }
      allow_any_instance_of(Delayed::Worker).to receive(:start).twice

      tester.start do |master|
        tester.enqueue_timer_job(:primary, queue: 'queue1')
        tester.wait_job_performing
        expect(master.workers.size).to eq(1)
      end

      $0 = proc_title
    end

    it 'runs multiple workers' do
      tester.start do |master|
        tester.enqueue_timer_job(:primary, queue: 'queue1')
        tester.enqueue_timer_job(:primary, queue: 'queue2')
        tester.wait_job_performing
        expect(master.workers.size).to eq(2)
        tester.wait_job_performed
      end

      expect(DelayedJobPrimary.count).to eq(0)
    end
  end

  context 'miltiple database' do
    it 'runs workers for each database' do
      tester.start do |master|
        tester.enqueue_timer_job(:primary, queue: 'queue1')
        tester.enqueue_timer_job(:secondary, queue: 'queue2')
        tester.wait_job_performing(:primary)
        tester.wait_job_performing(:secondary)
        expect(master.workers.size).to eq(2)
        tester.wait_job_performed(:primary)
        tester.wait_job_performed(:secondary)
      end

      expect(DelayedJobPrimary.count).to eq(0)
      expect(DelayedJobSecondary.count).to eq(0)
    end
  end
end
