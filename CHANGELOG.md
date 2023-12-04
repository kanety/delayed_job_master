# CHANGELOG

## 3.2.0

* Add callback config for `before_work`, `after_work`, and `around_work`.
* Add config for `max_execution`.

## 3.1.0

* Add timer feature.

## 3.0.1

* Fix title of forked process.

## 3.0.0

* Add multithread feature for workers.
* Add graceful stop feature by WINCH signal.
* Add command line options.
* Add listen/notify feature for postgresql.
* Support multiple callbacks.
* Separate waitpid thread and job checker thread.
* Rename some configurations (`worker.count` to `worker.max_processes`, `monitor_wait` to `monitor_interval`).
* Use LIMIT query instead of COUNT query for finding jobs.
* Patch default SQL of delayed_job for postgresql.
* Drop support for ruby < 2.7 and rails < 6.0.

## 2.0.3

* Fix database config detection for rails 7.0.

## 2.0.2

* Force establish_connection after fork.

## 2.0.1

* Force file reopen mode to `a+`.
* Set empty array for default `queues` config.
* Support to configure worker's option as false. (flavono123, #8)

## 2.0.0

* Support multiple databases.
* Logging memory usage.
* Remove static worker support.
* Remove mongoid support.

## 1.2.0

* Add destroy_failed_jobs for worker.
* Get pid and worker instance in after_fork callback.
* Change config class for convenience.

## 1.1.0

* Add monitor callback to verify database connection.
* Refactoring.

## 1.0.0

* First release.
