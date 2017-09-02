# monitor wait time in second
monitor_wait 1

# path to log file
log_file "#{Dir.pwd}/log/delayed_job_master.log"

# log level
log_level :info

# path to pid file
pid_file "#{Dir.pwd}/tmp/pids/delayed_job_master.pid"

# worker1
add_worker do |worker|
  # queue name for the worker
  worker.queues %w(queue1)

  # max memory in MB
  worker.max_memory 300

  # configs below are same as delayed_job, see https://github.com/collectiveidea/delayed_job
  # worker.sleep_delay 5
  # worker.read_ahead 5
  # worker.max_attempts 25
  # worker.max_run_time 4.hours
  # worker.min_priority 1
  # worker.max_priority 10
end

# worker2
add_worker do |worker|
  worker.queues %w(queue2)
end

before_fork do |master, worker_info|
  Delayed::Worker.before_fork
end

after_fork do |master, worker_info|
  Delayed::Worker.after_fork
end
