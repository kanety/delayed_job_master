describe Delayed::Master::Database do
  it 'gets model with specific database connection' do
    Delayed::Master::Database.new(:default).connect do |model|
      expect(model.current_shard).to eq(:default)
    end
    if ENV['DATABASE_CONFIG'] == 'multi'
      Delayed::Master::Database.new(:shard1).connect do |model|
        expect(model.current_shard).to eq(:shard1)
      end
    end
  end

  it 'detects shards with delayed_jobs table' do
    databases = Delayed::Master::Database.all
    if ENV['DATABASE_CONFIG'] == 'multi'
      expect(databases.map(&:shard)).to include(:shard1)
      expect(databases.map(&:shard)).to include(:shard2)
    else
      expect(databases.map(&:shard)).to include(:default)
    end
  end
end
