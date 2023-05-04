describe Delayed::Master::Database do
  it 'gets model with specific database connection' do
    model = Delayed::Master::Database.new(:primary).model
    expect(model.name).to eq('Delayed::Master::DelayedJobPrimary')
    if ENV['DATABASE_CONFIG'] == 'multi'
      model = Delayed::Master::Database.new(:secondary).model
      expect(model.name).to eq('Delayed::Master::DelayedJobSecondary')
    end
  end

  it 'detects databases with delayed_jobs table' do
    databases = Delayed::Master::Database.all
    if ENV['DATABASE_CONFIG'] == 'multi'
      expect(databases.map(&:spec_name)).to eq([:primary, :secondary])
    else
      expect(databases.map(&:spec_name)).to eq([:primary])
    end
  end
end
