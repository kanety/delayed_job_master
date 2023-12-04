# DelayedJobMaster

A simple delayed_job master process to control multiple workers.

## Features

* Support concurrent workers with multiprocess and multithread.
* Preload application and fork worker processes on demand.
* Check memory usage after processing a job to kill workers consuming large memory.
* Support signals for restarting master process / reopening log files.
* Check new jobs by polling multiple databases having delayed_jobs table.
* Detect new jobs quickly by using listen/notify feature. (only postgresql)

## Dependencies

* ruby 2.7+
* activesupport 6.0+
* delayed_job 4.1
* delayed_job_active_record 4.1 (execlude sqlite)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'delayed_job_master'
```

And then execute:

    $ bundle

## Generate files

Generate `bin/delayed_job_master` and `config/delayed_job_master.rb`:

    $ rails generate delayed_job_master:config

## Configurations

Edit `config/delayed_job_master.rb`:

```ruby
# working directory
working_directory Dir.pwd

# monitor interval for events (in seconds)
monitor_interval 5

# polling interval for new jobs (in seconds)
polling_interval 30

# path to pid file
pid_file "#{Dir.pwd}/tmp/pids/delayed_job_master.pid"

# path to log file
log_file "#{Dir.pwd}/log/delayed_job_master.log"

# log level
log_level :info

# databases for checking new jobs in case multiple databases
# databases [:primary, :secondary]

# worker1
add_worker do |worker|
  # queue name for the worker
  worker.queues %w(queue1)

  # max process count
  worker.max_processes 1

  # max thread count for each worker
  worker.max_threads 1

  # max memory in MB - if a worker exeeds this value, the worker will stop after finishing current jobs
  worker.max_memory 300

  # max execution time in seconds - if a worker exeeds this value, the worker will stop after finishing current jobs
  worker.max_execution 1.hours

  # configs below are same as delayed_job, see https://github.com/collectiveidea/delayed_job
  # worker.sleep_delay 5
  # worker.read_ahead 5
  # worker.max_attempts 25
  # worker.max_run_time 4.hours
  # worker.min_priority 1
  # worker.max_priority 10
  # worker.destroy_failed_jobs true
end

# worker2
add_worker do |worker|
  worker.queues %w(queue2)
  worker.max_processes 2
  worker.max_threads 2
end

before_fork do |master, worker|
  ActiveRecord::Base.connection.disconnect!
end

after_fork do |master, worker|
  ActiveRecord::Base.establish_connection
end

before_work do |master, worker|
end

after_work do |master, worker|
end

around_work do |master, worker, &block|
  block.call
end
```

### Listen/notify

Listen/notify feature is enabled by default if `pg` gem is detected.
To disable this feature, put `config/initializers/delayed_job_master.rb` as follows:

```ruby
DelayedJobMaster.configure do |config|
  config.listener = nil
end
```

## Usage

Start master:

    $ RAILS_ENV=production bin/delayed_job_master -c config/delayed_job_master.rb -D

Command line options:

* -c, --config: Specify configuration file.
* -D, --daemon: Start master as a daemon.

Stop master immediately, stop workers gracefully:

    $ kill -TERM `cat tmp/pids/delayed_job_master.pid`

Stop master and workers gracefully:

    $ kill -WINCH `cat tmp/pids/delayed_job_master.pid`

Stop master and workers immediately:

    $ kill -QUIT `cat tmp/pids/delayed_job_master.pid`

Reopen log files:

    $ kill -USR1 `cat tmp/pids/delayed_job_master.pid`

Restart master immediately, stop workers gracefully:

    $ kill -USR2 `cat tmp/pids/delayed_job_master.pid`

Workers handle each signal as follows:

* TERM/WINCH/USR2: Workers stop after finishing current jobs.
* QUIT: Workers are killed immediately.
* USR1: Workers reopen log files.

### Worker status

`ps` command shows worker status as follows:

```
$ ps aux
... delayed_job: worker[0] (queue1) [BUSY]  # BUSY process is currently proceeding some jobs
```

After graceful restart, you may find OLD process.

```
$ ps aux
... delayed_job: worker[0] (queue1) [BUSY] [OLD]  # OLD process will stop after finishing current jobs.
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kanety/delayed_job_master.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
