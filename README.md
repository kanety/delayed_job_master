# DelayedJobMaster

A simple delayed_job master process to control multiple workers.

## Features

* Preload application and fork workers fastly.
* Monitor workers and fork new workers if necessary.
* Restart workers with memory limitation.
* Trap USR1 signal to reopen log files.
* Trap USR2 signal to restart master and workers.
* Auto-scale worker processes.

## Dependencies

* ruby 2.3+
* delayed_job 4.1

## Supported delayed_job backends

* delayed_job_active_record 4.1
* delayed_job_mongoid 2.3

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'delayed_job_master', require: false
```

And then execute:

    $ bundle

Create config files:

    $ rails generate delayed_job_master:config

This command creates `bin/delayed_job_master` and `config/delayed_job_master.rb`.

## Configuration

Edit `config/delayed_job_master.rb`:

```ruby
# working directory
working_directory Dir.pwd

# monitor wait time in second
monitor_wait 5

# path to pid file
pid_file "#{Dir.pwd}/tmp/pids/delayed_job_master.pid"

# path to log file
log_file "#{Dir.pwd}/log/delayed_job_master.log"

# log level
log_level :info

# worker1
add_worker do |worker|
  # queue name for the worker
  worker.queues %w(queue1)

  # worker control (:static or :dynamic)
  worker.control :static

  # worker count
  worker.count 1

  # max memory in MB
  worker.max_memory 300

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
  worker.control :dynamic
  worker.count 2
end

before_fork do |master, worker|
  Delayed::Worker.before_fork if defined?(Delayed::Worker)
end

after_fork do |master, worker|
  Delayed::Worker.after_fork if defined?(Delayed::Worker)
end

before_monitor do |master|
  ActiveRecord::Base.connection.verify! if defined?(ActiveRecord::Base)
end

after_monitor do |master|
end
```

## Usage

Start master:

    $ RAILS_ENV=production bin/delayed_job_master -c config/delayed_job_master.rb -D

Command line options:

* -c, --config: Specify configuration file.
* -D, --daemon: Start master as a daemon.

Stop master and workers gracefully:

    $ kill -TERM `cat tmp/pids/delayed_job_master.pid`

Stop master and workers forcefully:

    $ kill -QUIT `cat tmp/pids/delayed_job_master.pid`

Reopen log files:

    $ kill -USR1 `cat tmp/pids/delayed_job_master.pid`

Restart gracefully:

    $ kill -USR2 `cat tmp/pids/delayed_job_master.pid`

Workers handle each signal as follows:

* TERM: Workers stop after finishing current jobs.
* QUIT: Workers are killed immediately.
* USR1: Workers reopen log files.
* USR2: New workers start, old workers stop after finishing current jobs.

## Worker status

`ps` command shows worker status as follows:

```
$ ps aux
... delayed_job.0 (queue1) [BUSY]  # BUSY process is currently proceeding some jobs
```

After graceful restart, you may find OLD process.

```
$ ps aux
... delayed_job.0 (queue1) [BUSY] [OLD]  # OLD process will stop after finishing current jobs.
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kanety/delayed_job_master. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

