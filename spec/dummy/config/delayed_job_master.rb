app_root = defined?(Rails) ? Rails.root : Dir.pwd

# working directory
working_directory app_root

# monitor wait time in second
monitor_wait 1

# path to pid file
pid_file "#{app_root}/tmp/pids/delayed_job_master.pid"

# path to log file
log_file STDOUT

# log level
log_level :debug

if ENV['DATABASE_CONFIG'] == 'multi'
  databases [:primary, :secondary]
end

# worker1
add_worker do |worker|
  # queue name for the worker
  worker.queues %w(queue1)

  # max memory in MB
  worker.max_memory 300

  # settings below are same as delayed_job, see https://github.com/collectiveidea/delayed_job
  worker.sleep_delay 5
  worker.read_ahead 5
  worker.max_attempts 25
  worker.max_run_time 4 * 3600
  worker.min_priority 1
  worker.max_priority 10
  worker.destroy_failed_jobs true
end

# worker2
add_worker do |worker|
  worker.queues %w(queue2)
  worker.max_processes 1
  worker.max_threads 5
end

# worker3
add_worker do |worker|
  worker.queues %w(queue3)
  worker.max_processes 3
  worker.max_threads 1
end

before_fork do |master, worker|
  ActiveRecord::Base.connection.disconnect!
end

after_fork do |master, worker|
  if ENV['DATABASE_CONFIG'] == 'multi'
    ActiveRecord::Base.establish_connection worker.database.spec_name
  else
    ActiveRecord::Base.establish_connection
  end
end

before_monitor do |master|
end

after_monitor do |master|
end
