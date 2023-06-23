describe Delayed::Master do
  let(:tester) do
    MasterTester.new(Rails.root.join("config/delayed_job_master.rb").to_s)
  end

  before do
    Delayed::Job.delete_all
  end

  context 'signal' do
    it 'traps TERM' do
      tester.start do |master|
        tester.enqueue_timer_job(queue: 'queue1')
        tester.wait_job_performing
        expect(master.workers.size).to eq(1)

        tester.kill(:TERM)
        tester.wait_job_performed
        tester.wait_worker_terminated
        expect(master.stop?).to eq(true)
      end
    end

    it 'traps INT' do
      tester.start do |master|
        tester.enqueue_timer_job(queue: 'queue1')
        tester.wait_job_performing
        expect(master.workers.size).to eq(1)

        tester.kill(:INT)
        tester.wait_job_performed
        tester.wait_worker_terminated
        expect(master.stop?).to eq(true)
      end
    end

    it 'traps WINCH' do
      tester.start do |master|
        tester.enqueue_timer_job(queue: 'queue1')
        tester.wait_job_performing
        expect(master.workers.size).to eq(1)

        tester.kill(:WINCH)
        tester.wait_job_performed
        tester.wait_worker_terminated
        expect(master.stop?).to eq(true)
      end
    end

    it 'traps QUIT' do
      tester.start do |master|
        tester.enqueue_timer_job(queue: 'queue1')
        tester.wait_job_performing
        expect(master.workers.size).to eq(1)

        tester.kill(:QUIT)
        tester.wait_worker_terminated
        expect(master.stop?).to eq(true)
        expect(Delayed::Job.count).to eq(1)
      end
    end

    it 'traps USR1' do
      tester.start do |master|
        tester.enqueue_timer_job(queue: 'queue1')
        tester.wait_job_performing
        expect(master.workers.size).to eq(1)

        tester.kill(:USR1)
        tester.wait_job_performed
        tester.wait_worker_terminated
        expect(master.stop?).to eq(false)
      end
    end

    it 'traps USR2' do
      tester.start do |master|
        tester.enqueue_timer_job(queue: 'queue1')
        tester.wait_job_performing
        expect(master.workers.size).to eq(1)

        allow(master).to receive(:exec).and_return(nil)
        tester.kill(:USR2)
        tester.wait_job_performed
        tester.wait_worker_terminated
        expect(master).to have_received(:exec).once
      end
    end
  end

  context 'workers' do
    it 'runs immediate jobs' do
      tester.start do |master|
        tester.enqueue_timer_job(queue: 'queue1')
        tester.wait_job_performing
        expect(master.workers.size).to eq(1)
        tester.wait_job_performed
        tester.wait_worker_terminated
      end

      expect(Delayed::Job.count).to eq(0)
    end

    it 'runs future jobs' do
      tester.start do |master|
        tester.enqueue_timer_job(queue: 'queue1', wait_until: 1.5.seconds.after)
        tester.wait_job_performing
        expect(master.workers.size).to eq(1)
        tester.wait_job_performed
        tester.wait_worker_terminated
      end

      expect(Delayed::Job.count).to eq(0)
    end

    it 'runs multiple workers with different queues' do
      tester.start do |master|
        tester.enqueue_timer_job(queue: 'queue1')
        tester.enqueue_timer_job(queue: 'queue2', count: 5)
        tester.wait_job_performing
        expect(master.workers.size).to eq(2)
        tester.wait_job_performed
        tester.wait_worker_terminated
      end

      expect(Delayed::Job.count).to eq(0)
    end

    it 'runs multiple workers with same queues' do
      tester.start do |master|
        tester.enqueue_timer_job(queue: 'queue3', count: 3)
        tester.wait_job_performing
        expect(master.workers.size).to eq(3)
        tester.wait_job_performed
        tester.wait_worker_terminated
      end

      expect(Delayed::Job.count).to eq(0)
    end
  end
end
