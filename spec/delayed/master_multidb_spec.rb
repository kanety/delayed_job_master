return if ENV['DATABASE_CONFIG'] != 'multi'

describe Delayed::Master do
  let(:tester) do
    MasterTester.new(Rails.root.join("config/delayed_job_master.rb").to_s)
  end

  before do
    [:primary, :secondary].each do |shard|
      DelayedJob.connect(shard) do |model|
        model.delete_all
      end
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
        tester.wait_worker_terminated
      end

      [:primary, :secondary].each do |shard|
        DelayedJob.connect(shard) do |model|
          expect(model.count).to eq(0)
        end
      end
    end
  end
end
