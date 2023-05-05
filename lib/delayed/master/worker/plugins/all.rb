# frozen_string_literal: true

require_relative 'memory_checker'
require_relative 'signal_handler'
require_relative 'status_notifier'

[
  Delayed::Master::Worker::Plugins::MemoryChecker,
  Delayed::Master::Worker::Plugins::SignalHandler,
  Delayed::Master::Worker::Plugins::StatusNotifier
].each do |plugin|
  unless Delayed::Worker.plugins.include?(plugin)
    Delayed::Worker.plugins << plugin
  end
end
