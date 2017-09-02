# DelayedJobMaster

A simple delayed_job master process for managing multiple workers.

## Features

* Preload application and fork multiple workers fastly.
* Monitor workers and fork new processes if they are killed.
* Check worker's memory and restart the worker exeeded memory limit.
* Trap USR1 signal to reopen log files for all workers.
* Trap USR2 signal to restart master and workers gracefully.

## Dependencies

* ruby 2.3+
* delayed_job 4.1

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'delayed_job_master', require: 'false'
```

And then execute:

    $ bundle

Create default files:

    $ rails generate delayed_job_master

This command creates `bin/delayed_job_master` and `config/delayed_job_master.rb`.

## Configuration

Edit `config/delayed_job_master.rb`:

```ruby
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
  # worker.max_memory 300

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
```

## Usage

Start master:

    $ RAILS_ENV=production bin/delayed_job_master -c config/delayed_job_master.rb -D

Command line options:

* -c, --config: Specify configuration file.
* -D, --daemon: Start master as a daemon.

Stop master and workers:

    $ kill -TERM `cat tmp/pids/delayed_job_master.pid`

Reopen log files:

    $ kill -USR1 `cat tmp/pids/delayed_job_master.pid`

Restart gracefully:

    $ kill -USR2 `cat tmp/pids/delayed_job_master.pid`

Workers handle each signal as follows:

* TERM: wWorkers will stop after finishing current job.
* USR1: workers will reopen log files.
* USR2: new workers will start, old workers will stop after finishing current job.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kanety/delayed_job_master. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

