# CHANGELOG

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
