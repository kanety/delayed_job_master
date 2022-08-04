describe Delayed::Master::DatabaseDetector do
  let(:detector) do
    Delayed::Master::DatabaseDetector.new
  end

  it 'detects databases with delayed_jobs' do
    spec_names = detector.call
    if Rails::VERSION::MAJOR >= 6
      expect(spec_names).to eq([:primary, :secondary])
    else
      expect(spec_names).to eq([Rails.env.to_sym])
    end
  end
end
