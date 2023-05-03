describe Delayed::Master::Database do
  it 'gets model with specific database connection' do
    model = Delayed::Master::Database.model_for(:primary)
    expect(model.name).to eq('Delayed::Master::DelayedJobPrimary')
    if ENV['DATABASE_CONFIG'] == 'multi'
      model = Delayed::Master::Database.model_for(:secondary)
      expect(model.name).to eq('Delayed::Master::DelayedJobSecondary')
    end
  end

  it 'detects spec names with delayed_jobs table' do
    spec_names = Delayed::Master::Database.spec_names
    if ENV['DATABASE_CONFIG'] == 'multi'
      expect(spec_names).to eq([:primary, :secondary])
    else
      expect(spec_names).to eq([:primary])
    end
  end
end
