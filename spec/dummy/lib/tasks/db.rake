namespace :dbs do
  task :migrate => [:environment] do
    if Rails::VERSION::MAJOR >= 6
      Rake::Task["db:migrate"].invoke
    else
      [:primary, :secondary].each do |spec_name|
        ActiveRecord::Base.establish_connection(spec_name)
        Rake::Task["db:migrate"].reenable
        Rake::Task["db:migrate"].invoke
      end
    end
  end
end
